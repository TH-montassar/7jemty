# Rapport technique complet — Projet **7jemty / hjamty**

## 1) Vue d’ensemble (chneya l’app tawa)

`7jemty` est un projet **multi-plateforme** avec :
- un **backend Node.js/TypeScript + Express + Prisma + PostgreSQL**,
- un **frontend mobile/web Flutter**,
- une orientation métier autour des **salons**, **clients**, **patrons**, **employés**, **rendez-vous** et **services**.

Le backend expose une API REST montée sous `/api/*`, et l’app Flutter consomme directement ces endpoints via des services HTTP (`auth_service`, `salon_service`, `appointment_service`).

---

## 2) Stack technique

## Backend
- Runtime: Node.js (ESM)
- Framework: Express 5
- ORM: Prisma (+ adapter PostgreSQL `@prisma/adapter-pg`)
- DB: PostgreSQL
- Validation input: Zod
- Auth: JWT (`jsonwebtoken`) + hash password (`bcryptjs`)

## Frontend
- Framework: Flutter (Dart)
- HTTP client: package `http`
- Stockage local: `shared_preferences`, `flutter_secure_storage` (dépendance présente)
- UI + navigation par espaces (client/patron/admin/employee)
- Localisation custom via `TranslationService` (langue `tn` par défaut)

---

## 3) Architecture globale

## Backend (structure)
- `backend/server.ts` : boot serveur + écoute sur `env.PORT`
- `backend/src/app.ts` : création app Express + middlewares + montage des routes
- `backend/src/config/env.ts` : config env (`PORT`, `DATABASE_URL`, `JWT_SECRET`)
- `backend/src/lib/db.ts` : connexion Prisma + pool PG
- `backend/src/middlewares/auth.middleware.ts` : `protect`, `isPatron`
- `backend/src/modules/*` : modules métier (auth, salon, appointment)

## Frontend (structure)
- `flutter_application_1/lib/main.dart` : racine app + `SplashScreen`
- `flutter_application_1/lib/pages/splash_screen.dart` : logique redirection selon token/role
- `flutter_application_1/lib/services/*.dart` : appels API
- `flutter_application_1/lib/features/*` : espaces fonctionnels (client, patron, admin, auth)
- `flutter_application_1/lib/core/*` : couleurs + traduction

---

## 4) Arbre de fichiers (résumé utile pour un prompt AI)

```text
/workspace/7jemty
├─ backend/
│  ├─ server.ts
│  ├─ package.json
│  ├─ prisma/
│  │  ├─ schema.prisma
│  │  └─ migrations/
│  └─ src/
│     ├─ app.ts
│     ├─ config/env.ts
│     ├─ lib/db.ts
│     ├─ middlewares/auth.middleware.ts
│     └─ modules/
│        ├─ auth/
│        │  ├─ auth.routes.ts
│        │  ├─ auth.controller.ts
│        │  ├─ auth.service.ts
│        │  └─ auth.schema.ts
│        ├─ salon/
│        │  ├─ salon.routes.ts
│        │  ├─ salon.controller.ts
│        │  ├─ salon.service.ts
│        │  └─ salon.schema.ts
│        └─ appointment/
│           ├─ appointment.routes.ts
│           ├─ appointment.controller.ts
│           ├─ appointment.service.ts
│           └─ appointment.schema.ts
└─ flutter_application_1/
   ├─ pubspec.yaml
   ├─ lib/
   │  ├─ main.dart
   │  ├─ core/
   │  ├─ services/
   │  ├─ features/
   │  │  ├─ auth/
   │  │  ├─ client_space/
   │  │  ├─ patron_space/
   │  │  └─ admin_space/
   │  └─ pages/
   └─ assets/images/
```

---

## 5) API actuelle (ce qui existe vraiment)

Base backend: `http://localhost:3000`

## Auth (`/api/auth`)
- `POST /register`
  - body attendu: `fullName, phoneNumber, password, role?, address?, latitude?, longitude?`
  - action: crée user + profile, hash password, renvoie JWT
- `POST /login`
  - body: `phoneNumber, password`
  - action: login + JWT + `hasSalon` pour rôle patron

## Salon (`/api/salon`)
Public:
- `GET /top-rated` : salons triés par note
- `GET /all?lat=&lng=` : liste salons (distance calculée si coords fournies)
- `GET /:id` : détail salon + services + équipe + social links + horaires

Protégé (JWT):
- `POST /create` (patron)
- `PUT /update` (patron)
- `GET /my-salon` (patron)
- `POST /employee/create-account` (patron)
- `POST /service/create` (patron)
- `GET /services` (patron)

## Appointment (`/api/appointment`)
Protégé:
- `PATCH /:id/status`
  - body: `{ status: CONFIRMED|DECLINED|COMPLETED|CANCELLED }`
  - permissions selon rôle (CLIENT/EMPLOYEE/PATRON) + règles de transition

---

