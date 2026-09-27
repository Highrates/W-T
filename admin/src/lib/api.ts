import { getTokenExpiresAtMs } from '@/lib/jwt'

const ACCESS_KEY = 'wt_admin_access'
const REFRESH_KEY = 'wt_admin_refresh'

function resolveApiBase(): string {
  const raw = import.meta.env.VITE_API_BASE_URL?.replace(/\/$/, '')
  if (import.meta.env.PROD) {
    if (!raw) {
      throw new Error(
        'VITE_API_BASE_URL must be set for production builds of the admin SPA',
      )
    }
    return raw
  }
  return raw || 'http://localhost:3000/api'
}

const API_BASE = resolveApiBase()

export function getApiBase() {
  return API_BASE
}

export function getAccessToken() {
  return localStorage.getItem(ACCESS_KEY)
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_KEY)
}

export function setTokens(accessToken: string, refreshToken: string) {
  localStorage.setItem(ACCESS_KEY, accessToken)
  localStorage.setItem(REFRESH_KEY, refreshToken)
}

export function clearTokens() {
  localStorage.removeItem(ACCESS_KEY)
  localStorage.removeItem(REFRESH_KEY)
}

export function getAccessTokenExpiresAtMs(): number | null {
  const token = getAccessToken()
  if (!token) return null
  return getTokenExpiresAtMs(token)
}

export class ApiError extends Error {
  status: number
  body: unknown

  constructor(status: number, message: string, body?: unknown) {
    super(message)
    this.status = status
    this.body = body
  }
}

type RequestOptions = {
  method?: string
  body?: unknown
  auth?: boolean
  retry?: boolean
}

type AuthFailureStatus = 401 | 403

type AuthFailureHandler = (status: AuthFailureStatus) => void

let authFailureHandler: AuthFailureHandler | null = null
let authFailureNotified = false

export function setAuthFailureHandler(handler: AuthFailureHandler | null) {
  authFailureHandler = handler
  authFailureNotified = false
}

function notifyAuthFailure(status: AuthFailureStatus) {
  if (authFailureNotified) return
  authFailureNotified = true
  clearTokens()
  authFailureHandler?.(status)
}

let refreshPromise: Promise<boolean> | null = null

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = getRefreshToken()
  if (!refreshToken) return false

  try {
    const res = await fetch(`${API_BASE}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    })
    if (!res.ok) {
      clearTokens()
      return false
    }
    const data = (await res.json()) as {
      accessToken: string
      refreshToken: string
    }
    setTokens(data.accessToken, data.refreshToken)
    return true
  } catch {
    clearTokens()
    return false
  }
}

/** Proactively refresh access/refresh pair (session warning UI). */
export async function refreshSession(): Promise<boolean> {
  if (!refreshPromise) {
    refreshPromise = refreshAccessToken().finally(() => {
      refreshPromise = null
    })
  }
  return refreshPromise
}

/** @internal test helper */
export function resetApiClientStateForTests() {
  refreshPromise = null
  authFailureNotified = false
  authFailureHandler = null
}

export async function apiRequest<T>(
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const { method = 'GET', body, auth = true, retry = true } = options
  const headers: Record<string, string> = {}
  if (body !== undefined) {
    headers['Content-Type'] = 'application/json'
  }
  if (auth) {
    const token = getAccessToken()
    if (token) headers.Authorization = `Bearer ${token}`
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  })

  if (res.status === 401 && auth && retry) {
    if (!refreshPromise) {
      refreshPromise = refreshAccessToken().finally(() => {
        refreshPromise = null
      })
    }
    const ok = await refreshPromise
    if (ok) {
      return apiRequest<T>(path, { ...options, retry: false })
    }
    notifyAuthFailure(401)
    throw new ApiError(401, 'Unauthorized')
  }

  if (res.status === 401 && auth) {
    notifyAuthFailure(401)
    throw new ApiError(401, 'Unauthorized')
  }

  if (res.status === 403 && auth) {
    notifyAuthFailure(403)
    throw new ApiError(403, 'Forbidden')
  }

  if (res.status === 204) {
    return undefined as T
  }

  const text = await res.text()
  let parsed: unknown = null
  if (text) {
    try {
      parsed = JSON.parse(text)
    } catch {
      parsed = text
    }
  }

  if (!res.ok) {
    const message =
      typeof parsed === 'object' &&
      parsed &&
      'message' in parsed &&
      (typeof (parsed as { message: unknown }).message === 'string' ||
        Array.isArray((parsed as { message: unknown }).message))
        ? Array.isArray((parsed as { message: unknown }).message)
          ? ((parsed as { message: string[] }).message).join(', ')
          : String((parsed as { message: string }).message)
        : `HTTP ${res.status}`
    throw new ApiError(res.status, message, parsed)
  }

  return parsed as T
}
