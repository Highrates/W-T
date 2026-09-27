import { describe, expect, it } from 'vitest'
import { isStaffRole, normalizeRole } from '@/lib/types'

describe('isStaffRole', () => {
  it('accepts admin and moderator (any case)', () => {
    expect(isStaffRole('ADMIN')).toBe(true)
    expect(isStaffRole('admin')).toBe(true)
    expect(isStaffRole('MODERATOR')).toBe(true)
    expect(isStaffRole('moderator')).toBe(true)
  })

  it('rejects regular users and unknown roles', () => {
    expect(isStaffRole('USER')).toBe(false)
    expect(isStaffRole('user')).toBe(false)
    expect(isStaffRole('')).toBe(false)
    expect(isStaffRole('guest')).toBe(false)
  })
})

describe('normalizeRole', () => {
  it('lowercases role strings', () => {
    expect(normalizeRole('ADMIN')).toBe('admin')
    expect(normalizeRole('Moderator')).toBe('moderator')
  })
})
