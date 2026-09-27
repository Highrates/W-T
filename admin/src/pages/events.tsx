import { useInfiniteQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { useMemo, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { QueryError } from '@/components/query-error'
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
import { occurrenceStatusLabel } from '@/lib/labels'
import type { AdminOccurrenceListItem, CursorPage } from '@/lib/types'

type StatusFilter = 'ALL' | 'PUBLISHED' | 'HIDDEN' | 'CANCELLED' | 'COMPLETED'

function parseStatus(raw: string | null): StatusFilter {
  if (
    raw === 'PUBLISHED' ||
    raw === 'HIDDEN' ||
    raw === 'CANCELLED' ||
    raw === 'COMPLETED'
  ) {
    return raw
  }
  return 'ALL'
}

export function EventsPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [q, setQ] = useState(searchParams.get('q') ?? '')
  const [qApplied, setQApplied] = useState(searchParams.get('q') ?? '')
  const status = parseStatus(searchParams.get('status'))

  const query = useMemo(() => {
    const params = new URLSearchParams({ limit: '50' })
    if (qApplied.trim()) params.set('q', qApplied.trim())
    if (status !== 'ALL') params.set('status', status)
    return params.toString()
  }, [qApplied, status])

  const {
    data,
    isLoading,
    error,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['admin-occurrences', query],
    queryFn: ({ pageParam }) => {
      const params = new URLSearchParams(query)
      if (pageParam) params.set('cursor', pageParam)
      return apiRequest<CursorPage<AdminOccurrenceListItem>>(
        `/admin/occurrences?${params.toString()}`,
      )
    },
    initialPageParam: undefined as string | undefined,
    getNextPageParam: (last) => last.nextCursor ?? undefined,
  })

  const items = data?.pages.flatMap((page) => page.items) ?? []

  function updateParams(patch: Record<string, string | null>) {
    const next = new URLSearchParams(searchParams)
    for (const [key, value] of Object.entries(patch)) {
      if (!value || value === 'ALL') next.delete(key)
      else next.set(key, value)
    }
    setSearchParams(next, { replace: true })
  }

  function applySearch() {
    setQApplied(q)
    updateParams({ q: q.trim() || null })
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">События</h1>
        <p className="text-sm text-muted-foreground">
          Опубликованные, скрытые и отменённые маршруты
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="grid min-w-[220px] flex-1 gap-2">
          <Label htmlFor="q">Поиск</Label>
          <Input
            id="q"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="название, описание, организатор"
            onKeyDown={(e) => {
              if (e.key === 'Enter') applySearch()
            }}
          />
        </div>
        <div className="w-44">
          <Label className="mb-2 block">Статус</Label>
          <Select
            value={status}
            onValueChange={(v) => updateParams({ status: v })}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Все</SelectItem>
              <SelectItem value="PUBLISHED">Опубликовано</SelectItem>
              <SelectItem value="HIDDEN">Скрыто</SelectItem>
              <SelectItem value="CANCELLED">Отменено</SelectItem>
              <SelectItem value="COMPLETED">Завершено</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <Button onClick={applySearch}>Найти</Button>
      </div>

      {isLoading ? (
        <PageSkeleton />
      ) : error ? (
        <QueryError
          error={error}
          fallback="Не удалось загрузить события"
          onRetry={() => void refetch()}
        />
      ) : (
        <div className="space-y-3">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Название</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Организатор</TableHead>
                  <TableHead>Город</TableHead>
                  <TableHead>Участники</TableHead>
                  <TableHead>Жалобы</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((event) => (
                  <TableRow key={event.id}>
                    <TableCell className="max-w-[240px] font-medium">
                      <span className="line-clamp-2">{event.title}</span>
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">
                        {occurrenceStatusLabel(event.status)}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {event.organizer ? (
                        <Link
                          className="underline-offset-4 hover:underline"
                          to={`/users/${event.organizer.id}`}
                        >
                          {event.organizer.name ??
                            event.organizer.id.slice(0, 8)}
                        </Link>
                      ) : (
                        '—'
                      )}
                    </TableCell>
                    <TableCell>{event.city?.name ?? '—'}</TableCell>
                    <TableCell>
                      {event.participantCount}/{event.maxParticipants}
                    </TableCell>
                    <TableCell>{event.counts.reports}</TableCell>
                    <TableCell className="text-right">
                      <Button asChild size="sm" variant="outline">
                        <Link to={`/events/${event.id}`}>Открыть</Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
                {items.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={7}
                      className="h-24 text-center text-muted-foreground"
                    >
                      Событий нет
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

export function useOccurrenceLifecycle() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (payload: {
      id: string
      action: 'hide' | 'cancel' | 'republish'
    }) =>
      apiRequest<{ id: string; status: string }>(
        `/admin/occurrences/${payload.id}/lifecycle`,
        {
          method: 'POST',
          body: { action: payload.action },
        },
      ),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrences'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-occurrence'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-stats'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-user'] })
    },
  })
}
