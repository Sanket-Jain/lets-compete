<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .team-card {
    background:#fff; border:1px solid var(--border); border-radius:var(--radius);
    padding:1.2rem 1.4rem; display:flex; align-items:center;
    justify-content:space-between; flex-wrap:wrap; gap:1rem; margin-bottom:.75rem;
    transition:box-shadow .15s;
  }
  .team-card:hover { box-shadow:var(--shadow); }
  .player-chip {
    background:var(--ivory); border:1px solid var(--border); border-radius:99px;
    padding:.22rem .8rem; font-size:.82rem; font-weight:600; color:var(--slate);
  }
  .stat-cell { text-align:center; }
  .stat-cell .val { font-family:'Bebas Neue',sans-serif; font-size:1.4rem; color:var(--gold); }
  .stat-cell .lbl { font-size:.68rem; text-transform:uppercase; letter-spacing:.06em; color:var(--muted); }
  .filter-bar { display:flex; gap:1rem; align-items:flex-end; flex-wrap:wrap; margin-bottom:1.2rem; }
</style>

<div class="page">
  <div class="section-header">
    <div class="section-title">Teams</div>
    <button class="btn btn-primary" onclick="openAddTeam()">+ Create Team</button>
  </div>
  <p class="text-muted" style="margin-bottom:1rem">Teams are used in Doubles tournaments (Carrom Doubles, Badminton Doubles, Badminton Mixed Doubles). Each team pairs two players.</p>

  <!-- Filter by tournament -->
  <div class="filter-bar">
    <div class="form-group" style="min-width:260px">
      <label>Filter by Tournament</label>
      <select id="sel-tournament" onchange="loadTeams()">
        <option value="">All Teams (global)</option>
      </select>
    </div>
  </div>

  <div id="noPlayersWarn" style="display:none;background:#fff8e1;border:1px solid #ffe082;border-radius:var(--radius);padding:.9rem 1.2rem;margin-bottom:1rem;font-size:.88rem;color:#7c5c00">
    ⚠️ You need at least 2 players before creating a team.
    <a href="/players" style="color:var(--rust);font-weight:600">Add players first →</a>
  </div>

  <div id="teamsArea"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></div>
</div>

<!-- Add Team Modal -->
<div class="modal-overlay" id="addTeamModal">
  <div class="modal" style="max-width:600px">
    <div class="modal-header">
      <div class="modal-title">Create Team</div>
      <button class="modal-close" onclick="closeModal('addTeamModal')">✕</button>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Team Name</label><input id="tm-name" type="text" placeholder="e.g. Thunder Duo"/></div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Link to Tournament (optional — enforces player uniqueness)</label>
        <select id="tm-tournament" onchange="onTournamentSelected()">
          <option value="">— No tournament (global team) —</option>
        </select>
      </div>
    </div>
    <div id="mixed-warn" style="display:none;background:#e8f4fd;border:1px solid #bee3f8;border-radius:var(--radius);padding:.7rem 1rem;font-size:.83rem;color:#1a4a6e;margin-bottom:.8rem">
      ℹ️ This is a <strong>Mixed Doubles</strong> tournament — team must have one Male and one Female player.
    </div>
    <div id="conflict-warn" style="display:none;background:#fff5f5;border:1px solid #f5c6cb;border-radius:var(--radius);padding:.7rem 1rem;font-size:.83rem;color:#721c24;margin-bottom:.8rem"></div>

    <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem">
      <div>
        <label style="font-size:.8rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:.5rem">Player 1</label>
        <div id="p1-grid" style="display:flex;flex-direction:column;gap:.4rem;max-height:240px;overflow-y:auto;padding-right:.3rem"></div>
      </div>
      <div>
        <label style="font-size:.8rem;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;display:block;margin-bottom:.5rem">Player 2</label>
        <div id="p2-grid" style="display:flex;flex-direction:column;gap:.4rem;max-height:240px;overflow-y:auto;padding-right:.3rem"></div>
      </div>
    </div>

    <div class="flex gap-1 mt-2" style="justify-content:flex-end;margin-top:1.2rem">
      <button class="btn btn-secondary" onclick="closeModal('addTeamModal')">Cancel</button>
      <button class="btn btn-primary" onclick="saveTeam()">Create Team</button>
    </div>
  </div>
</div>

<!-- Edit Modal -->
<div class="modal-overlay" id="editTeamModal">
  <div class="modal" style="max-width:380px">
    <div class="modal-header">
      <div class="modal-title">Edit Team Name</div>
      <button class="modal-close" onclick="closeModal('editTeamModal')">✕</button>
    </div>
    <input type="hidden" id="et-id"/>
    <input type="hidden" id="et-p1id"/>
    <input type="hidden" id="et-p2id"/>
    <div class="form-row"><div class="form-group"><label>Team Name</label><input id="et-name" type="text"/></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editTeamModal')">Cancel</button>
      <button class="btn btn-primary" onclick="updateTeam()">Update</button>
    </div>
  </div>
