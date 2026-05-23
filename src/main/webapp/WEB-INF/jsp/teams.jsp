<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .team-card {
    background: #fff;
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 1.2rem 1.4rem;
    display: flex;
    align-items: center;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: .75rem;
    transition: box-shadow .15s;
  }
  .team-card:hover { box-shadow: var(--shadow); }
  .team-players {
    display: flex;
    align-items: center;
    gap: .6rem;
    font-size: .92rem;
  }
  .player-chip {
    background: var(--ivory);
    border: 1px solid var(--border);
    border-radius: 99px;
    padding: .25rem .85rem;
    font-size: .82rem;
    font-weight: 600;
    color: var(--slate);
  }
  .amp { color: var(--muted); font-size: .8rem; }
  .team-stats { display: flex; gap: 1.4rem; }
  .stat-cell { text-align: center; }
  .stat-cell .val { font-family: 'Bebas Neue', sans-serif; font-size: 1.4rem; color: var(--gold); }
  .stat-cell .lbl { font-size: .68rem; text-transform: uppercase; letter-spacing: .06em; color: var(--muted); }
  .no-players-warn {
    background: #fff8e1; border: 1px solid #ffe082; border-radius: var(--radius);
    padding: .9rem 1.2rem; margin-bottom: 1.2rem; font-size: .88rem; color: #7c5c00; display: none;
  }
  .player-select-grid {
    display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin-bottom: 1rem;
  }
  .player-option {
    border: 2px solid var(--border); border-radius: var(--radius);
    padding: .7rem 1rem; cursor: pointer; transition: all .15s;
    display: flex; align-items: center; gap: .6rem;
  }
  .player-option:hover { border-color: var(--gold); background: #fffbe6; }
  .player-option.selected { border-color: var(--gold); background: #fffbe6; }
  .player-option input[type=radio] { accent-color: var(--gold); }
</style>

<div class="page">
  <div class="section-header">
    <div class="section-title">Teams</div>
    <button class="btn btn-primary" onclick="openAddTeam()">+ Create Team</button>
  </div>

  <p class="text-muted" style="margin-bottom:1.2rem">
    Teams are used in Doubles tournaments. Each team is a pair of two players.
  </p>

  <div class="no-players-warn" id="noPlayersWarn">
    ⚠️ You need at least 2 players before creating a team.
    <a href="/players" style="color:var(--rust);font-weight:600">Add players first →</a>
  </div>

  <div id="teamsArea">
    <div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div>
  </div>
</div>

<!-- Add Team Modal -->
<div class="modal-overlay" id="addTeamModal">
  <div class="modal" style="max-width:560px">
    <div class="modal-header">
      <div class="modal-title">Create Team</div>
      <button class="modal-close" onclick="closeModal('addTeamModal')">✕</button>
    </div>

    <div class="form-row">
      <div class="form-group">
        <label>Team Name</label>
        <input id="tm-name" type="text" placeholder="e.g. Thunder Duo"/>
      </div>
    </div>

    <div style="margin-bottom:.5rem">
      <label style="font-size:.8rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em">
        Player 1
      </label>
    </div>
    <div id="p1-grid" style="display:flex;flex-wrap:wrap;gap:.5rem;margin-bottom:1rem"></div>

    <div style="margin-bottom:.5rem">
      <label style="font-size:.8rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em">
        Player 2
      </label>
    </div>
    <div id="p2-grid" style="display:flex;flex-wrap:wrap;gap:.5rem;margin-bottom:1.2rem"></div>

    <div id="same-player-warn" style="display:none;color:var(--rust);font-size:.83rem;margin-bottom:.8rem">
      ⚠️ Player 1 and Player 2 must be different players.
    </div>

    <div class="flex gap-1" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addTeamModal')">Cancel</button>
      <button class="btn btn-primary" onclick="saveTeam()">Create Team</button>
    </div>
  </div>
</div>

<!-- Edit Team Modal -->
<div class="modal-overlay" id="editTeamModal">
  <div class="modal" style="max-width:420px">
    <div class="modal-header">
      <div class="modal-title">Edit Team Name</div>
      <button class="modal-close" onclick="closeModal('editTeamModal')">✕</button>
    </div>
    <input type="hidden" id="et-id"/>
    <div class="form-row">
      <div class="form-group">
        <label>Team Name</label>
        <input id="et-name" type="text"/>
      </div>
    </div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editTeamModal')">Cancel</button>
      <button class="btn btn-primary" onclick="updateTeam()">Update</button>
    </div>
  </div>
</div>

<script>
  let allPlayers = [];

  // ── Load players for use in team creation ─────────────────────────────────────
  async function loadPlayers() {
    try {
      allPlayers = await api('GET', '/api/players');
      if (allPlayers.length < 2) {
        document.getElementById('noPlayersWarn').style.display = 'block';
      }
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Load and render all teams ─────────────────────────────────────────────────
  async function loadTeams() {
    try {
      const teams = await api('GET', '/api/teams');
      const area  = document.getElementById('teamsArea');

      if (!teams.length) {
        area.innerHTML = '<div class="empty"><div class="empty-icon">🤝</div>' +
          '<p>No teams yet. Create the first team for a Doubles tournament.</p></div>';
        return;
      }

      area.innerHTML = teams.map(t => {
        const skillBadge = s => ({
          PRO: '<span class="badge badge-pro">PRO</span>',
          INTERMEDIATE: '<span class="badge badge-intermediate">INT</span>',
          BEGINNER: '<span class="badge badge-beginner">BEG</span>'
        })[s] || '';

        return '<div class="team-card">' +
          '<div>' +
            '<div style="font-weight:700;font-size:1rem;margin-bottom:.4rem">' + t.name + '</div>' +
            '<div class="team-players">' +
              '<span class="player-chip">' + t.player1.name + '</span>' +
              ' ' + skillBadge(t.player1.skillLevel) + ' ' +
              '<span class="amp">&amp;</span> ' +
              '<span class="player-chip">' + t.player2.name + '</span>' +
              ' ' + skillBadge(t.player2.skillLevel) +
            '</div>' +
          '</div>' +
          '<div style="display:flex;align-items:center;gap:1.5rem;flex-wrap:wrap">' +
            '<div class="team-stats">' +
              '<div class="stat-cell"><div class="val">' + t.totalScore + '</div><div class="lbl">Score</div></div>' +
              '<div class="stat-cell"><div class="val">' + t.matchesWon + '</div><div class="lbl">Won</div></div>' +
              '<div class="stat-cell"><div class="val">' + t.matchesPlayed + '</div><div class="lbl">Played</div></div>' +
            '</div>' +
            '<div class="flex gap-1">' +
              '<button class="btn btn-secondary btn-sm" onclick="editTeam(' + t.id + ',\'' + esc(t.name) + '\')">Edit</button>' +
              '<button class="btn btn-danger btn-sm" onclick="deleteTeam(' + t.id + ')">Delete</button>' +
            '</div>' +
          '</div>' +
        '</div>';
      }).join('');
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Open Add Team modal — populate player selectors ───────────────────────────
  async function openAddTeam() {
    if (allPlayers.length < 2) {
      showToast('Add at least 2 players first', 'error'); return;
    }
    document.getElementById('tm-name').value = '';
    document.getElementById('same-player-warn').style.display = 'none';
    renderPlayerPicker('p1-grid', 'p1-sel', null);
    renderPlayerPicker('p2-grid', 'p2-sel', null);
    openModal('addTeamModal');
  }

  function renderPlayerPicker(containerId, radioName, excludeId) {
    const container = document.getElementById(containerId);
    const available = allPlayers.filter(p => p.id !== excludeId);
    container.innerHTML = available.map(p =>
      '<label style="display:flex;align-items:center;gap:.45rem;background:var(--ivory);' +
        'border:1.5px solid var(--border);border-radius:var(--radius);padding:.45rem .85rem;' +
        'cursor:pointer;font-size:.85rem;font-weight:500;transition:border-color .15s" ' +
        'onmouseover="this.style.borderColor=\'var(--gold)\'" ' +
        'onmouseout="this.style.borderColor=\'var(--border)\'">' +
        '<input type="radio" name="' + radioName + '" value="' + p.id + '" ' +
          'onchange="onPlayerSelect()" style="accent-color:var(--gold)"/> ' +
        p.name + ' <span class="badge badge-' + p.skillLevel.toLowerCase() + '" style="margin-left:.3rem">' +
          p.skillLevel.substring(0,3) + '</span>' +
      '</label>'
    ).join('');
  }

  function onPlayerSelect() {
    // When player 1 is selected, refresh player 2 list to exclude that player
    const p1 = getSelected('p1-sel');
    const p2 = getSelected('p2-sel');
    if (p1) renderPlayerPicker('p2-grid', 'p2-sel', parseInt(p1));
    if (p2) renderPlayerPicker('p1-grid', 'p1-sel', parseInt(p2));
    // Re-select the previously chosen value if still available
    if (p1) { const r = document.querySelector('input[name="p1-sel"][value="' + p1 + '"]'); if(r) r.checked = true; }
    if (p2) { const r = document.querySelector('input[name="p2-sel"][value="' + p2 + '"]'); if(r) r.checked = true; }
    document.getElementById('same-player-warn').style.display = 'none';
  }

  function getSelected(radioName) {
    const el = document.querySelector('input[name="' + radioName + '"]:checked');
    return el ? el.value : null;
  }

  // ── Save new team ─────────────────────────────────────────────────────────────
  async function saveTeam() {
    const name = document.getElementById('tm-name').value.trim();
    const p1Id = getSelected('p1-sel');
    const p2Id = getSelected('p2-sel');

    if (!name)  { showToast('Team name is required', 'error'); return; }
    if (!p1Id)  { showToast('Select Player 1', 'error'); return; }
    if (!p2Id)  { showToast('Select Player 2', 'error'); return; }
    if (p1Id === p2Id) {
      document.getElementById('same-player-warn').style.display = 'block';
      return;
    }

    try {
      await api('POST', '/api/teams', {
        name,
        player1Id: parseInt(p1Id),
        player2Id: parseInt(p2Id)
      });
      showToast('Team created!', 'success');
      closeModal('addTeamModal');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Edit team name ────────────────────────────────────────────────────────────
  function editTeam(id, name) {
    document.getElementById('et-id').value  = id;
    document.getElementById('et-name').value = name;
    openModal('editTeamModal');
  }

  async function updateTeam() {
    const id   = document.getElementById('et-id').value;
    const name = document.getElementById('et-name').value.trim();
    if (!name) { showToast('Name required', 'error'); return; }
    try {
      // Fetch current team to get player IDs (required by API)
      const team = await api('GET', '/api/teams/' + id);
      await api('PUT', '/api/teams/' + id, {
        name,
        player1Id: team.player1.id,
        player2Id: team.player2.id
      });
      showToast('Team updated!', 'success');
      closeModal('editTeamModal');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  // ── Delete team ───────────────────────────────────────────────────────────────
  async function deleteTeam(id) {
    if (!confirm('Delete this team? This cannot be undone.')) return;
    try {
      await api('DELETE', '/api/teams/' + id);
      showToast('Team deleted', 'info');
      loadTeams();
    } catch(e) { showToast(e.message, 'error'); }
  }

  const esc = s => String(s || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");

  // ── Init ──────────────────────────────────────────────────────────────────────
  (async function init() {
    await loadPlayers();
    await loadTeams();
  })();
</script>
</body></html>
