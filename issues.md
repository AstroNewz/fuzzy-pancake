# Issues, Risk Register & Mitigation Strategy

## High Priority

### ISSUE-001: Supabase Free Tier Inactivity Pause
* **Risk:** Supabase projects pause after 7 days without incoming HTTP requests, causing connection timeouts during college breaks.
* **Mitigation:**
  1. Configure a free GitHub Actions cron job or UptimeRobot health check to ping the Supabase REST endpoint once every 3 days.
  2. Implement client-side error handling displaying an "Initializing Database..." state if an unpause latency occurs.

### ISSUE-002: Offline Scoring During Gym Connectivity Drops
* **Risk:** Badminton courts often have weak Wi-Fi/cellular signals; lost connection mid-match could corrupt scoring data.
* **Mitigation:**
  1. Implement local caching using `Hive` or `Isar` on the device.
  2. Keep all match state mutations local-first; trigger background sync with idempotent operations once network connectivity is restored.

---

## Medium Priority

### ISSUE-003: Attendance Proxy Scanning
* **Risk:** Players sharing screenshots of daily attendance QR codes with absent teammates.
* **Mitigation:**
  1. Dynamic QR code regeneration every 15 seconds on the Admin screen.
  2. Embed time-based one-time tokens (TOTP) in the QR payload.

### ISSUE-004: Rating Inflation in Elo / Trump Card Stats
* **Risk:** Players playing excessive casual matches against weaker peers to artificially inflate their OVR rating.
* **Mitigation:**
  1. Only designate "Official Ladder Matches" and "Tournament Fixtures" as rating-eligible games.
  2. Require mutual confirmation or umpire signature before a match record alters ladder standing.

---

## Low Priority

### ISSUE-005: Cross-Platform Asset Export on Web
* **Risk:** `RepaintBoundary` image byte generation behaving inconsistently across Safari Web PWA vs. Android native.
* **Mitigation:**
  1. Standardize canvas export using pure HTML5 canvas wrapper when running on `kIsWeb`.