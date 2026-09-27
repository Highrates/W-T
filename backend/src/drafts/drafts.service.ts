import {
  BadRequestException,
  Injectable,
  PayloadTooLargeException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../database/prisma.service';
import {
  assertDraftPayload,
  DRAFT_MAX_BYTES,
  DRAFT_SCHEMA_VERSION,
  DraftPayloadEnvelope,
  stripDraftEnvelope,
  wrapDraftPayload,
} from './draft-payload';
import { UpsertDraftDto } from './dto/upsert-draft.dto';

@Injectable()
export class DraftsService {
  constructor(private readonly prisma: PrismaService) {}

  async getMine(userId: string) {
    const draft = await this.prisma.routeDraft.findUnique({
      where: { userId },
    });

    if (!draft) {
      return { draft: null, schemaVersion: DRAFT_SCHEMA_VERSION };
    }

    const payload = draft.payload as DraftPayloadEnvelope;
    try {
      assertDraftPayload(payload);
    } catch (error) {
      throw new BadRequestException(
        error instanceof Error ? error.message : 'Invalid draft payload',
      );
    }

    return {
      step: draft.step,
      draft: stripDraftEnvelope(payload),
      schemaVersion: payload.schemaVersion ?? DRAFT_SCHEMA_VERSION,
      updatedAt: draft.updatedAt.toISOString(),
    };
  }

  async upsertMine(userId: string, dto: UpsertDraftDto) {
    const wrapped = wrapDraftPayload(dto.draft);
    const serialized = JSON.stringify(wrapped);

    if (serialized.length > DRAFT_MAX_BYTES) {
      throw new PayloadTooLargeException(
        `Draft payload exceeds ${DRAFT_MAX_BYTES} bytes`,
      );
    }

    const payload = wrapped as Prisma.InputJsonValue;

    const saved = await this.prisma.routeDraft.upsert({
      where: { userId },
      create: {
        userId,
        step: dto.step,
        payload,
      },
      update: {
        step: dto.step,
        payload,
      },
    });

    const stored = saved.payload as DraftPayloadEnvelope;

    return {
      step: saved.step,
      draft: stripDraftEnvelope(stored),
      schemaVersion: stored.schemaVersion ?? DRAFT_SCHEMA_VERSION,
      updatedAt: saved.updatedAt.toISOString(),
    };
  }

  async deleteMine(userId: string) {
    await this.prisma.routeDraft.deleteMany({ where: { userId } });
    return { ok: true };
  }
}
