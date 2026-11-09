import { saveState } from './store.js';

const featureLabels = {
  overview: '概要', weather: '天気', todos: 'Todo', assistant: 'アシスタント', privacy: 'プライバシー', system: 'システム・バックアップ'
};

export function initRouter(state) {
  const navButtons = [...document.querySelectorAll('.nav-item[data-target]')];
  const panels = [...document.querySelectorAll('.panel-feature[data-feature]')];
  const title = document.getElementById('pageTitle');
  const sidebar = document.getElementById('sidebar');
  const scrim = document.getElementById('sidebarScrim');
  const mobile = () => matchMedia('(max-width: 760px)').matches;

  function setSidebar(open) {
    state.ui.sidebarOpen = Boolean(open);
    document.body.classList.toggle('sidebar-collapsed', !open);
    if (scrim) scrim.hidden = !open || !mobile();
    sidebar?.setAttribute('aria-expanded', String(Boolean(open)));
    saveState(state);
  }

  function navigate(feature, options = {}) {
    if (!Object.hasOwn(featureLabels, feature)) feature = 'overview';
    state.app.currentFeature = feature;
    panels.forEach(panel => { panel.hidden = panel.dataset.feature !== feature; });
    navButtons.forEach(button => {
      const active = button.dataset.target === feature;
      button.classList.toggle('is-active', active);
      if (active) button.setAttribute('aria-current', 'page');
      else button.removeAttribute('aria-current');
    });
    if (title) title.textContent = featureLabels[feature];
    if (options.updateHash !== false && location.hash !== `#${feature}`) history.replaceState(null, '', `#${feature}`);
    if (options.persist !== false) saveState(state);
    if (mobile()) setSidebar(false);
  }

  navButtons.forEach(button => button.addEventListener('click', () => navigate(button.dataset.target)));
  document.querySelectorAll('[data-navigate]').forEach(button => button.addEventListener('click', () => navigate(button.dataset.navigate)));
  document.getElementById('sidebarOpen')?.addEventListener('click', () => setSidebar(true));
  document.getElementById('sidebarToggle')?.addEventListener('click', () => setSidebar(false));
  scrim?.addEventListener('click', () => setSidebar(false));
  window.addEventListener('nexus:navigate', event => navigate(event.detail));
  window.addEventListener('hashchange', () => navigate(location.hash.slice(1), { updateHash: false }));
  window.addEventListener('resize', () => { if (!mobile() && state.ui.sidebarOpen) setSidebar(true); });

  const requested = location.hash.slice(1);
  navigate(Object.hasOwn(featureLabels, requested) ? requested : state.app.currentFeature, { persist: false });
  setSidebar(state.ui.sidebarOpen);
}
