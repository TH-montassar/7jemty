/*
  Warnings:

  - You are about to drop the `Employee` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Employee" DROP CONSTRAINT "Employee_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Employee" DROP CONSTRAINT "Employee_userId_fkey";

-- AlterTable
ALTER TABLE "Profile" ADD COLUMN     "description" TEXT;

-- DropTable
DROP TABLE "Employee";

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_workplaceSalonId_fkey" FOREIGN KEY ("workplaceSalonId") REFERENCES "Salon"("id") ON DELETE SET NULL ON UPDATE CASCADE;
