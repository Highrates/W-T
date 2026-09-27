import { Button } from '@/components/ui/button'
import { useAuth } from '@/lib/auth'

export function ForbiddenPage() {
  const { logout, user } = useAuth()

  return (
    <div className="flex min-h-svh flex-col items-center justify-center gap-4 p-6 text-center">
      <h1 className="text-2xl font-semibold">Недостаточно прав</h1>
      <p className="max-w-md text-muted-foreground">
        Аккаунт {user?.email ?? user?.phone ?? user?.id} не имеет роли админа
        или модератора. Попросите ops выполнить{' '}
        <code className="rounded bg-muted px-1">npm run ops:promote-admin</code>.
      </p>
      <Button variant="outline" onClick={() => void logout()}>
        Выйти
      </Button>
    </div>
  )
}
