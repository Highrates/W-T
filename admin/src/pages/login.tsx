import { useState, type FormEvent } from 'react'
import { Navigate, useLocation, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
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
import { useAuth, type OtpChannel } from '@/lib/auth'
import { cn } from '@/lib/utils'

function redirectFromState(state: unknown): string {
  const from = (state as { from?: { pathname?: string; search?: string; hash?: string } } | null)
    ?.from
  if (!from?.pathname || from.pathname === '/login') return '/'
  return `${from.pathname}${from.search ?? ''}${from.hash ?? ''}`
}

export function LoginPage() {
  const { requestOtp, verifyOtp, isAuthenticated, isStaff, loading } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const afterLogin = redirectFromState(location.state)
  const [channel, setChannel] = useState<OtpChannel>('email')
  const [identity, setIdentity] = useState('')
  const [code, setCode] = useState('')
  const [step, setStep] = useState<'identity' | 'code'>('identity')
  const [busy, setBusy] = useState(false)

  if (!loading && isAuthenticated && isStaff) {
    return <Navigate to={afterLogin} replace />
  }

  async function onRequest(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    try {
      await requestOtp(channel, identity.trim())
      setStep('code')
      toast.success(
        channel === 'email'
          ? 'Код отправлен на email (в dev — лог бэкенда)'
          : 'Код отправлен по SMS (в stub/dev — лог бэкенда)',
      )
    } catch (err) {
      toast.error(
        err instanceof ApiError ? err.message : 'Не удалось отправить код',
      )
    } finally {
      setBusy(false)
    }
  }

  async function onVerify(e: FormEvent) {
    e.preventDefault()
    setBusy(true)
    try {
      await verifyOtp(channel, identity.trim(), code.trim())
      navigate(afterLogin, { replace: true })
    } catch (err) {
      if (err instanceof Error && err.message === 'STAFF_REQUIRED') {
        toast.error('Нужна роль админа или модератора')
        return
      }
      if (err instanceof Error && err.message === 'ACCOUNT_BLOCKED') {
        toast.error('Аккаунт заблокирован')
        return
      }
      toast.error(err instanceof ApiError ? err.message : 'Неверный код')
    } finally {
      setBusy(false)
    }
  }

  function switchChannel(next: OtpChannel) {
    setChannel(next)
    setIdentity('')
    setCode('')
    setStep('identity')
  }

  return (
    <div className="flex min-h-svh items-center justify-center bg-muted/40 p-4">
      <Card className="w-full max-w-md">
        <CardHeader>
          <CardTitle>Выходи — Админка</CardTitle>
          <CardDescription>
            Вход по OTP (email или телефон). Нужна роль модератора или админа.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-2 rounded-lg bg-muted p-1">
            <button
              type="button"
              className={cn(
                'rounded-md px-3 py-2 text-sm font-medium transition-colors',
                channel === 'email'
                  ? 'bg-background shadow-sm'
                  : 'text-muted-foreground',
              )}
              onClick={() => switchChannel('email')}
            >
              Email
            </button>
            <button
              type="button"
              className={cn(
                'rounded-md px-3 py-2 text-sm font-medium transition-colors',
                channel === 'phone'
                  ? 'bg-background shadow-sm'
                  : 'text-muted-foreground',
              )}
              onClick={() => switchChannel('phone')}
            >
              Телефон
            </button>
          </div>

          {step === 'identity' ? (
            <form className="grid gap-4" onSubmit={onRequest}>
              <div className="grid gap-2">
                <Label htmlFor="identity">
                  {channel === 'email' ? 'Email' : 'Телефон'}
                </Label>
                <Input
                  id="identity"
                  type={channel === 'email' ? 'email' : 'tel'}
                  autoComplete={channel === 'email' ? 'email' : 'tel'}
                  required
                  value={identity}
                  onChange={(e) => setIdentity(e.target.value)}
                  placeholder={
                    channel === 'email' ? 'ops@example.com' : '+79991234567'
                  }
                />
              </div>
              <Button type="submit" disabled={busy}>
                {busy ? 'Отправка…' : 'Получить код'}
              </Button>
            </form>
          ) : (
            <form className="grid gap-4" onSubmit={onVerify}>
              <div className="grid gap-2">
                <Label htmlFor="code">
                  {channel === 'email'
                    ? 'Код из письма / лога'
                    : 'Код из SMS / лога'}
                </Label>
                <Input
                  id="code"
                  inputMode="numeric"
                  pattern="[0-9]{6}"
                  maxLength={6}
                  required
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  placeholder="123456"
                />
              </div>
              <Button type="submit" disabled={busy}>
                {busy ? 'Проверка…' : 'Войти'}
              </Button>
              <Button
                type="button"
                variant="ghost"
                onClick={() => {
                  setStep('identity')
                  setCode('')
                }}
              >
                Изменить {channel === 'email' ? 'email' : 'телефон'}
              </Button>
            </form>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
