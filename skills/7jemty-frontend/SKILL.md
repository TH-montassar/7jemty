---
name: 7jemty-frontend
description: Work on the 7jemty Flutter frontend. Use when changing UI, screens, navigation, localization, Firebase initialization, phone authentication, FCM integration, API calls, or role-based flows inside frontEnd-mobile.
---

# 7jemty Frontend

Use this skill when editing the Flutter app in `frontEnd-mobile/`.

## Project Shape

- Entry point: `lib/main.dart`
- Firebase options: `lib/firebase_options.dart`
- Backend base URL logic: `lib/config/api_config.dart`
- Shared services: `lib/core/services/`
- Localization: `lib/core/localization/`
- Auth UI and data: `lib/features/auth/`
- Role-specific areas:
  - `lib/features/client_space/`
  - `lib/features/patron_space/`
  - `lib/features/admin_space/`

## Fast Project Map

Use this map first before searching the whole repo.

- App bootstrap:
  - `lib/main.dart`
  - `lib/firebase_options.dart`
- Global config:
  - `lib/config/api_config.dart`
  - `lib/core/constants/app_colors.dart`
- Localization:
  - `lib/core/localization/translation_service.dart`
  - `lib/core/localization/langs/en.dart`
  - `lib/core/localization/langs/tn.dart`
- Shared services:
  - `lib/core/services/fcm_service.dart`
  - `lib/core/services/location_service.dart`
  - `lib/core/services/notification_service.dart`
- Auth:
  - `lib/features/auth/signIn.dart`
  - `lib/features/auth/signUp.dart`
  - `lib/features/auth/data/auth_service.dart`
  - `lib/features/auth/data/firebase_phone_auth_service.dart`
- Splash/start routing:
  - `lib/features/splash/presentation/pages/splash_screen.dart`
- Client main flow:
  - `lib/features/client_space/main_layout/presentation/pages/client_main_layout.dart`
  - `lib/features/client_space/home/presentation/pages/client_home_page.dart`
  - `lib/features/client_space/appointments/presentation/pages/appointments_page.dart`
  - `lib/features/client_space/appointments/presentation/pages/booking_flow_screen.dart`
  - `lib/features/client_space/salon_profile/presentation/pages/salon_profile_page.dart`
- Patron main flow:
  - `lib/features/patron_space/main_page.dart`
  - `lib/features/patron_space/create_salon_screen.dart`
  - `lib/features/patron_space/salon_dashboard_screen.dart`
  - `lib/features/patron_space/main_layout/presentation/pages/home_page.dart`
- Employee main flow:
  - `lib/features/patron_space/employee/pages/presentation/employee_main_layout.dart`
- Admin main flow:
  - `lib/features/admin_space/presentation/pages/admin_main_screen.dart`
  - `lib/features/admin_space/presentation/pages/admin_home_page.dart`
  - `lib/features/admin_space/presentation/pages/manage_users_page.dart`
  - `lib/features/admin_space/presentation/pages/manage_salons_page.dart`
  - `lib/features/admin_space/presentation/pages/manage_reports_page.dart`

## Service Map

- Auth API: `lib/features/auth/data/auth_service.dart`
- Firebase phone auth wrapper: `lib/features/auth/data/firebase_phone_auth_service.dart`
- Salon read data: `lib/features/client_space/salon_profile/data/salon_service.dart`
- Appointment data: `lib/features/client_space/appointments/data/appointment_service.dart`
- Admin backend calls: `lib/features/admin_space/data/admin_service.dart`

Prefer extending these files before introducing new API layers.

## Working Rules

- Preserve the existing feature-first structure.
- Prefer editing the relevant feature folder instead of adding global utilities too early.
- Reuse `AuthService`, `FcmService`, and existing API service classes before adding new service layers.
- Keep user-facing text localizable when it is part of the UI.
- Match the app's existing visual language instead of introducing a new design system.

## Code Quality Rules

- Work with clean-code habits by default: small methods, clear names, simple control flow, and one obvious responsibility per widget or helper.
- Avoid duplicate code. If the same UI, state logic, mapping, or request handling appears in more than one place, prefer extracting a shared widget, helper, or service method.
- Prefer reuse over copy-paste, especially for dialogs, list shells, cards, filter bars, empty states, and API parsing.
- Keep comments short and useful. Add a brief comment only when the intent is not obvious from the code itself.
- When touching an area with duplication, reduce it as part of the change when it is safe to do so.
- After refactors, do a final sanity pass for missing method references, closing braces, imports, and obvious compile-time breakage before considering the task done.

## Auth and Firebase

