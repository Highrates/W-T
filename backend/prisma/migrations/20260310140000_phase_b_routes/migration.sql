-- CreateEnum
CREATE TYPE "JoinMode" AS ENUM ('AUTO', 'APPROVAL');

-- CreateEnum
CREATE TYPE "OccurrenceStatus" AS ENUM ('PUBLISHED', 'CANCELLED', 'HIDDEN', 'COMPLETED');

-- CreateEnum
CREATE TYPE "RouteSource" AS ENUM ('BLANK', 'FROM_PREVIOUS', 'FROM_TEMPLATE');

-- AlterTable
ALTER TABLE "cities" ADD COLUMN "center_lat" DOUBLE PRECISION,
ADD COLUMN "center_lng" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "route_drafts" (
    "user_id" UUID NOT NULL,
    "step" TEXT,
    "payload" JSONB NOT NULL,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "route_drafts_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "route_templates" (
    "id" UUID NOT NULL,
    "organizer_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "city_id" UUID NOT NULL,
    "format_ids" TEXT[],
    "theme_ids" TEXT[],
    "join_mode" "JoinMode" NOT NULL,
    "max_participants" INTEGER NOT NULL,
    "is_one_on_one" BOOLEAN NOT NULL DEFAULT false,
    "cover_urls" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "route_templates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "route_occurrences" (
    "id" UUID NOT NULL,
    "template_id" UUID,
    "organizer_id" UUID NOT NULL,
    "city_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "format_ids" TEXT[],
    "theme_ids" TEXT[],
    "join_mode" "JoinMode" NOT NULL,
    "max_participants" INTEGER NOT NULL,
    "is_one_on_one" BOOLEAN NOT NULL DEFAULT false,
    "cover_urls" TEXT[],
    "starts_at" TIMESTAMP(3),
    "hide_exact_time" BOOLEAN NOT NULL DEFAULT false,
    "status" "OccurrenceStatus" NOT NULL DEFAULT 'PUBLISHED',
    "start_latitude" DOUBLE PRECISION NOT NULL,
    "start_longitude" DOUBLE PRECISION NOT NULL,
    "participant_count" INTEGER NOT NULL DEFAULT 1,
    "source" "RouteSource" NOT NULL DEFAULT 'BLANK',
    "source_occurrence_id" UUID,
    "published_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "route_occurrences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "route_points" (
    "id" UUID NOT NULL,
    "occurrence_id" UUID NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "address" TEXT,
    "detail" TEXT,
    "description" TEXT,
    "photo_urls" TEXT[],
    "poi_id" TEXT,
    "is_start" BOOLEAN NOT NULL DEFAULT false,
    "is_finish" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "route_points_pkey" PRIMARY KEY ("id")
);

-- PostGIS geography columns for geo search
ALTER TABLE "route_occurrences"
  ADD COLUMN "location" geography(Point, 4326);

UPDATE "route_occurrences"
SET "location" = ST_SetSRID(ST_MakePoint("start_longitude", "start_latitude"), 4326)::geography;

ALTER TABLE "route_points"
  ADD COLUMN "location" geography(Point, 4326);

UPDATE "route_points"
SET "location" = ST_SetSRID(ST_MakePoint("longitude", "latitude"), 4326)::geography;

-- CreateIndex
CREATE INDEX "route_templates_organizer_id_idx" ON "route_templates"("organizer_id");

-- CreateIndex
CREATE INDEX "route_occurrences_city_id_status_published_at_idx" ON "route_occurrences"("city_id", "status", "published_at");

-- CreateIndex
CREATE INDEX "route_occurrences_organizer_id_idx" ON "route_occurrences"("organizer_id");

-- CreateIndex
CREATE INDEX "route_occurrences_status_starts_at_idx" ON "route_occurrences"("status", "starts_at");

-- CreateIndex
CREATE INDEX "route_occurrences_location_idx" ON "route_occurrences" USING GIST ("location");

-- CreateIndex
CREATE INDEX "route_points_occurrence_id_sort_order_idx" ON "route_points"("occurrence_id", "sort_order");

-- CreateIndex
CREATE INDEX "route_points_location_idx" ON "route_points" USING GIST ("location");

-- AddForeignKey
ALTER TABLE "route_drafts" ADD CONSTRAINT "route_drafts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_templates" ADD CONSTRAINT "route_templates_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_templates" ADD CONSTRAINT "route_templates_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "cities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_occurrences" ADD CONSTRAINT "route_occurrences_template_id_fkey" FOREIGN KEY ("template_id") REFERENCES "route_templates"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_occurrences" ADD CONSTRAINT "route_occurrences_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_occurrences" ADD CONSTRAINT "route_occurrences_city_id_fkey" FOREIGN KEY ("city_id") REFERENCES "cities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "route_points" ADD CONSTRAINT "route_points_occurrence_id_fkey" FOREIGN KEY ("occurrence_id") REFERENCES "route_occurrences"("id") ON DELETE CASCADE ON UPDATE CASCADE;
