/**
 * Promote an existing user to ADMIN by phone or email.
 *
 * Usage:
 *   SEED_ADMIN_EMAIL=ops@example.com npx ts-node scripts/promote-admin.ts
 *   SEED_ADMIN_PHONE=+79991234567 npx ts-node scripts/promote-admin.ts
 */
import { PrismaClient, UserRole } from '@prisma/client';

const prisma = new PrismaClient();

function normalizeEmail(raw: string): string {
  return raw.trim().toLowerCase();
}

function normalizePhone(raw: string): string {
  const digits = raw.replace(/\D/g, '');
  if (digits.length === 11 && digits.startsWith('8')) {
    return `+7${digits.slice(1)}`;
  }
  if (digits.length === 11 && digits.startsWith('7')) {
    return `+${digits}`;
  }
  if (raw.startsWith('+')) return raw;
  return raw;
}

async function main() {
  const emailRaw = process.env.SEED_ADMIN_EMAIL?.trim();
  const phoneRaw = process.env.SEED_ADMIN_PHONE?.trim();

  if (!emailRaw && !phoneRaw) {
    throw new Error('Set SEED_ADMIN_EMAIL and/or SEED_ADMIN_PHONE');
  }

  let user = null;

  if (emailRaw) {
    user = await prisma.user.findUnique({
      where: { email: normalizeEmail(emailRaw) },
    });
  }

  if (!user && phoneRaw) {
    user = await prisma.user.findUnique({
      where: { phone: normalizePhone(phoneRaw) },
    });
  }

  if (!user) {
    throw new Error(
      'User not found. Log in once via OTP (mobile/API) so the account exists, then rerun.',
    );
  }

  const updated = await prisma.user.update({
    where: { id: user.id },
    data: { role: UserRole.ADMIN },
  });

  // eslint-disable-next-line no-console
  console.log(
    `Promoted ${updated.id} (${updated.email ?? updated.phone}) → ADMIN`,
  );
}

main()
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
