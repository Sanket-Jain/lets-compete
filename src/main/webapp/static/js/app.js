// ── API helpers ──────────────────────────────────────────────────────────────
const API = {
  async get(url) {
    const r = await fetch(url);
    if (!r.ok) throw new Error((await r.json()).message || r.statusText);
    return r.json();
  },
  async post(url, body) {
    const r = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    if (!r.ok) throw new Error((await r.json()).message || r.statusText);
    return r.json();
  },
  async put(url, body) {
    const r = await fetch(url, { method: 'PUT', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
    if (!r.ok) throw new Error((await r.json()).message || r.statusText);
    return r.json();
  },
  async del(url) {
    const r = await fetch(url, { method: 'DELETE' });
    if (!r.ok) throw new Error((await r.json()).message || r.statusText);
    return r.status === 204 ? null : r.json();
  }
};

// ── Toast ─────────────────────────────────────────────────────────────────────
function showToast(msg, type = 'info') {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.className = 'show ' + type;
  clearTimeout(t._timer);
  t._timer = setTimeout(() => t.className = '', 3500);
}

// ── Modal helpers ─────────────────────────────────────────────────────────────
function openModal(id) { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal-overlay')) e.target.classList.remove('open');
  if (e.target.classList.contains('confirm-overlay')) e.target.classList.remove('open');
});

// ── Confirm dialog ────────────────────────────────────────────────────────────
function confirmAction(title, message, onConfirm) {
  const overlay = document.getElementById('confirmOverlay');
  document.getElementById('confirmTitle').textContent = title;
  document.getElementById('confirmMsg').textContent = message;
  overlay.classList.add('open');
  document.getElementById('confirmOk').onclick = () => {
    overlay.classList.remove('open');
    onConfirm();
  };
  document.getElementById('confirmCancel').onclick = () => overlay.classList.remove('open');
}

// ── Skill badge ───────────────────────────────────────────────────────────────
function skillBadge(s) {
  const map = { PRO: 'badge-pro', INTERMEDIATE: 'badge-int', BEGINNER: 'badge-beg' };
  return `<span class="badge ${map[s] || ''}">${s}</span>`;
}
function typeBadge(t) {
  return `<span class="badge ${t === 'SINGLES' ? 'badge-singles' : 'badge-doubles'}">${t}</span>`;
}
function statusBadge(s) {
  return `<span class="badge ${s === 'COMPLETED' ? 'badge-done' : 'badge-pending'}">${s}</span>`;
}

// ── Active nav ────────────────────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const path = location.pathname;
  document.querySelectorAll('.nav-link').forEach(a => {
    if (a.getAttribute('href') === path) a.classList.add('active');
  });
});
