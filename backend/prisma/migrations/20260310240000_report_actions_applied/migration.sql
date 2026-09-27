-- Persist moderation actions applied when resolving a report.
ALTER TABLE "reports"
ADD COLUMN "actions_applied" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[];
