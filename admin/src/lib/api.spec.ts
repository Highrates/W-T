import {
  afterEach,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest'
import {
  apiRequest,
  clearTokens,
  getAccessToken,
  getApiBase,
  resetApiClientStateForTests,
  setAuthFailureHandler,
  setTokens,
} from '@/lib/api'

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

describe('apiRequest refresh', () => {
  beforeEach(() => {
    localStorage.clear()
    resetApiClientStateForTests()
    vi.restoreAllMocks()
  })

  afterEach(() => {
    clearTokens()
    resetApiClientStateForTests()
  })

  it('refreshes on 401 and retries the original request', async () => {
    setTokens('old-access', 'refresh-1')
    const base = getApiBase()

    const fetchMock = vi
      .fn()
      // first protected call
      .mockResolvedValueOnce(new Response('Unauthorized', { status: 401 }))
      // refresh
      .mockResolvedValueOnce(
        jsonResponse({
          accessToken: 'new-access',
          refreshToken: 'refresh-2',
        }),
      )
      // retry
      .mockResolvedValueOnce(jsonResponse({ ok: true }))

    vi.stubGlobal('fetch', fetchMock)

    const data = await apiRequest<{ ok: boolean }>('/admin/stats')

    expect(data).toEqual({ ok: true })
    expect(getAccessToken()).toBe('new-access')
    expect(fetchMock).toHaveBeenCalledTimes(3)

    expect(String(fetchMock.mock.calls[0]![0])).toBe(`${base}/admin/stats`)
    expect(String(fetchMock.mock.calls[1]![0])).toBe(`${base}/auth/refresh`)
    expect(
      (fetchMock.mock.calls[2]![1] as RequestInit).headers,
    ).toMatchObject({
      Authorization: 'Bearer new-access',
    })
  })

  it('throws and clears tokens when refresh fails', async () => {
    setTokens('old-access', 'refresh-1')
    const onFail = vi.fn()
    setAuthFailureHandler(onFail)

    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(new Response('Unauthorized', { status: 401 }))
      .mockResolvedValueOnce(new Response('nope', { status: 401 }))

    vi.stubGlobal('fetch', fetchMock)

    await expect(apiRequest('/admin/stats')).rejects.toMatchObject({
      status: 401,
    })
    expect(getAccessToken()).toBeNull()
    expect(onFail).toHaveBeenCalledWith(401)
  })
})
