# DailyDesk v0.1.0

## Highlights

- Offline-first todo, calendar, memo, Pomodoro, habit, review, dashboard, and AI Copilot modules.
- Local LAN peer discovery through mDNS with UDP multicast fallback.
- PIN pairing, HMAC-authenticated incremental sync, LWW merge, and memo conflict backups.
- Android foreground Pomodoro notification bridge.
- Windows portable archive and split APK release artifacts.

## Verification

- Flutter analyzer and test suite pass in CI.
- Bundle verifier checks APK/Windows archive size, URL allowlist, and tag/version consistency.

## Known limitations

- Physical Windows/Android LAN synchronization and notification behavior require device-level validation.
- Android release signing uses the CI-provided signing configuration; production signing secrets must be configured before publishing.
