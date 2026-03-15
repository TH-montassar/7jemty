---
name: 7jemty-backend
description: Work on the 7jemty Node.js backend. Use when changing API routes, controllers, services, auth, Firebase Admin, notifications, Prisma access, cron jobs, uploads, or admin flows inside backend.
---

# 7jemty Backend

Use this skill when editing the backend in `backend/`.

## Project Shape

- Server entry: `server.ts`
- Express app wiring: `src/app.ts`
- Env config: `src/config/env.ts`
- Firebase Admin init: `src/config/firebase.ts`
- Cron startup: `src/config/cron.service.ts`
- DB access: `src/lib/db.ts`
- Shared middleware: `src/middlewares/`
- Feature modules: `src/modules/`
- Prisma schema and migrations: `prisma/`

## Fast Project Map

Use this map first before searching the whole backend.

- App bootstrap:
  - `server.ts`
  - `src/app.ts`
- Config:
  - `src/config/env.ts`
  - `src/config/firebase.ts`
  - `src/config/cron.service.ts`
- Shared lib:
  - `src/lib/db.ts`
  - `src/lib/cloudinary.ts`
  - `src/lib/normalizeDatabaseUrl.ts`
- Auth:
  - `src/modules/auth/auth.routes.ts`
  - `src/modules/auth/auth.controller.ts`
  - `src/modules/auth/auth.service.ts`
  - `src/modules/auth/auth.schema.ts`
  - `src/modules/auth/auth.admin.routes.ts`
  - `src/modules/auth/auth.admin.controller.ts`
- Salon:
  - `src/modules/salon/salon.routes.ts`
  - `src/modules/salon/salon.controller.ts`
  - `src/modules/salon/salon.service.ts`
  - `src/modules/salon/salon.schema.ts`
  - `src/modules/salon/salon.admin.routes.ts`
  - `src/modules/salon/salon.admin.controller.ts`
- Appointment:
  - `src/modules/appointment/appointment.routes.ts`
  - `src/modules/appointment/appointment.controller.ts`
  - `src/modules/appointment/appointment.service.ts`
  - `src/modules/appointment/appointment.schema.ts`
  - `src/modules/appointment/appointment.constants.ts`
  - `src/modules/appointment/appointment.admin.routes.ts`
  - `src/modules/appointment/appointment.admin.controller.ts`
- Notifications:
  - `src/modules/notifications/notifications.routes.ts`
  - `src/modules/notifications/notifications.controller.ts`
  - `src/modules/notifications/notifications.service.ts`
  - `src/modules/notifications/notification.orchestrator.ts`
- Upload:
  - `src/modules/upload/upload.routes.ts`
  - `src/modules/upload/upload.controller.ts`
  - `src/modules/upload/upload.service.ts`
  - `src/modules/upload/upload.schema.ts`
- Review:
  - `src/modules/review/review.routes.ts`
  - `src/modules/review/review.controller.ts`
  - `src/modules/review/review.service.ts`
- Auth middleware:
  - `src/middlewares/auth.middleware.ts`

## Route Map

- `/api/auth` -> `src/modules/auth/auth.routes.ts`
- `/api/salon` -> `src/modules/salon/salon.routes.ts`
- `/api/appointment` -> `src/modules/appointment/appointment.routes.ts`
- `/api/upload` -> `src/modules/upload/upload.routes.ts`
- `/api/notifications` -> `src/modules/notifications/notifications.routes.ts`
- `/api/review` -> `src/modules/review/review.routes.ts`
- `/api/admin` -> admin routes are mounted in `src/app.ts` after `protect` + `isAdmin`

Check `src/app.ts` first when route behavior is unclear.

## Service Map

- Auth business logic: `src/modules/auth/auth.service.ts`
- Salon business logic: `src/modules/salon/salon.service.ts`
- Appointment business logic: `src/modules/appointment/appointment.service.ts`
- Notification sending: `src/modules/notifications/notifications.service.ts`
- Notification realtime/websocket-like orchestration: `src/modules/notifications/notification.orchestrator.ts`
- Upload processing: `src/modules/upload/upload.service.ts`
- Review logic: `src/modules/review/review.service.ts`

Prefer extending service files before moving logic into controllers.

## Working Rules

- Keep the existing route -> controller -> service structure.
- Keep validation in `*.schema.ts` files using Zod.
- Keep controllers thin; put business logic in services.
- Reuse `prisma` from `src/lib/db.ts` instead of creating new DB clients.
- Reuse `env` from `src/config/env.ts` instead of reading `process.env` everywhere.
- Preserve existing admin route separation when adding admin-only endpoints.

