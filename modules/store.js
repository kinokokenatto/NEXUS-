const STORAGE_KEY = 'nexus_app_platform_state_v1';
const LEGACY_KEYS = ['nexus_app_platform_state'];
const VERSION = 1;

function makeId() {
  return globalThis.crypto?.randomUUID?.() || `todo-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`;
}

export const defaultState = Object.freeze({
  version: VERSION,
  app: { currentFeature: 'overview' },
  privacy: { autoNetwork: false, screenProtect: false, anonMode: false },
  weather: { city: 'tokyo', cache: null },
  todos: [],
  ui: { sidebarOpen: true, showCompleted: true }
});

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

function normalizeTodoList(value) {
  if (!Array.isArray(value)) return [];
  return value.slice(0, 1000).flatMap((item) => {
    if (!item || typeof item !== 'object') return [];
    const text = typeof item.text === 'string' ? item.text.trim().slice(0, 120) : '';
    if (!text) return [];
    const id = typeof item.id === 'string' && item.id.length <= 100 ? item.id : makeId();
    return [{ id, text, done: item.done === true, createdAt: Number.isFinite(item.createdAt) ? item.createdAt : Date.now() }];
  });
}

function normalizeState(input) {
  const source = input && typeof input === 'object' && !Array.isArray(input) ? input : {};
  const base = clone(defaultState);
  const validFeatures = new Set(['overview', 'weather', 'todos', 'assistant', 'privacy', 'system']);
  const currentFeature = source.app?.currentFeature;
  const city = source.weather?.city;
  const cities = new Set(['tokyo', 'osaka', 'kyoto', 'sapporo', 'fukuoka']);
  return {
    version: VERSION,
    app: { currentFeature: validFeatures.has(currentFeature) ? currentFeature : base.app.currentFeature },
    privacy: {
      autoNetwork: source.privacy?.autoNetwork === true,
      screenProtect: source.privacy?.screenProtect === true,
      anonMode: source.privacy?.anonMode === true
    },
    weather: {
      city: cities.has(city) ? city : base.weather.city,
      cache: source.weather?.cache && typeof source.weather.cache === 'object' ? source.weather.cache : null
    },
    todos: normalizeTodoList(source.todos),
    ui: {
      sidebarOpen: source.ui?.sidebarOpen !== false,
      showCompleted: source.ui?.showCompleted !== false
    }
  };
}

let currentState;
const listeners = new Set();
let storageAvailable = true;

export function loadState() {
  if (currentState) return currentState;
  try {
    let raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) {
      for (const key of LEGACY_KEYS) {
        raw = localStorage.getItem(key);
        if (raw) break;
      }
    }
    currentState = normalizeState(raw ? JSON.parse(raw) : defaultState);
    if (raw) saveState(currentState);
  } catch (error) {
    storageAvailable = false;
    currentState = normalizeState(defaultState);
  }
  return currentState;
}

export function saveState(state = currentState) {
  if (!state) return false;
  currentState = normalizeState(state);
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(currentState));
    storageAvailable = true;
  } catch (error) {
    storageAvailable = false;
  }
  for (const listener of listeners) listener(currentState, { storageAvailable });
  window.dispatchEvent(new CustomEvent('nexus:state-change', { detail: { storageAvailable } }));
  return storageAvailable;
}

export function replaceState(value) {
  return saveState(normalizeState(value));
}

export function resetState() {
  currentState = normalizeState(defaultState);
  saveState(currentState);
  return currentState;
}

export function subscribe(listener) {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

export function getStorageStatus() {
  return { available: storageAvailable, key: STORAGE_KEY, bytes: (() => {
    try { return new Blob([localStorage.getItem(STORAGE_KEY) || '']).size; } catch { return 0; }
  })() };
}

export { STORAGE_KEY, VERSION, normalizeState };

window.addEventListener('storage', (event) => {
  if (event.key !== STORAGE_KEY) return;
  try {
    currentState = normalizeState(event.newValue ? JSON.parse(event.newValue) : defaultState);
    for (const listener of listeners) listener(currentState, { storageAvailable: true, external: true });
    window.dispatchEvent(new CustomEvent('nexus:state-change', { detail: { external: true } }));
  } catch (error) {
    // Ignore malformed writes from other tabs; keep the last valid in-memory state.
  }
});
