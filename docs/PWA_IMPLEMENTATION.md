# BiddWorld PWA implementation

## Included in source

- `public/manifest.webmanifest` declares the app name, standalone display, app scope, relative start URL, dark-blue theme and app icon sizes.
- `public/biddworld-icon.svg` is the scalable app icon.
- `public/sw.js` caches only same-origin app-shell/static assets, uses network-first navigation with an offline shell fallback, and removes older versioned caches.
- `src/main.tsx` registers the worker only in production and uses Vite `BASE_URL` so GitHub Pages `/biddworld/` and a future root-domain deployment have the correct service-worker scope.
- `index.html` links the manifest and icon and includes mobile install metadata.
- `tests/pwa-installability.test.ts` protects these contracts.

## Safety and limitations

- The worker does not intercept cross-origin requests, Supabase requests, auth traffic, or non-GET requests. Wallet, bidding, package and other financial actions are never queued or replayed offline.
- Offline mode is a shell fallback only; authenticated member data is not persisted by the worker.
- A passing source test/build does not prove device installation. Verify Android Chrome install prompt, standalone launch, offline shell, update lifecycle and GitHub Pages scope on a real device during final QA.
