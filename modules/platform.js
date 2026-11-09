import { STORAGE_KEY, getStorageStatus, replaceState } from './store.js';

const featureOptions = [
  { id: 'overview', label: '⌂ 概要' }, { id: 'weather', label: '🌤 天気' }, { id: 'todos', label: '☑ Todo' },
  { id: 'assistant', label: '✦ アシスタント' }, { id: 'privacy', label: '🛡 プライバシー' }, { id: 'system', label: '▣ システム・バックアップ' }
];

function startClock() {
  const time = document.getElementById('clockTime');
  const date = document.getElementById('clockDate');
  const hands = {
    hour: document.querySelector('.analog-clock .hour'), minute: document.querySelector('.analog-clock .minute'), second: document.querySelector('.analog-clock .second')
  };
  function tick() {
    const now = new Date();
    time.textContent = now.toLocaleTimeString('ja-JP', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: false });
    date.textContent = now.toLocaleDateString('ja-JP', { year: 'numeric', month: 'long', day: 'numeric', weekday: 'long' });
    hands.hour.style.transform = `translate(-50%, -100%) rotate(${(now.getHours() % 12) * 30 + now.getMinutes() * 0.5}deg)`;
    hands.minute.style.transform = `translate(-50%, -100%) rotate(${now.getMinutes() * 6 + now.getSeconds() * 0.1}deg)`;
    hands.second.style.transform = `translate(-50%, -100%) rotate(${now.getSeconds() * 6}deg)`;
  }
  tick(); setInterval(tick, 1000);
}

function initCommandPalette() {
  const modal = document.getElementById('commandPanel');
  const input = document.getElementById('commandInput');
  const list = document.getElementById('commandList');
  function close() { modal.classList.add('hidden'); }
  function render() {
    const query = input.value.trim().toLocaleLowerCase('ja');
    const matches = featureOptions.filter(option => option.label.toLocaleLowerCase('ja').includes(query));
    list.replaceChildren();
    if (!matches.length) { const empty = document.createElement('li'); empty.className = 'command-empty'; empty.textContent = '一致する機能がありません。'; list.append(empty); return; }
    for (const option of matches) {
      const li = document.createElement('li'); const button = document.createElement('button');
      button.type = 'button'; button.textContent = option.label;
      button.addEventListener('click', () => { window.dispatchEvent(new CustomEvent('nexus:navigate', { detail: option.id })); close(); });
      li.append(button); list.append(li);
    }
  }
  function open() { modal.classList.remove('hidden'); input.value = ''; render(); input.focus(); }
  document.getElementById('commandButton').addEventListener('click', open);
  input.addEventListener('input', render);
  document.querySelectorAll('[data-close="commandPanel"]').forEach(button => button.addEventListener('click', close));
  modal.addEventListener('click', event => { if (event.target === modal) close(); });
  document.addEventListener('keydown', event => {
    const typing = /INPUT|TEXTAREA|SELECT/.test(document.activeElement?.tagName || '');
    if ((event.key === '/' && !typing) || ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === 'k')) { event.preventDefault(); open(); }
    if (event.key === 'Escape' && !modal.classList.contains('hidden')) close();
  });
}

function initPrivacyDialog() {
  const modal = document.getElementById('privacyPanel');
  document.getElementById('privacyButton').addEventListener('click', () => modal.classList.remove('hidden'));
  document.querySelectorAll('[data-close="privacyPanel"]').forEach(button => button.addEventListener('click', () => modal.classList.add('hidden')));
  modal.addEventListener('click', event => { if (event.target === modal) modal.classList.add('hidden'); });
}

function initBackup(state, resetState) {
  const status = document.getElementById('systemStatus');
  const fileInput = document.getElementById('importBackupFile');
  document.getElementById('exportBackup').addEventListener('click', () => {
    const data = JSON.stringify({ app: 'NEXUS App Platform', exportedAt: new Date().toISOString(), state }, null, 2);
    const url = URL.createObjectURL(new Blob([data], { type: 'application/json' }));
    const link = document.createElement('a'); link.href = url; link.download = `nexus-backup-${new Date().toISOString().slice(0, 10)}.json`;
    link.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
    status.textContent = 'バックアップを書き出しました。ファイルにはローカルデータが含まれます。';
  });
  document.getElementById('importBackupButton').addEventListener('click', () => fileInput.click());
  fileInput.addEventListener('change', async () => {
    const file = fileInput.files?.[0]; fileInput.value = '';
    if (!file) return;
    if (file.size > 2_000_000) { status.textContent = 'ファイルが大きすぎます（上限2MB）。'; return; }
    try {
      const payload = JSON.parse(await file.text());
      const candidate = payload?.state;
      if (!candidate || typeof candidate !== 'object' || !Array.isArray(candidate.todos)) throw new Error('Invalid backup format');
      if (!confirm('現在のTodo・設定をバックアップ内容で置き換えます。続行しますか？')) return;
      replaceState(candidate);
      status.textContent = 'バックアップを復元しました。画面を再読み込みします。';
      setTimeout(() => location.reload(), 250);
    } catch { status.textContent = 'バックアップを読み込めません。形式を確認してください。'; }
  });
  document.getElementById('resetData').addEventListener('click', () => {
    if (!confirm('このブラウザーに保存されたNEXUSの設定とTodoを初期化します。この操作は取り消せません。')) return;
    resetState(); status.textContent = '保存データを初期化しました。再読み込みします。'; setTimeout(() => location.reload(), 250);
  });
  const storage = getStorageStatus();
  const storageStatus = document.getElementById('storageStatus');
  storageStatus.textContent = storage.available ? `${(storage.bytes / 1024).toFixed(1)} KB` : '利用不可';
  window.addEventListener('nexus:state-change', () => {
    const current = getStorageStatus(); storageStatus.textContent = current.available ? `${(current.bytes / 1024).toFixed(1)} KB` : '利用不可';
  });
}

export function initPlatform(state, { resetState }) {
  initCommandPalette(); initPrivacyDialog(); initBackup(state, resetState); startClock();
}
