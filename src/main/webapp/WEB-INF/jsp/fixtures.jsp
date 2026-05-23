<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%@ include file="header.jsp" %>

<style>
  .fixture-card { background:#fff; border:1px solid var(--border); border-radius:var(--radius); padding:1.1rem 1.3rem; margin-bottom:.65rem; display:flex; align-items:flex-start; justify-content:space-between; flex-wrap:wrap; gap:1rem; }
  .fixture-card.completed  { border-left:4px solid var(--success); }
  .fixture-card.scheduled  { border-left:4px solid var(--gold); }
  .fixture-card.walkover   { border-left:4px solid #9c7bb5; background:#faf7ff; }
  .match-players { display:flex; align-items:center; gap:.8rem; font-weight:600; font-size:.96rem; flex-wrap:wrap; }
  .vs { color:var(--muted); font-size:.78rem; font-weight:400; }
  .match-score { font-family:'Bebas Neue',sans-serif; font-size:1.6rem; letter-spacing:.04em; color:var(--slate); }
  .winner-tag  { font-size:.72rem; color:var(--success); font-weight:700; text-transform:uppercase; }
  .bye-tag     { font-size:.72rem; color:#7c5cbf; font-weight:700; }
  .chess-time-badge { background:#e8d5f7; color:#5c3d8f; border-radius:99px; padding:.2rem .7rem; font-size:.75rem; font-weight:600; }
  .badminton-games { display:flex; gap:.4rem; margin-top:.3rem; flex-wrap:wrap; }
  .game-chip { background:#f0f0f0; border-radius:var(--radius); padding:.15rem .55rem; font-size:.78rem; font-weight:600; }
  .game-chip.won { background:#d4edda; color:#155724; }
  .game-chip.lost { background:#f8d7da; color:#721c24; }
  .controls-bar { background:#fff; border:1px solid var(--border); border-radius:var(--radius); padding:1.1rem 1.3rem; margin-bottom:1.1rem; display:flex; gap:1rem; align-items:flex-end; flex-wrap:wrap; }
  .level-header { font-family:'Bebas Neue',sans-serif; font-size:1rem; letter-spacing:.1em; color:var(--gold); background:var(--slate); padding:.35rem .9rem; border-radius:var(--radius); display:inline-flex; align-items:center; gap:.4rem; }
  /* Result modal sport sections */
  #chess-section, #badminton-section, #carrom-section { display:none; }
  .game-score-row { display:grid; grid-template-columns:80px 1fr 1fr; align-items:center; gap:.6rem; margin-bottom:.5rem; }
  .game-score-row label { font-size:.82rem; color:var(--muted); font-weight:600; }
</style>

<div class="page">
  <div class="section-title" style="margin-bottom:1.1rem">Fixtures</div>

  <div class="controls-bar">
    <div class="form-group" style="min-width:260px">
      <label>Select Tournament</label>
      <select id="sel-tournament" onchange="onTournamentChange()">
        <option value="">— Choose a tournament —</option>
      </select>
    </div>
    <button class="btn btn-primary"  id="btn-gen1" onclick="genLevel1()"    disabled>Generate Level 1 (Random)</button>
    <button class="btn btn-success"  id="btn-adv"  onclick="advanceLevel()" disabled>Advance to Next Level ›</button>
  </div>

  <div id="bracketHint" style="display:none;background:#fffbe6;border:1px solid #ffe58f;border-radius:var(--radius);padding:.7rem 1rem;margin-bottom:1rem;font-size:.84rem;color:#7c5c00"></div>

  <!-- Participant selector -->
  <div class="card" id="participantSection" style="display:none">
    <div class="card-title" id="participantTitle">Select Participants</div>
    <p class="text-muted" id="participantHint" style="margin-bottom:.8rem"></p>
    <div id="participantList" style="display:flex;flex-wrap:wrap;gap:.5rem;margin-bottom:1rem"></div>
    <div class="flex gap-1">
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(true)">Select All</button>
      <button class="btn btn-secondary btn-sm" onclick="toggleAll(false)">Deselect All</button>
      <button class="btn btn-primary" onclick="confirmGenLevel1()">Generate Fixtures</button>
      <button class="btn btn-secondary" onclick="hideParticipants()">Cancel</button>
    </div>
  </div>

  <div id="fixturesArea"></div>
</div>

<!-- Record Result Modal -->
<div class="modal-overlay" id="resultModal">
  <div class="modal" style="max-width:520px">
    <div class="modal-header">
      <div class="modal-title" id="result-modal-title">Record Result</div>
      <button class="modal-close" onclick="closeModal('resultModal')">✕</button>
    </div>
    <input type="hidden" id="r-id"/>
    <input type="hidden" id="r-sport"/>
    <p id="r-matchLabel" style="margin-bottom:1rem;font-weight:600;color:var(--slate)"></p>

    <!-- Chess section -->
    <div id="chess-section">
      <div id="chess-time-info" style="background:#e8d5f7;border-radius:var(--radius);padding:.55rem 1rem;font-size:.83rem;margin-bottom:.9rem;display:none">
        ♟️ Time limit: <strong id="chess-time-val"></strong> minutes per player
      </div>
      <div class="form-row">
        <div class="form-group">
          <label>Result Type</label>
          <select id="chess-result-type">
            <optgroup label="Decisive">
              <option value="CHECKMATE">Checkmate</option>
              <option value="RESIGNATION">Resignation</option>
              <option value="TIMEOUT">Timeout (Flag fall)</option>
            </optgroup>
            <optgroup label="Draw">
              <option value="STALEMATE">Stalemate</option>
              <option value="DRAW_AGREEMENT">Draw by Agreement</option>
              <option value="INSUFFICIENT_MATERIAL">Insufficient Material</option>
              <option value="THREEFOLD_REPETITION">Threefold Repetition</option>
              <option value="FIFTY_MOVE_RULE">50-Move Rule</option>
              <option value="DRAW_BY_PERPETUAL_CHECK">Perpetual Check</option>
            </optgroup>
          </select>
        </div>
      </div>
      <div class="form-row" id="chess-winner-row">
        <div class="form-group">
          <label>Winner</label>
          <select id="chess-winner">
            <option value="1">Player 1 wins</option>
            <option value="2">Player 2 wins</option>
          </select>
        </div>
      </div>
      <p class="text-muted" style="font-size:.8rem">Chess scores: 1 = win, 0 = loss/draw (FIDE standard)</p>
    </div>

    <!-- Badminton section -->
    <div id="badminton-section">
      <p class="text-muted" style="font-size:.82rem;margin-bottom:.9rem">BWF rules: First to 21, win by 2 (cap 30). Best of 3 games.</p>
      <div id="badminton-games-container">
        <div class="game-score-row">
          <label>Game 1</label>
          <div class="form-group"><label id="b-p1label-1" style="font-size:.75rem"></label><input type="number" id="b-g1p1" min="0" max="30" value="0"/></div>
          <div class="form-group"><label id="b-p2label-1" style="font-size:.75rem"></label><input type="number" id="b-g1p2" min="0" max="30" value="0"/></div>
        </div>
        <div class="game-score-row">
          <label>Game 2</label>
          <div class="form-group"><input type="number" id="b-g2p1" min="0" max="30" value="0"/></div>
          <div class="form-group"><input type="number" id="b-g2p2" min="0" max="30" value="0"/></div>
        </div>
        <div class="game-score-row" id="b-game3row">
          <label>Game 3</label>
          <div class="form-group"><input type="number" id="b-g3p1" min="0" max="30" value="0"/></div>
          <div class="form-group"><input type="number" id="b-g3p2" min="0" max="30" value="0"/></div>
        </div>
      </div>
      <label style="display:flex;align-items:center;gap:.4rem;margin-top:.5rem;font-size:.83rem;cursor:pointer">
        <input type="checkbox" id="b-use-game3" onchange="toggleGame3()"/> Include Game 3
      </label>
    </div>

    <!-- Carrom section -->
    <div id="carrom-section">
      <div class="form-row">
        <div class="form-group"><label id="c-p1label">Player 1 Score</label><input id="c-s1" type="number" min="0" value="0"/></div>
        <div class="form-group"><label id="c-p2label">Player 2 Score</label><input id="c-s2" type="number" min="0" value="0"/></div>
      </div>
    </div>

    <div class="flex gap-1 mt-2" style="justify-content:flex-end">
      <button class="btn btn-secondary" onclick="closeModal('resultModal')">Cancel</button>
      <button class="btn btn-primary" onclick="submitResult()">Save Result</button>
    </div>
  </div>
</div>

<script>
  let currentTournament = null;

  async function loadTournaments() {
    try {
      const ts = await api('GET','/api/tournaments');
      const sel = document.getElementById('sel-tournament');
      sel.innerHTML = '<option value="">— Choose a tournament —</option>' +
        ts.map(t => '<option value="'+t.id+'" data-type="'+t.competitionType+'" data-sport="'+t.sportType+'">' +
          sportIcon(t.sportType)+' '+t.name+' ('+t.sportType+' '+t.competitionType+')</option>').join('');
    } catch(e) { showToast(e.message,'error'); }
  }

  function sportIcon(s) { return ({'CARROM':'🎯','CHESS':'♟️','BADMINTON':'🏸'})[s]||'🏅'; }

  async function onTournamentChange() {
    const sel = document.getElementById('sel-tournament');
    const id  = sel.value;
    document.getElementById('bracketHint').style.display='none';
    document.getElementById('fixturesArea').innerHTML='';
    hideParticipants();
    document.getElementById('btn-gen1').disabled=true;
    document.getElementById('btn-adv').disabled=true;
    if (!id) { currentTournament=null; return; }
    const opt = sel.options[sel.selectedIndex];
    currentTournament = { id, type:opt.dataset.type, sport:opt.dataset.sport };
    document.getElementById('btn-gen1').disabled=false;
    await loadFixtures();
  }

  async function loadFixtures() {
    if (!currentTournament) return;
    try {
      const fixtures = await api('GET','/api/fixtures/tournament/'+currentTournament.id);
      renderFixtures(fixtures);
      const nonBye = fixtures.filter(f => !f.isBye);
      const pending = nonBye.filter(f => f.status!=='COMPLETED' && f.status!=='WALKOVER');
      document.getElementById('btn-adv').disabled = (nonBye.length===0 || pending.length>0);
    } catch(e) { showToast(e.message,'error'); }
  }

  function renderFixtures(fixtures) {
    const area = document.getElementById('fixturesArea');
    if (!fixtures.length) { area.innerHTML='<div class="empty"><div class="empty-icon">📋</div><p>No fixtures yet. Click Generate Level 1 to begin.</p></div>'; return; }
    const levels = {};
    fixtures.forEach(f => { if (!levels[f.levelNumber]) levels[f.levelNumber]=[]; levels[f.levelNumber].push(f); });
    area.innerHTML = Object.entries(levels).map(([lvl,fxs]) => {
      const real=fxs.filter(f=>!f.isBye).length, byes=fxs.filter(f=>f.isBye).length;
      const done=fxs.filter(f=>f.status==='COMPLETED'||f.status==='WALKOVER').length;
      return '<div style="margin-bottom:1.6rem">' +
        '<div style="display:flex;align-items:center;gap:.8rem;margin-bottom:.65rem">' +
          '<div class="level-header">🏅 Level '+lvl+'</div>' +
          '<span class="text-muted" style="font-size:.8rem">'+real+' match'+(real!==1?'es':'')+(byes?' + '+byes+' bye'+(byes!==1?'s':''):'')+' · '+done+'/'+fxs.length+' done</span>' +
        '</div>' +
        fxs.map(f => renderCard(f)).join('') +
      '</div>';
    }).join('');
  }

  function renderCard(f) {
    const isSingles = f.competitionType==='SINGLES';
    const p1 = isSingles ? (f.player1?f.player1.name:'—') : (f.team1?f.team1.name:'—');
    const p2 = isSingles ? (f.player2?f.player2.name:null) : (f.team2?f.team2.name:null);
    const winner = isSingles ? (f.winnerPlayer?f.winnerPlayer.name:null) : (f.winnerTeam?f.winnerTeam.name:null);
    const done = f.status==='COMPLETED'||f.status==='WALKOVER';
    const cls = f.isBye ? 'walkover' : (done ? 'completed' : 'scheduled');

    let scoreHtml = '';
    if (f.isBye) {
      scoreHtml = '<div class="bye-tag">🎫 Auto-Advanced (Bye)</div>';
    } else if (done) {
      if (f.sportType==='CHESS') {
        scoreHtml = '<div class="match-score">'+f.scoreParticipant1+' — '+f.scoreParticipant2+'</div>' +
          '<div class="winner-tag">🏆 '+winner+'</div>' +
          (f.chessResultType ? '<div class="text-muted" style="font-size:.74rem;margin-top:.2rem">'+f.chessResultType.replace(/_/g,' ')+'</div>' : '');
      } else if (f.sportType==='BADMINTON' && f.gameScores) {
        let games;
        try { games = JSON.parse(f.gameScores); } catch(e) { games = []; }
        const p1Won = games.filter(g=>g.p1>g.p2).length, p2Won = games.filter(g=>g.p2>g.p1).length;
        scoreHtml = '<div class="match-score">'+p1Won+' — '+p2Won+'</div>' +
          '<div class="badminton-games">' +
            games.map((g,i) => {
              const p1w = g.p1>g.p2;
              return '<span class="game-chip '+(p1w?'won':'lost')+'">G'+(i+1)+': '+g.p1+'-'+g.p2+'</span>';
            }).join('') +
          '</div>' +
          '<div class="winner-tag">🏆 '+winner+'</div>';
      } else {
        scoreHtml = '<div class="match-score">'+f.scoreParticipant1+' — '+f.scoreParticipant2+'</div>' +
          '<div class="winner-tag">🏆 '+winner+'</div>';
      }
    }

    const chessTimeBadge = (f.sportType==='CHESS' && f.chessTimeMinutes)
      ? '<span class="chess-time-badge">⏱ '+f.chessTimeMinutes+' min</span>' : '';

    return '<div class="fixture-card '+cls+'">' +
      '<div>' +
        '<div class="match-players">' +
          '<span '+(winner===p1?'style="color:var(--success)"':'')+'>'+p1+'</span>' +
          '<span class="vs">VS</span>' +
          (f.isBye ? '<span style="color:#9c7bb5;font-style:italic">BYE</span>'
            : '<span '+(winner===p2?'style="color:var(--success)"':'')+'>'+( p2||'—')+'</span>') +
          chessTimeBadge +
        '</div>' +
        scoreHtml +
      '</div>' +
      '<div class="flex gap-1" style="align-items:center">' +
        '<span class="badge '+(f.isBye?'':'(done?\'badge-completed\':\'badge-scheduled\')')+'" '+
          (f.isBye?'style="background:#e8d5f7;color:#5c3d8f"':'')+'>'+
          (f.isBye ? 'BYE' : f.status)+'</span>' +
        (!done && !f.isBye ? '<button class="btn btn-primary btn-sm" onclick="openResult('+f.id+',\''+esc(p1)+'\',\''+esc(p2||'')+'\',\''+f.sportType+'\','+(f.chessTimeMinutes||0)+')">Record Result</button>' : '') +
      '</div>' +
    '</div>';
  }

  // ── Level 1 generation ─────────────────────────────────────────────────────────
  async function genLevel1() {
    if (!currentTournament) { showToast('Select a tournament first','error'); return; }
    const existing = await api('GET','/api/fixtures/tournament/'+currentTournament.id).catch(()=>[]);
    if (existing.length>0) { showToast('Level 1 fixtures already exist','error'); return; }
    const isSingles = currentTournament.type==='SINGLES';
    document.getElementById('participantTitle').textContent = isSingles ? 'Select Players' : 'Select Teams';
    document.getElementById('participantSection').style.display='block';

    let all;
    if (isSingles) {
      all = await api('GET','/api/players');
    } else {
      all = await api('GET','/api/teams/tournament/'+currentTournament.id);
      if (!all.length) {
        all = await api('GET','/api/teams');
        if (!all.length) { showToast('Create teams first in the Teams tab','error'); hideParticipants(); return; }
        showToast('No teams linked to this tournament. Showing all teams.','info');
      }
    }

    document.getElementById('participantList').innerHTML = all.map(p => {
      const label = isSingles ? p.name : p.name+' ('+p.player1.name+' & '+p.player2.name+')';
      return '<label style="display:flex;align-items:center;gap:.4rem;background:var(--ivory);padding:.4rem .9rem;border-radius:var(--radius);cursor:pointer;border:1.5px solid var(--border)">' +
        '<input type="checkbox" value="'+p.id+'" checked/> '+label+'</label>';
    }).join('');
    updateBracketHint();
    document.querySelectorAll('#participantList input').forEach(cb => cb.addEventListener('change', updateBracketHint));
  }

  function updateBracketHint() {
    const n = document.querySelectorAll('#participantList input:checked').length;
    if (n<2) { document.getElementById('participantHint').textContent='Select at least 2 participants.'; return; }
    const b = nextPow2(n)-n;
    document.getElementById('participantHint').textContent =
      n+' selected → bracket: '+nextPow2(n)+(b?' · '+b+' bye'+(b>1?'s':'')+' in Level 1 (Level 2+ will be bye-free)':' (perfect — no byes needed)');
  }
  function nextPow2(n) { let p=1; while(p<n) p<<=1; return p; }
  function toggleAll(s) { document.querySelectorAll('#participantList input').forEach(cb=>cb.checked=s); updateBracketHint(); }
  function hideParticipants() { document.getElementById('participantSection').style.display='none'; }

  async function confirmGenLevel1() {
    const ids = [...document.querySelectorAll('#participantList input:checked')].map(cb=>parseInt(cb.value));
    if (ids.length<2) { showToast('Select at least 2 participants','error'); return; }
    try {
      await api('POST','/api/fixtures/tournament/'+currentTournament.id+'/generate-level1', ids);
      showToast('Level 1 fixtures generated!','success'); hideParticipants(); loadFixtures();
    } catch(e) { showToast(e.message,'error'); }
  }

  async function advanceLevel() {
    if (!currentTournament) return;
    try {
      await api('POST','/api/fixtures/tournament/'+currentTournament.id+'/advance-level');
      showToast('Next level fixtures generated!','success'); loadFixtures();
    } catch(e) { showToast(e.message,'error'); }
  }

  // ── Result recording ──────────────────────────────────────────────────────────
  function openResult(id, p1, p2, sport, chessTime) {
    document.getElementById('r-id').value=id;
    document.getElementById('r-sport').value=sport;
    document.getElementById('r-matchLabel').textContent=p1+' vs '+p2;
    document.getElementById('result-modal-title').textContent =
      ({'CHESS':'♟️ Record Chess Result','BADMINTON':'🏸 Record Badminton Result','CARROM':'🎯 Record Carrom Result'})[sport]||'Record Result';

    // Show correct sport section
    document.getElementById('chess-section').style.display = sport==='CHESS' ? 'block' : 'none';
    document.getElementById('badminton-section').style.display = sport==='BADMINTON' ? 'block' : 'none';
    document.getElementById('carrom-section').style.display = sport==='CARROM' ? 'block' : 'none';

    if (sport==='CHESS') {
      document.getElementById('chess-result-type').value='CHECKMATE';
      document.getElementById('chess-winner').innerHTML = '<option value="1">'+p1+' wins</option><option value="2">'+p2+' wins</option>';
      updateChessWinnerRow();
      if (chessTime>0) {
        document.getElementById('chess-time-info').style.display='block';
        document.getElementById('chess-time-val').textContent=chessTime;
      } else { document.getElementById('chess-time-info').style.display='none'; }
    } else if (sport==='BADMINTON') {
      document.getElementById('b-p1label-1').textContent=p1;
      document.getElementById('b-p2label-1').textContent=p2;
      ['b-g1p1','b-g1p2','b-g2p1','b-g2p2','b-g3p1','b-g3p2'].forEach(id=>document.getElementById(id).value=0);
      document.getElementById('b-use-game3').checked=false;
      toggleGame3();
    } else {
      document.getElementById('c-p1label').textContent=p1+' Score';
      document.getElementById('c-p2label').textContent=p2+' Score';
      document.getElementById('c-s1').value=0; document.getElementById('c-s2').value=0;
    }
    openModal('resultModal');
  }

  document.getElementById('chess-result-type').addEventListener('change', updateChessWinnerRow);
  function updateChessWinnerRow() {
    const isDraw = ['STALEMATE','DRAW_AGREEMENT','INSUFFICIENT_MATERIAL','THREEFOLD_REPETITION','FIFTY_MOVE_RULE','DRAW_BY_PERPETUAL_CHECK'].includes(document.getElementById('chess-result-type').value);
    document.getElementById('chess-winner-row').style.display = isDraw ? 'none' : 'flex';
  }

  function toggleGame3() {
    document.getElementById('b-game3row').style.display = document.getElementById('b-use-game3').checked ? 'grid' : 'none';
  }

  async function submitResult() {
    const id = document.getElementById('r-id').value;
    const sport = document.getElementById('r-sport').value;
    let payload = {};

    if (sport==='CHESS') {
      const resultType = document.getElementById('chess-result-type').value;
      const drawTypes  = ['STALEMATE','DRAW_AGREEMENT','INSUFFICIENT_MATERIAL','THREEFOLD_REPETITION','FIFTY_MOVE_RULE','DRAW_BY_PERPETUAL_CHECK'];
      const isDraw     = drawTypes.includes(resultType);
      let s1=0, s2=0;
      if (!isDraw) { const w=document.getElementById('chess-winner').value; s1=w==='1'?1:0; s2=w==='2'?1:0; }
      payload = { scoreParticipant1:s1, scoreParticipant2:s2, chessResultType:resultType };

    } else if (sport==='BADMINTON') {
      const useGame3 = document.getElementById('b-use-game3').checked;
      const games = [
        { p1:parseInt(document.getElementById('b-g1p1').value)||0, p2:parseInt(document.getElementById('b-g1p2').value)||0 },
        { p1:parseInt(document.getElementById('b-g2p1').value)||0, p2:parseInt(document.getElementById('b-g2p2').value)||0 }
      ];
      if (useGame3) games.push({ p1:parseInt(document.getElementById('b-g3p1').value)||0, p2:parseInt(document.getElementById('b-g3p2').value)||0 });
      const g1p1=games.filter(g=>g.p1>g.p2).length, g1p2=games.filter(g=>g.p2>g.p1).length;
      payload = { scoreParticipant1:g1p1, scoreParticipant2:g1p2, badmintonGameScores:games };

    } else {
      payload = { scoreParticipant1:parseInt(document.getElementById('c-s1').value)||0, scoreParticipant2:parseInt(document.getElementById('c-s2').value)||0 };
    }

    try {
      await api('PUT','/api/fixtures/'+id+'/result', payload);
      showToast('Result saved!','success'); closeModal('resultModal'); loadFixtures();
    } catch(e) { showToast(e.message,'error'); }
  }

  const esc = s => String(s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");
  loadTournaments();
</script>
</body></html>
