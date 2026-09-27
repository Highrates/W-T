import type { Request } from 'express';
import { parseTrustedProxyIps, resolveClientIp } from './client-ip';

function mockRequest(params: {
  remoteAddress?: string;
  xForwardedFor?: string;
  ip?: string;
}): Request {
  return {
    headers: {
      ...(params.xForwardedFor ? { 'x-forwarded-for': params.xForwardedFor } : {}),
    },
    socket: { remoteAddress: params.remoteAddress },
    ip: params.ip,
  } as Request;
}

describe('resolveClientIp', () => {
  it('ignores X-Forwarded-For when peer is not a trusted proxy', () => {
    const trusted = parseTrustedProxyIps('10.0.0.1');
    const req = mockRequest({
      remoteAddress: '203.0.113.50',
      xForwardedFor: '198.51.100.10, 10.0.0.1',
    });

    expect(resolveClientIp(req, trusted)).toBe('203.0.113.50');
  });

  it('uses first X-Forwarded-For hop when peer is trusted', () => {
    const trusted = parseTrustedProxyIps('127.0.0.1,::1');
    const req = mockRequest({
      remoteAddress: '127.0.0.1',
      xForwardedFor: '198.51.100.10, 10.0.0.1',
    });

    expect(resolveClientIp(req, trusted)).toBe('198.51.100.10');
  });

  it('normalizes IPv4-mapped IPv6 addresses', () => {
    const trusted = parseTrustedProxyIps('127.0.0.1');
    const req = mockRequest({
      remoteAddress: '::ffff:127.0.0.1',
      xForwardedFor: '198.51.100.20',
    });

    expect(resolveClientIp(req, trusted)).toBe('198.51.100.20');
  });
});
