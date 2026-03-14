# Rapport technique - Projet 7jemty / hjamty

Mise a jour: 2026-03-14

## 1) Perimetre audite

Code lu pour cette mise a jour:
- Backend: `backend/src`, `backend/prisma/schema.prisma`, `backend/scripts`
- Frontend mobile/web: `frontEnd-mobile/lib`, `frontEnd-mobile/pubspec.yaml`, `frontEnd-mobile/.env.example`

## 2) Resume executif

Le projet est un monorepo avec:
- une API backend Node.js + TypeScript + Express + Prisma + PostgreSQL
- une app Flutter multi-role (CLIENT, PATRON, EMPLOYEE, ADMIN)
- une couche notification hybride (SSE temps reel + Firebase FCM)
- une logique rendez-vous assez avancee (disponibilites, etats, rappels cron, reviews)

L'architecture actuelle est orientee "modules par feature" cote backend (`auth`, `salon`, `appointment`, `notifications`, `upload`) et "features par espace utilisateur" cote Flutter.

## 3) Structure du repo

Arborescence complete du depot (fichiers suivis Git) ajoutee dans:
- `ARBORESCENCE_COMPLETE.md`

Extrait racine:

```text
7jemty/
├── .gitignore
├── ARBORESCENCE_COMPLETE.md
├── RAPPORT_TECHNIQUE.md
├── README.md
├── backend/
├── docker-compose.yml
└── frontEnd-mobile/
```

## 4) Backend - architecture reelle

### 4.1 Boot et middleware

- `backend/server.ts`: lance Express sur `0.0.0.0:${PORT}`
- `backend/src/app.ts`:
  - initialise Firebase Admin
  - demarre le scheduler cron
  - active CORS + JSON/urlencoded
  - monte les routes metier
  - applique garde admin partagee sur `/api/admin` via `protect` + `isAdmin`

### 4.2 Modules backend

- `auth`: inscription, login, profile, OTP, admin users CRUD
- `salon`: creation/update salon, employes, services, favoris, portfolio, recherche, admin salon management
- `appointment`: dispo, creation, transitions d'etat, extension, reviews, vues patron/client/employe, admin listing
- `notifications`: historique, unread count, mark read, stream SSE
- `upload`: upload fichier vers Cloudinary

### 4.3 Endpoints exposes

Base: `http://localhost:3000`

Auth (`/api/auth`)
- `POST /register`
- `POST /login`
- `POST /check-phone`
- `POST /request-otp`
- `POST /verify-otp`
- `GET /me` (auth)
- `PATCH /me` (auth)

Salon (`/api/salon`)
- `GET /top-rated`
- `GET /all`
- `GET /search`
- `GET /:id`
- `POST /:id/favorite` (auth)
- `GET /:id/favorite-status` (auth)
- `GET /favorites/all` (auth)
- `POST /create` (patron/admin)
- `PUT /update` (patron/admin)
- `GET /my-salon` (patron/admin)
- `POST /employee/create-account` (patron/admin)
- `PATCH /employee/:employeeId` (patron/admin)
- `DELETE /employee/:employeeId` (patron/admin)
- `POST /service/create` (patron/admin)
- `GET /services` (patron/admin)
- `PATCH /service/:serviceId` (patron/admin)
- `DELETE /service/:serviceId` (patron/admin)
- `POST /portfolio` (patron/admin)
- `DELETE /portfolio/:imageId` (patron/admin)

Appointment (`/api/appointment`)
- `GET /availability`
- `GET /available-dates`
- `POST /` (client)
- `PATCH /:id/status` (auth)
- `PATCH /:id/extend` (patron/employe)
- `GET /salon` (patron)
- `GET /client` (client)
- `GET /employee` (employe)
- `GET /unreviewed` (client)
- `POST /:id/review` (client)

Notifications (`/api/notifications`)
- `GET /` (auth)
- `GET /unread-count` (auth)
- `GET /stream` (auth, SSE)
- `PATCH /:id/read` (auth)

