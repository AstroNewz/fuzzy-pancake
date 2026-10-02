# Project: SmashDeck (College Badminton Club App)

## 1. Overview & Vision
SmashDeck is a lightweight, mobile-first club management and performance-tracking application built for a 20-member collegiate badminton squad. It replaces manual registers, scattered WhatsApp group updates, and ad-hoc tournament planning with an automated, data-driven, gamified system.

## 2. Core Objectives
* **Zero Infrastructure Cost:** Lifetime-free architecture leveraging free-tier BaaS (Supabase / Firebase) and cross-platform Flutter framework.
* **Player Gamification:** Digital collectible "Trump Cards" showing dynamic Overall Ratings (OVR), attributes (Smash, Agility, Stamina, Consistency), and growth trajectories.
* **Streamlined Operations:** Seamless QR court attendance, live umpire scorekeeping, gear maintenance logs, and an intra-club Elo ladder challenge system.
* **Frictionless Distribution:** Internal distribution via direct Android APK sideloading and multi-platform Progressive Web App (PWA).

## 3. User Roles & Permissions
* **Admin / Head Coach:** Full system control, squad roster management, attendance overrides, tournament seeding, and club-wide broadcast notices.
* **Team Captain:** Live match verification, practice routine scheduling, court rotation management, and shuttlecock inventory updates.
* **Squad Member (Player):** Personal Trump Card view, QR check-in, issue/accept ladder challenges, string tension logging, and H2H stat checks.

## 4. Technology Stack (Zero-Cost Matrix)
* **Frontend:** Flutter (Mobile + Web PWA)
* **State Management:** Riverpod / Flutter BLoC
* **Backend & Database:** Supabase (PostgreSQL with Row Level Security and Realtime)
* **Authentication:** Supabase Auth (Passwordless Email Magic Links or College Roll No. UID)
* **Storage:** Supabase Storage (1 GB free tier for player avatars & gear photos)
* **Alerts & Notifications:** Telegram Bot Webhook API / Discord Webhook (100% free, reliable)
* **Hosting:** Vercel / Firebase Hosting (Web build)