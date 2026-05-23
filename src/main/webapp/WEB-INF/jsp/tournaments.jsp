<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .sport-icon { font-size:1.3rem; vertical-align:middle; margin-right:.3rem; }
  .chess-time-row { display:flex; gap:.5rem; align-items:center; margin-bottom:.5rem; flex-wrap:wrap; }
  .chess-time-row label { min-width:65px; font-size:.82rem; color:var(--muted); }
  .chess-time-row input { width:90px; }
  #chessConfig { display:none; background:#f9f6ef; border:1px solid var(--border); border-radius:var(--radius); padding:1rem; margin-top:.8rem; }
  #doublesTypeRow { display:none; }
  #chessOnlyInfo { display:none; background:#e8f4fd; border:1px solid #bee3f8; border-radius:var(--radius); padding:.6rem 1rem; font-size:.83rem; color:#1a4a6e; margin-top:.5rem; }
</style>

<div class="page">
  <div class="section-header">
    <div class="section-title">Tournaments</div>
    <button class="btn btn-primary" onclick="openModal('addTModal')">+ New Tournament</button>
  </div>

  <div class="card">
    <div class="table-wrap">
      <table>
        <thead><tr><th>#</th><th>Name</th><th>Sport</th><th>Type</th><th>Level</th><th>Status</th><th>Actions</th></tr></thead>
        <tbody id="tBody"><tr><td colspan="7"><div class="empty"><div class="empty-icon">⏳</div><p>Loading…</p></div></td></tr></tbody>
      </table>
    </div>
  </div>
</div>

<!-- Add Tournament Modal -->
<div class="modal-overlay" id="addTModal">
  <div class="modal" style="max-width:560px">
    <div class="modal-header">
      <div class="modal-title">New Tournament</div>
      <button class="modal-close" onclick="closeModal('addTModal')">✕</button>
    </div>
    <div class="form-row">
      <div class="form-group"><label>Tournament Name</label><input id="t-name" type="text" placeholder="e.g. Club Championship 2025"/></div>
    </div>
    <div class="form-row">
      <div class="form-group">
        <label>Sport</label>
        <select id="t-sport" onchange="onSportChange()">
          <option value="CARROM">🎯 Carrom</option>
          <option value="CHESS">♟️ Chess</option>
          <option value="BADMINTON">🏸 Badminton</option>
        </select>
      </div>
      <div class="form-group">
        <label>Competition Type</label>
        <select id="t-type" onchange="onTypeChange()">
          <option value="SINGLES">Singles</option>
          <option value="DOUBLES">Doubles</option>
        </select>
      </div>
    </div>

    <div id="chessOnlyInfo">♟️ Chess is Singles only — only individual matches are supported.</div>

    <div class="form-row" id="doublesTypeRow">
      <div class="form-group">
        <label>Doubles Format</label>
        <select id="t-doubles-type">
          <option value="SAME_GENDER">Same Gender</option>
          <option value="MIXED">Mixed (1 Male + 1 Female)</option>
        </select>
      </div>
    </div>

    <div class="form-row">
      <div class="form-group">
        <label>Total Levels</label>
        <input id="t-levels" type="number" value="3" min="1" max="10"/>
      </div>
    </div>

    <!-- Chess time config -->
    <div id="chessConfig">
      <div style="font-weight:600;font-size:.88rem;margin-bottom:.7rem;color:var(--slate)">
        ♟️ Time Limit per Level (minutes per player)
      </div>
      <p class="text-muted" style="font-size:.8rem;margin-bottom:.8rem">Set how many minutes each player gets per level. Leave blank to use no time limit.</p>
      <div id="chessTimeLevels"></div>
    </div>

    <div class="form-row" style="margin-top:.8rem"><div class="form-group"><label>Description</label><textarea id="t-desc" placeholder="Optional…"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('addTModal')">Cancel</button>
      <button class="btn btn-primary" onclick="saveTournament()">Create</button>
    </div>
  </div>
</div>

