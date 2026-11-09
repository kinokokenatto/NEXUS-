import { saveState } from './store.js';

const destinations = new Set(['overview', 'weather', 'todos', 'privacy', 'system']);

export function initAssistant(state) {
  const form = document.getElementById('assistantForm');
  const input = document.getElementById('assistantInput');
  const reply = document.getElementById('assistantReply');
  function navigate(feature) {
    if (!destinations.has(feature) && feature !== 'assistant') return false;
    state.app.currentFeature = feature;
    saveState(state);
    window.dispatchEvent(new CustomEvent('nexus:navigate', { detail: feature }));
    return true;
  }
  function run(raw) {
    const text = String(raw || '').trim();
    const lower = text.toLowerCase();
    if (!text) return;
    if (lower.startsWith('todo:') || lower.startsWith('todo ') || text.startsWith('Todo:') || text.startsWith('Todo ')) {
      const task = text.replace(/^todo\s*[:：]?\s*/i, '').trim();
      if (!task) { reply.textContent = '「Todo: タスク名」の形式で入力してください。'; return; }
      window.dispatchEvent(new CustomEvent('nexus:add-todo', { detail: task }));
      reply.textContent = `Todoに追加しました: ${task}`;
      input.value = '';
      return;
    }
    const routes = [
      [['weather', '天気'], 'weather'], [['todo', 'タスク', '予定'], 'todos'],
      [['privacy', 'プライバシー', 'セキュリティ'], 'privacy'], [['system', 'バックアップ', '設定'], 'system'],
      [['home', '概要', 'ホーム'], 'overview']
    ];
    for (const [terms, destination] of routes) {
      if (terms.some(term => lower.includes(term.toLowerCase()))) {
        navigate(destination);
        reply.textContent = `${destination === 'todos' ? 'Todo' : destination}を開きました。入力内容は外部へ送信していません。`;
        return;
      }
    }
    reply.textContent = 'ローカル操作を案内できます。「Todo: タスク名」と入力するか、「天気」「プライバシー」「バックアップ」などの機能名を入力してください。一般的な質問への回答や最新情報の取得は行いません。';
  }
  form.addEventListener('submit', event => { event.preventDefault(); run(input.value); });
  document.querySelectorAll('[data-quick]').forEach(button => button.addEventListener('click', () => {
    const feature = button.dataset.quick;
    if (feature === 'privacy') document.getElementById('privacyButton').click();
    else navigate(feature);
  }));
  window.addEventListener('nexus:add-todo', event => {
    const text = String(event.detail || '').trim().slice(0, 120);
    if (!text || state.todos.length >= 1000) { reply.textContent = 'Todoを追加できません。入力内容または上限を確認してください。'; return; }
    state.todos.unshift({ id: globalThis.crypto?.randomUUID?.() || `todo-${Date.now()}`, text, done: false, createdAt: Date.now() });
    saveState(state);
  });
}
