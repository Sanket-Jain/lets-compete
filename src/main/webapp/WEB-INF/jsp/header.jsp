<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Carrom Championship</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link href="https://fonts.googleapis.com/css2?family=Bebas+Neue&family=DM+Sans:wght@300;400;500;600&display=swap" rel="stylesheet"/>
  <style>
    :root {
      --ink:     #0d0d0d;
      --ivory:   #f5f0e8;
      --gold:    #c9a84c;
      --gold2:   #e8c96a;
      --rust:    #b94a2c;
      --slate:   #2a2d35;
      --muted:   #6b6b6b;
      --border:  #d9d2c5;
      --success: #2e7d32;
      --danger:  #c62828;
      --info:    #1565c0;
      --radius:  6px;
      --shadow:  0 2px 12px rgba(0,0,0,.10);
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    body {
      font-family: 'DM Sans', sans-serif;
      background: var(--ivory);
      color: var(--ink);
      min-height: 100vh;
    }

    /* ── NAV ─────────────────────────────── */
    nav {
      background: var(--slate);
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0 2.5rem;
      height: 62px;
      position: sticky;
      top: 0;
      z-index: 100;
      box-shadow: 0 2px 16px rgba(0,0,0,.3);
    }
    .nav-brand {
      font-family: 'Bebas Neue', sans-serif;
      font-size: 1.7rem;
      color: var(--gold);
      letter-spacing: .08em;
      text-decoration: none;
    }
    .nav-brand span { color: #fff; }
    .nav-links { display: flex; gap: .3rem; }
    .nav-links a {
      color: #ccc;
      text-decoration: none;
      font-size: .85rem;
      font-weight: 500;
      padding: .45rem .9rem;
      border-radius: var(--radius);
      transition: background .15s, color .15s;
      letter-spacing: .02em;
    }
    .nav-links a:hover,
    .nav-links a.active { background: var(--gold); color: var(--ink); }

    /* ── MAIN WRAPPER ────────────────────── */
    .page { max-width: 1100px; margin: 0 auto; padding: 2.5rem 1.5rem 4rem; }

    /* ── CARDS ───────────────────────────── */
    .card {
      background: #fff;
      border: 1px solid var(--border);
      border-radius: var(--radius);
      box-shadow: var(--shadow);
      padding: 1.8rem;
      margin-bottom: 1.6rem;
    }
    .card-title {
      font-family: 'Bebas Neue', sans-serif;
      font-size: 1.35rem;
      letter-spacing: .06em;
      color: var(--slate);
      margin-bottom: 1.2rem;
      padding-bottom: .6rem;
      border-bottom: 2px solid var(--gold);
    }

    /* ── FORM ELEMENTS ───────────────────── */
    .form-row { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1rem; }
    .form-group { display: flex; flex-direction: column; gap: .4rem; flex: 1; min-width: 180px; }
    label { font-size: .8rem; font-weight: 600; color: var(--muted); text-transform: uppercase; letter-spacing: .05em; }
    input, select, textarea {
      border: 1.5px solid var(--border);
      border-radius: var(--radius);
      padding: .6rem .85rem;
      font-family: inherit;
      font-size: .92rem;
      background: #faf9f6;
      color: var(--ink);
      transition: border-color .15s;
      width: 100%;
    }
    input:focus, select:focus, textarea:focus {
      outline: none; border-color: var(--gold);
    }
    textarea { resize: vertical; min-height: 70px; }

    /* ── BUTTONS ─────────────────────────── */
    .btn {
      display: inline-flex; align-items: center; gap: .4rem;
      padding: .6rem 1.4rem;
      border: none; border-radius: var(--radius);
      font-family: inherit; font-size: .88rem; font-weight: 600;
      cursor: pointer; transition: all .15s; text-decoration: none;
      letter-spacing: .02em;
    }
    .btn-primary   { background: var(--gold); color: var(--ink); }
    .btn-primary:hover { background: var(--gold2); }
    .btn-danger    { background: var(--rust); color: #fff; }
    .btn-danger:hover { filter: brightness(1.1); }
    .btn-secondary { background: var(--slate); color: #fff; }
    .btn-secondary:hover { background: #3a3f4b; }
    .btn-success   { background: var(--success); color: #fff; }
    .btn-success:hover { filter: brightness(1.1); }
    .btn-sm { padding: .35rem .85rem; font-size: .8rem; }
    .btn:disabled { opacity: .45; cursor: not-allowed; }

    /* ── TABLE ───────────────────────────── */
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; font-size: .88rem; }
    th {
      background: var(--slate); color: var(--gold);
      font-family: 'Bebas Neue', sans-serif;
      letter-spacing: .08em; font-size: .95rem;
      padding: .7rem 1rem; text-align: left;
    }
    td { padding: .65rem 1rem; border-bottom: 1px solid var(--border); vertical-align: middle; }
    tr:last-child td { border-bottom: none; }
    tr:hover td { background: #faf7f0; }

    /* ── BADGES ──────────────────────────── */
    .badge {
      display: inline-block;
      padding: .18rem .7rem; border-radius: 99px;
      font-size: .72rem; font-weight: 700; letter-spacing: .04em; text-transform: uppercase;
    }
    .badge-pro          { background: #fff3cd; color: #856404; }
    .badge-intermediate { background: #d1ecf1; color: #0c5460; }
    .badge-beginner     { background: #d4edda; color: #155724; }
    .badge-scheduled    { background: #e2e3e5; color: #383d41; }
    .badge-completed    { background: #d4edda; color: #155724; }
    .badge-singles      { background: #cce5ff; color: #004085; }
    .badge-doubles      { background: #e2d9f3; color: #4a235a; }

    /* ── ALERT / TOAST ───────────────────── */
    #toast {
      position: fixed; bottom: 2rem; right: 2rem;
      padding: .85rem 1.5rem;
      border-radius: var(--radius);
      font-weight: 600; font-size: .9rem;
      color: #fff; z-index: 9999;
      transform: translateY(120%); opacity: 0;
      transition: all .3s ease;
      max-width: 340px;
    }
    #toast.show { transform: translateY(0); opacity: 1; }
    #toast.success { background: var(--success); }
    #toast.error   { background: var(--danger); }
    #toast.info    { background: var(--info); }

    /* ── MODAL ───────────────────────────── */
    .modal-overlay {
      display: none; position: fixed; inset: 0;
      background: rgba(0,0,0,.55); z-index: 500;
      align-items: center; justify-content: center;
    }
    .modal-overlay.open { display: flex; }
    .modal {
      background: #fff; border-radius: var(--radius);
      padding: 2rem; width: 100%; max-width: 520px;
      box-shadow: 0 8px 40px rgba(0,0,0,.25);
      max-height: 90vh; overflow-y: auto;
      animation: slideUp .2s ease;
    }
    @keyframes slideUp {
      from { transform: translateY(30px); opacity: 0; }
      to   { transform: translateY(0);    opacity: 1; }
    }
    .modal-header {
      display: flex; justify-content: space-between; align-items: center;
      margin-bottom: 1.4rem;
    }
    .modal-title {
      font-family: 'Bebas Neue', sans-serif;
      font-size: 1.4rem; letter-spacing: .06em; color: var(--slate);
    }
    .modal-close {
      background: none; border: none; font-size: 1.4rem;
      cursor: pointer; color: var(--muted); line-height: 1;
    }
    .modal-close:hover { color: var(--rust); }

    /* ── SECTION HEADER ──────────────────── */
    .section-header {
      display: flex; align-items: center; justify-content: space-between;
      margin-bottom: 1.4rem; flex-wrap: wrap; gap: .8rem;
    }
    .section-title {
      font-family: 'Bebas Neue', sans-serif;
      font-size: 2rem; letter-spacing: .06em; color: var(--slate);
    }

    /* ── EMPTY STATE ─────────────────────── */
    .empty {
      text-align: center; padding: 3rem 1rem; color: var(--muted);
    }
    .empty-icon { font-size: 3rem; margin-bottom: .8rem; }
    .empty p { font-size: .95rem; }

    /* ── UTILITY ─────────────────────────── */
    .flex { display: flex; }
    .gap-1 { gap: .5rem; }
    .gap-2 { gap: 1rem; }
    .mt-1 { margin-top: .5rem; }
    .mt-2 { margin-top: 1rem; }
    .text-muted { color: var(--muted); font-size: .85rem; }
    .text-right { text-align: right; }
    .divider { border: none; border-top: 1px solid var(--border); margin: 1.2rem 0; }
  </style>
</head>
<body>

<nav>
  <a href="/" class="nav-brand">CARROM <span>CHAMPIONSHIP</span></a>
  <div class="nav-links">
    <a href="/"            id="nav-home">Home</a>
    <a href="/players"     id="nav-players">Players</a>
    <a href="/tournaments" id="nav-tournaments">Tournaments</a>
    <a href="/fixtures"    id="nav-fixtures">Fixtures</a>
    <a href="/results"     id="nav-results">Results</a>
  </div>
</nav>

<div id="toast"></div>

<script>
  // Highlight active nav link
  (function(){
    const path = window.location.pathname;
    const map = { '/': 'nav-home', '/players': 'nav-players', '/tournaments': 'nav-tournaments', '/fixtures': 'nav-fixtures', '/results': 'nav-results' };
    const id = map[path];
    if (id) document.getElementById(id)?.classList.add('active');
  })();

  // Toast helper
  function showToast(msg, type='info') {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = 'show ' + type;
    setTimeout(() => t.className = '', 3000);
  }

  // Fetch wrapper
  async function api(method, url, body) {
    const opts = { method, headers: { 'Content-Type': 'application/json' } };
    if (body) opts.body = JSON.stringify(body);
    const res = await fetch(url, opts);
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.message || 'Request failed');
    return data;
  }

  function openModal(id)  { document.getElementById(id).classList.add('open'); }
  function closeModal(id) { document.getElementById(id).classList.remove('open'); }
</script>
