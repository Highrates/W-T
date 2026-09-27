import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';
import { AuthUser } from '../../auth/auth.types';

@Injectable()
export class VerifiedContactGuard implements CanActivate {
  constructor(private readonly prisma: PrismaService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<{ user?: AuthUser }>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    const record = await this.prisma.user.findUnique({
      where: { id: user.id },
      select: { phoneVerified: true, emailVerified: true },
    });

    if (!record?.phoneVerified && !record?.emailVerified) {
      throw new ForbiddenException(
        'Verify phone or email before publishing routes',
      );
    }

    return true;
  }
}
