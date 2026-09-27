import { useInfiniteQuery } from '@tanstack/react-query'
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
import { blockedLabel, roleLabel } from '@/lib/labels'
import type { AdminUserListItem, CursorPage } from '@/lib/types'

type RoleFilter = 'ALL' | 'USER' | 'MODERATOR' | 'ADMIN'
type BlockedFilter = 'ALL' | 'true' | 'false'

function parseRole(raw: string | null): RoleFilter {
  if (raw === 'USER' || raw === 'MODERATOR' || raw === 'ADMIN') return raw
  return 'ALL'
}

function parseBlocked(raw: string | null): BlockedFilter {
  if (raw === 'true' || raw === 'false') return raw
  return 'ALL'
}

export function UsersPage() {
  const [searchParams, setSearchParams] = useSearchParams()
  const [q, setQ] = useState(searchParams.get('q') ?? '')
  const [qApplied, setQApplied] = useState(searchParams.get('q') ?? '')
  const role = parseRole(searchParams.get('role'))
  const blocked = parseBlocked(searchParams.get('isBlocked'))

  const query = useMemo(() => {
    const params = new URLSearchParams({ limit: '50' })
    if (qApplied.trim()) params.set('q', qApplied.trim())
    if (role !== 'ALL') params.set('role', role)
    if (blocked !== 'ALL') params.set('isBlocked', blocked)
    return params.toString()
  }, [qApplied, role, blocked])

  const {
    data,
    isLoading,
    error,
    refetch,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
  } = useInfiniteQuery({
    queryKey: ['admin-users', query],
    queryFn: ({ pageParam }) => {
      const params = new URLSearchParams(query)
      if (pageParam) params.set('cursor', pageParam)
      return apiRequest<CursorPage<AdminUserListItem>>(
        `/admin/users?${params.toString()}`,
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
        <h1 className="text-2xl font-semibold tracking-tight">Пользователи</h1>
        <p className="text-sm text-muted-foreground">
          Поиск, блокировка, роли (роль меняет только админ)
        </p>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <div className="grid min-w-[220px] flex-1 gap-2">
          <Label htmlFor="q">Поиск</Label>
          <Input
            id="q"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="имя, email, телефон"
            onKeyDown={(e) => {
              if (e.key === 'Enter') applySearch()
            }}
          />
        </div>
        <div className="w-44">
          <Label className="mb-2 block">Роль</Label>
          <Select
            value={role}
            onValueChange={(v) => updateParams({ role: v })}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Все</SelectItem>
              <SelectItem value="USER">Пользователь</SelectItem>
              <SelectItem value="MODERATOR">Модератор</SelectItem>
              <SelectItem value="ADMIN">Админ</SelectItem>
            </SelectContent>
          </Select>
        </div>
        <div className="w-44">
          <Label className="mb-2 block">Блок</Label>
          <Select
            value={blocked}
            onValueChange={(v) => updateParams({ isBlocked: v })}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="ALL">Все</SelectItem>
              <SelectItem value="false">Активные</SelectItem>
              <SelectItem value="true">Заблокированные</SelectItem>
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
          fallback="Не удалось загрузить пользователей"
          onRetry={() => void refetch()}
        />
      ) : (
        <div className="space-y-3">
          <div className="rounded-lg border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Имя</TableHead>
                  <TableHead>Контакт</TableHead>
                  <TableHead>Роль</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Город</TableHead>
                  <TableHead className="text-right">События</TableHead>
                  <TableHead className="text-right">Жалобы</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {items.map((user) => (
                  <TableRow key={user.id}>
                    <TableCell className="font-medium">
                      {user.name ?? '—'}
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {user.email ?? user.phone ?? '—'}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline">{roleLabel(user.role)}</Badge>
                    </TableCell>
                    <TableCell>
                      {user.isBlocked ? (
                        <Badge variant="destructive">
                          {blockedLabel(true)}
                        </Badge>
                      ) : (
                        <Badge variant="secondary">
                          {blockedLabel(false)}
                        </Badge>
                      )}
                    </TableCell>
                    <TableCell>{user.city?.name ?? '—'}</TableCell>
                    <TableCell className="text-right tabular-nums">
                      {user.counts.organizedEvents}
                    </TableCell>
                    <TableCell className="text-right tabular-nums">
                      <span title="на него / подал">
                        {user.counts.reportsReceived}
                        <span className="text-muted-foreground"> / </span>
                        {user.counts.reportsFiled}
                      </span>
                    </TableCell>
                    <TableCell className="text-right">
                      <Button asChild size="sm" variant="outline">
                        <Link to={`/users/${user.id}`}>Открыть</Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
                {items.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={8}
                      className="h-24 text-center text-muted-foreground"
                    >
                      Никого не найдено
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
