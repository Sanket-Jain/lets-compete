<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .tab-bar {
    display: flex; gap: 0; margin-bottom: 1.4rem;
    border-bottom: 2px solid var(--border);
  }
  .tab-btn {
    padding: .6rem 1.6rem; font-family: inherit; font-size: .9rem; font-weight: 600;
    border: none; background: none; cursor: pointer; color: var(--muted);
    border-bottom: 3px solid transparent; margin-bottom: -2px;
    transition: color .15s, border-color .15s; letter-spacing: .02em;
  }
  .tab-btn.active { color: var(--slate); border-bottom-color: var(--gold); }
  .tab-btn:hover:not(.active) { color: var(--slate); }
  .tab-panel { display: none; }
  .tab-panel.active { display: block; }
  .team-member {
    display: inline-flex; align-items: center; gap: .3rem;
    background: #f0ecff; color: #4a235a; border-radius: 99px;
    padding: .15rem .6rem; font-size: .78rem; font-weight: 600; margin: .1rem;
  }
</style>

<div class="page">
  <div class="section-header">
    <div class="section-title" id="pageTitle">Players</div>
    <div>
      <button class="btn btn-primary" id="btnAddPlayer"  onclick="openModal('addPlayerModal')">+ Add Player</button>
      <button class="btn btn-primary" id="btnAddTeam" style="display:none" onclick="openAddTeam()">+ Create Team</button>
    </div>
  </div>

  <!-- Tab bar -->
  <div class="tab-bar">
    <button class="tab-btn active" id="tab-players" onclick="switchTab('players')">👤 Players</button>
    <button class="tab-btn"        id="tab-teams"   onclick="switchTab('teams')">👥 Teams (Doubles)</button>
  </div>

  <!-- Players tab -->
  <div class="tab-panel active" id="panel-players">
    <div class="card">
      <div class="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Name</th><th>Skill</th><th>Achievements</th><th>Score</th><th>W/P</th><th>Actions</th></tr></thead>
          <tbody id="playersBody">
            <tr><td colspan="7"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Teams tab -->
  <div class="tab-panel" id="panel-teams">
    <div class="card" style="background:#fffbe6;border-color:#ffe58f;margin-bottom:1rem;padding:1rem 1.2rem">
      <span style="font-size:.85rem;color:#7c5c00">
        💡 Teams are used for <strong>Doubles</strong> tournaments. Each team requires exactly 2 players.
        Create your players first, then form teams here.
      </span>
    </div>
    <div class="card">
      <div class="table-wrap">
        <table>
          <thead><tr><th>#</th><th>Team Name</th><th>Players</th><th>Score</th><th>W/P</th><th>Actions</th></tr></thead>
          <tbody id="teamsBody">
            <tr><td colspan="6"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></td></tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<!-- Add Player Modal -->
<div class="modal-overlay" id="addPlayerModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Add Player</div>
      <button class="modal-close" onclick="closeModal('addPlayerModal')">✕</button>
    </div>
    <div class="form-row"><div class="form-group"><label>Full Name</label><input id="p-name" type="text" placeholder="e.g. Rahul Sharma"/></div></div>
    <div class="form-row"><div class="form-group"><label>Skill Level</label>
      <select id="p-skill">
        <option value="BEGINNER">Beginner</option>
        <option value="INTERMEDIATE">Intermediate</option>
        <option value="PRO">Pro</option>
      </select>
    </div></div>
    <div class="form-row"><div class="form-group"><label>Achievements</label><textarea id="p-ach" placeholder="e.g. State champion 2023"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addPlayerModal')">Cancel</button>
      <button class="btn btn-primary"   onclick="savePlayer()">Save Player</button>
    </div>
  </div>
</div>

