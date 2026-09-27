import { useInfiniteQuery } from '@tanstack/react-query'
import { useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { QueryError } from '@/components/query-error'
import { AuditMetadataCell } from '@/components/audit-metadata-cell'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
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
import { apiRequest } from '@/lib/api'
import {
  auditActionLabel,
  auditTargetTypeLabel,
} from '@/lib/labels'
import type { AdminAuditLog, CursorPage } from '@/lib/types'

const ACTIONS = [
  'USER_BLOCKED',
  'USER_UNBLOCKED',
  'USER_ROLE_CHANGED',
  'OCCURRENCE_HIDDEN',
  'OCCURRENCE_UNHIDDEN',
  'OCCURRENCE_CANCELLED',
  'REPORT_STATUS_CHANGED',
] as const

type ActionFilter = 'ALL' | (typeof ACTIONS)[number]
type TargetTypeFilter = 'ALL' | 'user' | 'occurrence' | 'report'

function targetHref(targetType: string, targetId: string) {
  if (targetType === 'user') return `/users/${targetId}`
  if (targetType === 'occurrence') return `/events/${targetId}`
  if (targetType === 'report') {
    return `/reports?status=ALL&reportId=${encodeURIComponent(targetId)}`
  }
  return null
}

export function AuditLogsPage() {
  const [targetType, setTargetType] = useState<TargetTypeFilter>('ALL')
  const [action, setAction] = useState<ActionFilter>('ALL')
  const [actorId, setActorId] = useState('')
  const [actorIdApplied, setActorIdApplied] = useState('')

  const query = useMemo(() => {
    const params = new URLSearchParams({ limit: '50' })
    if (targetType !== 'ALL') params.set('targetType', targetType)
    if (action !== 'ALL') params.set('action', action)
    if (actorIdApplied.trim()) params.set('actorId', actorIdApplied.trim())
    return params.toString()
  }, [targetType, action, actorIdApplied])

  const {
    data,
    isLoading,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    error,
    refetch,
  } = useInfiniteQuery({
    queryKey: ['admin-audit-logs', query],
    queryFn: ({ pageParam }) => {
      const params = new URLSearchParams(query)
      if (pageParam) params.set('cursor', pageParam)
      return apiRequest<CursorPage<AdminAuditLog>>(
        `/admin/audit-logs?${params.toString()}`,
      )
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.nextCursor ?? undefined,
  })

  const items = data?.pages.flatMap((page) => page.items) ?? []

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">
          Журнал действий
        </h1>
        <p className="text-sm text-muted-foreground">
          Действия модераторов и админов
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="w-44">
          <Label className="mb-2 block">Тип объекта</Label>
          <Select
            value={targetType}
            onValueChange={(v) => setTargetType(v as TargetTypeFilter)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Все</SelectItem>
              <SelectItem value="user">Пользователь</SelectItem>
              <SelectItem value="occurrence">Событие</SelectItem>
              <SelectItem value="report">Жалоба</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="w-64">
          <Label className="mb-2 block">Действие</Label>
          <Select
            value={action}
            onValueChange={(v) => setAction(v as ActionFilter)}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Все</SelectItem>
              {ACTIONS.map((item) => (
                <SelectItem key={item} value={item}>
                  {auditActionLabel(item)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>
        <div className="grid min-w-[260px] flex-1 gap-2">
          <Label htmlFor="actorId">ID модератора</Label>
          <Input
            id="actorId"
            value={actorId}
            onChange={(e) => setActorId(e.target.value)}
            placeholder="UUID модератора"
            onKeyDown={(e) => {
              if (e.key === 'Enter') setActorIdApplied(actorId.trim())
            }}
          />
        </div>
        <Button onClick={() => setActorIdApplied(actorId.trim())}>
          Применить
        </Button>
      </div>

      {isLoading ? (
        <PageSkeleton />
      ) : error ? (
        <QueryError
          error={error}
          fallback="Не удалось загрузить журнал действий"
          onRetry={() => void refetch()}
        />
      ) : (
        <div className="space-y-3">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Когда</TableHead>
                  <TableHead>Действие</TableHead>
                  <TableHead>Кто</TableHead>
                  <TableHead>Объект</TableHead>
                  <TableHead>Детали</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((row) => {
                  const href = targetHref(row.targetType, row.targetId)
                  return (
                    <TableRow key={row.id}>
                      <TableCell className="whitespace-nowrap text-muted-foreground">
                        {new Date(row.createdAt).toLocaleString('ru-RU')}
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {auditActionLabel(row.action)}
                        </Badge>
                      </TableCell>
                      <TableCell>
                        <Link
                          className="underline-offset-4 hover:underline"
                          to={`/users/${row.actor.id}`}
                        >
                          {row.actor.name ??
                            row.actor.email ??
                            row.actor.phone ??
                            row.actor.id.slice(0, 8)}
                        </Link>
                      </TableCell>
                      <TableCell>
                        <div className="text-sm">
                          <Badge variant="outline" className="mb-1">
                            {auditTargetTypeLabel(row.targetType)}
                          </Badge>
                          <div>
                            {href ? (
                              <Link
                                className="font-mono text-xs underline-offset-4 hover:underline"
                                to={href}
                              >
                                {row.targetId.slice(0, 8)}…
                              </Link>
                            ) : (
                              <span className="font-mono text-xs">
                                {row.targetId.slice(0, 8)}…
                              </span>
                            )}
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        <AuditMetadataCell metadata={row.metadata} />
                      </TableCell>
                    </TableRow>
                  )
                })}
                {items.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={5}
                      className="h-24 text-center text-muted-foreground"
                    >
                      Записей нет
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
    </div>
  )
}