</div>

<script>
  let allPlayers = [];
  let allTournaments = [];
  let takenPlayerIds = new Set(); // players already in a team for selected tournament

  const skillBadge = s => ({'PRO':'<span class="badge badge-pro">PRO</span>','INTERMEDIATE':'<span class="badge badge-intermediate">INT</span>','BEGINNER':'<span class="badge badge-beginner">BEG</span>'})[s]||s;
  const genderIcon = g => g === 'FEMALE' ? '<span style="color:#c2185b">♀</span>' : '<span style="color:#1565c0">♂</span>';
  const esc = s => String(s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");

  async function init() {
    allPlayers = await api('GET','/api/players').catch(()=>[]);
    allTournaments = await api('GET','/api/tournaments').catch(()=>[]);
    if (allPlayers.length < 2) document.getElementById('noPlayersWarn').style.display='block';

    // Populate tournament filters
    const doublesTournaments = allTournaments.filter(t => t.competitionType === 'DOUBLES');
    const selT = document.getElementById('sel-tournament');
    const tmT  = document.getElementById('tm-tournament');
    const opts = doublesTournaments.map(t => '<option value="'+t.id+'" data-doubles-type="'+(t.doublesType||'')+'">'+ t.name+' ('+t.sportType+' '+t.competitionType+')</option>').join('');
    selT.innerHTML = '<option value="">All Teams (global)</option>' + opts;
    tmT.innerHTML  = '<option value="">— No tournament (global team) —</option>' + opts;

    await loadTeams();
  }

  async function loadTeams() {
    const tournamentId = document.getElementById('sel-tournament').value;
    try {
      const teams = tournamentId
        ? await api('GET', '/api/teams/tournament/'+tournamentId)
        : await api('GET', '/api/teams');
      renderTeams(teams);
    } catch(e) { showToast(e.message,'error'); }
  }

  function renderTeams(teams) {
    const area = document.getElementById('teamsArea');
    if (!teams.length) {
      area.innerHTML='<div class="empty"><div class="empty-icon">🤝</div><p>No teams yet. Create the first team for a Doubles tournament.</p></div>';
      return;
    }
    area.innerHTML = teams.map(t =>
      '<div class="team-card">' +
        '<div>' +
          '<div style="font-weight:700;font-size:1rem;margin-bottom:.4rem">'+t.name+'</div>' +
          '<div style="display:flex;align-items:center;gap:.5rem;flex-wrap:wrap">' +
            '<span class="player-chip">'+genderIcon(t.player1.gender)+' '+t.player1.name+'</span>' +
            skillBadge(t.player1.skillLevel) +
            '<span style="color:var(--muted)">&amp;</span>' +
            '<span class="player-chip">'+genderIcon(t.player2.gender)+' '+t.player2.name+'</span>' +
            skillBadge(t.player2.skillLevel) +
          '</div>' +
          (t.tournamentId ? '<div class="text-muted" style="font-size:.75rem;margin-top:.3rem">Tournament ID #'+t.tournamentId+'</div>' : '') +
        '</div>' +
        '<div style="display:flex;align-items:center;gap:1.2rem;flex-wrap:wrap">' +
          '<div style="display:flex;gap:1.2rem">' +
            '<div class="stat-cell"><div class="val">'+t.totalScore+'</div><div class="lbl">Score</div></div>' +
            '<div class="stat-cell"><div class="val">'+t.matchesWon+'</div><div class="lbl">Won</div></div>' +
            '<div class="stat-cell"><div class="val">'+t.matchesPlayed+'</div><div class="lbl">Played</div></div>' +
          '</div>' +
          '<div class="flex gap-1">' +
            '<button class="btn btn-secondary btn-sm" onclick="editTeam('+t.id+',\''+esc(t.name)+'\','+t.player1.id+','+t.player2.id+')">Edit</button>' +
            '<button class="btn btn-danger btn-sm" onclick="deleteTeam('+t.id+')">Delete</button>' +
          '</div>' +
        '</div>' +
      '</div>'
    ).join('');
  }

  async function onTournamentSelected() {
    const sel = document.getElementById('tm-tournament');
    const id  = sel.value;
    const opt = sel.options[sel.selectedIndex];
    const doublesType = opt.dataset.doublesType || '';

    document.getElementById('mixed-warn').style.display = doublesType==='MIXED' ? 'block' : 'none';
    document.getElementById('conflict-warn').style.display = 'none';

    takenPlayerIds = new Set();
    if (id) {
      const existingTeams = await api('GET','/api/teams/tournament/'+id).catch(()=>[]);
      existingTeams.forEach(t => { takenPlayerIds.add(t.player1.id); takenPlayerIds.add(t.player2.id); });
    }
    renderPlayerPickers(doublesType);
  }

  async function openAddTeam() {
    if (allPlayers.length < 2) { showToast('Add at least 2 players first','error'); return; }
    document.getElementById('tm-name').value='';
    document.getElementById('tm-tournament').value='';
    document.getElementById('mixed-warn').style.display='none';
    document.getElementById('conflict-warn').style.display='none';
    takenPlayerIds = new Set();
    renderPlayerPickers('');
    openModal('addTeamModal');
  }

  function renderPlayerPickers(doublesType) {
    const isMixed = doublesType === 'MIXED';
    // For mixed: p1 = male, p2 = female
    const p1Candidates = isMixed
      ? allPlayers.filter(p => p.gender==='MALE'   && !takenPlayerIds.has(p.id))
      : allPlayers.filter(p => !takenPlayerIds.has(p.id));
    const p2Candidates = isMixed
      ? allPlayers.filter(p => p.gender==='FEMALE' && !takenPlayerIds.has(p.id))
      : allPlayers.filter(p => !takenPlayerIds.has(p.id));

    renderGrid('p1-grid','p1-sel', p1Candidates);
    renderGrid('p2-grid','p2-sel', p2Candidates);
  }

  function renderGrid(containerId, radioName, players) {
    document.getElementById(containerId).innerHTML = players.length === 0
      ? '<div class="text-muted" style="font-size:.83rem;padding:.5rem">No eligible players</div>'
      : players.map(p =>
          '<label style="display:flex;align-items:center;gap:.45rem;background:var(--ivory);border:1.5px solid var(--border);border-radius:var(--radius);padding:.4rem .8rem;cursor:pointer;font-size:.84rem;font-weight:500" ' +
          'onmouseover="this.style.borderColor=\'var(--gold)\'" onmouseout="this.style.borderColor=\'var(--border)\'">' +
            '<input type="radio" name="'+radioName+'" value="'+p.id+'" style="accent-color:var(--gold)" onchange="onPickerChange()"/> ' +
            genderIcon(p.gender)+' '+p.name+' '+skillBadge(p.skillLevel) +
          '</label>'
        ).join('');
  }

  function onPickerChange() {
    const p1 = getSelected('p1-sel'), p2 = getSelected('p2-sel');
    const warn = document.getElementById('conflict-warn');
    if (p1 && p2 && p1===p2) {
      warn.style.display='block'; warn.textContent='⚠️ Both players are the same. Please pick different players.';
    } else { warn.style.display='none'; }
  }

  function getSelected(name) {
    const el = document.querySelector('input[name="'+name+'"]:checked');
    return el ? el.value : null;
  }

  async function saveTeam() {
    const name = document.getElementById('tm-name').value.trim();
    const p1Id = getSelected('p1-sel');
    const p2Id = getSelected('p2-sel');
    const tId  = document.getElementById('tm-tournament').value || null;

    if (!name)  { showToast('Team name is required','error'); return; }
    if (!p1Id)  { showToast('Select Player 1','error'); return; }
    if (!p2Id)  { showToast('Select Player 2','error'); return; }
    if (p1Id===p2Id) { showToast('Players must be different','error'); return; }

    try {
      await api('POST','/api/teams', { name, player1Id:parseInt(p1Id), player2Id:parseInt(p2Id), tournamentId: tId ? parseInt(tId) : null });
      showToast('Team created!','success');
      closeModal('addTeamModal');
      init();
    } catch(e) { showToast(e.message,'error'); }
  }

  function editTeam(id,name,p1id,p2id) {
    document.getElementById('et-id').value=id;
    document.getElementById('et-name').value=name;
    document.getElementById('et-p1id').value=p1id;
    document.getElementById('et-p2id').value=p2id;
    openModal('editTeamModal');
  }

  async function updateTeam() {
    const id=document.getElementById('et-id').value, name=document.getElementById('et-name').value.trim();
    if (!name) { showToast('Name required','error'); return; }
    try {
      await api('PUT','/api/teams/'+id, { name, player1Id:parseInt(document.getElementById('et-p1id').value), player2Id:parseInt(document.getElementById('et-p2id').value) });
      showToast('Team updated!','success'); closeModal('editTeamModal'); loadTeams();
    } catch(e) { showToast(e.message,'error'); }
  }

  async function deleteTeam(id) {
    if (!confirm('Delete this team?')) return;
    try { await api('DELETE','/api/teams/'+id); showToast('Deleted','info'); loadTeams(); }
    catch(e) { showToast(e.message,'error'); }
  }

  init();
</script>
</body></html>
