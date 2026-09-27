/** Current wizard draft JSON schema stored in route_drafts.payload. */
export const DRAFT_SCHEMA_VERSION = 1;

/** Max serialized payload size (bytes). */
export const DRAFT_MAX_BYTES = 512 * 1024;

export type DraftPayloadEnvelope = Record<string, unknown> & {
  schemaVersion?: number;
};

export function wrapDraftPayload(
  draft: Record<string, unknown>,
): DraftPayloadEnvelope {
  return {
    schemaVersion: DRAFT_SCHEMA_VERSION,
    ...draft,
  };
}

export function assertDraftPayload(payload: DraftPayloadEnvelope): void {
  const version = payload.schemaVersion ?? DRAFT_SCHEMA_VERSION;

  if (version > DRAFT_SCHEMA_VERSION) {
    throw new Error(
      `Unsupported draft schemaVersion ${version} (max ${DRAFT_SCHEMA_VERSION})`,
    );
  }
}

export function stripDraftEnvelope(
  payload: DraftPayloadEnvelope,
): Record<string, unknown> {
  const { schemaVersion: _version, ...rest } = payload;
  return rest;
}
