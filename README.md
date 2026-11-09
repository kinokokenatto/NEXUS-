# NEXUS App Platform

A modular, local-first redesign of the NEXUS workspace. The original `NEXUS_SUPER4.1.html` remains available as the legacy single-file edition; this platform is the maintainable modular application entry point.

## Run locally

ES modules are loaded from local files, so run from a local static web server rather than opening `index.html` directly as `file://`.

```sh
python3 -m http.server 8000
```

Then visit `http://localhost:8000/`.

## Architecture

- `index.html`: semantic app shell and accessible UI structure
- `styles.css`: responsive layout, visual tokens, and component styles
- `app.js`: startup composition only
- `modules/store.js`: versioned, validated local state, persistence and subscriptions
- `modules/router.js`: feature navigation, URL hash, and responsive sidebar
- `modules/todo.js`: Todo CRUD, completion, filters, and persistence
- `modules/weather.js`: weather UI and cache; manual refresh only
- `modules/privacy.js`: communication allowlist and privacy controls
- `modules/assistant.js`: local command helper; no AI/network transmission
- `modules/platform.js`: clock, command palette, privacy dialog, backup/restore

## Privacy and security

- State is stored in this browser's `localStorage`; it is not encrypted. Do not put secrets in it.
- External requests are off by default. Weather requests require explicit permission and a manual refresh.
- The network helper restricts HTTPS requests to the Open-Meteo API, omits credentials/referrer, rejects redirects, and applies a timeout.
- “NEXUS external communication block” only describes requests initiated by this app; it is not a VPN, IP anonymizer, or browser-wide firewall.
- Backups are plain JSON and can contain personal data. Store them securely.
- The CSP is defense in depth, not a substitute for reviewing changes or serving the app over HTTPS in production.

## State and migration

State is schema-normalized and stored under `nexus_app_platform_state_v1`. Existing data under the previous platform key is read and migrated. Backup import validates and normalizes supported fields before replacing current state. The original SUPER4.1 single-file data format is not automatically migrated; retain the old file and export its data before switching if needed.

## Extension guide

Create a feature panel in `index.html` with a unique `data-feature` id and a matching navigation button. Add feature-specific behavior in a new file under `modules/`, export an `initFeature(state)` function, and register it in `app.js`. Persist changes through the shared store (`saveState`) rather than direct localStorage access.
