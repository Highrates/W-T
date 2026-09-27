import { useEffect, useRef, useState } from 'react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import {
  getAccessToken,
  getAccessTokenExpiresAtMs,
  refreshSession,
} from '@/lib/api'
import { useAuth } from '@/lib/auth'

const WARN_SECONDS = Number(import.meta.env.VITE_SESSION_WARN_SECONDS || 120)

function formatLeft(seconds: number) {
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  if (m <= 0) return `${s} с`
  return `${m} мин ${s.toString().padStart(2, '0')} с`
}

/**
 * Optional UX: warn before access JWT expiry and offer proactive refresh.
 * Does not replace 401→refresh in apiRequest.
 */
export function SessionExpiryWatcher() {
  const { isAuthenticated, isStaff } = useAuth()
  const [secondsLeft, setSecondsLeft] = useState<number | null>(null)
  const [busy, setBusy] = useState(false)
  const warnedRef = useRef(false)
  const tokenEpochRef = useRef<string | null>(null)

  useEffect(() => {
    if (!isAuthenticated || !isStaff) {
      setSecondsLeft(null)
      warnedRef.current = false
      tokenEpochRef.current = null
      return
    }

    const tick = () => {
      const token = getAccessToken()
      if (token !== tokenEpochRef.current) {
        tokenEpochRef.current = token
        warnedRef.current = false
      }

      const expiresAt = getAccessTokenExpiresAtMs()
      if (expiresAt == null) {
        setSecondsLeft(null)
        return
      }

      const left = Math.max(0, Math.floor((expiresAt - Date.now()) / 1000))
      setSecondsLeft(left)

      if (
        WARN_SECONDS > 0 &&
        left > 0 &&
        left <= WARN_SECONDS &&
        !warnedRef.current
      ) {
        warnedRef.current = true
        toast.warning('Сессия скоро истечёт', {
          description: `Access-токен истечёт через ${formatLeft(left)}. Продлите сессию, чтобы не прерывать работу.`,
          duration: 12_000,
        })
      }
    }

    tick()
    const id = window.setInterval(tick, 1000)
    return () => window.clearInterval(id)
  }, [isAuthenticated, isStaff])

  if (
    !isAuthenticated ||
    !isStaff ||
    secondsLeft == null ||
    WARN_SECONDS <= 0 ||
    secondsLeft > WARN_SECONDS ||
    secondsLeft <= 0
  ) {
    return null
  }

  async function onExtend() {
    setBusy(true)
    try {
      const ok = await refreshSession()
      if (ok) {
        warnedRef.current = false
        toast.success('Сессия продлена')
      } else {
        toast.error('Не удалось продлить сессию — войдите снова')
      }
    } finally {
      setBusy(false)
    }
  }

  return (
    <div
      role="status"
      className="flex flex-wrap items-center justify-between gap-3 border-b border-amber-500/30 bg-amber-50 px-4 py-2 text-sm text-amber-950 dark:bg-amber-950/40 dark:text-amber-50"
    >
      <p>
        Сессия истечёт через <strong>{formatLeft(secondsLeft)}</strong>
      </p>
      <Button
        size="sm"
        variant="outline"
        disabled={busy}
        onClick={() => void onExtend()}
      >
        {busy ? 'Продление…' : 'Продлить сессию'}
      </Button>
    </div>
  )
}
