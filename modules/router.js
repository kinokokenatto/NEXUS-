const STORAGE_KEY = 'nexus_app_platform_state_v1';

export const defaultState = {
  app: {
    currentFeature: 'overview'
  },
  privacy: {
    autoNetwork: false,
    screenProtect: false,
    anonMode: false
  },
  weather: {
    city: 'tokyo'
  },
  todos: [
    { id: crypto.randomUUID ? crypto.randomUUID() : 'todo-1', text: 'Review NEXUS storage config', done: false },
    { id: crypto.randomUUID ? crypto.randomUUID() : 'todo-2', text: 'Refine privacy settings', done: true }
  ],
  ui: {
    sidebarOpen: true
  }
};

function deepClone(value) {
  return JSON.parse(JSON.stringify(value));
}

export function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return deepClone(defaultState);
    const saved = JSON.parse(raw);
    return {
      ...deepClone(defaultState),
      ...saved,
      privacy: { ...deepClone(defaultState.privacy), ...(saved.privacy || {}) },
      weather: { ...deepClone(defaultState.weather), ...(saved.weather || {}) },
      app: { ...deepClone(defaultState.app), ...(saved.app || {}) },
      ui: { ...deepClone(defaultState.ui), ...(saved.ui || {}) },
      todos: Array.isArray(saved.todos) ? saved.todos : deepClone(defaultState.todos)
    };
  } catch (error) {
    return deepClone(defaultState);
  }
}

export function saveState(state) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (error) {
    console.warn('State could not be saved.', error);
  }
}

export function updateState(nextState) {
  const current = loadState();
  const merged = { ...current, ...nextState };
  saveState(merged);
  return merged;
}

export { STORAGE_KEY };
