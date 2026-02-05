-- CreateEnum
CREATE TYPE "UserBadgeStatus" AS ENUM ('locked', 'in_progress', 'collected');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "avatar_url" TEXT,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "locations" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "area" TEXT,
    "nfc_id" TEXT,
    "is_nfc_enabled" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP NOT NULL,

    CONSTRAINT "locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_location_collections" (
    "id" SERIAL NOT NULL,
    "user_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "collected_at" TIMESTAMP NOT NULL,

    CONSTRAINT "user_location_collections_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activities" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "start_time" TIMESTAMP NOT NULL,
    "end_time" TIMESTAMP,
    "distance" DOUBLE PRECISION,
    "duration" INTEGER,
    "average_speed" DOUBLE PRECISION,
    "total_coins" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_track_points" (
    "id" SERIAL NOT NULL,
    "activity_id" TEXT NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "timestamp" TIMESTAMP NOT NULL,
    "accuracy" DOUBLE PRECISION,

    CONSTRAINT "activity_track_points_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_collected_locations" (
    "id" SERIAL NOT NULL,
    "activity_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,
    "collected_at" TIMESTAMP NOT NULL,
    "coins_earned" INTEGER NOT NULL DEFAULT 1,

    CONSTRAINT "activity_collected_locations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "badges" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "image_url" TEXT,
    "created_at" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP NOT NULL,

    CONSTRAINT "badges_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "badge_location_requirements" (
    "id" SERIAL NOT NULL,
    "badge_id" TEXT NOT NULL,
    "location_id" TEXT NOT NULL,

    CONSTRAINT "badge_location_requirements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_badges" (
    "id" SERIAL NOT NULL,
    "user_id" TEXT NOT NULL,
    "badge_id" TEXT NOT NULL,
    "unlocked_at" TIMESTAMP,
    "status" "UserBadgeStatus" NOT NULL DEFAULT 'locked',

    CONSTRAINT "user_badges_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "locations_nfc_id_key" ON "locations"("nfc_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_location_collections_user_id_location_id_key" ON "user_location_collections"("user_id", "location_id");

-- CreateIndex
CREATE UNIQUE INDEX "badge_location_requirements_badge_id_location_id_key" ON "badge_location_requirements"("badge_id", "location_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_badges_user_id_badge_id_key" ON "user_badges"("user_id", "badge_id");

-- AddForeignKey
ALTER TABLE "user_location_collections" ADD CONSTRAINT "user_location_collections_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_location_collections" ADD CONSTRAINT "user_location_collections_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activities" ADD CONSTRAINT "activities_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_track_points" ADD CONSTRAINT "activity_track_points_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_collected_locations" ADD CONSTRAINT "activity_collected_locations_activity_id_fkey" FOREIGN KEY ("activity_id") REFERENCES "activities"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_collected_locations" ADD CONSTRAINT "activity_collected_locations_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "badge_location_requirements" ADD CONSTRAINT "badge_location_requirements_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "badges"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "badge_location_requirements" ADD CONSTRAINT "badge_location_requirements_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "locations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_badges" ADD CONSTRAINT "user_badges_badge_id_fkey" FOREIGN KEY ("badge_id") REFERENCES "badges"("id") ON DELETE CASCADE ON UPDATE CASCADE;