<!-- Edit Player Modal -->
<div class="modal-overlay" id="editPlayerModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Edit Player</div>
      <button class="modal-close" onclick="closeModal('editPlayerModal')">✕</button>
    </div>
    <input type="hidden" id="ep-id"/>
    <div class="form-row"><div class="form-group"><label>Full Name</label><input id="ep-name" type="text"/></div></div>
    <div class="form-row"><div class="form-group"><label>Skill Level</label>
      <select id="ep-skill">
        <option value="BEGINNER">Beginner</option>
        <option value="INTERMEDIATE">Intermediate</option>
        <option value="PRO">Pro</option>
      </select>
    </div></div>
    <div class="form-row"><div class="form-group"><label>Achievements</label><textarea id="ep-ach"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editPlayerModal')">Cancel</button>
      <button class="btn btn-primary"   onclick="updatePlayer()">Update</button>
    </div>
  </div>
</div>

<!-- Add Team Modal -->
<div class="modal-overlay" id="addTeamModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Create Team</div>
      <button class="modal-close" onclick="closeModal('addTeamModal')">✕</button>
    </div>
    <div class="form-row"><div class="form-group"><label>Team Name</label><input id="tm-name" type="text" placeholder="e.g. Thunder Duo"/></div></div>
    <div class="form-row">
      <div class="form-group">
        <label>Player 1</label>
        <select id="tm-p1" onchange="validateTeamPlayers()">
          <option value="">— Select player —</option>
        </select>
      </div>
      <div class="form-group">
        <label>Player 2</label>
        <select id="tm-p2" onchange="validateTeamPlayers()">
          <option value="">— Select player —</option>
        </select>
      </div>
    </div>
    <p id="tm-error" style="color:var(--rust);font-size:.82rem;min-height:1.1rem"></p>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addTeamModal')">Cancel</button>
      <button class="btn btn-primary"   onclick="saveTeam()">Create Team</button>
    </div>
  </div>
</div>

<!-- Edit Team Modal -->
<div class="modal-overlay" id="editTeamModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Edit Team</div>
      <button class="modal-close" onclick="closeModal('editTeamModal')">✕</button>
    </div>
    <input type="hidden" id="et-id"/>
    <div class="form-row"><div class="form-group"><label>Team Name</label><input id="et-name" type="text"/></div></div>
    <div class="form-row">
      <div class="form-group">
        <label>Player 1</label>
        <select id="et-p1" onchange="validateEditTeamPlayers()">
          <option value="">— Select player —</option>
        </select>
      </div>
      <div class="form-group">
        <label>Player 2</label>
        <select id="et-p2" onchange="validateEditTeamPlayers()">
          <option value="">— Select player —</option>
        </select>
      </div>
    </div>
    <p id="et-error" style="color:var(--rust);font-size:.82rem;min-height:1.1rem"></p>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editTeamModal')">Cancel</button>
      <button class="btn btn-primary"   onclick="updateTeam()">Update Team</button>
    </div>
  </div>
</div>

