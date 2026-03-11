-- AlterTable
ALTER TABLE "Notification" ADD COLUMN     "appointmentId" INTEGER,
ADD COLUMN     "deeplink" TEXT,
ADD COLUMN     "eventType" TEXT;
