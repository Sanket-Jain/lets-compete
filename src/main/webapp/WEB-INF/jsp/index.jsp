<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Home"/>
<%@ include file="layout/header.jsp" %>

<style>
.hero {
  text-align: center;
  padding: 5rem 1rem 3.5rem;
  position: relative;
}
.hero-eyebrow {
  font-size: .8rem;
  font-weight: 700;
  letter-spacing: .25em;
  text-transform: uppercase;
  color: var(--accent);
  margin-bottom: 1rem;
}
.hero h1 {
  font-family: 'Bebas Neue', sans-serif;
  font-size: clamp(3rem, 8vw, 6rem);
  line-height: .95;
  letter-spacing: 3px;
  margin-bottom: 1.2rem;
}
.hero h1 .line2 { color: var(--accent); }
.hero p {
  max-width: 480px;
  margin: 0 auto 2.5rem;
  color: var(--text-secondary);
  font-size: 1.05rem;
}
.hero-actions { display: flex; gap: 1rem; justify-content: center; flex-wrap: wrap; }
.hero-ring {
  position: absolute;
  width: 500px; height: 500px;
  border-radius: 50%;
  border: 1px solid rgba(240,165,0,.07);
  top: 50%; left: 50%;
  transform: translate(-50%, -50%);
  pointer-events: none;
}
.hero-ring:nth-child(2) { width: 700px; height: 700px; border-color: rgba(240,165,0,.04); }

.steps {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 1.2rem;
  margin: 3rem 0;
}
.step-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 1.5rem;
  text-align: center;
  transition: border-color .2s, transform .2s;
}
.step-card:hover { border-color: rgba(240,165,0,.35); transform: translateY(-3px); }
.step-num {
  font-family: 'Bebas Neue', sans-serif;
  font-size: 2.5rem;
  color: var(--accent);
  opacity: .3;
  line-height: 1;
}
.step-card h3 { font-size: 1rem; font-weight: 600; margin: .4rem 0 .4rem; }
.step-card p  { font-size: .83rem; color: var(--text-secondary); }

.quick-actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
  margin-top: 2rem;
}
.qa-card {
  background: var(--bg-card);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 1.3rem 1.5rem;
  text-decoration: none;
  display: flex; align-items: center; gap: 1rem;
  transition: all .2s;
  color: var(--text-primary);
}
.qa-card:hover {
  border-color: var(--accent);
  background: var(--bg-raised);
  transform: translateX(4px);
}
.qa-icon {
  font-size: 1.6rem;
  width: 44px; height: 44px;
  background: var(--accent-glow);
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  flex-shrink: 0;
}
.qa-card strong { display: block; font-size: .95rem; }
.qa-card small  { color: var(--text-secondary); font-size: .8rem; }
</style>

<div class="page-wrap">

  <div class="hero">
    <div class="hero-ring"></div>
    <div class="hero-ring"></div>
    <div class="hero-eyebrow">⬤ Tournament Management System</div>
    <h1>
      CARROM<br>
      <span class="line2">COMPETITION</span>
    </h1>
    <p>Organise singles &amp; doubles tournaments with automatic fixture generation, score tracking, and smart seeding.</p>
    <div class="hero-actions">
      <a href="/tournaments" class="btn btn-primary">Start a Tournament</a>
      <a href="/players" class="btn btn-outline">Manage Players</a>
    </div>
  </div>

  <!-- Stats bar -->
  <div id="statsBar" class="stat-row" style="justify-content:center; margin-bottom:2.5rem;"></div>

  <!-- How it works -->
  <div class="card" style="margin-bottom:2rem;">
    <div class="card-title">How It Works</div>
    <div class="steps">
      <div class="step-card">
        <div class="step-num">01</div>
        <h3>Add Players</h3>
        <p>Register all players with skill level and achievements.</p>
      </div>
      <div class="step-card">
        <div class="step-num">02</div>
        <h3>Form Teams</h3>
        <p>For doubles, pair players into teams before creating a tournament.</p>
      </div>
      <div class="step-card">
        <div class="step-num">03</div>
        <h3>Create Tournament</h3>
        <p>Choose singles or doubles, name it, set the number of levels.</p>
      </div>
      <div class="step-card">
        <div class="step-num">04</div>
        <h3>Generate Fixtures</h3>
        <p>Level 1 is a random draw. Higher levels seed by score.</p>
      </div>
      <div class="step-card">
        <div class="step-num">05</div>
        <h3>Record Results</h3>
        <p>Enter match scores. Winners advance automatically.</p>
      </div>
      <div class="step-card">
        <div class="step-num">06</div>
        <h3>Advance &amp; Repeat</h3>
        <p>Advance level — winners are re-seeded by cumulative score.</p>
      </div>
    </div>
  </div>

  <!-- Quick actions -->
  <div class="card">
    <div class="card-title">Quick Actions</div>
    <div class="quick-actions">
      <a href="/players" class="qa-card">
        <div class="qa-icon">👤</div>
        <div><strong>Players</strong><small>Add &amp; manage all players</small></div>
      </a>
      <a href="/teams" class="qa-card">
        <div class="qa-icon">👥</div>
        <div><strong>Teams</strong><small>Form doubles pairs</small></div>
      </a>
      <a href="/tournaments" class="qa-card">
        <div class="qa-icon">🏆</div>
        <div><strong>Tournaments</strong><small>Create &amp; manage events</small></div>
      </a>
      <a href="/fixtures" class="qa-card">
        <div class="qa-icon">📋</div>
        <div><strong>Fixtures</strong><small>View &amp; record match results</small></div>
      </a>
    </div>
  </div>

</div>

<script>
(async () => {
  try {
    const [players, tournaments, teams] = await Promise.all([
      API.get('/api/players'),
      API.get('/api/tournaments'),
      API.get('/api/teams')
    ]);
    const active = tournaments.filter(t => t.isActive).length;
    document.getElementById('statsBar').innerHTML = `
      <div class="stat-pill"><div class="val">${players.length}</div><div class="lbl">Players</div></div>
      <div class="stat-pill"><div class="val">${teams.length}</div><div class="lbl">Teams</div></div>
      <div class="stat-pill"><div class="val">${tournaments.length}</div><div class="lbl">Tournaments</div></div>
      <div class="stat-pill"><div class="val">${active}</div><div class="lbl">Active</div></div>
    `;
  } catch(e) {}
})();
</script>

<%@ include file="layout/footer.jsp" %>
