import { saveState } from './store.js';

export function initPrivacy(state) {
  const autoNetworkToggle = document.getElementById('autoNetworkToggle');
  const screenProtectToggle = document.getElementById('screenProtectToggle');
  const anonModeToggle = document.getElementById('anonModeToggle');
  const screenProtectOverlay = document.getElementById('screenProtectOverlay');
  const privacyAudit = document.getElementById('privacyAudit');
  const privacyStatusText = document.getElementById('privacyStatusText');

  function applyPrivacyState() {
    const enabled = state.privacy;

    if (autoNetworkToggle) autoNetworkToggle.checked = enabled.autoNetwork;
    if (screenProtectToggle) screenProtectToggle.checked = enabled.screenProtect;
    if (anonModeToggle) anonModeToggle.checked = enabled.anonMode;

    document.body.classList.toggle('anon-mode', enabled.anonMode);
    document.body.classList.toggle('screen-protect', enabled.screenProtect);

    if (screenProtectOverlay) {
      screenProtectOverlay.classList.toggle('hidden', !enabled.screenProtect);
    }

    if (privacyAudit) {
      const checks = [
        'Local-only storage active',
        enabled.autoNetwork ? 'Explicit network permission' : 'Network fetches gated',
        enabled.anonMode ? 'Anonymous mode active' : 'Normal communication mode'
      ];
      privacyAudit.textContent = checks.join(' · ');
    }

    if (privacyStatusText) {
      privacyStatusText.textContent = enabled.anonMode ? 'secured' : enabled.autoNetwork ? 'opt-in' : 'default';
    }
  }

  function syncState() {
    state.privacy = {
      autoNetwork: Boolean(autoNetworkToggle?.checked),
      screenProtect: Boolean(screenProtectToggle?.checked),
      anonMode: Boolean(anonModeToggle?.checked)
    };
    saveState(state);
    applyPrivacyState();
  }

  autoNetworkToggle?.addEventListener('change', syncState);
  screenProtectToggle?.addEventListener('change', syncState);
  anonModeToggle?.addEventListener('change', syncState);

  document.addEventListener('visibilitychange', () => {
    if (document.hidden && state.privacy.screenProtect && screenProtectOverlay) {
      screenProtectOverlay.classList.remove('hidden');
    }
  });

  window.addEventListener('blur', () => {
    if (state.privacy.screenProtect && screenProtectOverlay) {
      screenProtectOverlay.classList.remove('hidden');
    }
  });

  screenProtectOverlay?.addEventListener('click', () => {
    state.privacy.screenProtect = false;
    if (screenProtectToggle) screenProtectToggle.checked = false;
    saveState(state);
    applyPrivacyState();
  });

  applyPrivacyState();
}
