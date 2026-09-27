import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import { ConfirmDialog } from '@/components/confirm-dialog'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Label } from '@/components/ui/label'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import { DetailSkeleton } from '@/components/ui/skeleton'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { ApiError, apiRequest } from '@/lib/api'
import { useAuth } from '@/lib/auth'
import {
  blockedLabel,
  occurrenceStatusLabel,
  reportActionLabel,
  reportReasonLabel,
  reportStatusLabel,
  roleLabel,
} from '@/lib/labels'
import type { AdminUserDetail } from '@/lib/types'

function initials(name: string | null, fallback: string) {
  if (name?.trim()) {
    return name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((part) => part[0]?.toUpperCase() ?? '')
      .join('')
  }
  return fallback.slice(0, 2).toUpperCase()
}

export function UserDetailPage() {
  const { id = '' } = useParams()
  const { user: me, isAdmin } = useAuth()
  const queryClient = useQueryClient()
  const [blockConfirm, setBlockConfirm] = useState(false)
  const [pendingRole, setPendingRole] = useState<string | null>(null)

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-user', id],
    queryFn: () => apiRequest<AdminUserDetail>(`/admin/users/${id}`),
    enabled: !!id,
  })

  const updateMutation = useMutation({
    mutationFn: (body: { isBlocked?: boolean; role?: string }) =>
      apiRequest<AdminUserDetail>(`/admin/users/${id}`, {
        method: 'PATCH',
        body,
      }),
    onSuccess: () => {
      toast.success('Пользователь обновлён')
      setBlockConfirm(false)
      setPendingRole(null)
      void queryClient.invalidateQueries({ queryKey: ['admin-user', id] })
      void queryClient.invalidateQueries({ queryKey: ['admin-users'] })
      void queryClient.invalidateQueries({ queryKey: ['admin-stats'] })
    },
    onError: (err) => {
      toast.error(err instanceof ApiError ? err.message : 'Ошибка')
    },
  })

  if (isLoading) {
    return <DetailSkeleton />
  }

  if (error || !data) {
    return (
      <p className="text-sm text-destructive">Пользователь не найден</p>
    )
  }

  const isSelf = me?.id === data.id
  const canBlock = !(isSelf && !data.isBlocked)
  // Self-admin: cannot demote (backend forbids); disable non-ADMIN options
  const roleSelectDisabled =
    updateMutation.isPending || (isSelf && data.role.toLowerCase() === 'admin')

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="flex items-start gap-4">
          <Avatar className="size-20 border">
            {data.avatarUrl ? (
              <AvatarImage src={data.avatarUrl} alt="" />
            ) : null}
            <AvatarFallback>
              {initials(data.name, data.email ?? data.phone ?? data.id)}
            </AvatarFallback>
          </Avatar>
          <div>
            <Button asChild variant="ghost" size="sm" className="-ml-2 mb-2">
              <Link to="/users">← Назад</Link>
            </Button>
            <h1 className="text-2xl font-semibold tracking-tight">
              {data.name ?? 'Без имени'}
            </h1>
            <p className="text-sm text-muted-foreground">
              {data.email ?? data.phone ?? data.id}
            </p>
            {data.interestTags.length > 0 ? (
              <div className="mt-3 flex flex-wrap gap-1.5">
                {data.interestTags.map((tag) => (
                  <Badge key={tag} variant="secondary">
                    {tag}
                  </Badge>
                ))}
              </div>
            ) : (
              <p className="mt-2 text-xs text-muted-foreground">
                Интересы не указаны
              </p>
            )}
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="outline">{roleLabel(data.role)}</Badge>
          {data.isBlocked ? (
            <Badge variant="destructive">{blockedLabel(true)}</Badge>
          ) : (
            <Badge variant="secondary">{blockedLabel(false)}</Badge>
          )}
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Профиль</CardTitle>
            <CardDescription>Город и активность</CardDescription>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <p>Город: {data.city?.name ?? '—'}</p>
            <p>О себе: {data.bio ?? '—'}</p>
            <p>
              Был в сети:{' '}
              {data.lastActiveAt
                ? new Date(data.lastActiveAt).toLocaleString('ru-RU')
                : '—'}
            </p>
            <p>
              Создан: {new Date(data.createdAt).toLocaleString('ru-RU')}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Счётчики</CardTitle>
          </CardHeader>
          <CardContent className="grid grid-cols-2 gap-3 text-sm">
            <div>
              <p className="text-muted-foreground">Организовал</p>
              <p className="text-lg font-semibold">
                {data.counts.organizedEvents}
              </p>
            </div>
            <div>
              <p className="text-muted-foreground">Участия</p>
              <p className="text-lg font-semibold">
                {data.counts.participations}
              </p>
            </div>
            <div>
              <p className="text-muted-foreground">Жалобы на него</p>
              <p className="text-lg font-semibold">
                {data.counts.reportsReceived}
              </p>
              {data.counts.reportsReceived > 0 ? (
                <Button asChild size="sm" variant="link" className="h-auto px-0">
                  <Link to={`/reports?status=ALL&targetUserId=${data.id}`}>
                    Открыть в жалобах
                  </Link>
                </Button>
              ) : null}
            </div>
            <div>
              <p className="text-muted-foreground">Подал жалоб</p>
              <p className="text-lg font-semibold">
                {data.counts.reportsFiled}
              </p>
            </div>
            <div>
              <p className="text-muted-foreground">Push-устройства</p>
              <p className="text-lg font-semibold">
                {data.counts.deviceTokens}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Модерация</CardTitle>
          <CardDescription>
            Блокировка отзывает сессии. Роль меняет только админ.
            {isSelf
              ? ' Нельзя заблокировать или понизить собственный аккаунт.'
              : ''}
          </CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap items-end gap-4">
          <Button
            variant={data.isBlocked ? 'secondary' : 'destructive'}
            disabled={updateMutation.isPending || !canBlock}
            title={
              !canBlock
                ? 'Нельзя заблокировать собственный аккаунт'
                : undefined
            }
            onClick={() => setBlockConfirm(true)}
          >
            {data.isBlocked ? 'Разблокировать' : 'Заблокировать'}
          </Button>

          {isAdmin ? (
            <div className="w-48 space-y-2">
              <Label>Роль</Label>
              <Select
                value={data.role.toUpperCase()}
                onValueChange={(role) => {
                  if (role === data.role.toUpperCase()) return
                  if (isSelf && role !== 'ADMIN') return
                  setPendingRole(role)
                }}
                disabled={roleSelectDisabled}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="USER" disabled={isSelf}>
                    Пользователь
                  </SelectItem>
                  <SelectItem value="MODERATOR" disabled={isSelf}>
                    Модератор
                  </SelectItem>
                  <SelectItem value="ADMIN">Админ</SelectItem>
                </SelectContent>
              </Select>
              {isSelf ? (
                <p className="text-xs text-muted-foreground">
                  Свою роль админа понизить нельзя
                </p>
              ) : null}
            </div>
          ) : null}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Маршруты / события</CardTitle>
          <CardDescription>
            До 30 последних событий, где пользователь — организатор
          </CardDescription>
        </CardHeader>
        <CardContent>
          {(data.organizedEvents?.length ?? 0) === 0 ? (
            <p className="text-sm text-muted-foreground">Событий нет</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Название</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Город</TableHead>
                  <TableHead>Жалобы</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.organizedEvents!.map((event) => (
                  <TableRow key={event.id}>
                    <TableCell className="font-medium">{event.title}</TableCell>
                    <TableCell>
                      <Badge variant="secondary">
                        {occurrenceStatusLabel(event.status)}
                      </Badge>
                    </TableCell>
                    <TableCell>{event.city?.name ?? '—'}</TableCell>
                    <TableCell>{event.counts.reports}</TableCell>
                    <TableCell className="text-right">
                      <Button asChild size="sm" variant="outline">
                        <Link to={`/events/${event.id}`}>Открыть</Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
            <CardTitle>Жалобы на пользователя</CardTitle>
            <Button asChild size="sm" variant="outline">
              <Link to={`/reports?status=ALL&targetUserId=${data.id}`}>
                Все жалобы
              </Link>
            </Button>
          </CardHeader>
          <CardContent>
            {(data.reportsReceived?.length ?? 0) === 0 ? (
              <p className="text-sm text-muted-foreground">Нет</p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Причина</TableHead>
                    <TableHead>Статус</TableHead>
                    <TableHead>Событие</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {data.reportsReceived!.map((report) => (
                    <TableRow key={report.id}>
                      <TableCell>
                        <div className="space-y-1">
                          <div>{reportReasonLabel(report.reason)}</div>
                          {(report.status === 'reviewed' ||
                            report.status === 'dismissed') &&
                          report.moderatorNote ? (
                            <p className="text-xs text-muted-foreground">
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
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Подал жалобы</CardTitle>
          </CardHeader>
          <CardContent>
            {(data.reportsFiled?.length ?? 0) === 0 ? (
              <p className="text-sm text-muted-foreground">Нет</p>
            ) : (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Причина</TableHead>
                    <TableHead>Статус</TableHead>
                    <TableHead>Цель</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {data.reportsFiled!.map((report) => (
                    <TableRow key={report.id}>
                      <TableCell>
                        <div className="space-y-1">
                          <div>{reportReasonLabel(report.reason)}</div>
                          {(report.status === 'reviewed' ||
                            report.status === 'dismissed') &&
                          report.moderatorNote ? (
                            <p className="text-xs text-muted-foreground">
                              {report.moderatorNote}
                            </p>
                          ) : null}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="secondary">
                          {reportStatusLabel(report.status)}
                        </Badge>
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
                        ) : report.occurrence ? (
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
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            )}
          </CardContent>
        </Card>
      </div>

      <ConfirmDialog
        open={blockConfirm}
        title={data.isBlocked ? 'Разблокировать?' : 'Заблокировать?'}
        description={
          data.isBlocked
            ? 'Пользователь снова сможет пользоваться приложением.'
            : 'Активные сессии будут отозваны, вход станет недоступен.'
        }
        confirmLabel={data.isBlocked ? 'Разблокировать' : 'Заблокировать'}
        destructive={!data.isBlocked}
        loading={updateMutation.isPending}
        onOpenChange={setBlockConfirm}
        onConfirm={() =>
          updateMutation.mutate({ isBlocked: !data.isBlocked })
        }
      />

      <ConfirmDialog
        open={!!pendingRole}
        title="Сменить роль?"
        description={`Новая роль: ${pendingRole ? roleLabel(pendingRole) : ''}. Это влияет на доступ к админке.`}
        confirmLabel="Сменить роль"
        loading={updateMutation.isPending}
        onOpenChange={(open) => {
          if (!open) setPendingRole(null)
        }}
        onConfirm={() => {
          if (!pendingRole) return
          updateMutation.mutate({ role: pendingRole })
        }}
      />
    </div>
  )
}
