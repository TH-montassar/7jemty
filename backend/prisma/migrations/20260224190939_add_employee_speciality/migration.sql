/*
  Warnings:

  - The values [SANA3] on the enum `Role` will be removed. If these variants are still used in the database, this will fail.
  - You are about to drop the column `tier` on the `Salon` table. All the data in the column will be lost.
  - You are about to drop the `SalonSpeciality` table. If the table is not empty, all the data it contains will be lost.

*/
-- AlterEnum
BEGIN;
CREATE TYPE "Role_new" AS ENUM ('CLIENT', 'PATRON', 'EMPLOYEE', 'ADMIN');
ALTER TABLE "public"."User" ALTER COLUMN "role" DROP DEFAULT;
ALTER TABLE "User" ALTER COLUMN "role" TYPE "Role_new" USING ("role"::text::"Role_new");
ALTER TYPE "Role" RENAME TO "Role_old";
ALTER TYPE "Role_new" RENAME TO "Role";
DROP TYPE "public"."Role_old";
ALTER TABLE "User" ALTER COLUMN "role" SET DEFAULT 'CLIENT';
COMMIT;

-- DropForeignKey
ALTER TABLE "SalonSpeciality" DROP CONSTRAINT "SalonSpeciality_salonId_fkey";

-- AlterTable
ALTER TABLE "Salon" DROP COLUMN "tier",
ADD COLUMN     "speciality" TEXT;

-- DropTable
DROP TABLE "SalonSpeciality";

-- DropEnum
DROP TYPE "Tier";

-- CreateTable
CREATE TABLE "Employee" (
    "id" SERIAL NOT NULL,
    "salonId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT,
    "bio" TEXT,
    "description" TEXT,
    "imageUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Employee_pkey" PRIMARY KEY ("id")
);

-- AddForeignKey
ALTER TABLE "Employee" ADD CONSTRAINT "Employee_salonId_fkey" FOREIGN KEY ("salonId") REFERENCES "Salon"("id") ON DELETE CASCADE ON UPDATE CASCADE;