## Code Quality Rules

- Work with clean-code habits by default: clear naming, focused functions, thin controllers, and business logic grouped in the right service.
- Avoid duplicate code. If validation, query shaping, auth checks, response mapping, or notification logic repeats, extract a shared helper or service-level function.
- Prefer extending an existing module or shared utility over copy-pasting logic into another route or controller.
- Keep comments short and useful. Add a brief comment only when the intent is not obvious from the code itself.
- When changing a duplicated area, reduce the duplication if it can be done safely without changing behavior.
- After refactors, do a final sanity pass for missing references, imports, route wiring, and obvious compile-time breakage before considering the task done.

## Auth Flow

- Register/login logic lives in `src/modules/auth/auth.service.ts`
- JWT creation uses `JWT_SECRET`
- Phone verification currently supports:
  - backend OTP flow for development
  - Firebase token verification flow for production/mobile

Key auth files:
- `src/modules/auth/auth.service.ts`
- `src/modules/auth/auth.controller.ts`
- `src/modules/auth/auth.schema.ts`
- `src/middlewares/auth.middleware.ts`

Important auth endpoints:
- `POST /api/auth/register`
- `POST /api/auth/login`
- `POST /api/auth/check-phone`
- `POST /api/auth/request-otp`
- `POST /api/auth/verify-otp`
- `POST /api/auth/verify-firebase-token`
- `GET /api/auth/me`
- `PATCH /api/auth/me`

If signup/login breaks, inspect in this order:
1. `auth.routes.ts`
2. `auth.controller.ts`
3. `auth.schema.ts`
4. `auth.service.ts`
5. `auth.middleware.ts`

## Firebase Admin and Notifications

- Firebase Admin init: `src/config/firebase.ts`
- FCM send logic: `src/modules/notifications/notifications.service.ts`
- App startup calls Firebase init from `src/app.ts`

Common Firebase-related issues:
- invalid or expired FCM token
- missing Firebase Admin credentials
- production phone auth token verification failure
- billing/project eligibility issues for real SMS on the mobile Firebase side

Do not let notification send failures break critical business flows unless explicitly required.

## Prisma and Data

- Main Prisma access is through `src/lib/db.ts`
- Generated Prisma client is under `generated/prisma/`
- Schema and migrations live under `backend/prisma/`

When changing data behavior:
- inspect Prisma queries in the service file first
- then inspect schema/migration impact
- avoid scattering raw DB access across controllers

## Uploads and Cloudinary

- Cloudinary config: `src/lib/cloudinary.ts`
- Upload module:
  - `src/modules/upload/upload.routes.ts`
  - `src/modules/upload/upload.controller.ts`
  - `src/modules/upload/upload.service.ts`

If media upload breaks, check Cloudinary env vars first.

## Cron and Time-Based Behavior

- Cron jobs start from `src/config/cron.service.ts`
- Test helpers/scripts live in `backend/scripts/`
- Reminder-related behavior often touches:
  - `src/config/cron.service.ts`
  - `src/modules/appointment/appointment.service.ts`
  - `src/modules/notifications/`

## Build and Run

- Dev: `npm run dev`
- Build: `npm run build`
- Start built server: `npm run start`
- Prisma generate: `npm run prsm:gen`
- Prisma migrate dev: `npm run prsm:mig`
- Prisma studio: `npm run prsm:std`

## Search Order

When asked to change backend behavior, inspect in this order before broader search:

1. `src/app.ts`
2. Route file for the feature
3. Controller file for the feature
4. Schema file for request validation
5. Service file for the business logic
6. Shared config/lib/middleware only if needed
7. Prisma schema/migrations if data shape is involved

Only search the wider backend if the mapped files above do not explain the behavior.

## Common Hotspots

- Auth and OTP issues: `src/modules/auth/auth.service.ts`
- Route registration issues: `src/app.ts`
- Token/auth guard issues: `src/middlewares/auth.middleware.ts`
- Firebase Admin init issues: `src/config/firebase.ts`
- FCM failures: `src/modules/notifications/notifications.service.ts`
- Appointment workflow issues: `src/modules/appointment/appointment.service.ts`
- Cloudinary/upload issues: `src/modules/upload/upload.service.ts`

## Validation

- Run `npm run build` after backend code changes.
- If routes changed, test the exact endpoint.
- If auth changed, test both request validation and service behavior.
- If Prisma queries changed, verify against the real schema assumptions.
- If notifications changed, ensure failures are logged clearly and do not block unrelated core flows unless intended.
