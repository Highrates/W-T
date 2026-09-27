import type { Request } from 'express';

/** Parse TRUSTED_PROXY_IPS (comma-separated exact IPs, e.g. 127.0.0.1,::1). */
export function parseTrustedProxyIps(raw?: string): Set<string> {
  if (!raw?.trim()) return new Set();
  return new Set(
    raw
      .split(',')
      .map((item) => normalizeIp(item.trim()))
      .filter(Boolean) as string[],
  );
}

export function isTrustedProxy(remoteAddress: string | undefined, trusted: Set<string>): boolean {
  if (!remoteAddress || trusted.size === 0) return false;
  return trusted.has(normalizeIp(remoteAddress) ?? remoteAddress);
}

/**
 * Client IP for rate limits / audit.
 * X-Forwarded-For is used only when the TCP peer is a trusted reverse proxy.
 */
export function resolveClientIp(req: Request, trustedProxies: Set<string>): string {
  const remote = req.socket.remoteAddress;
  const peer = normalizeIp(remote) ?? remote;

  if (peer && isTrustedProxy(peer, trustedProxies)) {
    const forwarded = req.headers['x-forwarded-for'];
    const first = firstForwardedIp(forwarded);
    if (first) return first;
  }

  return peer ?? req.ip ?? 'unknown';
}

function firstForwardedIp(header: string | string[] | undefined): string | null {
  if (typeof header === 'string' && header.trim().length > 0) {
    return normalizeIp(header.split(',')[0].trim());
  }
  if (Array.isArray(header) && header.length > 0) {
    return normalizeIp(header[0].split(',')[0].trim());
  }
  return null;
}

/** Strip IPv4-mapped IPv6 prefix (::ffff:1.2.3.4). */
export function normalizeIp(value: string | undefined): string | null {
  if (!value?.trim()) return null;
  const trimmed = value.trim();
  if (trimmed.startsWith('::ffff:')) {
    return trimmed.slice('::ffff:'.length);
  }
  return trimmed;
}
