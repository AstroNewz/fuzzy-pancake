# Implementation & Development Plan

## Phase 1: Foundation & Data Architecture (Week 1–2)
* [ ] Initialize Flutter project structure and multi-platform build pipelines (Android / Web).
* [ ] Provision free Supabase project and write PostgreSQL schemas:
  * `players`, `matches`, `match_sets`, `attendance_logs`, `ladder_positions`, `gear_logs`.
* [ ] Implement secure authentication flow restricted to registered squad roll numbers.
* [ ] Build role-based route guards (Admin vs. Player dashboards).

## Phase 2: Core Utility Modules (Week 3–4)
* [x] **Attendance Engine:**
  * Admin-generated daily QR code with time-bound cryptographic token.
  * In-app QR scanner with instant check-in logging and duplicate scan prevention.
* [x] **Live Court Umpire & Scoring Engine:**
  * Clean +1/-1 touch scoring UI supporting standard BWF 21-point / 30-point deuce rules.
  * Live server side calculation and automatic side/service box rotation indicator.
  * Match completion trigger saving set scores and updating head-to-head records.

## Phase 3: Gamification & The Trump Card Engine (Week 5–6)
* [x] Build the 3D interactive Trump Card UI:
  * Front: Dynamic gradient frame (Bronze/Silver/Gold/Diamond), player photo, OVR rating, and radar attribute chart (`fl_chart`).
  * Back: Win/Loss streak, career match count, H2H top rival, and playstyle tags.
  * Flip interaction via 3D matrix transformation.
* [x] Integrate `RepaintBoundary` PNG renderer for 1-tap card sharing to social/WhatsApp status.
* [x] Implement SQL views and stored procedures for Elo rating calculation and dynamic OVR adjustments.

## Phase 4: Club Operations & Ladder Challenges (Week 7)
* [ ] Intra-Club Ladder ("King of the Court"):
  * Standings board (Ranks 1–20).
  * Direct challenge issuance logic (max +2 ranks above).
  * Auto-swap algorithm on lower-rank victory.
* [ ] Equipment Tracker (Racket string tension date log + tension loss alert trigger).
* [ ] Automated Telegram Bot webhook integration for match results and practice alerts.

## Phase 5: Testing, Hardening & Deployment (Week 8)
* [ ] Conduct offline-first sync testing for courts with patchy Wi-Fi.
* [ ] Build release APK (`flutter build apk --split-per-abi`) and distribute to team captains.
* [ ] Deploy Web PWA to Vercel/Firebase Hosting for iOS squad members.