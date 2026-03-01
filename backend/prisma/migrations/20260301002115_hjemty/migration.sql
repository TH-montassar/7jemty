-- CreateEnum
CREATE TYPE "AppointmentTarget" AS ENUM ('EMPLOYEE', 'PATRON');

-- AlterEnum
ALTER TYPE "AppointmentStatus" ADD VALUE 'IN_PROGRESS';

-- AlterTable
ALTER TABLE "Appointment" ADD COLUMN     "actualEndTime" TIMESTAMP(3),
ADD COLUMN     "cancelledAt" TIMESTAMP(3),
ADD COLUMN     "completedAt" TIMESTAMP(3),
ADD COLUMN     "completionPromptCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "confirmedAt" TIMESTAMP(3),
ADD COLUMN     "nextCompletionCheckAt" TIMESTAMP(3),
ADD COLUMN     "reviewRequestedAt" TIMESTAMP(3),
ADD COLUMN     "startedAt" TIMESTAMP(3),
ADD COLUMN     "targetType" "AppointmentTarget" NOT NULL DEFAULT 'EMPLOYEE';

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "blacklistedAt" TIMESTAMP(3),
ADD COLUMN     "ignoredAppointmentsCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "isBlacklistedBySystem" BOOLEAN NOT NULL DEFAULT false;

-- CreateTable
CREATE TABLE "AppointmentFault" (
    "id" SERIAL NOT NULL,
    "appointmentId" INTEGER NOT NULL,
    "barberId" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AppointmentFault_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "BarberServiceStat" (
    "id" SERIAL NOT NULL,
    "barberId" INTEGER NOT NULL,
    "serviceId" INTEGER NOT NULL,
    "completedAppointments" INTEGER NOT NULL DEFAULT 0,
    "totalActualDurationMin" INTEGER NOT NULL DEFAULT 0,
    "averageDurationMin" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "BarberServiceStat_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "BarberServiceStat_barberId_serviceId_key" ON "BarberServiceStat"("barberId", "serviceId");

-- AddForeignKey
ALTER TABLE "AppointmentFault" ADD CONSTRAINT "AppointmentFault_appointmentId_fkey" FOREIGN KEY ("appointmentId") REFERENCES "Appointment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AppointmentFault" ADD CONSTRAINT "AppointmentFault_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BarberServiceStat" ADD CONSTRAINT "BarberServiceStat_barberId_fkey" FOREIGN KEY ("barberId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "BarberServiceStat" ADD CONSTRAINT "BarberServiceStat_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "Service"("id") ON DELETE CASCADE ON UPDATE CASCADE;
