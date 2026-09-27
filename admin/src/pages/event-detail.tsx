import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import { ConfirmDialog } from '@/components/confirm-dialog'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
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
import {
  blockedLabel,
  joinModeLabel,
  lifecycleActionLabel,
  occurrenceStatusLabel,
  pointRoleLabel,
  reportReasonLabel,
  reportStatusLabel,
} from '@/lib/labels'
import type { AdminOccurrenceDetail } from '@/lib/types'
import { useOccurrenceLifecycle } from '@/pages/events'

export function EventDetailPage() {
  const { id = '' } = useParams()
  const lifecycle = useOccurrenceLifecycle()
  const [confirmAction, setConfirmAction] = useState<
    'hide' | 'cancel' | 'republish' | null
  >(null)

  const { data, isLoading, error } = useQuery({
    queryKey: ['admin-occurrence', id],
    queryFn: () =>
      apiRequest<AdminOccurrenceDetail>(`/admin/occurrences/${id}`),
    enabled: !!id,
  })

  if (isLoading) {
    return <DetailSkeleton />
  }

  if (error || !data) {
    return <p className="text-sm text-destructive">Событие не найдено</p>
  }

  function runLifecycle(action: 'hide' | 'cancel' | 'republish') {
    lifecycle.mutate(
      { id: data!.id, action },
      {
        onSuccess: () => {
          toast.success(`Событие ${lifecycleActionLabel(action)}`)
          setConfirmAction(null)
        },
        onError: (err) =>
          toast.error(err instanceof ApiError ? err.message : 'Ошибка'),
      },
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div>
          <Button asChild variant="ghost" size="sm" className="-ml-2 mb-2">
            <Link to="/events">← Назад</Link>
          </Button>
          <h1 className="text-2xl font-semibold tracking-tight">{data.title}</h1>
          <p className="text-sm text-muted-foreground">
            {data.city.name} · {data.participantCount}/{data.maxParticipants}{' '}
            участников
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <Badge variant="secondary">
            {occurrenceStatusLabel(data.status)}
          </Badge>
          <Badge variant="outline">{joinModeLabel(data.joinMode)}</Badge>
          {data.status !== 'cancelled' ? (
            <>
              {data.status !== 'hidden' ? (
                <Button
                  size="sm"
                  variant="secondary"
                  disabled={lifecycle.isPending}
                  onClick={() => setConfirmAction('hide')}
                >
                  Скрыть
                </Button>
              ) : (
                <Button
                  size="sm"
                  variant="outline"
                  disabled={lifecycle.isPending}
                  onClick={() => setConfirmAction('republish')}
                >
                  Опубликовать
                </Button>
              )}
              <Button
                size="sm"
                variant="destructive"
                disabled={lifecycle.isPending}
                onClick={() => setConfirmAction('cancel')}
              >
                Отменить
              </Button>
            </>
          ) : null}
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Описание</CardTitle>
            <CardDescription>
              Старт:{' '}
              {data.startsAt
                ? new Date(data.startsAt).toLocaleString('ru-RU')
                : 'скрыто / не указано'}
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3 text-sm whitespace-pre-wrap">
            {data.description}
            <div className="flex flex-wrap gap-1">
              {[...data.formatIds, ...data.themeIds].map((tag) => (
                <Badge key={tag} variant="outline">
                  {tag}
                </Badge>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Организатор</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2 text-sm">
            <p>
              <Link
                className="font-medium underline-offset-4 hover:underline"
                to={`/users/${data.organizer.id}`}
              >
                {data.organizer.name ?? data.organizer.id}
              </Link>
              {data.organizer.isBlocked ? (
                <Badge className="ml-2" variant="destructive">
                  {blockedLabel(true)}
                </Badge>
              ) : null}
            </p>
            <p className="text-muted-foreground">
              {data.organizer.email ?? data.organizer.phone ?? '—'}
            </p>
            <p className="text-muted-foreground">
              Точек: {data.counts.points} · жалоб: {data.counts.reports} ·
              заявок: {data.counts.participations}
            </p>
          </CardContent>
        </Card>
      </div>

      {data.coverUrls[0] ? (
        <img
          src={data.coverUrls[0]}
          alt=""
          className="max-h-64 w-full rounded-xl border object-cover"
        />
      ) : null}

      <Card>
        <CardHeader>
          <CardTitle>Точки маршрута</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>#</TableHead>
                <TableHead>Название</TableHead>
                <TableHead>Роль</TableHead>
                <TableHead>Адрес</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data.points.map((point) => (
                <TableRow key={point.id}>
                  <TableCell>{point.sortOrder + 1}</TableCell>
                  <TableCell className="font-medium">{point.title}</TableCell>
                  <TableCell>
                    {pointRoleLabel(point)}
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {point.address ?? `${point.latitude}, ${point.longitude}`}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="flex flex-row items-center justify-between gap-2 space-y-0">
          <CardTitle>Жалобы на событие</CardTitle>
          {(data.reports.length ?? 0) > 0 ? (
            <Button asChild size="sm" variant="outline">
              <Link
                to={`/reports?status=ALL&occurrenceId=${encodeURIComponent(data.id)}`}
              >
                Все в очереди
              </Link>
            </Button>
          ) : null}
        </CardHeader>
        <CardContent>
          {(data.reports.length ?? 0) === 0 ? (
            <p className="text-sm text-muted-foreground">Жалоб нет</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Причина</TableHead>
                  <TableHead>Статус</TableHead>
                  <TableHead>Кто</TableHead>
                  <TableHead>Когда</TableHead>
                  <TableHead />
                </TableRow>
              </TableHeader>
              <TableBody>
                {data.reports.map((report) => (
                  <TableRow key={report.id}>
                    <TableCell>{reportReasonLabel(report.reason)}</TableCell>
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
                        {report.reporter.name ?? report.reporter.id.slice(0, 8)}
                      </Link>
                    </TableCell>
                    <TableCell className="text-muted-foreground">
                      {new Date(report.createdAt).toLocaleString('ru-RU')}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button asChild size="sm" variant="outline">
                        <Link
                          to={`/reports?status=ALL&reportId=${encodeURIComponent(report.id)}&occurrenceId=${encodeURIComponent(data.id)}`}
                        >
                          {report.status === 'open' ? 'Разобрать' : 'Открыть'}
                        </Link>
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <ConfirmDialog
        open={confirmAction === 'hide'}
        title="Скрыть событие?"
        description="Событие исчезнет из ленты. Можно будет опубликовать снова."
        confirmLabel="Скрыть"
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setConfirmAction(null)
        }}
        onConfirm={() => runLifecycle('hide')}
      />

      <ConfirmDialog
        open={confirmAction === 'cancel'}
        title="Отменить событие?"
        description="Участники получат уведомление, участия будут отменены."
        confirmLabel="Отменить"
        destructive
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setConfirmAction(null)
        }}
        onConfirm={() => runLifecycle('cancel')}
      />

      <ConfirmDialog
        open={confirmAction === 'republish'}
        title="Опубликовать снова?"
        description="Событие снова появится в ленте."
        confirmLabel="Опубликовать"
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setConfirmAction(null)
        }}
        onConfirm={() => runLifecycle('republish')}
      />
    </div>
  )
}
