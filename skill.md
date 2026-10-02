# Engineering Skills, Standards & Developer Guide

## 1. Required Technical Competencies
* **Dart & Flutter:** State management (`riverpod`), custom animations, 3D matrix transformations, responsive layouts for mobile and web.
* **PostgreSQL & Database Design:** Relational integrity, triggers, stored functions, Materialized Views for leaderboards, Row Level Security (RLS) policies.
* **Edge & Webhook Automation:** Supabase Database Webhooks, Telegram Bot API, RESTful payloads.
* **Offline-First Synchronization:** Local persistence, connection monitoring, idempotent write buffers.

## 2. Coding & Architectural Standards

### Project Structure Convention (Feature-First)
```text
lib/
├── core/
│   ├── network/          # Supabase client wrapper & offline handler
│   ├── theme/            # Badges, gradients, card themes
│   └── utils/            # BWF badminton scoring logic helpers
├── features/
│   ├── auth/             # Authentication & session controllers
│   ├── trump_card/       # 3D Flip Card widget & radar chart
│   ├── match_engine/     # Live umpire scoring interface & state
│   ├── attendance/       # Dynamic QR generator & scanner
│   ├── ladder/           # Intra-club ranking and challenge logic
│   └── gear_tracker/     # Racket string tension logs
└── main.dart