## 6) Data model (Prisma) — entités clés

Enums:
- `Role`: CLIENT, PATRON, EMPLOYEE, ADMIN
- `AppointmentStatus`: PENDING, CONFIRMED, ARRIVED, COMPLETED, CANCELLED, DECLINED
- `ApprovalStatus`: PENDING, APPROVED, SUSPENDED

Tables principales:
- `User` (+ relation `Profile`)
- `Salon` (owner patron + employees + services + appointments...)
- `Service`
- `Appointment` + `AppointmentService`
- `Review`
- `FavoriteSalon`
- `Product`, `Order`, `OrderItem`

=> DB conçue pour une app assez large (booking + avis + e-commerce produits), même si toutes les routes ne sont pas encore implémentées.

---

## 7) Design & UX (frontend)

- Lancement via `SplashScreen` avec animation logo + redirection.
- Navigation selon `user_role` stocké localement:
  - non connecté -> `ClientMainLayout`
  - `PATRON` -> `MainPage`
  - `ADMIN` -> `AdminHomePage`
  - `EMPLOYEE` -> actuellement redirigé client layout
- Séparation par espaces:
  - `client_space`: home, booking, appointments, products, profile, salon profile
  - `patron_space`: dashboard salon, gestion équipe/services/profil
  - `admin_space`: page admin de base
- Thème visuel centralisé (`AppColors`) + traduction locale massive (`TranslationService`)

---

## 8) Flux techniques importants

## Auth flow
1. Register/Login côté Flutter via `AuthService`
2. Réponse backend retourne `token` + user
3. Token sauvegardé dans `SharedPreferences`
4. Requêtes protégées ajoutent `Authorization: Bearer <token>`

## Salon flow
1. Patron crée son salon (`/api/salon/create`)
2. Peut enrichir infos (`/api/salon/update`)
3. Peut ajouter employés (`/employee/create-account`)
4. Peut ajouter services (`/service/create`)
5. Client peut consulter `/all`, `/top-rated`, `/api/salon/:id`

## Appointment status flow
- Un seul endpoint existe pour l’instant : update status
- Contrôle permissions basé sur rôle + ownership

---

## 9) État actuel / gaps / incohérences à connaître

1. **Coverage API partielle**
   - Beaucoup de modèles DB existent (orders, products, reviews...) mais routes pas encore exposées.

2. **Incohérence endpoint front/back détectée**
   - Front `SalonService.getServices()` appelle `GET /api/salon/service/list`
   - Back expose `GET /api/salon/services`
   - Risque: 404 sur cet appel précis.

3. **Secret JWT par défaut en dur**
   - Fallback hardcodé si variable env absente.

4. **Logs DB verbeux**
   - Prisma log `query/info/warn/error` actif -> utile dev, à ajuster prod.

5. **Rôle EMPLOYEE côté splash**
   - Redirigé actuellement vers layout client (pas espace employee dédié au démarrage).

---

## 10) Prompt prêt à donner à une IA (copier/coller)

```text
Tu es mon assistant technique senior sur le projet 7jemty.

Contexte architecture:
- Monorepo avec 2 apps:
  1) backend Node.js/TypeScript/Express/Prisma/PostgreSQL dans /backend
  2) frontend Flutter dans /flutter_application_1
- API REST principale:
  - /api/auth: register, login
  - /api/salon: top-rated, all, :id, create/update/my-salon, employee/create-account, service/create, services
  - /api/appointment: PATCH :id/status
- Auth JWT Bearer.
- Validation Zod côté backend.
- DB Prisma avec rôles CLIENT/PATRON/EMPLOYEE/ADMIN et modèle salon/appointment/service/review/product/order.

Convention de travail demandée:
- Donne toujours un plan d’action avant modifications.
- Propose des patches ciblés avec impact minimal.
- Si tu touches API, mentionne contrat request/response et impacts Flutter.
- Si tu touches Flutter, précise les écrans et flux utilisateur affectés.
- Toujours lister risques, tests recommandés, et checklist de validation manuelle.

Objectif:
Aide-moi à améliorer progressivement le projet (fiabilité, sécurité, cohérence API front/back, qualité code, et architecture évolutive).
```

---

## 11) Commandes utiles (quick start)

## Backend
```bash
cd backend
npm run dev
```

## Prisma
```bash
cd backend
npm run prisma:mig
npm run prisma:gen
npm run prisma:studio
```

## Flutter
```bash
cd flutter_application_1
flutter pub get
flutter run
```

---

## 12) TL;DR (version courte)

- Projet solide en base: backend modulaire + Flutter structuré par espaces.
- API déjà utilisable pour auth/salon/update status rdv.
- Schéma DB riche (préparé pour features futures).
- Point urgent: aligner endpoint `getServices` côté front/back.
- Avec ce rapport + le prompt fourni, une IA peut comprendre rapidement l’architecture et proposer des évolutions concrètes.
