# Test Flow — Review Reporting (Step by Step)

This document gives a practical QA flow for the full feature:

- Client posts review.
- Patron reports review (reason + message).
- Admin receives notification and reviews pending reports.
- Admin dismisses OR takes action (delete review + warn client).

---

## 0) Preconditions

1. Have 4 users:
   - `CLIENT_A` (will post review)
   - `PATRON_A` (owner of Salon A)
   - `ADMIN_A`
   - optional `CLIENT_B` (negative authorization tests)
2. `Salon A` exists and belongs to `PATRON_A`.
3. `CLIENT_A` has a completed appointment eligible for review on `Salon A`.
4. Backend is running.

---

## 1) Happy Path — Action Taken (Delete + Warning)

### Step 1 — Client posts review
- Login as `CLIENT_A`.
- Create a review on `Salon A`.
- Verify review appears in salon reviews list.

### Step 2 — Patron reports review
- Login as `PATRON_A`.
- Open reviews list in patron salon dashboard.
- On the review, click `...` then `Report`.
- Fill:
  - `reason`: e.g. `HARASSMENT`
  - `message`: clear explanation
- Submit.

**Expected:**
- API returns success (201).
- A new `ReportedReview` row is created with:
  - `status = PENDING`
  - correct `reviewId`, `reporterId`, `reason`, `message`.

### Step 3 — Admin sees pending report
- Login as `ADMIN_A`.
- Open admin reports page.

**Expected:**
- Report appears in pending list with:
  - reporter info
  - review owner/client info
  - salon info
  - reason + message.

### Step 4 — Admin takes action
- Click action that triggers `PATCH /api/review/reports/:id/action`.

**Expected:**
- Review is deleted.
- `ReportedReview.status = ACTION_TAKEN` and `resolvedAt` set.
- One `UserWarning` created for review owner (`CLIENT_A`).
- `User.warningCount` increments by 1.
- Client notification row created (`⚠️ Avertissement`).
- If client has FCM token, push notification sent.

---

## 2) Happy Path — Dismiss Report

### Step 1
- Repeat creation of a second report.

### Step 2
- Admin triggers `PATCH /api/review/reports/:id/dismiss`.

**Expected:**
- `ReportedReview.status = DISMISSED`.
- `resolvedAt` set.
- Review remains visible.
- No warning increment on client.

---

## 3) Authorization & Validation Tests

### A) Client cannot report
- Login as `CLIENT_B`.
- Call `POST /api/review/:id/report`.

**Expected:**
- 403 / business error: no permission to report review.

### B) Employee cannot report
- Login as employee.
- Call same endpoint.

**Expected:**
- 403 / business error.

### C) Patron can report only own salon reviews
- Login as patron of Salon B.
- Try to report review belonging to Salon A.

**Expected:**
- Error: cannot report reviews outside own salon.

### D) Duplicate report blocked
- Same patron tries to report same review twice.

**Expected:**
- Error: already reported.

### E) Missing reason blocked
- Submit report with empty reason.

**Expected:**
- 400 validation error.

---

## 4) API Smoke Checklist

1. `POST /api/review/:id/report` → 201 success on valid input.
2. `GET /api/review/reports` (admin) → contains pending reports only.
3. `GET /api/review/reports/resolved` (admin) → contains dismissed/actioned reports.
4. `PATCH /api/review/reports/:id/dismiss` (admin) → sets `DISMISSED`.
5. `PATCH /api/review/reports/:id/action` (admin) → delete review + warning side effects.

---

## 5) UI Regression Checklist

- Patron dashboard:
  - report button is visible on review item.
  - dialog has reason + message.
- Client salon profile:
  - report action should not be available.
- Admin reports page:
  - displays reason/message/review/salon/reporter.
  - allows dismiss and action.

---

## 6) Suggested Test Data Matrix

- Reasons: `INAPPROPRIATE`, `SPAM`, `HARASSMENT`.
- Messages:
  - short text
  - long text (500+ chars)
  - special chars / emoji.
- Review types:
  - with comment
  - without comment.