<script>
  const skillBadge = s => ({
    PRO:          '<span class="badge badge-pro">PRO</span>',
    INTERMEDIATE: '<span class="badge badge-intermediate">INTERMEDIATE</span>',
    BEGINNER:     '<span class="badge badge-beginner">BEGINNER</span>'
  })[s] || s;
  const esc = s => String(s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");

  // ── Tab switching ─────────────────────────────────────────────────────────────
  function switchTab(tab) {
    document.getElementById('panel-players').classList.toggle('active', tab === 'players');
    document.getElementById('panel-teams').classList.toggle('active',   tab === 'teams');
    document.getElementById('tab-players').classList.toggle('active',   tab === 'players');
    document.getElementById('tab-teams').classList.toggle('active',     tab === 'teams');
    document.getElementById('btnAddPlayer').style.display = tab === 'players' ? '' : 'none';
    document.getElementById('btnAddTeam').style.display   = tab === 'teams'   ? '' : 'none';
    document.getElementById('pageTitle').textContent = tab === 'players' ? 'Players' : 'Teams';
    if (tab === 'teams') loadTeams();
  }

  // ── PLAYERS ───────────────────────────────────────────────────────────────────
  async function loadPlayers() {
    try {
      const ps = await api('GET', '/api/players');
      const tb = document.getElementById('playersBody');
      if (!ps.length) {
        tb.innerHTML = '<tr><td colspan="7"><div class="empty"><div class="empty-icon">👤</div><p>No players yet. Add the first one!</p></div></td></tr>';
        return;
      }
      tb.innerHTML = ps.map((p, i) =>
        '<tr>' +
        '<td class="text-muted">' + (i+1) + '</td>' +
        '<td><strong>' + p.name + '</strong></td>' +
        '<td>' + skillBadge(p.skillLevel) + '</td>' +
        '<td class="text-muted" style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">' + (p.achievements || '—') + '</td>' +
        '<td><strong style="color:var(--gold)">' + p.totalScore + '</strong></td>' +
        '<td class="text-muted">' + p.matchesWon + '/' + p.matchesPlayed + '</td>' +
        '<td><div class="flex gap-1">' +
          '<button class="btn btn-secondary btn-sm" onclick="editPlayer(' + p.id + ',\'' + esc(p.name) + '\',\'' + p.skillLevel + '\',\'' + esc(p.achievements||'') + '\')">Edit</button>' +
          '<button class="btn btn-danger btn-sm" onclick="delPlayer(' + p.id + ')">Delete</button>' +
        '</div></td>' +
        '</tr>'
      ).join('');
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function savePlayer() {
    const name = document.getElementById('p-name').value.trim();
    if (!name) { showToast('Name required', 'error'); return; }
    try {
      await api('POST', '/api/players', {
        name,
        skillLevel:   document.getElementById('p-skill').value,
        achievements: document.getElementById('p-ach').value
      });
      showToast('Player added!', 'success');
      closeModal('addPlayerModal');
      document.getElementById('p-name').value = '';
      document.getElementById('p-ach').value  = '';
      loadPlayers();
    } catch(e) { showToast(e.message, 'error'); }
  }

  function editPlayer(id, name, skill, ach) {
    document.getElementById('ep-id').value    = id;
    document.getElementById('ep-name').value  = name;
    document.getElementById('ep-skill').value = skill;
    document.getElementById('ep-ach').value   = ach;
    openModal('editPlayerModal');
  }

  async function updatePlayer() {
    const id   = document.getElementById('ep-id').value;
    const name = document.getElementById('ep-name').value.trim();
    if (!name) { showToast('Name required', 'error'); return; }
    try {
      await api('PUT', '/api/players/' + id, {
        name,
        skillLevel:   document.getElementById('ep-skill').value,
        achievements: document.getElementById('ep-ach').value
      });
      showToast('Updated!', 'success');
      closeModal('editPlayerModal');
      loadPlayers();
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function delPlayer(id) {
    if (!confirm('Delete this player? They will also be removed from any teams.')) return;
    try {
      await api('DELETE', '/api/players/' + id);
      showToast('Deleted', 'info');
      loadPlayers();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── TEAMS ─────────────────────────────────────────────────────────────────────
  async function loadTeams() {
    try {
      const teams = await api('GET', '/api/teams');
      const tb = document.getElementById('teamsBody');
      if (!teams.length) {
        tb.innerHTML = '<tr><td colspan="6"><div class="empty"><div class="empty-icon">👥</div><p>No teams yet. Create one to use in Doubles tournaments.</p></div></td></tr>';
        return;
      }
      tb.innerHTML = teams.map((t, i) =>
        '<tr>' +
        '<td class="text-muted">' + (i+1) + '</td>' +
        '<td><strong>' + t.name + '</strong></td>' +
        '<td>' +
          '<span class="team-member">👤 ' + t.player1.name + '</span>' +
          '<span class="team-member">👤 ' + t.player2.name + '</span>' +
        '</td>' +
        '<td><strong style="color:var(--gold)">' + t.totalScore + '</strong></td>' +
        '<td class="text-muted">' + t.matchesWon + '/' + t.matchesPlayed + '</td>' +
        '<td><div class="flex gap-1">' +
          '<button class="btn btn-secondary btn-sm" onclick="editTeam(' + t.id + ',\'' + esc(t.name) + '\',' + t.player1.id + ',' + t.player2.id + ')">Edit</button>' +
          '<button class="btn btn-danger btn-sm" onclick="delTeam(' + t.id + ')">Delete</button>' +
        '</div></td>' +
        '</tr>'
      ).join('');
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function openAddTeam() {
    // Load players into dropdowns
    const players = await api('GET', '/api/players');
    if (players.length < 2) {
      showToast('You need at least 2 players before creating a team', 'error');
      return;
    }
    const opts = '<option value="">— Select player —</option>' +
      players.map(p => '<option value="' + p.id + '">' + p.name + ' (' + p.skillLevel + ')</option>').join('');
    document.getElementById('tm-p1').innerHTML = opts;
    document.getElementById('tm-p2').innerHTML = opts;
    document.getElementById('tm-name').value   = '';
    document.getElementById('tm-error').textContent = '';
    openModal('addTeamModal');
  }

  function validateTeamPlayers() {
    const p1 = document.getElementById('tm-p1').value;
    const p2 = document.getElementById('tm-p2').value;
    const err = document.getElementById('tm-error');
    if (p1 && p2 && p1 === p2) {
      err.textContent = '⚠ A team cannot have the same player twice.';
    } else {
      err.textContent = '';
    }
  }

  async function saveTeam() {
    const name = document.getElementById('tm-name').value.trim();
    const p1   = document.getElementById('tm-p1').value;
    const p2   = document.getElementById('tm-p2').value;
    if (!name)      { showToast('Team name required', 'error'); return; }
    if (!p1 || !p2) { showToast('Select both players', 'error'); return; }
    if (p1 === p2)  { showToast('Players must be different', 'error'); return; }
    try {
      await api('POST', '/api/teams', {
        name,
        player1Id: parseInt(p1),
        player2Id: parseInt(p2)
      });
      showToast('Team created!', 'success');
      closeModal('addTeamModal');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function editTeam(id, name, p1Id, p2Id) {
    const players = await api('GET', '/api/players');
    const opts = '<option value="">— Select player —</option>' +
      players.map(p => '<option value="' + p.id + '">' + p.name + ' (' + p.skillLevel + ')</option>').join('');
    document.getElementById('et-p1').innerHTML = opts;
    document.getElementById('et-p2').innerHTML = opts;
    document.getElementById('et-id').value    = id;
    document.getElementById('et-name').value  = name;
    document.getElementById('et-p1').value    = p1Id;
    document.getElementById('et-p2').value    = p2Id;
    document.getElementById('et-error').textContent = '';
    openModal('editTeamModal');
  }

  function validateEditTeamPlayers() {
    const p1 = document.getElementById('et-p1').value;
    const p2 = document.getElementById('et-p2').value;
    const err = document.getElementById('et-error');
    err.textContent = (p1 && p2 && p1 === p2) ? '⚠ A team cannot have the same player twice.' : '';
  }

  async function updateTeam() {
    const id   = document.getElementById('et-id').value;
    const name = document.getElementById('et-name').value.trim();
    const p1   = document.getElementById('et-p1').value;
    const p2   = document.getElementById('et-p2').value;
    if (!name)      { showToast('Team name required', 'error'); return; }
    if (!p1 || !p2) { showToast('Select both players', 'error'); return; }
    if (p1 === p2)  { showToast('Players must be different', 'error'); return; }
    try {
      await api('PUT', '/api/teams/' + id, {
        name,
        player1Id: parseInt(p1),
        player2Id: parseInt(p2)
      });
      showToast('Team updated!', 'success');
      closeModal('editTeamModal');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  async function delTeam(id) {
    if (!confirm('Delete this team?')) return;
    try {
      await api('DELETE', '/api/teams/' + id);
      showToast('Team deleted', 'info');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // Initial load
  loadPlayers();
</script>
</body></html>