Upload (`/api/upload`)
- `POST /` (auth, multipart `file`)

Admin prefix (`/api/admin`) applique globalement
- Users: `GET /users`, `PATCH /users/:id`, `DELETE /users/:id`
- Salons: `GET /salons`, `PATCH /salons/:id`, `PATCH /salons/:id/status`, `DELETE /salons/:id`, `GET /salons/:id/stats`
- Salon services: `POST/PATCH/DELETE /salons/:id/service...`
- Salon employees: `POST/PATCH/DELETE /salons/:id/employee...`
- Salon portfolio: `POST/DELETE /salons/:id/portfolio...`
- Appointment admin view: `GET /salons/:id/appointments`

### 4.4 Logique metier notable

- Rendez-vous:
  - transitions d'etat controlees (`PENDING`, `CONFIRMED`, `IN_PROGRESS`, `ARRIVED`, `COMPLETED`, `CANCELLED`, `DECLINED`)
  - verification permissions par role + ownership
  - creation de rdv avec verif overlap client et disponibilite barbier
  - gestion duree estimee/fin reelle + stats par service/barbier
- Cron (`node-cron`, chaque minute):
  - rappels T-1h et T-15m
  - prompts de completion
  - gestion fautes si ignore trop longtemps
- Notifications:
  - persistance DB
  - push FCM si token present
  - stream SSE pour mise a jour temps reel

## 5) Data model Prisma

Schema principal dans `backend/prisma/schema.prisma`.

Entites coeur:
- `User`, `Profile`, `Notification`, `OtpCode`
- `Salon`, `WorkingHours`, `SalonSocialLink`, `PortfolioImage`, `Service`
- `Appointment`, `AppointmentService`, `AppointmentFault`, `BarberServiceStat`
- `Review`, `FavoriteSalon`
- `Product`, `Order`, `OrderItem`

Enums:
- `Role`: `CLIENT`, `PATRON`, `EMPLOYEE`, `ADMIN`
- `ApprovalStatus`: `PENDING`, `APPROVED`, `SUSPENDED`
- `AppointmentStatus`: `PENDING`, `CONFIRMED`, `IN_PROGRESS`, `ARRIVED`, `COMPLETED`, `CANCELLED`, `DECLINED`
- `AppointmentTarget`: `EMPLOYEE`, `PATRON`

## 6) Frontend Flutter - architecture reelle

### 6.1 Initialisation et config

- `main.dart`:
  - charge `.env` via `flutter_dotenv`
  - initialise Firebase (`firebase_options.dart`)
  - initialise FCM (hors web)
  - lance `SplashScreen`
- `firebase_options.dart`:
  - lit les valeurs Firebase depuis variables `FIREBASE_*` du `.env`
  - fail fast si variable requise manquante
- `config/api_config.dart`:
  - support `--dart-define=API_BASE_URL=...`
  - Android emulator default: `http://10.0.2.2:3000`

### 6.2 Navigation role-based

- `SplashScreen` lit `jwt_token` + `user_role` depuis `SharedPreferences`
- Redirections:
  - `CLIENT` -> `ClientMainLayout`
  - `PATRON` -> `MainPage`
  - `ADMIN` -> `AdminMainScreen`
  - `EMPLOYEE` -> `EmployeeMainLayout`

### 6.3 Services Flutter

- `AuthService`: auth, profile, OTP, upload image
- `SalonService`: salons publics + gestion patron + actions admin peek
- `AppointmentService`: rdv client/patron/employe + admin appointment list
- `AdminService`: users/salons CRUD + stats
- `NotificationService`: poll + SSE + unread notifier
- `FcmService`: sync token backend + notifications locales

## 7) Flux fonctionnels principaux

### 7.1 Auth

