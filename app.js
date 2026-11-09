import { loadState, saveState, subscribe, resetState } from './modules/store.js';
import { initRouter } from './modules/router.js';
import { initTodo } from './modules/todo.js';
import { initWeather } from './modules/weather.js';
import { initPrivacy } from './modules/privacy.js';
import { initAssistant } from './modules/assistant.js';
import { initPlatform } from './modules/platform.js';

const state = loadState();

function start() {
  initRouter(state);
  initTodo(state);
  initWeather(state);
  initPrivacy(state);
  initAssistant(state);
  initPlatform(state, { resetState });

  subscribe(() => {
    const total = state.todos.length;
    const complete = state.todos.filter(todo => todo.done).length;
    const count = document.getElementById('overviewTodoCount');
    if (count) count.textContent = `${complete} / ${total}`;
  });

  window.addEventListener('error', (event) => {
    console.error('NEXUS runtime error:', event.message);
    const status = document.getElementById('systemStatus');
    if (status) status.textContent = '一部の機能でエラーが発生しました。再読み込みしても続く場合は開発者ツールを確認してください。';
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', start, { once: true });
} else {
  start();
}
