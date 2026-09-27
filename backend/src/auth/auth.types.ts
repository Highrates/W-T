import { UserRole } from '@prisma/client';

export interface AuthUser {
  id: string;
  role: UserRole;
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface AuthSessionResponse extends TokenPair {
  user: {
    id: string;
    phone: string | null;
    email: string | null;
    phoneVerified: boolean;
    emailVerified: boolean;
    role: UserRole;
    isBlocked: boolean;
  };
}
