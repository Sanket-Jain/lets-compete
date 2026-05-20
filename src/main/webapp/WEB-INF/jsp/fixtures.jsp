<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .fixture-card {
    background:#fff; border:1px solid var(--border); border-radius:var(--radius);
    padding:1.2rem 1.4rem; margin-bottom:.7rem;
    display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem;
  }
  .fixture-card.completed  { border-left:4px solid var(--success); }
  .fixture-card.scheduled  { border-left:4px solid var(--gold); }
  .fixture-card.walkover   { border-left:4px solid #9c7bb5; background:#faf7ff; }
  .match-players { display:flex; align-items:center; gap:.9rem; font-weight:600; font-size:.97rem; }
  .vs { color:var(--muted); font-size:.78rem; font-weight:400; }
  .match-score { font-family:'Bebas Neue',sans-serif; font-size:1.7rem; letter-spacing:.05em; color:var(--slate); }
  .winner-tag  { font-size:.72rem; color:var(--success); font-weight:700; text-transform:uppercase; }
  .bye-tag     { font-size:.72rem; color:#7c5cbf; font-weight:700; text-transform:uppercase; letter-spacing:.06em; }
  .level-header {
    font-family:'Bebas Neue',sans-serif; font-size:1.05rem; letter-spacing:.1em;
    color:var(--gold); background:var(--slate); padding:.38rem 1rem;
    border-radius:var(--radius); margin-bottom:.7rem; display:inline-flex; align-items:center; gap:.5rem;
  }
  .controls-bar {
    background:#fff; border:1px solid var(--border); border-radius:var(--radius);
    padding:1.2rem 1.4rem; margin-bottom:1.2rem;
    display:flex; gap:1rem; align-items:flex-end; flex-wrap:wrap;
  }
  .bracket-info {
    background:#fffbe6; border:1px solid #ffe58f; border-radius:var(--radius);
    padding:.8rem 1.1rem; margin-bottom:1rem; font-size:.85rem; color:#7c5c00;
    display:none;
  }
  .bracket-info b { color:#5c4000; }
</style>

<div class="page">
  <div class="section-title" style="margin-bottom:1.2rem">Fixtures</div>

  <div class="controls-bar">
    <div class="form-group" style="min-width:240px">
      <label>Select Tournament</label>
      <select id="sel-tournament" onchange="onTournamentChange()">
        <option value="">— Choose a tournament —</option>
      </select>
    </div>
    <button class="btn btn-primary"   id="btn-gen1" onclick="genLevel1()"     disabled>Generate Level 1 (Random)</button>
    <button class="btn btn-success"   id="btn-adv"  onclick="advanceLevel()"  disabled>Advance to Next Level ›</button>
  </div>

  <!-- Bracket info banner shown after tournament is selected -->
  <div class="bracket-info" id="bracketInfo"></div>

  <!-- Participant selector -->
  <div class="card" id="participantSection" style="display:none">
    <div class="card-title" id="participantTitle">Select Participants</div>
    <p class="text-muted" style="margin-bottom:.9rem" id="participantHint"></p>
    <div id="participantList" style="display:flex;flex-wrap:wrap;gap:.55rem;margin-bottom:1rem"></div>
    <div class="flex gap-1">
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(true)">Select All</button>
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(false)">Deselect All</button>
      <button class="btn btn-primary"          onclick="confirmGenLevel1()">Generate Fixtures</button>
      <button class="btn btn-secondary"        onclick="hideParticipants()">Cancel</button>
    </div>
  </div>

  <div id="fixturesArea"></div>
</div>

<!-- Record Result Modal -->
<div class="modal-overlay" id="resultModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Record Result</div>
      <button class="modal-close" onclick="closeModal('resultModal')">✕</button>
    </div>
    <input type="hidden" id="r-id"/>
    <p id="r-matchLabel" style="margin-bottom:1rem;font-weight:600;color:var(--slate)"></p>
    <div class="form-row">
      <div class="form-group"><label id="r-p1label">Player 1 Score</label><input id="r-s1" type="number" min="0" value="0"/></div>
      <div class="form-group"><label id="r-p2label">Player 2 Score</label><input id="r-s2" type="number" min="0" value="0"/></div>
    </div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('resultModal')">Cancel</button>
      <button class="btn btn-primary"   onclick="submitResult()">Save Result</button>
    </div>
  </div>
</div>

<script>
  let currentTournament = null;

  // ── Load tournaments into selector ────────────────────────────────────────────
  async function loadTournaments() {
    try {
      const ts = await api('GET', '/api/tournaments');
      const sel = document.getElementById('sel-tournament');
      sel.innerHTML = '<option value="">— Choose a tournament —</option>' +
        ts.map(t => '<option value="' + t.id + '" data-type="' + t.competitionType + '">' +
          t.name + ' (' + t.competitionType + ')</option>').join('');
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function onTournamentChange() {
    const sel = document.getElementById('sel-tournament');
    const id  = sel.value;
    document.getElementById('bracketInfo').style.display = 'none';
    document.getElementById('fixturesArea').innerHTML = '';
    hideParticipants();
    document.getElementById('btn-gen1').disabled = true;
    document.getElementById('btn-adv').disabled  = true;

    if (!id) { currentTournament = null; return; }
    const opt = sel.options[sel.selectedIndex];
    currentTournament = { id, type: opt.dataset.type };
    document.getElementById('btn-gen1').disabled = false;
    await loadFixtures();
  }

  async function loadFixtures() {
    if (!currentTournament) return;
    try {
      const fixtures = await api('GET', '/api/fixtures/tournament/' + currentTournament.id);
      renderFixtures(fixtures);
      const nonBye = fixtures.filter(f => !f.isBye);
      const pending = nonBye.filter(f => f.status !== 'COMPLETED' && f.status !== 'WALKOVER');
      // Advance button: fixtures exist AND all real (non-bye) matches completed
      document.getElementById('btn-adv').disabled = (nonBye.length === 0 || pending.length > 0);
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Render fixtures grouped by level ─────────────────────────────────────────
  function renderFixtures(fixtures) {
    const area = document.getElementById('fixturesArea');
    if (!fixtures.length) {
      area.innerHTML = '<div class="empty"><div class="empty-icon">📋</div><p>No fixtures yet. Click "Generate Level 1" to begin.</p></div>';
      return;
    }
    const levels = {};
    fixtures.forEach(f => { if (!levels[f.levelNumber]) levels[f.levelNumber] = []; levels[f.levelNumber].push(f); });

    area.innerHTML = Object.entries(levels).map(([lvl, fxs]) => {
      const real = fxs.filter(f => !f.isBye).length;
      const byes = fxs.filter(f => f.isBye).length;
      const done = fxs.filter(f => f.status === 'COMPLETED' || f.status === 'WALKOVER').length;
      const summary = real + ' match' + (real !== 1 ? 'es' : '') +
        (byes ? ' + ' + byes + ' bye' + (byes !== 1 ? 's' : '') : '') +
        ' &nbsp;·&nbsp; ' + done + '/' + fxs.length + ' done';
      return '<div style="margin-bottom:1.8rem">' +
        '<div style="display:flex;align-items:center;gap:.8rem;margin-bottom:.7rem">' +
        '<div class="level-header">🏅 Level ' + lvl + '</div>' +
        '<span class="text-muted" style="font-size:.82rem">' + summary + '</span></div>' +
        fxs.map(f => renderFixtureCard(f)).join('') +
        '</div>';
    }).join('');
  }

  function renderFixtureCard(f) {
    const isSingles  = f.competitionType === 'SINGLES';
    const p1         = isSingles ? (f.player1 ? f.player1.name : '—') : (f.team1 ? f.team1.name : '—');
    const p2         = isSingles ? (f.player2 ? f.player2.name : null) : (f.team2 ? f.team2.name : null);
    const winnerName = isSingles ? (f.winnerPlayer ? f.winnerPlayer.name : null) : (f.winnerTeam ? f.winnerTeam.name : null);
    const done       = f.status === 'COMPLETED' || f.status === 'WALKOVER';
    const cardClass  = f.isBye ? 'walkover' : (done ? 'completed' : 'scheduled');

    let opponentHtml;
    if (f.isBye) {
      opponentHtml = '<span style="color:#9c7bb5;font-style:italic">BYE</span>';
    } else {
      opponentHtml = '<span ' + (winnerName === p2 ? 'style="color:var(--success)"' : '') + '>' + (p2 || '—') + '</span>';
    }

    let resultHtml = '';
    if (f.isBye) {
      resultHtml = '<div class="bye-tag">🎫 Auto-Advanced (Bye)</div>';
    } else if (done) {
      resultHtml = '<div class="match-score">' + f.scoreParticipant1 + ' — ' + f.scoreParticipant2 + '</div>' +
                   '<div class="winner-tag">🏆 ' + winnerName + '</div>';
    }

    let actionHtml = '';
    if (!done && !f.isBye) {
      actionHtml = '<button class="btn btn-primary btn-sm" onclick="openResult(' +
        f.id + ',\'' + esc(p1) + '\',\'' + esc(p2 || '') + '\')">Record Result</button>';
    }

    return '<div class="fixture-card ' + cardClass + '">' +
      '<div>' +
        '<div class="match-players">' +
          '<span ' + (winnerName === p1 ? 'style="color:var(--success)"' : '') + '>' + p1 + '</span>' +
          '<span class="vs">VS</span>' +
          opponentHtml +
        '</div>' +
        resultHtml +
      '</div>' +
      '<div class="flex gap-1" style="align-items:center">' +
        '<span class="badge ' + (f.isBye ? '' : (done ? 'badge-completed' : 'badge-scheduled')) + '"' +
          (f.isBye ? 'style="background:#e8d5f7;color:#5c3d8f"' : '') + '>' +
          (f.isBye ? 'BYE' : f.status) + '</span>' +
        actionHtml +
      '</div>' +
    '</div>';
  }

  // ── Level 1 generation ────────────────────────────────────────────────────────
  async function genLevel1() {
    if (!currentTournament) { showToast('Select a tournament first', 'error'); return; }

    // Check if Level 1 already exists
    const existing = await api('GET', '/api/fixtures/tournament/' + currentTournament.id);
    if (existing.length > 0) { showToast('Level 1 fixtures already exist', 'error'); return; }

    const isSingles = currentTournament.type === 'SINGLES';
    document.getElementById('participantTitle').textContent = isSingles ? 'Select Players' : 'Select Teams';
    document.getElementById('participantSection').style.display = 'block';

    const all = isSingles ? await api('GET', '/api/players') : await api('GET', '/api/teams');
    const list = document.getElementById('participantList');
    list.innerHTML = all.map(p => {
      const label = isSingles ? p.name : p.name + ' (' + p.player1.name + ' & ' + p.player2.name + ')';
      return '<label style="display:flex;align-items:center;gap:.4rem;background:#f5f0e8;padding:.4rem .9rem;border-radius:var(--radius);cursor:pointer">' +
        '<input type="checkbox" value="' + p.id + '" checked/> ' + label + '</label>';
    }).join('');

    updateBracketHint();
    document.getElementById('participantSection').querySelectorAll('input[type=checkbox]')
      .forEach(cb => cb.addEventListener('change', updateBracketHint));
  }

  function updateBracketHint() {
    const checked = document.querySelectorAll('#participantList input:checked').length;
    if (checked < 2) { document.getElementById('participantHint').textContent = 'Select at least 2 participants.'; return; }
    const bracketSize = nextPow2(checked);
    const byes = bracketSize - checked;
    let msg = checked + ' participants selected → bracket size: ' + bracketSize;
    if (byes > 0) {
      msg += ' · ' + byes + ' bye' + (byes > 1 ? 's' : '') + ' will be assigned randomly in Level 1';
      msg += ' → Level 2 onward will have no byes (' + (bracketSize / 2) + ' matches)';
    } else {
      msg += ' · Perfect bracket — no byes needed';
    }
    document.getElementById('participantHint').textContent = msg;
  }

  function nextPow2(n) { let p = 1; while (p < n) p <<= 1; return p; }

  function toggleAll(state) {
    document.querySelectorAll('#participantList input[type=checkbox]').forEach(cb => cb.checked = state);
    updateBracketHint();
  }

  function hideParticipants() { document.getElementById('participantSection').style.display = 'none'; }

  async function confirmGenLevel1() {
    const ids = [...document.querySelectorAll('#participantList input:checked')].map(cb => parseInt(cb.value));
    if (ids.length < 2) { showToast('Select at least 2 participants', 'error'); return; }
    try {
      await api('POST', '/api/fixtures/tournament/' + currentTournament.id + '/generate-level1', ids);
      showToast('Level 1 fixtures generated!', 'success');
      hideParticipants();
      loadFixtures();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Advance level ─────────────────────────────────────────────────────────────
  async function advanceLevel() {
    if (!currentTournament) return;
    try {
      await api('POST', '/api/fixtures/tournament/' + currentTournament.id + '/advance-level');
      showToast('Next level fixtures generated!', 'success');
      loadFixtures();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Record result ─────────────────────────────────────────────────────────────
  function openResult(id, p1, p2) {
    document.getElementById('r-id').value = id;
    document.getElementById('r-matchLabel').textContent = p1 + ' vs ' + p2;
    document.getElementById('r-p1label').textContent = p1 + ' Score';
    document.getElementById('r-p2label').textContent = p2 + ' Score';
    document.getElementById('r-s1').value = 0;
    document.getElementById('r-s2').value = 0;
    openModal('resultModal');
  }

  async function submitResult() {
    const id = document.getElementById('r-id').value;
    const s1 = parseInt(document.getElementById('r-s1').value) || 0;
    const s2 = parseInt(document.getElementById('r-s2').value) || 0;
    try {
      await api('PUT', '/api/fixtures/' + id + '/result', { scoreParticipant1: s1, scoreParticipant2: s2 });
      showToast('Result saved!', 'success');
      closeModal('resultModal');
      loadFixtures();
    } catch(e) { showToast(e.message, 'error'); }
  }

  const esc = s => String(s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");

  loadTournaments();
</script>
</body></html>
