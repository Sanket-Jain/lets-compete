<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<c:set var="pageTitle" value="Teams"/>
<%@ include file="layout/header.jsp" %>

<div class="page-wrap">
  <div class="page-header">
    <h1>MANAGE <span>TEAMS</span></h1>
    <p>Form doubles teams by pairing two players together.</p>
  </div>

  <div class="grid-2" style="gap:2rem; align-items:start;">

    <!-- Form -->
    <div class="card" id="formCard">
      <div class="card-title" id="formTitle">CREATE TEAM</div>
      <input type="hidden" id="editId"/>
      <div class="form-group">
        <label>Team Name</label>
        <input type="text" id="fName" placeholder="e.g. Thunder Duo"/>
      </div>
      <div class="form-group">
        <label>Player 1</label>
        <select id="fP1"><option value="">— Select Player —</option></select>
      </div>
      <div class="form-group">
        <label>Player 2</label>
        <select id="fP2"><option value="">— Select Player —</option></select>
      </div>
      <div style="display:flex;gap:.8rem;">
        <button class="btn btn-primary" onclick="saveTeam()">Save Team</button>
        <button class="btn btn-outline" onclick="resetForm()" id="cancelBtn" style="display:none">Cancel</button>
      </div>
    </div>

    <!-- Team list -->
    <div class="card">
      <div class="card-title">ALL TEAMS</div>
      <div id="teamList"><div class="empty-state"><div class="icon">👥</div><p>Loading teams...</p></div></div>
    </div>

  </div>
</div>

<script>
let teams = [], players = [];

async function init() {
  [teams, players] = await Promise.all([API.get('/api/teams'), API.get('/api/players')]);
  populatePlayerSelects();
  renderTeams();
}

function populatePlayerSelects() {
  const opts = players.map(p => `<option value="${p.id}">${p.name} (${p.skillLevel})</option>`).join('');
  ['fP1','fP2'].forEach(id => {
    const el = document.getElementById(id);
    el.innerHTML = '<option value="">— Select Player —</option>' + opts;
  });
}

function renderTeams() {
  const el = document.getElementById('teamList');
  if (!teams.length) {
    el.innerHTML = '<div class="empty-state"><div class="icon">👥</div><p>No teams yet. Create one!</p></div>';
    return;
  }
  el.innerHTML = `
    <div class="table-wrap">
    <table>
      <thead><tr><th>Team</th><th>Players</th><th>Score</th><th>W/P</th><th></th></tr></thead>
      <tbody>${teams.map(t => `
        <tr>
          <td><strong>${t.name}</strong></td>
          <td style="font-size:.85rem">
            <div>${t.player1.name} ${skillBadge(t.player1.skillLevel)}</div>
            <div>${t.player2.name} ${skillBadge(t.player2.skillLevel)}</div>
          </td>
          <td><strong style="color:var(--accent)">${t.totalScore}</strong></td>
          <td style="font-size:.82rem;color:var(--text-secondary)">${t.matchesWon}/${t.matchesPlayed}</td>
          <td>
            <button class="btn btn-outline btn-sm" onclick="editTeam(${t.id})">Edit</button>
            <button class="btn btn-danger btn-sm" onclick="deleteTeam(${t.id},'${t.name}')">Del</button>
          </td>
        </tr>`).join('')}
      </tbody>
    </table>
    </div>`;
}

async function saveTeam() {
  const id   = document.getElementById('editId').value;
  const name = document.getElementById('fName').value.trim();
  const p1   = document.getElementById('fP1').value;
  const p2   = document.getElementById('fP2').value;
  if (!name || !p1 || !p2) { showToast('All fields are required', 'error'); return; }
  if (p1 === p2) { showToast('Players must be different', 'error'); return; }
  const body = { name, player1Id: parseInt(p1), player2Id: parseInt(p2) };
  try {
    if (id) { await API.put('/api/teams/' + id, body); showToast('Team updated!', 'success'); }
    else    { await API.post('/api/teams', body);       showToast('Team created!', 'success'); }
    resetForm(); init();
  } catch(e) { showToast(e.message, 'error'); }
}

function editTeam(id) {
  const t = teams.find(x => x.id === id);
  document.getElementById('editId').value = id;
  document.getElementById('fName').value = t.name;
  document.getElementById('fP1').value = t.player1Id;
  document.getElementById('fP2').value = t.player2Id;
  document.getElementById('formTitle').textContent = 'EDIT TEAM';
  document.getElementById('cancelBtn').style.display = '';
}

function deleteTeam(id, name) {
  confirmAction('Delete Team', `Remove team "${name}"?`, async () => {
    try { await API.del('/api/teams/' + id); showToast('Team deleted.', 'success'); init(); }
    catch(e) { showToast(e.message, 'error'); }
  });
}

function resetForm() {
  ['editId','fName'].forEach(i => document.getElementById(i).value = '');
  document.getElementById('fP1').value = '';
  document.getElementById('fP2').value = '';
  document.getElementById('formTitle').textContent = 'CREATE TEAM';
  document.getElementById('cancelBtn').style.display = 'none';
}

init();
</script>

<%@ include file="layout/footer.jsp" %>
