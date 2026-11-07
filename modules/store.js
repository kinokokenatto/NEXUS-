* {
  box-sizing: border-box;
}

:root {
  --bg: #040915;
  --bg-2: #0b1730;
  --panel: rgba(10, 18, 36, 0.78);
  --panel-strong: rgba(16, 24, 48, 0.96);
  --panel-soft: rgba(18, 33, 58, 0.7);
  --line: rgba(133, 196, 255, 0.28);
  --text: #edf6ff;
  --muted: #a6bfd8;
  --accent: #6ecbff;
  --accent-2: #af8bff;
  --success: #78f2b7;
  --warning: #ffca7a;
  --danger: #ff7a91;
  --shadow: 0 18px 35px rgba(7, 18, 34, 0.45);
  --radius: 18px;
}

html, body {
  margin: 0;
  min-height: 100%;
  font-family: Inter, "Segoe UI", sans-serif;
  background: linear-gradient(135deg, var(--bg), var(--bg-2));
  color: var(--text);
}

body {
  min-height: 100vh;
}

button, input, select {
  font: inherit;
}

button {
  cursor: pointer;
}

.app-shell {
  display: flex;
  min-height: 100vh;
  gap: 18px;
  padding: 18px;
}

.sidebar {
  width: 260px;
  background: rgba(9, 18, 34, 0.88);
  border: 1px solid var(--line);
  border-radius: 22px;
  padding: 16px 14px 14px;
  display: flex;
  flex-direction: column;
  box-shadow: var(--shadow);
  transition: transform 0.2s ease;
}

.brand-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--line);
}

.brand-mark {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, var(--accent), var(--accent-2));
  color: #071520;
  font-weight: 800;
}

.brand-label {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.brand-label strong {
  letter-spacing: 0.12em;
  font-size: 12px;
}

.brand-label small {
  color: var(--muted);
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.icon-button {
  width: 38px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 10px;
  border: 1px solid var(--line);
  background: rgba(123, 154, 196, 0.08);
  color: var(--text);
}

.profile-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 10px;
  margin-top: 16px;
  background: rgba(17, 27, 44, 0.9);
  border: 1px solid var(--line);
  border-radius: 14px;
}

.avatar {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  display: grid;
  place-items: center;
  background: linear-gradient(135deg, #74e0ff, #957dff);
  color: #081621;
  font-weight: 800;
}

.profile-card b,
.profile-card small {
  display: block;
}

.profile-card small {
  color: var(--muted);
}

.live-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--success);
  box-shadow: 0 0 12px rgba(120, 242, 183, 0.9);
  margin-left: auto;
}

.nav-group {
  margin-top: 18px;
  display: grid;
  gap: 8px;
}

.nav-item {
  width: 100%;
  border: 1px solid transparent;
  color: var(--text);
  background: transparent;
  text-align: left;
  padding: 10px 12px;
  border-radius: 12px;
  transition: 0.15s ease;
}

.nav-item:hover,
.nav-item.is-active {
  background: rgba(32, 62, 103, 0.8);
  border-color: rgba(121, 198, 255, 0.5);
}

.sidebar-footer {
  margin-top: auto;
  display: flex;
  flex-direction: column;
  gap: 8px;
  border-top: 1px solid var(--line);
  padding-top: 12px;
  color: var(--muted);
}

.status-pill,
.pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 24px;
  padding: 2px 10px;
  border-radius: 999px;
  font-size: 11px;
  border: 1px solid var(--line);
}

.pill.success {
  color: var(--success);
  border-color: rgba(120, 242, 183, 0.5);
  background: rgba(27, 94, 70, 0.25);
}

.pill.neutral {
  color: var(--text);
}

.main-column {
  flex: 1;
  min-width: 0;
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  background: rgba(8, 17, 30, 0.84);
  border: 1px solid var(--line);
  border-radius: 16px;
  padding: 14px 18px;
  margin-bottom: 18px;
  box-shadow: var(--shadow);
}

.topbar-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.eyebrow {
  display: block;
  color: var(--muted);
  text-transform: uppercase;
  letter-spacing: 0.12em;
  font-size: 10px;
}

.title-block h1 {
  margin: 4px 0 0;
  font-size: clamp(1.1rem, 2vw, 1.8rem);
}