1. Sign up/login via `/api/auth/*`
2. stockage `jwt_token` et `user_role`
3. redirection dynamique selon role
4. profile update sur `/api/auth/me`

### 7.2 Salon (patron)

1. creation salon
2. update infos (social links, working hours, cover, etc.)
3. gestion employees
4. gestion services
5. gestion portfolio

### 7.3 Appointment

1. client consulte `availability` / `available-dates`
2. client cree un rdv
3. patron/employe changent statut
4. client depose review apres `COMPLETED`

### 7.4 Notification temps reel

- backend ecrit notification en DB
- push FCM si possible
- event SSE diffuse en temps reel
- frontend incremente badge et peut refresh automatiquement

## 8) Audit Clean Code / architecture

### Points solides

- separation en modules par feature cote backend
- separation par espaces fonctionnels cote Flutter
- endpoint admin par feature (auth, salon, appointment) tout en gardant une garde admin centrale
- Prisma schema riche et coherent avec roadmap produit
- logique rdv assez complete (regles, overlap, transitions)

### Points a ameliorer

- services backend trop volumineux (surtout `salon.service.ts` et `appointment.service.ts`)
- usage frequent de `any` dans controllers/services (perte de robustesse TS)
- melange des responsabilites (ex: service notification importe un controller SSE)
- reponses API non uniformes (`{success,data}` vs payload brut dans notifications)
- textes/commentaires multilangues et encodage heterogene dans plusieurs fichiers
- pas de suite de tests backend, test Flutter par defaut non lie au produit

## 9) Incoherences detectees (importantes)

1. Endpoint front/back non aligne
- Front: `SalonService.getServices()` appelle `GET /api/salon/service/list`
- Back: endpoint reel `GET /api/salon/services`
- Impact: risque 404 sur cette action

2. Secret JWT par defaut hardcode
- `env.ts` garde une fallback string pour `JWT_SECRET`
- Impact: risque securite si env mal configure

3. Prisma log en mode verbeux
- `db.ts` active `query/info/warn/error`
- Impact: bruit et risque exposition logs sensibles en prod

4. Identifiants projet Flutter non harmonises
- dossier renomme `frontEnd-mobile`, mais certains identifiants natifs gardent `flutter_application_1` (ex package Android)
- Impact: dette technique de naming (fonctionnel OK, mais confusion equipe)

## 10) Plan d'amelioration recommande (ordre pragmatique)

### Phase 1 (rapide, fort impact)

- corriger endpoint Flutter `service/list` -> `services`
- imposer `JWT_SECRET` requis en prod (supprimer fallback)
- passer logs Prisma en mode env-driven (`warn/error` en prod)
- normaliser format de reponse API

### Phase 2 (stabilite)

- extraire logique volumineuse appointment/salon en sous-services (`validators`, `policies`, `notifiers`)
- typer strictement DTO request/response (plus de `any`)
- ajouter tests backend sur:
  - transitions de statut rdv
  - permissions role-based
  - disponibilite / overlap

### Phase 3 (maintenabilite)

- harmoniser naming projet Flutter (package id / namespaces)
- centraliser erreurs API (codes + messages)
- ajouter observabilite (structured logs, correlation id)

## 11) Commandes utiles

Backend:
```bash
cd backend
npm install
npm run prsm:gen
npm run dev
```

Prisma:
```bash
cd backend
npm run prsm:mig
npm run prsm:gen
npm run prsm:std
```

Flutter:
```bash
cd frontEnd-mobile
flutter pub get
flutter run
```

Docker (racine):
```bash
docker compose up --build
```

## 12) TL;DR

- L'app est deja bien avancee fonctionnellement, surtout sur le flux rendez-vous.
- L'architecture est globalement modulaire, mais certaines couches sont encore trop chargees.
- Le gap principal immediate a corriger: endpoint `GET /api/salon/service/list` cote Flutter.
- Priorite suivante: securite env (`JWT_SECRET`), tests backend, et typage strict TS.
