import { useQuery } from '@tanstack/react-query'
import { Link } from 'react-router-dom'
import { QueryError } from '@/components/query-error'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { CardsSkeleton } from '@/components/ui/skeleton'
import { apiRequest } from '@/lib/api'
import type { AdminStats } from '@/lib/types'
import { cn } from '@/lib/utils'

export function DashboardPage() {
  const { data, isLoading, error, refetch } = useQuery({
    queryKey: ['admin-stats'],
    queryFn: () => apiRequest<AdminStats>('/admin/stats'),
  })

  if (isLoading) {
    return <CardsSkeleton count={6} />
  }

  if (error) {
    return (
      <div className="space-y-6">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight">Дашборд</h1>
          <p className="text-sm text-muted-foreground">
            Сводка модерации — нажмите на карточку, чтобы открыть фильтр
          </p>
        </div>
        <QueryError
          error={error}
          fallback="Не удалось загрузить статистику"
          onRetry={() => void refetch()}
        />
      </div>
    )
  }

  if (!data) {
    return (
      <QueryError
        error={null}
        fallback="Нет данных статистики"
        onRetry={() => void refetch()}
      />
    )
  }

  const cards = [
    {
      title: 'Пользователи',
      description: 'Всего в системе',
      value: `${data.users.total}`,
      hint: `заблокировано ${data.users.blocked}`,
      to: '/users',
    },
    {
      title: 'Заблокированные',
      description: 'Пользователи с блоком',
      value: `${data.users.blocked}`,
      hint: 'открыть фильтр',
      to: '/users?isBlocked=true',
    },
    {
      title: 'Жалобы',
      description: 'Открытые в очереди',
      value: `${data.reports.open}`,
      hint: `разбрано ${data.reports.reviewed} · отклонено ${data.reports.dismissed}`,
      to: '/reports?status=OPEN',
    },
    {
      title: 'События',
      description: 'Опубликовано',
      value: `${data.occurrences.published}`,
      hint: `скрыто ${data.occurrences.hidden} · отменено ${data.occurrences.cancelled}`,
      to: '/events?status=PUBLISHED',
    },
    {
      title: 'Скрытые события',
      description: 'Не видны в ленте',
      value: `${data.occurrences.hidden}`,
      hint: 'фильтр «Скрыто»',
      to: '/events?status=HIDDEN',
    },
    {
      title: 'Участия',
      description: 'Принятые / ожидают',
      value: `${data.joins.accepted}`,
      hint: `ожидают ${data.joins.pending} · всего ${data.joins.total}`,
      to: '/events',
    },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Дашборд</h1>
        <p className="text-sm text-muted-foreground">
          Сводка модерации — нажмите на карточку, чтобы открыть фильтр
        </p>
      </div>
      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => (
          <Link
            key={card.title}
            to={card.to}
            className={cn(
              'rounded-xl outline-none transition-opacity hover:opacity-90 focus-visible:ring-2 focus-visible:ring-ring',
            )}
          >
            <Card className="h-full">
              <CardHeader className="pb-2">
                <CardDescription>{card.description}</CardDescription>
                <CardTitle className="text-3xl">{card.value}</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="text-xs text-muted-foreground">{card.hint}</p>
                <p className="mt-1 text-sm font-medium">{card.title}</p>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}
