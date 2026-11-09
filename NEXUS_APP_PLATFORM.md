# NEXUS App Platform — modularization notes

## Completed foundation

The platform now has a dedicated app shell, separated stylesheet, ES module entry point, shared versioned state store, feature router, Todo module, weather module, privacy/network policy, local assistant, command palette, and backup/restore controls.

## Data-safety notes

- The store whitelists supported state fields and normalizes imported values.
- Browser storage can be unavailable or full; save operations report availability instead of crashing the app.
- Backups are not encrypted. Import is capped at 2MB and asks before replacing current data.
- Legacy SUPER4.1 browser data is not assumed to be compatible with the new state schema.

## Extending the platform

Keep startup wiring in `app.js` minimal. Each feature should own its event handlers and DOM rendering in a module, and use the shared store for persistence. Avoid `innerHTML` for user-provided text; use `textContent` and DOM node construction.
