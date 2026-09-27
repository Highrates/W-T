import { PrismaClient, UserRole } from '@prisma/client';

const prisma = new PrismaClient();

const cities = [
  { slug: 'sochi', name: 'Сочи 🌴', centerLat: 43.5855, centerLng: 39.7231 },
  { slug: 'moscow', name: 'Москва', centerLat: 55.7558, centerLng: 37.6173 },
  { slug: 'spb', name: 'Санкт-Петербург', centerLat: 59.9343, centerLng: 30.3351 },
  { slug: 'kazan', name: 'Казань', centerLat: 55.7961, centerLng: 49.1064 },
  { slug: 'krasnodar', name: 'Краснодар', centerLat: 45.0355, centerLng: 38.9753 },
];

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

async function promoteSeedAdmin() {
  const emailRaw = process.env.SEED_ADMIN_EMAIL?.trim();
  const phoneRaw = process.env.SEED_ADMIN_PHONE?.trim();

  if (!emailRaw && !phoneRaw) return;

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
    // eslint-disable-next-line no-console
    console.warn(
      'SEED_ADMIN_* set but user not found — log in via OTP first, then npm run ops:promote-admin',
    );
    return;
  }

  await prisma.user.update({
    where: { id: user.id },
    data: { role: UserRole.ADMIN },
  });

  // eslint-disable-next-line no-console
  console.log(`Promoted seed admin: ${user.email ?? user.phone} → ADMIN`);
}

async function main() {
  for (const city of cities) {
    await prisma.city.upsert({
      where: { slug: city.slug },
      create: city,
      update: {
        name: city.name,
        centerLat: city.centerLat,
        centerLng: city.centerLng,
      },
    });
  }

  // eslint-disable-next-line no-console
  console.log(`Seeded ${cities.length} cities`);

  await promoteSeedAdmin();
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
