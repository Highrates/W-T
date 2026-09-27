import { useState } from 'react'
import { Link } from 'react-router-dom'
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
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { ApiError } from '@/lib/api'
import { lifecycleActionLabel, occurrenceStatusLabel } from '@/lib/labels'
import { useOccurrenceLifecycle } from '@/pages/events'

type LifecycleAction = 'hide' | 'cancel' | 'republish'

export function ToolsPage() {
  const lifecycle = useOccurrenceLifecycle()
  const [occurrenceId, setOccurrenceId] = useState('')
  const [pending, setPending] = useState<LifecycleAction | null>(null)
  const [lastStatus, setLastStatus] = useState<string | null>(null)

  const id = occurrenceId.trim()

  function run(action: LifecycleAction) {
    if (!id) {
      toast.error('Укажите ID события')
      return
    }
    lifecycle.mutate(
      { id, action },
      {
        onSuccess: (data) => {
          const status =
            data && typeof data === 'object' && 'status' in data
              ? String((data as { status: string }).status)
              : null
          setLastStatus(status)
          setPending(null)
          toast.success(`Событие ${lifecycleActionLabel(action)}`)
        },
        onError: (err) =>
          toast.error(err instanceof ApiError ? err.message : 'Ошибка'),
      },
    )
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight">Инструменты</h1>
        <p className="text-sm text-muted-foreground">
          Быстрые действия по ID без поиска в списке
        </p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Жизненный цикл события</CardTitle>
          <CardDescription>
            Скрыть, отменить или снова опубликовать событие по UUID
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-2">
            <Label htmlFor="occurrenceId">ID события</Label>
            <Input
              id="occurrenceId"
              value={occurrenceId}
              onChange={(e) => setOccurrenceId(e.target.value)}
              placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
              className="font-mono text-sm"
            />
          </div>

          <div className="flex flex-wrap gap-2">
            <Button
              variant="secondary"
              disabled={!id || lifecycle.isPending}
              onClick={() => setPending('hide')}
            >
              Скрыть
            </Button>
            <Button
              variant="destructive"
              disabled={!id || lifecycle.isPending}
              onClick={() => setPending('cancel')}
            >
              Отменить
            </Button>
            <Button
              variant="outline"
              disabled={!id || lifecycle.isPending}
              onClick={() => setPending('republish')}
            >
              Опубликовать снова
            </Button>
            {id ? (
              <Button asChild variant="ghost">
                <Link to={`/events/${id}`}>Открыть карточку</Link>
              </Button>
            ) : null}
          </div>

          {lastStatus ? (
            <p className="text-sm text-muted-foreground">
              Последний статус:{' '}
              <Badge variant="secondary">
                {occurrenceStatusLabel(lastStatus)}
              </Badge>
            </p>
          ) : null}
        </CardContent>
      </Card>

      <ConfirmDialog
        open={pending === 'hide'}
        title="Скрыть событие?"
        description={`ID: ${id}. Событие исчезнет из ленты.`}
        confirmLabel="Скрыть"
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setPending(null)
        }}
        onConfirm={() => run('hide')}
      />
      <ConfirmDialog
        open={pending === 'cancel'}
        title="Отменить событие?"
        description={`ID: ${id}. Участники будут уведомлены.`}
        confirmLabel="Отменить"
        destructive
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setPending(null)
        }}
        onConfirm={() => run('cancel')}
      />
      <ConfirmDialog
        open={pending === 'republish'}
        title="Опубликовать снова?"
        description={`ID: ${id}. Событие снова появится в ленте (если было скрыто).`}
        confirmLabel="Опубликовать"
        loading={lifecycle.isPending}
        onOpenChange={(open) => {
          if (!open) setPending(null)
        }}
        onConfirm={() => run('republish')}
      />
    </div>
  )
}
