<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .fixture-card {
    background:#fff; border:1px solid var(--border); border-radius:var(--radius);
    padding:1.2rem 1.4rem; margin-bottom:.8rem;
    display:flex; align-items:center; justify-content:space-between; flex-wrap:wrap; gap:1rem;
  }
  .fixture-card.completed { border-left:4px solid var(--success); }
  .fixture-card.scheduled { border-left:4px solid var(--gold); }
  .match-players { display:flex; align-items:center; gap:1rem; font-weight:600; font-size:1rem; }
  .vs { color:var(--muted); font-size:.8rem; font-weight:400; }
  .match-score { font-family:'Bebas Neue',sans-serif; font-size:1.8rem; letter-spacing:.05em; color:var(--slate); }
  .winner-tag { font-size:.72rem; color:var(--success); font-weight:700; text-transform:uppercase; }
  .level-header {
    font-family:'Bebas Neue',sans-serif; font-size:1.1rem; letter-spacing:.1em;
    color:var(--gold); background:var(--slate); padding:.4rem 1rem;
    border-radius:var(--radius); margin-bottom:.8rem; display:inline-block;
  }
  .controls-bar {
    background:#fff; border:1px solid var(--border); border-radius:var(--radius);
    padding:1.2rem 1.4rem; margin-bottom:1.4rem;
    display:flex; gap:1rem; align-items:flex-end; flex-wrap:wrap;
  }
</style>

<div class="page">
  <div class="section-title" style="margin-bottom:1.2rem">Fixtures</div>

  <!-- Controls -->
  <div class="controls-bar">
    <div class="form-group" style="min-width:220px">
      <label>Select Tournament</label>
      <select id="sel-tournament" onchange="onTournamentChange()">
        <option value="">— Choose a tournament —</option>
      </select>
    </div>
    <button class="btn btn-primary" id="btn-gen1" onclick="genLevel1()" disabled>Generate Level 1 (Random)</button>
    <button class="btn btn-success" id="btn-adv" onclick="advanceLevel()" disabled>Advance to Next Level</button>
  </div>

  <!-- Participant selector (for level 1 generation) -->
  <div class="card" id="participantSection" style="display:none">
    <div class="card-title" id="participantTitle">Select Participants</div>
    <div id="participantList" style="display:flex;flex-wrap:wrap;gap:.6rem;margin-bottom:1rem"></div>
    <div class="flex gap-1">
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(true)">Select All</button>
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(false)">Deselect All</button>
      <button class="btn btn-primary" onclick="confirmGenLevel1()">Generate Fixtures</button>
    </div>
  </div>

  <!-- Fixtures display -->
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
      <button class="btn btn-primary" onclick="submitResult()">Save Result</button>
    </div>
  </div>
</div>

