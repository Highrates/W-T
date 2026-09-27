/** Decode JWT `exp` (seconds) without verifying signature — client UX only. */
export function parseJwtExp(token: string): number | null {
  const parts = token.split('.')
  if (parts.length < 2) return null
  try {
    const payload = parts[1]
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/')
    const padded = normalized.padEnd(
      normalized.length + ((4 - (normalized.length % 4)) % 4),
      '=',
    )
    const json = JSON.parse(atob(padded)) as { exp?: unknown }
    return typeof json.exp === 'number' ? json.exp : null
  } catch {
    return null
  }
}

/** Access-token expiry as epoch milliseconds, or null if unknown. */
export function getTokenExpiresAtMs(token: string): number | null {
  const exp = parseJwtExp(token)
  return exp == null ? null : exp * 1000
}
