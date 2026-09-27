import type { CorsOptions } from '@nestjs/common/interfaces/external/cors-options.interface';

export function isDevelopment(): boolean {
  return (process.env.NODE_ENV ?? 'development') === 'development';
}

export function parseCorsOrigins(): string[] {
  const raw = process.env.CORS_ORIGINS ?? '';
  return raw
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
}

const devCorsOrigins = [
  'http://localhost:3000',
  'http://127.0.0.1:3000',
  'http://localhost:5173',
  'http://127.0.0.1:5173',
];

export function getCorsOptions(): CorsOptions {
  const origins = parseCorsOrigins();
  return {
    origin: origins.length > 0 ? origins : devCorsOrigins,
    credentials: true,
  };
}

export function validateEnv(): void {
  if (isDevelopment()) {
    if (!process.env.JWT_ACCESS_SECRET?.trim()) {
      process.env.JWT_ACCESS_SECRET =
        'dev-access-secret-change-me-min-32-chars';
    }
    return;
  }

  const accessSecret = process.env.JWT_ACCESS_SECRET?.trim();
  if (!accessSecret) {
    throw new Error(
      'JWT_ACCESS_SECRET is required when NODE_ENV is not development',
    );
  }
  if (accessSecret.length < 32) {
    throw new Error('JWT_ACCESS_SECRET must be at least 32 characters');
  }

  if (parseCorsOrigins().length === 0) {
    throw new Error(
      'CORS_ORIGINS is required when NODE_ENV is not development (comma-separated allowlist)',
    );
  }
}