<!-- Edit Tournament Modal -->
<div class="modal-overlay" id="editTModal">
  <div class="modal" style="max-width:480px">
    <div class="modal-header">
      <div class="modal-title">Edit Tournament</div>
      <button class="modal-close" onclick="closeModal('editTModal')">✕</button>
    </div>
    <input type="hidden" id="et-id"/>
    <input type="hidden" id="et-sport"/>
    <div class="form-row"><div class="form-group"><label>Tournament Name</label><input id="et-name" type="text"/></div></div>
    <div class="form-row">
      <div class="form-group"><label>Total Levels</label><input id="et-levels" type="number" min="1" max="10"/></div>
      <div class="form-group">
        <label>Status</label>
        <select id="et-active"><option value="true">Active</option><option value="false">Inactive</option></select>
      </div>
    </div>
    <div id="et-chessConfig" style="display:none;background:#f9f6ef;border:1px solid var(--border);border-radius:var(--radius);padding:1rem;margin-bottom:.8rem">
      <div style="font-weight:600;font-size:.88rem;margin-bottom:.7rem">♟️ Time Limit per Level (minutes)</div>
      <div id="et-chessTimeLevels"></div>
    </div>
    <div class="form-row"><div class="form-group"><label>Description</label><textarea id="et-desc"></textarea></div></div>
    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('editTModal')">Cancel</button>
      <button class="btn btn-primary" onclick="updateTournament()">Update</button>
    </div>
  </div>
</div>

