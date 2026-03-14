-- AlterTable
ALTER TABLE "User" ADD COLUMN "warningCount" INTEGER NOT NULL DEFAULT 0;

-- CreateEnum
CREATE TYPE "ReportStatus" AS ENUM ('PENDING', 'DISMISSED', 'ACTION_TAKEN');

-- CreateTable
CREATE TABLE "ReportedReview" (
    "id" SERIAL NOT NULL,
    "reviewId" INTEGER NOT NULL,
    "reporterId" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "message" TEXT,
    "status" "ReportStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "resolvedAt" TIMESTAMP(3),
    "resolvedBy" INTEGER,

    CONSTRAINT "ReportedReview_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "UserWarning" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UserWarning_pkey" PRIMARY KEY ("id")
);

-- Optional data migration from old ReviewReport table
INSERT INTO "ReportedReview" ("reviewId", "reporterId", "reason", "message", "status", "createdAt", "resolvedAt", "resolvedBy")
SELECT
  rr."reviewId",
  rr."reporterId",
  rr."reason",
  rr."message",
  CASE
    WHEN rr."status" = 'RESOLVED_KEPT' THEN 'DISMISSED'::"ReportStatus"
    WHEN rr."status" = 'RESOLVED_DELETED' THEN 'ACTION_TAKEN'::"ReportStatus"
    ELSE 'PENDING'::"ReportStatus"
  END,
  rr."createdAt",
  rr."reviewedAt",
  NULL
FROM "ReviewReport" rr;

-- CreateIndex
CREATE INDEX "ReportedReview_reviewId_idx" ON "ReportedReview"("reviewId");

-- CreateIndex
CREATE INDEX "ReportedReview_status_idx" ON "ReportedReview"("status");

-- AddForeignKey
ALTER TABLE "ReportedReview" ADD CONSTRAINT "ReportedReview_reviewId_fkey" FOREIGN KEY ("reviewId") REFERENCES "Review"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ReportedReview" ADD CONSTRAINT "ReportedReview_reporterId_fkey" FOREIGN KEY ("reporterId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "UserWarning" ADD CONSTRAINT "UserWarning_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- DropTable
DROP TABLE "ReviewReport";
