/*
  Warnings:

  - You are about to drop the `Appointment` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `AppointmentService` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `FavoriteSalon` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Order` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `OrderItem` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `OtpCode` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `PortfolioImage` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Product` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Profile` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Review` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Salon` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `SalonSocialLink` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `SalonSpeciality` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `Service` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `User` table. If the table is not empty, all the data it contains will be lost.
  - You are about to drop the `WorkingHours` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_barberId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_clientId_fkey";

-- DropForeignKey
ALTER TABLE "Appointment" DROP CONSTRAINT "Appointment_salonId_fkey";

-- DropForeignKey
ALTER TABLE "AppointmentService" DROP CONSTRAINT "AppointmentService_appointmentId_fkey";

-- DropForeignKey
ALTER TABLE "AppointmentService" DROP CONSTRAINT "AppointmentService_serviceId_fkey";

-- DropForeignKey
ALTER TABLE "FavoriteSalon" DROP CONSTRAINT "FavoriteSalon_clientId_fkey";

-- DropForeignKey
ALTER TABLE "FavoriteSalon" DROP CONSTRAINT "FavoriteSalon_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Order" DROP CONSTRAINT "Order_clientId_fkey";

-- DropForeignKey
ALTER TABLE "Order" DROP CONSTRAINT "Order_salonId_fkey";

-- DropForeignKey
ALTER TABLE "OrderItem" DROP CONSTRAINT "OrderItem_orderId_fkey";

-- DropForeignKey
ALTER TABLE "OrderItem" DROP CONSTRAINT "OrderItem_productId_fkey";

-- DropForeignKey
ALTER TABLE "PortfolioImage" DROP CONSTRAINT "PortfolioImage_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Product" DROP CONSTRAINT "Product_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Profile" DROP CONSTRAINT "Profile_userId_fkey";

-- DropForeignKey
ALTER TABLE "Review" DROP CONSTRAINT "Review_appointmentId_fkey";

-- DropForeignKey
ALTER TABLE "Review" DROP CONSTRAINT "Review_clientId_fkey";

-- DropForeignKey
ALTER TABLE "Review" DROP CONSTRAINT "Review_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Salon" DROP CONSTRAINT "Salon_patronId_fkey";

-- DropForeignKey
ALTER TABLE "SalonSocialLink" DROP CONSTRAINT "SalonSocialLink_salonId_fkey";

-- DropForeignKey
ALTER TABLE "SalonSpeciality" DROP CONSTRAINT "SalonSpeciality_salonId_fkey";

-- DropForeignKey
ALTER TABLE "Service" DROP CONSTRAINT "Service_salonId_fkey";

-- DropForeignKey
ALTER TABLE "WorkingHours" DROP CONSTRAINT "WorkingHours_salonId_fkey";

-- DropTable
DROP TABLE "Appointment";

-- DropTable
DROP TABLE "AppointmentService";

-- DropTable
DROP TABLE "FavoriteSalon";

-- DropTable
DROP TABLE "Order";

-- DropTable
DROP TABLE "OrderItem";

-- DropTable
DROP TABLE "OtpCode";

-- DropTable
DROP TABLE "PortfolioImage";

-- DropTable
DROP TABLE "Product";

-- DropTable
DROP TABLE "Profile";

-- DropTable
DROP TABLE "Review";

-- DropTable
DROP TABLE "Salon";

-- DropTable
DROP TABLE "SalonSocialLink";

-- DropTable
DROP TABLE "SalonSpeciality";

-- DropTable
DROP TABLE "Service";

-- DropTable
DROP TABLE "User";

-- DropTable
DROP TABLE "WorkingHours";

-- DropEnum
DROP TYPE "AppointmentStatus";

-- DropEnum
DROP TYPE "ApprovalStatus";

-- DropEnum
DROP TYPE "Role";

-- DropEnum
DROP TYPE "Tier";
