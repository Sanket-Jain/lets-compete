<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<div class="page">
  <div class="section-header">
    <div class="section-title">Tournaments</div>
    <button class="btn btn-primary" onclick="openModal('addTModal')">+ New Tournament</button>
  </div>

  <div class="card">
    <div class="table-wrap">
      <table>
        <thead><tr><th>#</th><th>Name</th><th>Type</th><th>Level</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody id="tBody"><tr><td colspan="6"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></td></tr></tbody>
      </table>
    </div>
  </div>
</div>

<!-- Add Tournament Modal -->
<div class="modal-overlay" id="addTModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">New Tournament</div>
      <button class="modal-close" onclick="closeModal('addTModal')">✕</button>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Tournament Name</label><input id="t-name" type="text" placeholder="e.g. Club Championship 2025"/></div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Competition Type</label>
        <select id="t-type">
          <option value="SINGLES">Singles</option>
          <option value="DOUBLES">Doubles</option>
        </select>
      </div>
      <div class="form-group">
        <label>Total Levels</label>
        <input id="t-levels" type="number" value="3" min="1" max="10"/>
      </div>
    </div>
    <div class="form-row"><div class="form-group"><label>Description</label><textarea id="t-desc" placeholder="Optional description…"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addTModal')">Cancel</button>
      <button class="btn btn-primary" onclick="saveTournament()">Create</button>
    </div>
  </div>
</div>

<!-- Edit Tournament Modal -->
<div class="modal-overlay" id="editTModal">
  <div class="modal">
    <div class="modal-header">
      <div class="modal-title">Edit Tournament</div>
      <button class="modal-close" onclick="closeModal('editTModal')">✕</button>
    </div>
    <input type="hidden" id="et-id"/>
    <div class="form-row"><div class="form-group"><label>Tournament Name</label><input id="et-name" type="text"/></div></div>
    <div class="form-row">
      <div class="form-group"><label>Total Levels</label><input id="et-levels" type="number" min="1" max="10"/></div>
      <div class="form-group">
        <label>Active</label>
        <select id="et-active"><option value="true">Active</option><option value="false">Inactive</option></select>
      </div>
    </div>
    <div class="form-row"><div class="form-group"><label>Description</label><textarea id="et-desc"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editTModal')">Cancel</button>
      <button class="btn btn-primary" onclick="updateTournament()">Update</button>
    </div>
  </div>
</div>

<script>
  const typeBadge = t => t==='SINGLES' ? '<span class="badge badge-singles">SINGLES</span>' : '<span class="badge badge-doubles">DOUBLES</span>';
  const esc = s => String(s).replace(/\\/g,'\\\\').replace(/'/g,"\\'");

  async function loadTournaments(){
    try{
      const ts = await api('GET','/api/tournaments');
      const tb = document.getElementById('tBody');
      if(!ts.length){ tb.innerHTML='<tr><td colspan="6"><div class="empty"><div class="empty-icon">🏆</div><p>No tournaments yet.</p></div></td></tr>'; return; }
      tb.innerHTML = ts.map((t,i)=>`<tr>
        <td class="text-muted">${i+1}</td>
        <td><strong>${t.name}</strong><br><span class="text-muted" style="font-size:.78rem">${t.description||''}</span></td>
        <td>${typeBadge(t.competitionType)}</td>
        <td>Level <strong>${t.currentLevel}</strong> / ${t.totalLevels||'?'}</td>
        <td><span class="badge ${t.isActive?'badge-completed':'badge-scheduled'}">${t.isActive?'Active':'Closed'}</span></td>
        <td><div class="flex gap-1">
          <button class="btn btn-secondary btn-sm" onclick="editT(${t.id},'${esc(t.name)}',${t.totalLevels||3},'${esc(t.description||'')}',${t.isActive})">Edit</button>
          <button class="btn btn-danger btn-sm" onclick="delT(${t.id})">Delete</button>
        </div></td></tr>`).join('');
    }catch(e){showToast(e.message,'error');}
  }

  async function saveTournament(){
    const name=document.getElementById('t-name').value.trim();
    if(!name){showToast('Name required','error');return;}
    try{
      await api('POST','/api/tournaments',{
        name, competitionType:document.getElementById('t-type').value,
        totalLevels:parseInt(document.getElementById('t-levels').value)||3,
        description:document.getElementById('t-desc').value
      });
      showToast('Tournament created!','success'); closeModal('addTModal');
      document.getElementById('t-name').value=''; document.getElementById('t-desc').value='';
      loadTournaments();
    }catch(e){showToast(e.message,'error');}
  }

  function editT(id,name,levels,desc,active){
    document.getElementById('et-id').value=id; document.getElementById('et-name').value=name;
    document.getElementById('et-levels').value=levels; document.getElementById('et-desc').value=desc;
    document.getElementById('et-active').value=String(active);
    openModal('editTModal');
  }

  async function updateTournament(){
    const id=document.getElementById('et-id').value;
    const name=document.getElementById('et-name').value.trim();
    if(!name){showToast('Name required','error');return;}
    try{
      await api('PUT',`/api/tournaments/${id}`,{
        name, totalLevels:parseInt(document.getElementById('et-levels').value)||3,
        description:document.getElementById('et-desc').value,
        isActive:document.getElementById('et-active').value==='true'
      });
      showToast('Updated!','success'); closeModal('editTModal'); loadTournaments();
    }catch(e){showToast(e.message,'error');}
  }

  async function delT(id){
    if(!confirm('Delete this tournament and all its fixtures?'))return;
    try{ await api('DELETE',`/api/tournaments/${id}`); showToast('Deleted','info'); loadTournaments(); }
    catch(e){showToast(e.message,'error');}
  }

  loadTournaments();
</script>
</body></html>
