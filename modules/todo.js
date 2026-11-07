import { saveState } from './store.js';

export function initRouter(state) {
  const navButtons = [...document.querySelectorAll('.nav-item')];
  const featurePanels = [...document.querySelectorAll('.panel-feature')];
  const sidebar = document.getElementById('sidebar');

  const activateFeature = (featureId) => {
    state.app.currentFeature = featureId;
    saveState(state);

    navButtons.forEach(button => {
      button.classList.toggle('is-active', button.dataset.target === featureId);
    });

    featurePanels.forEach(panel => {
      const shouldShow = panel.dataset.feature === featureId;
      panel.hidden = !shouldShow;
    });
  };

  navButtons.forEach(button => {
    button.addEventListener('click', () => activateFeature(button.dataset.target));
  });

  document.getElementById('sidebarToggle').addEventListener('click', () => {
    document.body.classList.add('sidebar-collapsed');
  });

  document.getElementById('sidebarOpen').addEventListener('click', () => {
    document.body.classList.remove('sidebar-collapsed');
  });

  window.addEventListener('nexus:navigate', (event) => {
    activateFeature(event.detail || 'overview');
  });

  activateFeature(state.app.currentFeature || 'overview');

  if (sidebar) {
    sidebar.setAttribute('aria-expanded', String(!document.body.classList.contains('sidebar-collapsed')));
  }
}
