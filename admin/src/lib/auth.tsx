import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import {
  apiRequest,
  clearTokens,
  getAccessToken,
  getRefreshToken,
  setAuthFailureHandler,
  setTokens,
} from '@/lib/api'
import {
  isStaffRole,
  type AuthTokens,
  type AuthUser,
} from '@/lib/types'

export type OtpChannel = 'email' | 'phone'

type AuthState = {
  user: AuthUser | null
  loading: boolean
  isAuthenticated: boolean
  isStaff: boolean
  isAdmin: boolean
  requestOtp: (channel: OtpChannel, identity: string) => Promise<void>
  verifyOtp: (
    channel: OtpChannel,
    identity: string,
    code: string,
  ) => Promise<AuthUser>
  logout: () => Promise<void>
  refreshMe: () => Promise<void>
}

const AuthContext = createContext<AuthState | null>(null)

function assertStaff(user: AuthUser) {
  if (!isStaffRole(user.role)) {
    clearTokens()
    throw new Error('STAFF_REQUIRED')
  }
  if (user.isBlocked) {
    clearTokens()
    throw new Error('ACCOUNT_BLOCKED')
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [loading, setLoading] = useState(true)

  const refreshMe = useCallback(async () => {
    if (!getAccessToken()) {
      setUser(null)
      return
    }
    const me = await apiRequest<AuthUser>('/auth/me')
    if (!isStaffRole(me.role) || me.isBlocked) {
      clearTokens()
      setUser(null)
      return
    }
    setUser(me)
  }, [])

  useEffect(() => {
    setAuthFailureHandler((status) => {
      setUser(null)
      const target = status === 403 ? '/forbidden' : '/login'
      if (window.location.pathname !== target) {
        window.location.assign(target)
      }
    })
    return () => setAuthFailureHandler(null)
  }, [])

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        if (getAccessToken() || getRefreshToken()) {
          await refreshMe()
        }
      } catch {
        clearTokens()
        if (!cancelled) setUser(null)
      } finally {
        if (!cancelled) setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [refreshMe])

  const requestOtp = useCallback(
    async (channel: OtpChannel, identity: string) => {
      if (channel === 'email') {
        await apiRequest('/auth/email/request', {
          method: 'POST',
          body: { email: identity },
          auth: false,
        })
        return
      }
      await apiRequest('/auth/phone/request', {
        method: 'POST',
        body: { phone: identity },
        auth: false,
      })
    },
    [],
  )

  const verifyOtp = useCallback(
    async (channel: OtpChannel, identity: string, code: string) => {
      const path =
        channel === 'email' ? '/auth/email/verify' : '/auth/phone/verify'
      const body =
        channel === 'email'
          ? { email: identity, code }
          : { phone: identity, code }
      const data = await apiRequest<AuthTokens>(path, {
        method: 'POST',
        body,
        auth: false,
      })
      try {
        assertStaff(data.user)
      } catch (err) {
        setUser(null)
        throw err
      }
      setTokens(data.accessToken, data.refreshToken)
      setUser(data.user)
      return data.user
    },
    [],
  )

  const logout = useCallback(async () => {
    const refreshToken = getRefreshToken()
    try {
      if (refreshToken) {
        await apiRequest('/auth/logout', {
          method: 'POST',
          body: { refreshToken },
        })
      }
    } catch {
      // ignore
    } finally {
      clearTokens()
      setUser(null)
    }
  }, [])

  const value = useMemo<AuthState>(
    () => ({
      user,
      loading,
      isAuthenticated: !!user,
      isStaff: !!user && isStaffRole(user.role),
      isAdmin: !!user && user.role.toLowerCase() === 'admin',
      requestOtp,
      verifyOtp,
      logout,
      refreshMe,
    }),
    [user, loading, requestOtp, verifyOtp, logout, refreshMe],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
