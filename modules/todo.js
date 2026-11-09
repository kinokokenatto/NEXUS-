import { saveState, subscribe } from './store.js';

const createId = () => globalThis.crypto?.randomUUID?.() || `todo-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;

export function initTodo(state) {
  const form = document.getElementById('todoForm');
  const input = document.getElementById('todoInput');
  const list = document.getElementById('todoList');
  const summary = document.getElementById('todoSummary');
  const empty = document.getElementById('todoEmpty');
  const showCompleted = document.getElementById('todoShowCompleted');
  const clearCompleted = document.getElementById('todoClearCompleted');

  function render() {
    if (!list) return;
    const visible = state.todos.filter(todo => state.ui.showCompleted || !todo.done);
    list.replaceChildren();
    for (const todo of visible) {
      const row = document.createElement('li');
      row.className = `todo-item${todo.done ? ' is-complete' : ''}`;
      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox'; checkbox.checked = todo.done;
      checkbox.setAttribute('aria-label', `${todo.text}を完了にする`);
      checkbox.addEventListener('change', () => {
        const match = state.todos.find(item => item.id === todo.id);
        if (match) match.done = checkbox.checked;
        saveState(state);
      });
      const text = document.createElement('span'); text.className = 'todo-text'; text.textContent = todo.text;
      const remove = document.createElement('button'); remove.type = 'button'; remove.className = 'todo-delete'; remove.textContent = '削除'; remove.setAttribute('aria-label', `${todo.text}を削除`);
      remove.addEventListener('click', () => { state.todos = state.todos.filter(item => item.id !== todo.id); saveState(state); });
      row.append(checkbox, text, remove); list.append(row);
    }
    const done = state.todos.filter(todo => todo.done).length;
    if (summary) summary.textContent = `${done} / ${state.todos.length} 完了`;
    if (empty) empty.hidden = visible.length !== 0;
    const overview = document.getElementById('overviewTodoCount');
    if (overview) overview.textContent = `${done} / ${state.todos.length}`;
  }

  form?.addEventListener('submit', event => {
    event.preventDefault();
    const text = input.value.trim();
    if (!text || text.length > 120 || state.todos.length >= 1000) return;
    state.todos.unshift({ id: createId(), text, done: false, createdAt: Date.now() });
    input.value = '';
    saveState(state);
    input.focus();
  });
  showCompleted.checked = state.ui.showCompleted;
  showCompleted.addEventListener('change', () => { state.ui.showCompleted = showCompleted.checked; saveState(state); });
  clearCompleted.addEventListener('click', () => { state.todos = state.todos.filter(todo => !todo.done); saveState(state); });
  subscribe(render);
  render();

  return {
    add(text) {
      const clean = String(text).trim().slice(0, 120);
      if (!clean || state.todos.length >= 1000) return false;
      state.todos.unshift({ id: createId(), text: clean, done: false, createdAt: Date.now() });
      saveState(state);
      return true;
    }
  };
}