.topbar-actions {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.ghost-button,
.mini-button,
.todo-form button,
.assistant-form button {
  border: 1px solid var(--line);
  background: rgba(124, 151, 193, 0.1);
  color: var(--text);
  border-radius: 10px;
  padding: 8px 12px;
}

.workspace {
  display: grid;
  gap: 18px;
}

.panel {
  background: var(--panel);
  border: 1px solid var(--line);
  border-radius: var(--radius);
  padding: 18px;
  box-shadow: var(--shadow);
}

.panel-feature[hidden] {
  display: none !important;
}

.hero-grid {
  display: grid;
  grid-template-columns: 1.4fr 1fr;
  gap: 18px;
}

.clock-card,
.summary-card {
  border: 1px solid var(--line);
  border-radius: 18px;
  background: rgba(15, 24, 42, 0.82);
  padding: 18px;
}

.time-row {
  display: flex;
  align-items: center;
  gap: 18px;
}

.analog-wrap {
  display: flex;
  justify-content: center;
  align-items: center;
}

.analog-clock {
  position: relative;
  width: 120px;
  height: 120px;
  border-radius: 50%;
  border: 2px solid rgba(142, 201, 255, 0.48);
  background: radial-gradient(circle at center, rgba(28, 64, 103, 0.9), rgba(9, 19, 35, 0.9));
  box-shadow: inset 0 0 18px rgba(64, 162, 255, 0.16);
}

.analog-clock .hand {
  position: absolute;
  left: 50%;
  bottom: 50%;
  width: 3px;
  border-radius: 999px;
  transform-origin: center bottom;
  transform: translate(-50%, -100%) rotate(0deg);
}

.analog-clock .hour {
  height: 28%;
  background: rgba(255, 255, 255, 0.96);
}

.analog-clock .minute {
  height: 38%;
  background: rgba(120, 196, 255, 0.96);
}

.analog-clock .second {
  height: 42%;
  background: rgba(255, 120, 178, 0.96);
}

.analog-clock .center-dot {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 12px;
  height: 12px;
  border-radius: 50%;
  transform: translate(-50%, -50%);
  background: linear-gradient(135deg, var(--accent), var(--accent-2));
}

.digital-wrap {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.clock-date {
  color: var(--muted);
  letter-spacing: 0.12em;
  text-transform: uppercase;
  font-size: 12px;
}

.clock-time {
  margin-top: 8px;
  font-size: clamp(2rem, 4vw, 3.5rem);
  font-weight: 700;
  letter-spacing: 0.05em;
}

.summary-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-bottom: 12px;
  color: var(--muted);
}

.summary-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 12px;
}

.summary-list li {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  padding-bottom: 8px;
  border-bottom: 1px solid rgba(130, 201, 255, 0.14);
}

.summary-list strong {
  color: var(--text);
}

.panel-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
  margin-bottom: 14px;
}

.panel-head h2 {
  margin: 0;
  font-size: 1.1rem;
}

.weather-layout,
.todo-form,
.assistant-form {
  display: flex;
  gap: 10px;
  align-items: center;
}

.field-label {
  display: block;
  color: var(--muted);
  margin-bottom: 8px;
}

select, input {
  width: 100%;
  background: rgba(7, 13, 26, 0.8);
  color: var(--text);
  border: 1px solid var(--line);
  border-radius: 10px;
  padding: 10px 12px;
}

.inline-row {
  display: flex;
  gap: 8px;
}

.weather-summary {
  margin-top: 16px;
  font-size: clamp(1.5rem, 3vw, 2.7rem);
  font-weight: 700;
  letter-spacing: 0.04em;
}

.supporting-text,
.audit-box,
.policy-box {
  color: var(--muted);
  line-height: 1.7;
  font-size: 0.92rem;
}

.todo-form {
  margin-top: 6px;
}

.todo-form input {
  flex: 1;
}

.todo-list {
  list-style: none;
  padding: 0;
  margin: 18px 0 0;
  display: grid;
  gap: 10px;
}

.todo-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  background: rgba(12, 21, 36, 0.8);
  border: 1px solid var(--line);
  border-radius: 12px;
}

.todo-item input[type="checkbox"] {
  width: 16px;
  height: 16px;
}

.todo-item.is-complete .todo-text {
  text-decoration: line-through;
  opacity: 0.6;
}

.todo-text {
  flex: 1;
  word-break: break-word;
}

