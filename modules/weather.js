import { saveState } from './store.js';

export function initTodo(state) {
  const form = document.getElementById('todoForm');
  const input = document.getElementById('todoInput');
  const list = document.getElementById('todoList');
  const summary = document.getElementById('todoSummary');

  function syncSummary() {
    const total = state.todos.length;
    const done = state.todos.filter(item => item.done).length;
    if (summary) summary.textContent = `${done}/${total}`;
  }

  function render() {
    if (!list) return;
    list.innerHTML = '';

    state.todos.forEach(item => {
      const li = document.createElement('li');
      li.className = 'todo-item' + (item.done ? ' is-complete' : '');

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.checked = item.done;
      checkbox.addEventListener('change', () => {
        item.done = checkbox.checked;
        saveState(state);
        render();
      });

      const text = document.createElement('span');
      text.className = 'todo-text';
      text.textContent = item.text;

      const remove = document.createElement('button');
      remove.type = 'button';
      remove.className = 'todo-delete';
      remove.textContent = 'Delete';
      remove.addEventListener('click', () => {
        state.todos = state.todos.filter(entry => entry.id !== item.id);
        saveState(state);
        render();
      });

      li.appendChild(checkbox);
      li.appendChild(text);
      li.appendChild(remove);
      list.appendChild(li);
    });

    syncSummary();
  }

  form?.addEventListener('submit', (event) => {
    event.preventDefault();
    const text = input.value.trim();
    if (!text) return;

    state.todos.unshift({
      id: crypto.randomUUID ? crypto.randomUUID() : `todo-${Date.now()}`,
      text,
      done: false
    });

    saveState(state);
    input.value = '';
    render();
  });

  render();
}
