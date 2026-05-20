<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  /* Hero */
  .hero {
    position: relative;
    background: var(--slate);
    color: #fff;
    overflow: hidden;
    padding: 5rem 2.5rem 4rem;
    text-align: center;
  }
  .hero::before {
    content: '';
    position: absolute; inset: 0;
    background:
      radial-gradient(ellipse 70% 60% at 20% 50%, rgba(201,168,76,.18) 0%, transparent 70%),
      radial-gradient(ellipse 60% 80% at 80% 30%, rgba(185,74,44,.14) 0%, transparent 70%);
  }
  /* Decorative board rings */
  .hero::after {
    content: '';
    position: absolute;
    width: 480px; height: 480px;
    border: 1px solid rgba(201,168,76,.18);
    border-radius: 50%;
    top: 50%; left: 50%;
    transform: translate(-50%, -50%);
    box-shadow: 0 0 0 60px rgba(201,168,76,.06), 0 0 0 120px rgba(201,168,76,.03);
    pointer-events: none;
  }
  .hero-content { position: relative; z-index: 1; }
  .hero-eyebrow {
    display: inline-block;
    background: var(--gold);
    color: var(--ink);
    font-size: .72rem;
    font-weight: 700;
    letter-spacing: .18em;
    text-transform: uppercase;
    padding: .3rem 1rem;
    border-radius: 99px;
    margin-bottom: 1.4rem;
  }
  .hero h1 {
    font-family: 'Bebas Neue', sans-serif;
    font-size: clamp(3.5rem, 8vw, 6.5rem);
    letter-spacing: .06em;
    line-height: .95;
    margin-bottom: 1.2rem;
  }
  .hero h1 span { color: var(--gold); }
  .hero p {
    max-width: 540px; margin: 0 auto 2.4rem;
    font-size: 1.05rem; color: #bbb; line-height: 1.6;
  }
  .hero-cta { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }
  .btn-hero {
    padding: .9rem 2.2rem;
    font-size: 1rem;
    border-radius: var(--radius);
    font-family: inherit;
    font-weight: 700;
    cursor: pointer;
    border: none;
    text-decoration: none;
    letter-spacing: .03em;
    transition: all .15s;
  }
  .btn-hero-primary { background: var(--gold); color: var(--ink); }
  .btn-hero-primary:hover { background: var(--gold2); transform: translateY(-2px); }
  .btn-hero-outline { background: transparent; color: #fff; border: 2px solid rgba(255,255,255,.35); }
  .btn-hero-outline:hover { border-color: var(--gold); color: var(--gold); }

  /* Stats bar */
  .stats-bar {
    display: flex; justify-content: center; gap: 0;
    background: #fff; border-bottom: 1px solid var(--border);
    flex-wrap: wrap;
  }
  .stat-item {
    padding: 1.4rem 2.5rem;
    text-align: center;
    border-right: 1px solid var(--border);
    flex: 1; min-width: 140px;
  }
  .stat-item:last-child { border-right: none; }
  .stat-value {
    font-family: 'Bebas Neue', sans-serif;
    font-size: 2.4rem; color: var(--gold); letter-spacing: .04em;
    line-height: 1;
  }
  .stat-label { font-size: .75rem; color: var(--muted); font-weight: 600; text-transform: uppercase; letter-spacing: .07em; margin-top: .3rem; }

  /* How it works */
  .steps { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-top: 2rem; }
  .step {
    background: #fff;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 1.8rem 1.4rem;
    position: relative;
    transition: box-shadow .2s;
  }
  .step:hover { box-shadow: 0 6px 24px rgba(0,0,0,.1); }
  .step-num {
    font-family: 'Bebas Neue', sans-serif;
    font-size: 3rem; color: var(--gold); opacity: .35;
    line-height: 1; margin-bottom: .5rem;
  }
  .step h3 { font-size: 1rem; font-weight: 700; margin-bottom: .4rem; }
  .step p  { font-size: .85rem; color: var(--muted); line-height: 1.5; }

  /* Quick actions */
  .quick-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 1rem; }
  .quick-card {
    background: var(--slate); color: #fff;
    border-radius: var(--radius); padding: 1.6rem;
    cursor: pointer; text-decoration: none;
    transition: transform .15s, box-shadow .15s;
    display: flex; flex-direction: column; gap: .5rem;
  }
  .quick-card:hover { transform: translateY(-3px); box-shadow: 0 8px 24px rgba(0,0,0,.2); }
  .quick-icon { font-size: 2rem; }
  .quick-card h3 { font-family: 'Bebas Neue', sans-serif; font-size: 1.3rem; letter-spacing: .05em; color: var(--gold); }
  .quick-card p  { font-size: .82rem; color: #aaa; line-height: 1.4; }

  .section-head {
    font-family: 'Bebas Neue', sans-serif;
    font-size: 1.8rem; letter-spacing: .06em; color: var(--slate);
    margin-bottom: 1.4rem;
  }
</style>

<!-- Hero -->
<div class="hero">
  <div class="hero-content">
    <div class="hero-eyebrow">🎯 Tournament Management</div>
    <h1>CARROM<br><span>CHAMPIONSHIP</span></h1>
    <p>Organise singles and doubles carrom tournaments with automated fixture generation, score tracking, and results management.</p>
    <div class="hero-cta">
      <a href="/tournaments" class="btn-hero btn-hero-primary">Start a Tournament</a>
      <a href="/players" class="btn-hero btn-hero-outline">Manage Players</a>
    </div>
  </div>
</div>

<!-- Live stats -->
<div class="stats-bar">
  <div class="stat-item"><div class="stat-value" id="stat-players">—</div><div class="stat-label">Players</div></div>
  <div class="stat-item"><div class="stat-value" id="stat-tournaments">—</div><div class="stat-label">Tournaments</div></div>
  <div class="stat-item"><div class="stat-value" id="stat-fixtures">—</div><div class="stat-label">Fixtures</div></div>
  <div class="stat-item"><div class="stat-value" id="stat-completed">—</div><div class="stat-label">Completed</div></div>
</div>

<div class="page">

  <!-- Quick actions -->
  <h2 class="section-head">Quick Actions</h2>
  <div class="quick-grid">
    <a href="/players" class="quick-card">
      <div class="quick-icon">👤</div>
      <h3>Add Players</h3>
      <p>Register players with their skill level and achievements before the tournament begins.</p>
    </a>
    <a href="/tournaments" class="quick-card">
      <div class="quick-icon">🏆</div>
      <h3>New Tournament</h3>
      <p>Create a Singles or Doubles tournament and configure the number of levels.</p>
    </a>
    <a href="/fixtures" class="quick-card">
      <div class="quick-icon">📋</div>
      <h3>Fixtures</h3>
      <p>Generate fixtures — random draw for Level 1, score-seeded for subsequent levels.</p>
    </a>
    <a href="/results" class="quick-card">
      <div class="quick-icon">🎯</div>
      <h3>Results & Cleanup</h3>
      <p>Record match results, view standings, and clean up data when a tournament ends.</p>
    </a>
  </div>

  <hr class="divider" style="margin: 2.5rem 0"/>

  <!-- How it works -->
  <h2 class="section-head">How It Works</h2>
  <div class="steps">
    <div class="step"><div class="step-num">01</div><h3>Register Players</h3><p>Add all players with skill level (Beginner / Intermediate / Pro) and past achievements.</p></div>
    <div class="step"><div class="step-num">02</div><h3>Create Tournament</h3><p>Choose Singles or Doubles, name the tournament, and set the total number of levels.</p></div>
    <div class="step"><div class="step-num">03</div><h3>Generate Level 1</h3><p>Select participating players/teams. Fixtures are drawn at random for the first level.</p></div>
    <div class="step"><div class="step-num">04</div><h3>Record Results</h3><p>Enter scores for each match. Winners and stats are updated automatically.</p></div>
    <div class="step"><div class="step-num">05</div><h3>Advance Levels</h3><p>Winners advance. Level 2+ fixtures are seeded by score — highest vs lowest.</p></div>
    <div class="step"><div class="step-num">06</div><h3>Clean Up</h3><p>Once a tournament concludes, reset scores or delete data to prepare for the next event.</p></div>
  </div>

</div>

<script>
  // Load live stats
  async function loadStats() {
    try {
      const [players, tournaments] = await Promise.all([
        fetch('/api/players').then(r => r.json()),
        fetch('/api/tournaments').then(r => r.json())
      ]);
      document.getElementById('stat-players').textContent     = players.length;
      document.getElementById('stat-tournaments').textContent = tournaments.length;

      let fixtures = 0, completed = 0;
      for (const t of tournaments) {
        const fx = await fetch(`/api/fixtures/tournament/${t.id}`).then(r => r.json()).catch(() => []);
        fixtures  += fx.length;
        completed += fx.filter(f => f.status === 'COMPLETED').length;
      }
      document.getElementById('stat-fixtures').textContent  = fixtures;
      document.getElementById('stat-completed').textContent = completed;
    } catch(e) { /* silently ignore on first load */ }
  }
  loadStats();
</script>

</body>
</html>
