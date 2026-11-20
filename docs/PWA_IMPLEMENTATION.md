# BiddWorld PWA implementation

## Included in source

- `public/manifest.webmanifest` declares the app name, standalone display, app scope, relative start URL, dark-blue theme and app icon sizes.
- `public/biddworld-icon.svg` remains the scalable favicon, with actual 192×192 and 512×512 PNG install icons under `public/icons/`; the 512 icon is declared `any maskable`.
- `index.html` uses the 192×192 PNG as the Apple touch icon.
- `public/sw.js` caches only same-origin app-shell/static assets (including both PNG icons), uses network-first navigation with an offline shell fallback, and removes older versioned caches; the cache namespace is currently v4; the source test still contains a stale v3 literal assertion and is intentionally deferred to the consolidated test/repair phase.
- `src/main.tsx` registers the worker only in production and uses Vite `BASE_URL` so GitHub Pages `/biddworld/` and a future root-domain deployment have the correct service-worker scope.
- `index.html` links the manifest and icon and includes mobile install metadata.
- `tests/pwa-installability.test.ts` verifies the manifest contract, actual PNG signatures and dimensions, worker scope/cache behavior and non-interception of API traffic.

## Safety and limitations

- The worker does not intercept cross-origin requests, Supabase requests, auth traffic, or non-GET requests. Wallet, bidding, package and other financial actions are never queued or replayed offline.
- Offline mode is a shell fallback only; authenticated member data is not persisted by the worker.
- A passing source test/build does not prove device installation. Verify Android Chrome install prompt, standalone launch, offline shell, update lifecycle and GitHub Pages scope on a real device during final QA.

## Browser install control

- `src/components/PWAInstallButton.tsx` listens for `beforeinstallprompt` and `appinstalled`.
- The header shows **Install App** only when the browser has offered a valid install prompt; it hides after the install prompt is used or the app is installed.
- Browsers that do not expose `beforeinstallprompt` (for example, iOS Safari) keep their native Add to Home Screen workflow; the custom button stays hidden.
