# 7jemty (Hjamty)

7jemty is a salon booking and management platform.

It connects:
- clients who discover salons, book appointments, and leave reviews
- salon owners (patrons) who manage salons, employees, and services
- admins who manage users and salon approval

## Tech Stack

- Backend: Node.js + TypeScript + Express + Prisma + PostgreSQL
- Frontend: Flutter (mobile + web)
- Orchestration: Docker Compose

## Project Structure

- `backend/` : REST API (`/api/*`), Prisma schema/migrations, auth/business logic
- `frontEnd-mobile/` : Flutter client app
- `docker-compose.yml` : runs backend + Flutter web app together

## Prerequisites

### Option A: Docker
- Docker Desktop (with Docker Compose)

### Option B: Without Docker
- Node.js 20+
- npm
- Flutter SDK (stable)
- A PostgreSQL database (or cloud Postgres URL)

## Backend Environment Variables

Create/update `backend/.env` with:

```env
PORT=3000
DATABASE_URL=postgresql://USER:PASSWORD@HOST:5432/DB_NAME?sslmode=require
JWT_SECRET=change_me

CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_key
CLOUDINARY_API_SECRET=your_cloudinary_secret
```

Notes:
- `DATABASE_URL` is required.
- `JWT_SECRET` has a fallback in code, but you should set your own value.
- Firebase admin init uses application default credentials; configure it only if your flow needs push notifications.

## Run With Docker (recommended quick start)

From repository root:

```bash
docker compose up --build
```

Services:
- Backend API: `http://localhost:3000`
- Flutter web app: `http://localhost:8080`

Stop:

```bash
docker compose down
```

## Run Without Docker

### 1) Start Backend

```bash
cd backend
npm install
npm run prsm:gen
npx prisma migrate deploy
npm run dev
```

Backend runs on:
- `http://localhost:3000`

Quick check:
- `GET http://localhost:3000/`

### 2) Start Flutter App

In another terminal:

```bash
cd frontEnd-mobile
flutter pub get
```

Then run one of these:

- Android emulator:

```bash
flutter run
```

- Web (Chrome):

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:3000
```

- Real phone on same Wi-Fi:

```bash
flutter run --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:3000
```

Optional helper script for Android devices:
- `frontEnd-mobile/scripts/run_phone.sh`

## Useful Commands (Backend)

From `backend/`:

- `npm run dev` : start dev server
- `npm run prsm:mig` : create/apply dev migration
- `npm run prsm:gen` : regenerate Prisma client
- `npm run prsm:res` : reset database (destructive)
- `npm run prsm:std` : open Prisma Studio

## Current Product Idea (Summary)

7jemty aims to digitize salon operations end-to-end:
- client side: discover salons, view services, book/manage appointments, review experiences
- salon side: manage profile, staff, service catalog, and incoming appointments
- system side: enforce role-based access, scheduling flows, and moderation/approval workflows

## Firebase (Flutter)

The Flutter app now reads Firebase config from `frontEnd-mobile/.env`.

1. Copy `frontEnd-mobile/.env.example` to `frontEnd-mobile/.env`
2. Fill in your Firebase values

The `.env` file is ignored by git.