<script>
  let currentTournament = null;
  let allParticipants   = [];

  async function loadTournaments(){
    const ts = await api('GET','/api/tournaments');
    const sel = document.getElementById('sel-tournament');
    sel.innerHTML = '<option value="">— Choose a tournament —</option>' +
      ts.map(t=>`<option value="${t.id}" data-type="${t.competitionType}">${t.name} (${t.competitionType})</option>`).join('');
  }

  async function onTournamentChange(){
    const sel = document.getElementById('sel-tournament');
    const id  = sel.value;
    if(!id){ currentTournament=null; document.getElementById('fixturesArea').innerHTML=''; hideParticipants(); return; }
    const opt = sel.options[sel.selectedIndex];
    currentTournament = { id, type: opt.dataset.type };
    document.getElementById('btn-gen1').disabled = false;
    await loadFixtures();
  }

  async function loadFixtures(){
    if(!currentTournament) return;
    try{
      const fixtures = await api('GET',`/api/fixtures/tournament/${currentTournament.id}`);
      renderFixtures(fixtures);
      // Enable advance if all current-level matches done
      const pending = fixtures.filter(f=>f.status!=='COMPLETED');
      document.getElementById('btn-adv').disabled = (fixtures.length===0 || pending.length>0);
    }catch(e){ showToast(e.message,'error'); }
  }

  function renderFixtures(fixtures){
    const area = document.getElementById('fixturesArea');
    if(!fixtures.length){
      area.innerHTML='<div class="empty"><div class="empty-icon">📋</div><p>No fixtures yet. Generate Level 1 to begin.</p></div>';
      return;
    }
    // Group by level
    const levels = {};
    fixtures.forEach(f=>{ if(!levels[f.levelNumber]) levels[f.levelNumber]=[]; levels[f.levelNumber].push(f); });
    area.innerHTML = Object.entries(levels).map(([lvl,fxs])=>`
      <div style="margin-bottom:1.6rem">
        <div class="level-header">🏅 Level ${lvl}</div>
        ${fxs.map(f=>renderFixtureCard(f)).join('')}
      </div>`).join('');
  }

  function renderFixtureCard(f){
    const isSingles = f.competitionType==='SINGLES';
    const p1 = isSingles ? f.player1?.name : f.team1?.name;
    const p2 = isSingles ? f.player2?.name : f.team2?.name;
    const done = f.status==='COMPLETED';
    const winnerName = isSingles ? f.winnerPlayer?.name : f.winnerTeam?.name;
    return `<div class="fixture-card ${f.status.toLowerCase()}">
      <div>
        <div class="match-players">
          <span ${winnerName===p1?'style="color:var(--success)"':''}>${p1||'TBD'}</span>
          <span class="vs">VS</span>
          <span ${winnerName===p2?'style="color:var(--success)"':''}>${p2||'TBD'}</span>
        </div>
        ${done?`<div class="match-score">${f.scoreParticipant1} — ${f.scoreParticipant2}</div>
                <div class="winner-tag">🏆 ${winnerName}</div>`:''}
      </div>
      <div class="flex gap-1" style="align-items:center">
        <span class="badge ${done?'badge-completed':'badge-scheduled'}">${f.status}</span>
        ${!done?`<button class="btn btn-primary btn-sm" onclick="openResult(${f.id},'${esc(p1)}','${esc(p2)}')">Record Result</button>`:''}
      </div>
    </div>`;
  }

  // ── Level 1 generation ──────────────────────────────────────────
  async function genLevel1(){
    if(!currentTournament){showToast('Select a tournament first','error');return;}
    const isSingles = currentTournament.type==='SINGLES';
    document.getElementById('participantTitle').textContent = isSingles ? 'Select Players' : 'Select Teams';
    document.getElementById('participantSection').style.display='block';
    // Load participants
    allParticipants = isSingles ? await api('GET','/api/players') : await api('GET','/api/teams');
    const list = document.getElementById('participantList');
    list.innerHTML = allParticipants.map(p=>`
      <label style="display:flex;align-items:center;gap:.4rem;background:#f5f0e8;padding:.4rem .8rem;border-radius:var(--radius);cursor:pointer">
        <input type="checkbox" value="${p.id}" checked/>
        ${isSingles ? p.name : p.name+' ('+p.player1.name+' & '+p.player2.name+')'}
      </label>`).join('');
  }

  function toggleAll(state){ document.querySelectorAll('#participantList input[type=checkbox]').forEach(cb=>cb.checked=state); }
  function hideParticipants(){ document.getElementById('participantSection').style.display='none'; }

  async function confirmGenLevel1(){
    const ids = [...document.querySelectorAll('#participantList input:checked')].map(cb=>parseInt(cb.value));
    if(ids.length<2){showToast('Select at least 2 participants','error');return;}
    try{
      await api('POST',`/api/fixtures/tournament/${currentTournament.id}/generate-level1`, ids);
      showToast('Level 1 fixtures generated!','success');
      hideParticipants();
      loadFixtures();
    }catch(e){showToast(e.message,'error');}
  }

  // ── Advance level ───────────────────────────────────────────────
  async function advanceLevel(){
    if(!currentTournament)return;
    try{
      await api('POST',`/api/fixtures/tournament/${currentTournament.id}/advance-level`);
      showToast('Next level fixtures generated!','success');
      loadFixtures();
    }catch(e){showToast(e.message,'error');}
  }

  // ── Record result ───────────────────────────────────────────────
  function openResult(id,p1,p2){
    document.getElementById('r-id').value=id;
    document.getElementById('r-matchLabel').textContent=p1+' vs '+p2;
    document.getElementById('r-p1label').textContent=p1+' Score';
    document.getElementById('r-p2label').textContent=p2+' Score';
    document.getElementById('r-s1').value=0; document.getElementById('r-s2').value=0;
    openModal('resultModal');
  }

  async function submitResult(){
    const id=document.getElementById('r-id').value;
    const s1=parseInt(document.getElementById('r-s1').value)||0;
    const s2=parseInt(document.getElementById('r-s2').value)||0;
    try{
      await api('PUT',`/api/fixtures/${id}/result`,{scoreParticipant1:s1,scoreParticipant2:s2});
      showToast('Result saved!','success'); closeModal('resultModal'); loadFixtures();
    }catch(e){showToast(e.message,'error');}
  }

  const esc = s => String(s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");

  loadTournaments();
</script>
</body></html>