<script>
  const sportIcon = s => ({'CARROM':'🎯','CHESS':'♟️','BADMINTON':'🏸'})[s]||'🏅';
  const typeBadge = t => t==='SINGLES'?'<span class="badge badge-singles">SINGLES</span>':'<span class="badge badge-doubles">DOUBLES</span>';
  const esc = s => String(s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");

  function onSportChange() {
    const sport = document.getElementById('t-sport').value;
    const typeEl = document.getElementById('t-type');
    const chessInfo = document.getElementById('chessOnlyInfo');

    if (sport === 'CHESS') {
      typeEl.value = 'SINGLES'; typeEl.disabled = true;
      chessInfo.style.display = 'block';
      document.getElementById('doublesTypeRow').style.display = 'none';
    } else {
      typeEl.disabled = false;
      chessInfo.style.display = 'none';
    }
    onTypeChange();
    buildChessTimeLevels('chessTimeLevels', parseInt(document.getElementById('t-levels').value)||3);
    document.getElementById('chessConfig').style.display = (sport==='CHESS') ? 'block' : 'none';
  }

  function onTypeChange() {
    const sport = document.getElementById('t-sport').value;
    const type  = document.getElementById('t-type').value;
    const show  = (sport === 'BADMINTON' && type === 'DOUBLES') || (sport === 'CARROM' && type === 'DOUBLES');
    document.getElementById('doublesTypeRow').style.display = show ? 'flex' : 'none';
    // Carrom doubles doesn't have MIXED, hide that option
    const dtSel = document.getElementById('t-doubles-type');
    if (sport === 'CARROM') {
      dtSel.innerHTML = '<option value="SAME_GENDER">Same Gender</option>';
    } else {
      dtSel.innerHTML = '<option value="SAME_GENDER">Same Gender</option><option value="MIXED">Mixed (1 Male + 1 Female)</option>';
    }
  }

  function buildChessTimeLevels(containerId, levels) {
    const container = document.getElementById(containerId);
    let html = '';
    for (let i = 1; i <= levels; i++) {
      html += '<div class="chess-time-row">' +
        '<label>Level '+i+'</label>' +
        '<input type="number" id="chess-time-'+containerId+'-'+i+'" min="1" max="180" placeholder="minutes"/>' +
        '<span class="text-muted" style="font-size:.78rem">min/player</span>' +
      '</div>';
    }
    container.innerHTML = html;
  }

  function getChessTimeLimits(prefix, levels) {
    const result = {};
    for (let i = 1; i <= levels; i++) {
      const val = parseInt(document.getElementById('chess-time-'+prefix+'-'+i)?.value);
      if (!isNaN(val) && val > 0) result[String(i)] = val;
    }
    return Object.keys(result).length ? result : null;
  }

  async function loadTournaments() {
    try {
      const ts = await api('GET','/api/tournaments');
      const tb = document.getElementById('tBody');
      if (!ts.length) { tb.innerHTML='<tr><td colspan="7"><div class="empty"><div class="empty-icon">🏆</div><p>No tournaments yet.</p></div></td></tr>'; return; }
      tb.innerHTML = ts.map((t,i) => {
        const doublesLabel = t.doublesType ? ' ('+t.doublesType.replace('_',' ')+')' : '';
        return '<tr>' +
          '<td class="text-muted">'+(i+1)+'</td>' +
          '<td><strong>'+t.name+'</strong><br><span class="text-muted" style="font-size:.75rem">'+(t.description||'')+'</span></td>' +
          '<td>'+sportIcon(t.sportType)+' '+t.sportType+'</td>' +
          '<td>'+typeBadge(t.competitionType)+doublesLabel+'</td>' +
          '<td>Level <strong>'+t.currentLevel+'</strong> / '+(t.totalLevels||'?')+'</td>' +
          '<td><span class="badge '+(t.isActive?'badge-completed':'badge-scheduled')+'">'+(t.isActive?'Active':'Closed')+'</span></td>' +
          '<td><div class="flex gap-1">' +
            '<button class="btn btn-secondary btn-sm" onclick="editT('+t.id+',\''+esc(t.name)+'\','+(t.totalLevels||3)+',\''+esc(t.description||'')+'\','+t.isActive+',\''+t.sportType+'\')">Edit</button>' +
            '<button class="btn btn-danger btn-sm" onclick="delT('+t.id+')">Delete</button>' +
          '</div></td></tr>';
      }).join('');
    } catch(e) { showToast(e.message,'error'); }
  }

  async function saveTournament() {
    const name = document.getElementById('t-name').value.trim();
    if (!name) { showToast('Name required','error'); return; }
    const sport  = document.getElementById('t-sport').value;
    const type   = document.getElementById('t-type').value;
    const levels = parseInt(document.getElementById('t-levels').value)||3;
    const needsDoublesType = (sport==='BADMINTON'||sport==='CARROM') && type==='DOUBLES';
    const doublesType = needsDoublesType ? document.getElementById('t-doubles-type').value : null;
    const chessTimeLimits = sport==='CHESS' ? getChessTimeLimits('chessTimeLevels', levels) : null;

    try {
      await api('POST','/api/tournaments',{
        name, sportType:sport, competitionType:type, doublesType,
        totalLevels:levels, description:document.getElementById('t-desc').value,
        chessTimeLimits
      });
      showToast('Tournament created!','success'); closeModal('addTModal');
      document.getElementById('t-name').value=''; document.getElementById('t-desc').value='';
      loadTournaments();
    } catch(e) { showToast(e.message,'error'); }
  }

  function editT(id,name,levels,desc,active,sport) {
    document.getElementById('et-id').value=id; document.getElementById('et-name').value=name;
    document.getElementById('et-levels').value=levels; document.getElementById('et-desc').value=desc;
    document.getElementById('et-active').value=String(active);
    document.getElementById('et-sport').value=sport;
    const chessDiv = document.getElementById('et-chessConfig');
    if (sport==='CHESS') {
      chessDiv.style.display='block';
      buildChessTimeLevels('et-chessTimeLevels', levels);
    } else { chessDiv.style.display='none'; }
    openModal('editTModal');
  }

  async function updateTournament() {
    const id=document.getElementById('et-id').value, name=document.getElementById('et-name').value.trim();
    if (!name) { showToast('Name required','error'); return; }
    const levels=parseInt(document.getElementById('et-levels').value)||3;
    const sport=document.getElementById('et-sport').value;
    const chessTimeLimits = sport==='CHESS' ? getChessTimeLimits('et-chessTimeLevels', levels) : null;
    try {
      await api('PUT','/api/tournaments/'+id,{
        name, totalLevels:levels, description:document.getElementById('et-desc').value,
        isActive:document.getElementById('et-active').value==='true', chessTimeLimits
      });
      showToast('Updated!','success'); closeModal('editTModal'); loadTournaments();
    } catch(e) { showToast(e.message,'error'); }
  }

  async function delT(id) {
    if (!confirm('Delete this tournament and all its fixtures?')) return;
    try { await api('DELETE','/api/tournaments/'+id); showToast('Deleted','info'); loadTournaments(); }
    catch(e) { showToast(e.message,'error'); }
  }

  // Init chess time builder when levels change
  document.getElementById('t-levels').addEventListener('change', () => {
    if (document.getElementById('t-sport').value==='CHESS')
      buildChessTimeLevels('chessTimeLevels', parseInt(document.getElementById('t-levels').value)||3);
  });

  loadTournaments();
</script>
</body></html>
