import { saveState } from './store.js';
import { requestAllowedJson } from './privacy.js';

const cities = {
  tokyo: { label: '東京', lat: 35.6762, lon: 139.6503 }, osaka: { label: '大阪', lat: 34.6937, lon: 135.5023 },
  kyoto: { label: '京都', lat: 35.0214, lon: 135.7556 }, sapporo: { label: '札幌', lat: 43.0618, lon: 141.3545 },
  fukuoka: { label: '福岡', lat: 33.5904, lon: 130.4017 }
};
const conditions = { 0: '快晴', 1: 'おおむね晴れ', 2: '晴れ時々くもり', 3: 'くもり', 45: '霧', 48: '霧', 51: '弱い霧雨', 61: '雨', 71: '雪', 80: 'にわか雨', 95: '雷雨' };
const sample = { tokyo: '東京', osaka: '大阪', kyoto: '京都', sapporo: '札幌', fukuoka: '福岡' };

export function initWeather(state) {
  const select = document.getElementById('weatherCity');
  const summary = document.getElementById('weatherSummary');
  const note = document.getElementById('weatherNote');
  const refresh = document.getElementById('weatherRefresh');
  if (!select || !summary || !note) return;
  select.value = cities[state.weather.city] ? state.weather.city : 'tokyo';
  let requestId = 0;

  function showCachedOrPrompt() {
    const city = cities[state.weather.city] || cities.tokyo;
    const cache = state.weather.cache;
    if (cache?.city === state.weather.city && Date.now() - cache.timestamp < 30 * 60 * 1000) {
      summary.textContent = `${cache.temperature}°C · ${cache.condition}`;
      note.textContent = `${city.label} · ${new Date(cache.timestamp).toLocaleTimeString('ja-JP')} 更新（キャッシュ）`;
    } else {
      summary.textContent = '取得待ち';
      note.textContent = state.privacy.autoNetwork && !state.privacy.anonMode
        ? '「更新」を押すと、許可された天気サービスへ問い合わせます。'
        : '外部通信は停止中です。サンプル天気は表示せず、更新にはプライバシー設定で許可が必要です。';
    }
  }

  async function update() {
    const cityKey = select.value;
    state.weather.city = cities[cityKey] ? cityKey : 'tokyo';
    saveState(state);
    const currentRequest = ++requestId;
    if (!state.privacy.autoNetwork || state.privacy.anonMode) {
      showCachedOrPrompt();
      if (state.privacy.anonMode) note.textContent = 'NEXUS外部通信ブロック中です。通信を許可するにはプライバシー設定を変更してください。';
      return;
    }
    const city = cities[state.weather.city];
    summary.textContent = '取得中…';
    note.textContent = `${city.label}の天気を取得しています。`;
    const url = new URL('https://api.open-meteo.com/v1/forecast');
    url.search = new URLSearchParams({ latitude: String(city.lat), longitude: String(city.lon), current: 'temperature_2m,weather_code', timezone: 'Asia/Tokyo' });
    try {
      const data = await requestAllowedJson(url.href, { timeoutMs: 8000 });
      if (currentRequest !== requestId) return;
      const temperature = Number(data.current?.temperature_2m);
      if (!Number.isFinite(temperature)) throw new Error('Invalid weather response');
      const condition = conditions[Number(data.current.weather_code)] || '天気情報';
      state.weather.cache = { city: cityKey, temperature, condition, timestamp: Date.now() };
      saveState(state);
      summary.textContent = `${temperature}°C · ${condition}`;
      note.textContent = `${city.label} · Open-Meteoから取得。情報は参考値です。`;
    } catch (error) {
      if (currentRequest !== requestId) return;
      summary.textContent = '取得できません';
      note.textContent = '通信がブロックされたか、天気サービスに接続できませんでした。設定と接続を確認してください。';
    }
  }
  select.addEventListener('change', showCachedOrPrompt);
  refresh.addEventListener('click', update);
  window.addEventListener('nexus:privacy-change', showCachedOrPrompt);
  showCachedOrPrompt();
}
