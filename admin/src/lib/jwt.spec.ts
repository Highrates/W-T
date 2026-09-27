import { describe, expect, it } from 'vitest'
import { getTokenExpiresAtMs, parseJwtExp } from '@/lib/jwt'

function fakeJwt(payload: Record<string, unknown>) {
  const header = btoa(JSON.stringify({ alg: 'none', typ: 'JWT' }))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  const body = btoa(JSON.stringify(payload))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '')
  return `${header}.${body}.sig`
}

describe('parseJwtExp', () => {
  it('reads exp claim', () => {
    const exp = 1_700_000_000
    expect(parseJwtExp(fakeJwt({ exp, sub: 'u1' }))).toBe(exp)
  })

  it('returns null for garbage', () => {
    expect(parseJwtExp('not-a-jwt')).toBeNull()
    expect(parseJwtExp('a.b')).toBeNull()
  })

  it('getTokenExpiresAtMs converts to ms', () => {
    const exp = 1_700_000_000
    expect(getTokenExpiresAtMs(fakeJwt({ exp }))).toBe(exp * 1000)
  })
})
