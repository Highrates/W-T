import {
  useInfiniteQuery,
  useMutation,
  useQueryClient,
} from '@tanstack/react-query'
import { useEffect, useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import { ConfirmDialog } from '@/components/confirm-dialog'
import { QueryError } from '@/components/query-error'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { PageSkeleton } from '@/components/ui/skeleton'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Textarea } from '@/components/ui/textarea'
import { ApiError, apiRequest } from '@/lib/api'
import {
  lifecycleActionLabel,
  reportActionLabel,
  reportReasonLabel,
  reportStatusLabel,
} from '@/lib/labels'
import type { AdminReport, CursorPage } from '@/lib/types'

type StatusFilter = 'OPEN' | 'REVIEWED' | 'DISMISSED' | 'ALL'

function parseStatus(raw: string | null): StatusFilter {
  if (
    raw === 'OPEN' ||
    raw === 'REVIEWED' ||
    raw === 'DISMISSED' ||
    raw === 'ALL'
  ) {
    return raw
  }
  return 'OPEN'
}

export function ReportsPage() {
  const queryClient = useQueryClient()
  const [searchParams, setSearchParams] = useSearchParams()
  const status = parseStatus(searchParams.get('status'))
  const targetUserId = searchParams.get('targetUserId') ?? ''
  const occurrenceId = searchParams.get('occurrenceId') ?? ''
  const reportId = searchParams.get('reportId') ?? ''
  const [selected, setSelected] = useState<AdminReport | null>(null)
  const [note, setNote] = useState('')
  const [blockUser, setBlockUser] = useState(false)
  const [hideOccurrence, setHideOccurrence] = useState(false)
  const [lifecycleConfirm, setLifecycleConfirm] = useState<{
    id: string
    action: 'hide' | 'cancel' | 'republish'
  } | null>(null)

  const listQuery = useMemo(() => {
    const params = new URLSearchParams({ limit: '50' })
    if (status !== 'ALL') params.set('status', status)
    if (targetUserId) params.set('targetUserId', targetUserId)
    if (occurrenceId) params.set('occurrenceId', occurrenceId)
    return params.toString()
  }, [status, targetUserId, occurrenceId])

  const {
    data,
    isLoading,
    error,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    isFetching,
  } = useInfiniteQuery({
    queryKey: ['admin-reports', status, targetUserId, occurrenceId],
    queryFn: ({ pageParam }) => {
      const params = new URLSearchParams(listQuery)
      if (pageParam) params.set('cursor', pageParam)
      return apiRequest<CursorPage<AdminReport>>(
        `/admin/reports?${params.toString()}`,
      )
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.nextCursor ?? undefined,
  })

  const items = data?.pages.flatMap((page) => page.items) ?? []

  const resolveMutation = useMutation({
    mutationFn: async (payload: {
      id: string
      status: 'REVIEWED' | 'DISMISSED'
      moderatorNote?: string
      actions?: string[]
    }) =>
      apiRequest<AdminReport>(`/admin/reports/${payload.id}`, {
        method: 'PATCH',
        body: {
          status: payload.status,
          moderatorNote: payload.moderatorNote || undefined,
          actions: payload.actions?.length ? payload.actions : undefined,
        },
      }),
    onSuccess: () => {
      toast.success('Жалоба обновлена')
      setSelected(null)
      void queryClient.invalidateQueries({ queryKey: ['admin-reports'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-stats'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrences'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrence'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-users'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-user'] })
    },
    onError: (err) => {
      toast.error(err instanceof ApiError ? err.message : 'Ошибка')
    },
  })

  const lifecycleMutation = useMutation({
    mutationFn: async (payload: {
      id: string
      action: 'hide' | 'cancel' | 'republish'
    }) =>
      apiRequest(`/admin/occurrences/${payload.id}/lifecycle`, {
        method: 'POST',
        body: { action: payload.action },
      }),
    onSuccess: (_, vars) => {
      toast.success(`Событие ${lifecycleActionLabel(vars.action)}`)
      setLifecycleConfirm(null)
      void queryClient.invalidateQueries({ queryKey: ['admin-stats'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-reports'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrences'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrence'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-user'] })
    },
    onError: (err) => {
      toast.error(
        err instanceof ApiError ? err.message : 'Ошибка смены статуса события',
      )
    },
  })

  function openResolve(report: AdminReport) {
    setSelected(report)
    setNote(report.moderatorNote ?? '')
    setBlockUser(false)
    setHideOccurrence(false)
  }

  useEffect(() => {
    if (!reportId) return
    if (selected?.id === reportId) return
    const found = items.find((report) => report.id === reportId)
    if (found) {
      openResolve(found)
      return
    }
    if (hasNextPage && !isFetchingNextPage && !isFetching) {
      void fetchNextPage()
    }
  }, [
    reportId,
    items,
    selected?.id,
    hasNextPage,
    isFetchingNextPage,
    isFetching,
    fetchNextPage,
  ])

  function clearDeepLinkParams() {
    if (!reportId && !occurrenceId) return
    const next = new URLSearchParams(searchParams)
    next.delete('reportId')
    setSearchParams(next, { replace: true })
  }

  function submit(statusValue: 'REVIEWED' | 'DISMISSED') {
    if (!selected) return
    const actions: string[] = []
    if (statusValue === 'REVIEWED') {
      if (blockUser && selected.targetUser) actions.push('block_target_user')
      if (hideOccurrence && selected.occurrence) actions.push('hide_occurrence')
    }
    resolveMutation.mutate({
      id: selected.id,
      status: statusValue,
      moderatorNote: note.trim() || undefined,
      actions,
    })
  }

  function setStatusFilter(value: StatusFilter) {
    const next = new URLSearchParams(searchParams)
    if (value === 'OPEN') next.delete('status')
    else next.set('status', value)
    setSearchParams(next, { replace: true })
  }

  function clearTargetFilter() {
    const next = new URLSearchParams(searchParams)
    next.delete('targetUserId')
    setSearchParams(next, { replace: true })
  }

  function clearOccurrenceFilter() {
    const next = new URLSearchParams(searchParams)
    next.delete('occurrenceId')
    setSearchParams(next, { replace: true })
  }

  const isClosed =
    selected &&
    (selected.status === 'reviewed' || selected.status === 'dismissed')

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Жалобы</h1>
          <p className="text-sm text-muted-foreground">
            Очередь модерации после публикации
          </p>
          {targetUserId ? (
            <p className="mt-2 text-sm">
              Фильтр: жалобы на пользователя{' '}
              <Link
                className="font-mono underline-offset-4 hover:underline"
                to={`/users/${targetUserId}`}
              >
                {targetUserId.slice(0, 8)}…
              </Link>{' '}
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={clearTargetFilter}
              >
                Сбросить
              </Button>
            </p>
          ) : null}
          {occurrenceId ? (
            <p className="mt-2 text-sm">
              Фильтр: жалобы на событие{' '}
              <Link
                className="font-mono underline-offset-4 hover:underline"
                to={`/events/${occurrenceId}`}
              >
                {occurrenceId.slice(0, 8)}…
              </Link>{' '}
              <Button
                type="button"
                size="sm"
                variant="ghost"
                onClick={clearOccurrenceFilter}
              >
                Сбросить
              </Button>
            </p>
          ) : null}
          {reportId && !selected ? (
            <p className="mt-2 text-sm text-muted-foreground">
              Ищем жалобу {reportId.slice(0, 8)}…
            </p>
          ) : null}
        </div>
        <div className="w-48">
          <Label className="mb-2 block">Статус</Label>
          <Select
            value={status}
            onValueChange={(v) => setStatusFilter(v as StatusFilter)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="OPEN">Открытые</SelectItem>
              <SelectItem value="REVIEWED">Разбранные</SelectItem>
              <SelectItem value="DISMISSED">Отклонённые</SelectItem>
              <SelectItem value="ALL">Все</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {isLoading ? (
        <PageSkeleton />
      ) : error ? (
        <QueryError
          error={error}
          fallback="Не удалось загрузить жалобы"
          onRetry={() => void refetch()}
        />
      ) : (
        <div className="space-y-3">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Причина</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Кто пожаловался</TableHead>
                  <TableHead>На кого</TableHead>
                  <TableHead>Событие</TableHead>
                  <TableHead>Когда</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((report) => (
                  <TableRow key={report.id}>
                    <TableCell className="font-medium">
                      <div className="space-y-1">
                        <div>{reportReasonLabel(report.reason)}</div>
                        {(report.status === 'reviewed' ||
                          report.status === 'dismissed') &&
                        report.moderatorNote ? (
                          <p className="line-clamp-2 text-xs text-muted-foreground">
                            {report.moderatorNote}
                          </p>
                        ) : null}
                        {(report.actionsApplied?.length ?? 0) > 0 ? (
                          <div className="flex flex-wrap gap-1">
                            {report.actionsApplied!.map((action) => (
                              <Badge key={action} variant="outline">
                                {reportActionLabel(action)}
                              </Badge>
                            ))}
                          </div>
                        ) : null}
                      </div>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">
                        {reportStatusLabel(report.status)}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      <Link
                        className="underline-offset-4 hover:underline"
                        to={`/users/${report.reporter.id}`}
                      >
                        {report.reporter.name ??
                          report.reporter.id.slice(0, 8)}
                      </Link>
                    </TableCell>
                    <TableCell>
                      {report.targetUser ? (
                        <Link
                          className="underline-offset-4 hover:underline"
                          to={`/users/${report.targetUser.id}`}
                        >
                          {report.targetUser.name ??
                            report.targetUser.id.slice(0, 8)}
                        </Link>
                      ) : (
                        '—'
                      )}
                    </TableCell>
                    <TableCell className="max-w-[200px] truncate">
                      {report.occurrence ? (
                        <Link
                          className="underline-offset-4 hover:underline"
                          to={`/events/${report.occurrence.id}`}
                        >
                          {report.occurrence.title}
                        </Link>
                      ) : (
                        '—'
                      )}
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-muted-foreground">
                      {new Date(report.createdAt).toLocaleString('ru-RU')}
                    </TableCell>
                    <TableCell className="text-right">
                      {report.status === 'open' ? (
                        <Button
                          size="sm"
                          variant="outline"
                          onClick={() => openResolve(report)}
                        >
                          Разобрать
                        </Button>
                      ) : (
                        <Button
                          size="sm"
                          variant="ghost"
                          onClick={() => openResolve(report)}
                        >
                          Детали
                        </Button>
                      )}
                    </TableCell>
                  </TableRow>
                ))}
                {items.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={7}
                      className="h-24 text-center text-muted-foreground"
                    >
                      Жалоб нет
                    </TableCell>
                  </TableRow>
                ) : null}
              </TableBody>
            </Table>
          </div>
          {hasNextPage ? (
            <Button
              variant="outline"
              disabled={isFetchingNextPage}
              onClick={() => void fetchNextPage()}
            >
              {isFetchingNextPage ? 'Загрузка…' : 'Загрузить ещё'}
            </Button>
          ) : null}
        </div>
      )}

      <Dialog
        open={!!selected}
        onOpenChange={(open) => {
          if (!open) {
            setSelected(null)
            clearDeepLinkParams()
          }
        }}
      >
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>
              {selected?.status === 'open' ? 'Разбор жалобы' : 'Жалоба'}
            </DialogTitle>
            <DialogDescription>
              {selected ? reportReasonLabel(selected.reason) : ''}
              {selected?.comment ? ` — ${selected.comment}` : ''}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="text-sm text-muted-foreground">
              Кто пожаловался:{' '}
              {selected ? (
                <Link
                  className="underline-offset-4 hover:underline"
                  to={`/users/${selected.reporter.id}`}
                >
                  {selected.reporter.name ?? selected.reporter.id}
                </Link>
              ) : null}
              <br />
              На кого:{' '}
              {selected?.targetUser ? (
                <Link
                  className="underline-offset-4 hover:underline"
                  to={`/users/${selected.targetUser.id}`}
                >
                  {selected.targetUser.name ?? selected.targetUser.id}
                </Link>
              ) : (
                '—'
              )}
              <br />
              Событие:{' '}
              {selected?.occurrence ? (
                <Link
                  className="underline-offset-4 hover:underline"
                  to={`/events/${selected.occurrence.id}`}
                >
                  {selected.occurrence.title}
                </Link>
              ) : (
                '—'
              )}
            </div>

            {isClosed ? (
              <div className="space-y-2 text-sm">
                <p>
                  <span className="text-muted-foreground">Заметка: </span>
                  {selected?.moderatorNote || '—'}
                </p>
                {(selected?.actionsApplied?.length ?? 0) > 0 ? (
                  <div className="flex flex-wrap gap-1">
                    {selected!.actionsApplied!.map((action) => (
                      <Badge key={action} variant="outline">
                        {reportActionLabel(action)}
                      </Badge>
                    ))}
                  </div>
                ) : null}
              </div>
            ) : (
              <>
                <div className="grid gap-2">
                  <Label htmlFor="note">Заметка модератора</Label>
                  <Textarea
                    id="note"
                    value={note}
                    onChange={(e) => setNote(e.target.value)}
                    maxLength={2000}
                    placeholder="Необязательно"
                  />
                </div>

                {selected?.targetUser ? (
                  <label className="flex items-center gap-2 text-sm">
                    <Checkbox
                      checked={blockUser}
                      onCheckedChange={(v) => setBlockUser(v === true)}
                    />
                    Заблокировать пользователя (при подтверждении)
                  </label>
                ) : null}

                {selected?.occurrence ? (
                  <label className="flex items-center gap-2 text-sm">
                    <Checkbox
                      checked={hideOccurrence}
                      onCheckedChange={(v) => setHideOccurrence(v === true)}
                    />
                    Скрыть событие (при подтверждении)
                  </label>
                ) : null}

                {selected?.occurrence ? (
                  <div className="flex flex-wrap gap-2">
                    <Button
                      type="button"
                      size="sm"
                      variant="secondary"
                      disabled={lifecycleMutation.isPending}
                      onClick={() =>
                        setLifecycleConfirm({
                          id: selected.occurrence!.id,
                          action: 'hide',
                        })
                      }
                    >
                      Скрыть
                    </Button>
                    <Button
                      type="button"
                      size="sm"
                      variant="secondary"
                      disabled={lifecycleMutation.isPending}
                      onClick={() =>
                        setLifecycleConfirm({
                          id: selected.occurrence!.id,
                          action: 'cancel',
                        })
                      }
                    >
                      Отменить
                    </Button>
                    <Button
                      type="button"
                      size="sm"
                      variant="outline"
                      disabled={lifecycleMutation.isPending}
                      onClick={() =>
                        setLifecycleConfirm({
                          id: selected.occurrence!.id,
                          action: 'republish',
                        })
                      }
                    >
                      Опубликовать снова
                    </Button>
                  </div>
                ) : null}
              </>
            )}
          </div>

          {selected?.status === 'open' ? (
            <DialogFooter>
              <Button
                variant="outline"
                disabled={resolveMutation.isPending}
                onClick={() => submit('DISMISSED')}
              >
                Отклонить
              </Button>
              <Button
                disabled={resolveMutation.isPending}
                onClick={() => submit('REVIEWED')}
              >
                Подтвердить
              </Button>
            </DialogFooter>
          ) : null}
        </DialogContent>
      </Dialog>

      <ConfirmDialog
        open={!!lifecycleConfirm}
        title={
          lifecycleConfirm?.action === 'hide'
            ? 'Скрыть событие?'
            : lifecycleConfirm?.action === 'cancel'
              ? 'Отменить событие?'
              : 'Опубликовать снова?'
        }
        description={
          lifecycleConfirm?.action === 'hide'
            ? 'Событие исчезнет из ленты. Можно будет опубликовать снова.'
            : lifecycleConfirm?.action === 'cancel'
              ? 'Участники получат уведомление, участия будут отменены.'
              : 'Событие снова появится в ленте (если было скрыто).'
        }
        confirmLabel={
          lifecycleConfirm?.action === 'hide'
            ? 'Скрыть'
            : lifecycleConfirm?.action === 'cancel'
              ? 'Отменить'
              : 'Опубликовать'
        }
        destructive={lifecycleConfirm?.action === 'cancel'}
        loading={lifecycleMutation.isPending}
        onOpenChange={(open) => {
          if (!open) setLifecycleConfirm(null)
        }}
        onConfirm={() => {
          if (!lifecycleConfirm) return
          lifecycleMutation.mutate(lifecycleConfirm)
        }}
      />
    </div>
  )
}
