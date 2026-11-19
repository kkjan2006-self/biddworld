# PWA install experience follow-up — 2026-11-19

- The header install control previously disappeared whenever the browser did not dispatch `beforeinstallprompt`, leaving Android users without an in-app explanation of the manual install route.
- The control now remains available until the app is detected as installed. It invokes the native browser prompt when available and otherwise explains Chrome on Android's browser-menu “Install app” / “Add to Home screen” path.
- Standalone display mode and the platform's Apple standalone flag are detected; the control hides when already installed and reacts to `appinstalled`.
- Service-worker scope and cache behavior were not changed. The offline shell remains network-first for same-origin static assets and never intercepts non-GET or cross-origin requests.
- Updated the PWA source-contract test to assert the v4 cache version already present in the worker and the manual install fallback. Test source is authored only; no tests, build, type-check, browser or Android QA were run.
- No Supabase access, migrations, data changes, deployment or protected-branch updates occurred.
