import { saveState } from './store.js';

const cityCenters = {
  tokyo: { lat: 35.6762, lon: 139.6503 },
  osaka: { lat: 34.6937, lon: 135.5023 },
  kyoto: { lat: 35.0214, lon: 135.7556 },
  sapporo: { lat: 43.0618, lon: 141.3545 },
  fukuoka: { lat: 33.5904, lon: 130.4017 }
};

const weatherIcons = {
  0: '☀️ Clear',
  1: '🌤 Mostly clear',
  2: '⛅ Partly cloudy',
  3: '☁️ Cloudy',
  45: '🌫 Fog',
  48: '🌫 Fog',
  51: '🌦 Light drizzle',
  61: '🌧 Rain',
  71: '🌨 Snow',
  80: '🌧 Rain showers',
  95: '⛈ Thunderstorm'
};

function localWeather(city) {
  const map = {
    tokyo: { temp: 23, condition: '☀️ Clear sky', note: 'Warm and stable. Local-only mode is active.' },
    osaka: { temp: 25, condition: '🌤 Clear to fair', note: 'Comfortable afternoon conditions.' },
    kyoto: { temp: 22, condition: '⛅ Calm weather', note: 'A relaxed, mild city rhythm.' },
    sapporo: { temp: 17, condition: '🌦 Mild shower', note: 'Cooler than the main island cities.' },
    fukuoka: { temp: 27, condition: '☀️ Sunny', note: 'Warm and bright daylight.' }
  };

  return map[city] || map.tokyo;
}

async function fetchWeather(city, summaryNode, noteNode) {
  const coords = cityCenters[city] || cityCenters.tokyo;
  const url = `https://api.open-meteo.com/v1/forecast?latitude=${coords.lat}&longitude=${coords.lon}&current=temperature_2m,weather_code&timezone=auto`;

  try {
    const response = await fetch(url, { headers: { Accept: 'application/json' } });
    if (!response.ok) throw new Error('Weather service rejected the request');
    const data = await response.json();
    const temp = data.current?.temperature_2m ?? '--';
    const code = Number(data.current?.weather_code ?? 0);
    const condition = weatherIcons[code] || '🌤 Condition';

    summaryNode.textContent = `${temp}°C · ${condition}`;
    noteNode.textContent = `${city.toUpperCase()} · retrieved via explicit external access.`;
  } catch (error) {
    const fallback = localWeather(city);
    summaryNode.textContent = `${fallback.temp}°C · ${fallback.condition}`;
    noteNode.textContent = `${fallback.note} · fetch blocked or unavailable.`;
  }
}

export function initWeather(state) {
  const select = document.getElementById('weatherCity');
  const summary = document.getElementById('weatherSummary');
  const note = document.getElementById('weatherNote');
  const refreshButton = document.getElementById('weatherRefresh');

  if (!select || !summary || !note) return;

  const updateWeather = async () => {
    const city = select.value || state.weather.city || 'tokyo';
    state.weather.city = city;
    saveState(state);

    if (state.privacy.autoNetwork) {
      await fetchWeather(city, summary, note);
      return;
    }

    const fallback = localWeather(city);
    summary.textContent = `${fallback.temp}°C · ${fallback.condition}`;
    note.textContent = `${fallback.note} · external weather fetch disabled by policy.`;
  };

  select.value = state.weather.city || 'tokyo';
  select.addEventListener('change', updateWeather);
  refreshButton?.addEventListener('click', updateWeather);
  updateWeather();
}
