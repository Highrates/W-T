import { ApiError } from '@/lib/api'
import { Button } from '@/components/ui/button'

function errorMessage(error: unknown, fallback: string): string {
  if (error instanceof ApiError) return error.message || fallback
  if (error instanceof Error) {
    if (error.cause instanceof ApiError) {
      return error.cause.message || fallback
    }
    return error.message || fallback
  }
  if (
    typeof error === 'object' &&
    error &&
    'message' in error &&
    typeof (error as { message: unknown }).message === 'string'
  ) {
    return (error as { message: string }).message || fallback
  }
  return fallback
}

export function QueryError({
  error,
  fallback = 'Не удалось загрузить данные',
  onRetry,
}: {
  error: unknown
  fallback?: string
  onRetry?: () => void
}) {
  const message = errorMessage(error, fallback)

  return (
    <div className="rounded-lg border border-destructive/30 bg-destructive/5 px-4 py-6 text-center">
      <p className="text-sm text-destructive">{message}</p>
      {onRetry ? (
        <Button
          type="button"
          size="sm"
          variant="outline"
          className="mt-3"
          onClick={onRetry}
        >
          Повторить
        </Button>
      ) : null}
    </div>
  )
}
