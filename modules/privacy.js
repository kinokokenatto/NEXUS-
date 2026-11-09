import { saveState } from './store.js';

const ALLOWED_ORIGINS = new Set(['https://api.open-meteo.com']);

export async function requestAllowedJson(input, { timeoutMs = 8000 } = {}) {
  const url = new URL(input);
  if (!ALLOWED_ORIGINS.has(url.origin) || url.protocol !== 'https:') throw new Error('Network destination is not allowed.');
  const state = window.nexusState;
  if (!state?.privacy?.autoNetwork || state.privacy.anonMode) throw new Error('External requests are disabled by privacy settings.');
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url.href, { method: 'GET', mode: 'cors', credentials: 'omit', cache: 'no-store', redirect: 'error', referrerPolicy: 'no-referrer', headers: { Accept: 'application/json' }, signal: controller.signal });
    if (!response.ok) throw new Error(`Request failed (${response.status}).`);
    return await response.json();
  } finally {
    clearTimeout(timer);
  }
}

export function initPrivacy(state) {
  window.nexusState = state;
  const autoNetwork = document.getElementById('autoNetworkToggle');
  const screenProtect = document.getElementById('screenProtectToggle');
  const anonMode = document.getElementById('anonModeToggle');
  const overlay = document.getElementById('screenProtectOverlay');
  const audit = document.getElementById('privacyAudit');
  const status = document.getElementById('privacyStatusText');
  let wasAway = false;

  function render() {
    autoNetwork.checked = state.privacy.autoNetwork;
    screenProtect.checked = state.privacy.screenProtect;
    anonMode.checked = state.privacy.anonMode;
    if (status) status.textContent = state.privacy.anonMode ? '外部通信ブロック' : state.privacy.autoNetwork ? '天気通信を許可' : 'ローカル優先';
    if (audit) audit.textContent = `天気通信: ${state.privacy.autoNetwork && !state.privacy.anonMode ? '許可（更新操作時のみ）' : '停止'} · 画面保護: ${state.privacy.screenProtect ? '有効' : '無効'} · 外部通信ブロック: ${state.privacy.anonMode ? '有効' : '無効'}。VPNや端末全体の保護機能ではありません。`;
    window.dispatchEvent(new CustomEvent('nexus:privacy-change'));
  }
  function sync() {
    state.privacy.autoNetwork = autoNetwork.checked;
    state.privacy.screenProtect = screenProtect.checked;
    state.privacy.anonMode = anonMode.checked;
    saveState(state);
    render();
  }
  [autoNetwork, screenProtect, anonMode].forEach(input => input.addEventListener('change', sync));
  function protect() {
    if (state.privacy.screenProtect && wasAway) overlay.classList.remove('hidden');
    wasAway = false;
  }
  document.addEventListener('visibilitychange', () => { if (document.hidden && state.privacy.screenProtect) { wasAway = true; overlay.classList.remove('hidden'); } else if (!document.hidden) protect(); });
  window.addEventListener('blur', () => { if (state.privacy.screenProtect) { wasAway = true; overlay.classList.remove('hidden'); } });
  window.addEventListener('focus', protect);
  render();
}
