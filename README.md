# NEXUS App Platform

This repository now includes a redesigned NEXUS App Platform foundation that prepares the original one-page experience for modular growth.

## Goals

- Improve usability and visual consistency
- Strengthen privacy and security defaults
- Create a clear app-shell model for future feature expansion
- Split large HTML logic into maintainable modules
- Use browser localStorage as a safe, local-only state layer

## Structure

- `index.html` – app shell and layout structure
- `styles.css` – visual design and responsive layout
- `app.js` – platform bootstrap logic
- `modules/store.js` – shared localStorage state layer
- `modules/router.js` – navigation and feature switching
- `modules/todo.js` – todo management
- `modules/weather.js` – explicit opt-in weather access
- `modules/privacy.js` – screen protection, privacy mode, anonymous mode

## Security defaults

- External network fetches are disabled by default.
- Weather access is only performed when the user enables automatic network retrieval.
- Privacy overlays can guard the screen when focus is lost.
- Anonymous mode toggles the app into a safer local-only posture.

## Future roadmap

- Add a command palette and richer modular widgets
- Separate app-specific panels into additional modules
- Add import/export backup and restore logic
- Expand into assistant, board, and diagnostic feature modules

## Notes

This is a foundation for the next-generation NEXUS architecture without losing the original single-file prototype in the existing repository.
