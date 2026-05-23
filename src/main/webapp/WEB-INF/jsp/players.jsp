<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<div class="page">
  <div class="section-header">
    <div class="section-title">Players</div>
    <button class="btn btn-primary" onclick="openModal('addPlayerModal')">+ Add Player</button>
  </div>

  <div class="card">
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>#</th><th>Name</th><th>Gender</th><th>Skill Level</th><th>Achievements</th><th>Score</th><th>W / P</th><th>Actions</th></tr>
        </thead>
        <tbody id="playersBody">
          <tr><td colspan="8"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- Add Modal -->
<div class="modal-overlay" id="addPlayerModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Add Player</div>
      <button class="modal-close" onclick="closeModal('addPlayerModal')">✕</button>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Full Name</label><input id="p-name" type="text" placeholder="e.g. Rahul Sharma"/></div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Gender</label>
        <select id="p-gender">
          <option value="MALE">Male</option>
          <option value="FEMALE">Female</option>
        </select>
      </div>
      <div class="form-group">
        <label>Skill Level</label>
        <select id="p-skill">
          <option value="BEGINNER">Beginner</option>
          <option value="INTERMEDIATE">Intermediate</option>
          <option value="PRO">Pro</option>
        </select>
      </div>
    </div>
    <div class="form-row"><div class="form-group"><label>Achievements</label><textarea id="p-ach" placeholder="e.g. State champion 2023"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addPlayerModal')">Cancel</button>
      <button class="btn btn-primary" onclick="savePlayer()">Save</button>
    </div>
  </div>
</div>

<!-- Edit Modal -->
<div class="modal-overlay" id="editPlayerModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Edit Player</div>
      <button class="modal-close" onclick="closeModal('editPlayerModal')">✕</button>
    </div>
    <input type="hidden" id="ep-id"/>
    <div class="form-row">
      <div class="form-group"><label>Full Name</label><input id="ep-name" type="text"/></div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Gender</label>
        <select id="ep-gender">
          <option value="MALE">Male</option>
          <option value="FEMALE">Female</option>
        </select>
      </div>
      <div class="form-group">
        <label>Skill Level</label>
        <select id="ep-skill">
          <option value="BEGINNER">Beginner</option>
          <option value="INTERMEDIATE">Intermediate</option>
          <option value="PRO">Pro</option>
        </select>
      </div>
    </div>
    <div class="form-row"><div class="form-group"><label>Achievements</label><textarea id="ep-ach"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editPlayerModal')">Cancel</button>
      <button class="btn btn-primary" onclick="updatePlayer()">Update</button>
    </div>
  </div>
</div>

<script>
  const skillBadge = s => ({'PRO':'<span class="badge badge-pro">PRO</span>','INTERMEDIATE':'<span class="badge badge-intermediate">INT</span>','BEGINNER':'<span class="badge badge-beginner">BEG</span>'})[s]||s;
  const genderIcon = g => g === 'FEMALE' ? '♀' : '♂';
  const esc = s => String(s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");

  async function loadPlayers() {
    try {
      const ps = await api('GET','/api/players');
      const tb = document.getElementById('playersBody');
      if (!ps.length) { tb.innerHTML='<tr><td colspan="8"><div class="empty"><div class="empty-icon">👤</div><p>No players yet.</p></div></td></tr>'; return; }
      tb.innerHTML = ps.map((p,i) => '<tr>' +
        '<td class="text-muted">'+(i+1)+'</td>' +
        '<td><strong>'+p.name+'</strong></td>' +
        '<td style="font-size:1.1rem">'+genderIcon(p.gender)+'</td>' +
        '<td>'+skillBadge(p.skillLevel)+'</td>' +
        '<td class="text-muted" style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">'+(p.achievements||'—')+'</td>' +
        '<td><strong style="color:var(--gold)">'+p.totalScore+'</strong></td>' +
        '<td class="text-muted">'+p.matchesWon+'/'+p.matchesPlayed+'</td>' +
        '<td><div class="flex gap-1">' +
          '<button class="btn btn-secondary btn-sm" onclick="editPlayer('+p.id+',\''+esc(p.name)+'\',\''+p.gender+'\',\''+p.skillLevel+'\',\''+esc(p.achievements||'')+'\')">Edit</button>' +
          '<button class="btn btn-danger btn-sm" onclick="delPlayer('+p.id+')">Delete</button>' +
        '</div></td></tr>').join('');
    } catch(e) { showToast(e.message,'error'); }
  }

  async function savePlayer() {
    const name = document.getElementById('p-name').value.trim();
    if (!name) { showToast('Name required','error'); return; }
    try {
      await api('POST','/api/players',{name, gender:document.getElementById('p-gender').value, skillLevel:document.getElementById('p-skill').value, achievements:document.getElementById('p-ach').value});
      showToast('Player added!','success'); closeModal('addPlayerModal');
      document.getElementById('p-name').value=''; document.getElementById('p-ach').value='';
      loadPlayers();
    } catch(e) { showToast(e.message,'error'); }
  }

  function editPlayer(id,name,gender,skill,ach) {
    document.getElementById('ep-id').value=id; document.getElementById('ep-name').value=name;
    document.getElementById('ep-gender').value=gender; document.getElementById('ep-skill').value=skill;
    document.getElementById('ep-ach').value=ach; openModal('editPlayerModal');
  }

  async function updatePlayer() {
    const id=document.getElementById('ep-id').value, name=document.getElementById('ep-name').value.trim();
    if (!name) { showToast('Name required','error'); return; }
    try {
      await api('PUT','/api/players/'+id,{name, gender:document.getElementById('ep-gender').value, skillLevel:document.getElementById('ep-skill').value, achievements:document.getElementById('ep-ach').value});
      showToast('Updated!','success'); closeModal('editPlayerModal'); loadPlayers();
    } catch(e) { showToast(e.message,'error'); }
  }

  async function delPlayer(id) {
    if (!confirm('Delete this player?')) return;
    try { await api('DELETE','/api/players/'+id); showToast('Deleted','info'); loadPlayers(); }
    catch(e) { showToast(e.message,'error'); }
  }

  loadPlayers();
</script>
</body></html>