.todo-delete {
  border: 0;
  background: rgba(255, 122, 145, 0.15);
  color: #ffc5cf;
  border-radius: 8px;
  padding: 4px 8px;
}

.assistant-box {
  display: grid;
  gap: 14px;
}

.assistant-bubble {
  background: rgba(7, 17, 28, 0.9);
  border: 1px solid var(--line);
  border-radius: 14px;
  padding: 14px 16px;
  line-height: 1.7;
  min-height: 86px;
}

.assistant-form {
  display: flex;
  gap: 10px;
  align-items: center;
}

.assistant-form input {
  flex: 1;
}

.quick-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.quick-actions button {
  border: 1px solid var(--line);
  background: rgba(109, 155, 210, 0.08);
  color: var(--text);
  border-radius: 999px;
  padding: 6px 12px;
}

.toggle-row {
  display: flex;
  align-items: flex-start;
  gap: 12px;
  border: 1px solid var(--line);
  background: rgba(8, 15, 24, 0.62);
  border-radius: 12px;
  padding: 12px 14px;
  margin-top: 12px;
}

.toggle-row input {
  width: 18px;
  height: 18px;
  margin-top: 4px;
}

.toggle-row span {
  display: grid;
  gap: 4px;
}

.toggle-row small {
  color: var(--muted);
  line-height: 1.5;
}

.audit-box {
  margin-top: 18px;
  border: 1px solid rgba(120, 242, 183, 0.34);
  background: rgba(21, 52, 43, 0.24);
  border-radius: 12px;
  padding: 12px 14px;
}

.info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
}

.info-card {
  padding: 14px 16px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: rgba(11, 22, 36, 0.76);
  display: grid;
  gap: 8px;
}

.info-card span {
  color: var(--muted);
  font-size: 0.82rem;
}

.info-card strong {
  font-size: 1rem;
}

.modal {
  position: fixed;
  inset: 0;
  background: rgba(3, 8, 16, 0.74);
  display: grid;
  place-items: center;
  padding: 20px;
  z-index: 40;
}

.modal.hidden,
.screen-protect.hidden {
  display: none !important;
}

.modal-card {
  width: min(540px, 92vw);
  background: var(--panel-strong);
  border: 1px solid var(--line);
  border-radius: 20px;
  box-shadow: var(--shadow);
  padding: 18px;
}

.command-card {
  width: min(460px, 92vw);
}

.modal-head {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  margin-bottom: 12px;
}

.modal-head h2 {
  margin: 0;
}

.command-list {
  list-style: none;
  margin: 14px 0 0;
  padding: 0;
  display: grid;
  gap: 8px;
}

.command-list button {
  width: 100%;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: rgba(16, 26, 38, 0.9);
  color: var(--text);
  text-align: left;
  padding: 10px 12px;
}

.command-empty {
  color: var(--muted);
  padding: 10px 12px;
}

.screen-protect {
  position: fixed;
  inset: 0;
  display: grid;
  place-items: center;
  background: radial-gradient(circle at 50% 25%, rgba(29, 66, 101, 0.9), rgba(4, 8, 16, 0.96));
  z-index: 50;
}

.screen-protect-card {
  width: min(420px, 80vw);
  padding: 28px 22px;
  border: 1px solid rgba(130, 198, 255, 0.7);
  border-radius: 20px;
  background: rgba(8, 14, 22, 0.95);
  text-align: center;
}

.screen-protect-icon {
  font-size: 42px;
  margin-bottom: 12px;
}

.screen-protect-card h2 {
  margin: 0 0 12px;
}

.screen-protect-card p {
  margin: 0;
  color: var(--muted);
  line-height: 1.7;
}

@media (max-width: 760px) {
  .app-shell {
    padding: 12px;
    gap: 12px;
  }

  .sidebar {
    position: fixed;
    z-index: 25;
    left: 12px;
    top: 12px;
    bottom: 12px;
    width: min(280px, calc(100vw - 24px));
    transform: translateX(0);
  }

  body.sidebar-collapsed .sidebar {
    transform: translateX(-120%);
  }

  .main-column {
    width: 100%;
  }

  .hero-grid {
    grid-template-columns: 1fr;
  }

  .topbar {
    flex-wrap: wrap;
  }
}

body.sidebar-collapsed .main-column {
  margin-left: 0;
}

body.sidebar-collapsed .sidebar {
  transform: translateX(-120%);
}