- Firebase is initialized in `lib/main.dart`.
- Firebase config values come from `frontEnd-mobile/.env` through `lib/firebase_options.dart`.
- Dev and production auth are intentionally different:
  - Dev/web flow can use backend OTP simulation.
  - Production mobile flow uses Firebase Phone Auth, then exchanges the Firebase token with the backend.
- Relevant files:
  - `lib/features/auth/signUp.dart`
  - `lib/features/auth/data/auth_service.dart`
  - `lib/features/auth/data/firebase_phone_auth_service.dart`

When changing auth:
- Keep backend OTP flow working for development.
- Do not break the backend token exchange contract expected by registration.
- Normalize Tunisian phone numbers carefully and consistently.

## Known Auth Flow

- Signup starts in `lib/features/auth/signUp.dart`.
- Dev/web path:
  - call backend `request-otp`
  - user enters OTP
  - backend `verify-otp`
  - backend returns `phoneVerificationToken`
- Production mobile path:
  - use Firebase Phone Auth
  - exchange Firebase ID token with backend `verify-firebase-token`
  - backend returns `phoneVerificationToken`
- Registration then calls backend `register` with:
  - `fullName`
  - `phoneNumber`
  - `password`
  - `role`
  - `phoneVerificationToken`

If signup breaks, inspect these first:
- `lib/features/auth/signUp.dart`
- `lib/features/auth/data/auth_service.dart`
- `lib/features/auth/data/firebase_phone_auth_service.dart`
- `lib/config/api_config.dart`

## API Workflow

- Backend auth endpoints live under `/api/auth`.
- Centralize backend calls in service files under `data/` folders.
- If a screen already uses a service file, extend that service instead of calling `http` directly from widgets.
- Preserve existing response parsing and error extraction patterns in `AuthService`.

## Role Navigation Map

- After auth, role-based redirects are handled from auth/splash related screens.
- Main destination screens:
  - Client: `lib/features/client_space/main_layout/presentation/pages/client_main_layout.dart`
  - Patron with salon: `lib/features/patron_space/main_page.dart`
  - Patron without salon: `lib/features/patron_space/create_salon_screen.dart`
  - Employee: `lib/features/patron_space/employee/pages/presentation/employee_main_layout.dart`
  - Admin: `lib/features/admin_space/presentation/pages/admin_main_screen.dart`

When changing login/signup/splash, verify these redirects still work.

## Localization

- Translation maps live in:
  - `lib/core/localization/langs/en.dart`
  - `lib/core/localization/langs/tn.dart`
- Add new strings to both language files.
- Reuse `tr(context, 'key')` patterns already used in the app.

## Push Notifications

- FCM setup lives in `lib/core/services/fcm_service.dart`.
- Do not block core user flows on notification failures unless the feature truly depends on delivery.

## Android Release Notes

- Android Gradle app config: `android/app/build.gradle.kts`
- Firebase Android file: `android/app/google-services.json`
- Current Android package name: `com.example.hjamty`
- Current local release builds use debug signing unless explicitly changed in Gradle.

For mobile Firebase failures, check in this order:
1. `google-services.json` package name matches app `applicationId`
2. Firebase Phone sign-in enabled
3. SHA fingerprints added in Firebase Console
4. Billing/project eligibility complete for real SMS
5. App running on Android device, not browser

## Search Order

When asked to change something, inspect in this order before broader search:

1. `lib/main.dart`
2. `lib/config/api_config.dart`
3. The feature screen under `lib/features/...`
4. The paired `data/` service for that feature
5. Shared services in `lib/core/services/`
6. Localization files if UI text changed

Only search the wider project if the issue is still unclear after checking the mapped files above.

## Android/Firebase Notes

- Android package name is `com.example.hjamty`.
- `android/app/google-services.json` must match the package name.
- For real Firebase Phone Auth SMS on Android, project setup outside the repo still matters:
  - Phone sign-in enabled in Firebase Console
  - Correct SHA fingerprints added
  - Billing/project eligibility configured when required by Firebase

## Safe Change Process

1. Identify the feature folder affected.
2. Update service/data layer first if API behavior changes.
3. Update screen/widget logic next.
4. Add or update localization keys if UI text changes.
5. Check auth, navigation, and role-based redirects if the change touches signup, login, splash, or profile flows.

## Common Hotspots

- Signup and OTP flow: `lib/features/auth/signUp.dart`
- Login flow: `lib/features/auth/signIn.dart`
- App startup and Firebase boot: `lib/main.dart`
- API host issues in web/dev: `lib/config/api_config.dart`
- Notification token sync issues: `lib/core/services/fcm_service.dart`

## Validation

- Run `flutter pub get` after dependency changes.
- Prefer testing the exact affected flow:
  - web dev for backend OTP simulation
  - Android device for Firebase Phone Auth
- If a mobile-only feature is changed, do not rely on browser testing alone.
