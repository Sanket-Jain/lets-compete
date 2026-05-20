<%@ include file="header.jsp" %>

<style>
  .leaderboard-row td:nth-child(1) { font-family:'Bebas Neue',sans-serif; font-size:1.3rem; color:var(--muted); }
  .rank-1 td:nth-child(1) { color:var(--gold) !important; }
  .rank-2 td:nth-child(1) { color:#aaa !important; }
  .rank-3 td:nth-child(1) { color:#cd7f32 !important; }
  .danger-zone { background:#fff5f5; border:1px solid #f5c6cb; border-radius:var(--radius); padding:1.6rem; }
  .danger-title { font-family:'Bebas Neue',sans-serif; color:var(--rust); font-size:1.3rem; letter-spacing:.06em; margin-bottom:.8rem; }
  .danger-actions { display:flex; gap:1rem; flex-wrap:wrap; margin-top:1rem; }
</style>

<div class="page">
  <div class="section-title" style="margin-bottom:1.2rem">Results & Management</div>

  <!-- Tournament picker -->
  <div class="card">
    <div class="card-title">Select Tournament</div>
    <div class="form-row">
      <div class="form-group" style="max-width:340px">
        <label>Tournament</label>
        <select id="sel-t" onchange="loadResults()">
          <option value="">— Choose —</option>
        </select>
      </div>
    </div>
  </div>

  <!-- Leaderboard -->
  <div class="card" id="leaderboardCard" style="display:none">
    <div class="card-title">🏆 Leaderboard</div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Rank</th><th>Name</th><th>Score</th><th>Won</th><th>Played</th><th>Win %</th></tr></thead>
        <tbody id="leaderboardBody"></tbody>
      </table>
    </div>
  </div>

  <!-- Fixtures summary -->
  <div class="card" id="summaryCard" style="display:none">
    <div class="card-title">Match Summary</div>
    <div id="summaryBody"></div>
  </div>

  <!-- Danger zone -->
  <div class="danger-zone" id="dangerCard" style="display:none">
    <div class="danger-title">⚠️ Data Management</div>
    <p class="text-muted">Use these actions once a tournament is complete. These operations cannot be undone.</p>
    <div class="danger-actions">
      <button class="btn btn-secondary" onclick="resetScores()">Reset Player Scores</button>
      <button class="btn btn-danger" onclick="deleteFixtures()">Delete All Fixtures</button>
      <button class="btn btn-danger" onclick="deleteTournament()">Delete Entire Tournament</button>
    </div>
  </div>
</div>

<script>
  let selTId = null;

  async function loadTournaments(){
    const ts = await api('GET','/api/tournaments');
    const sel = document.getElementById('sel-t');
    sel.innerHTML = '<option value="">— Choose —</option>' +
      ts.map(t=>`<option value="${t.id}">${t.name} (${t.competitionType})</option>`).join('');
  }

  async function loadResults(){
    const id = document.getElementById('sel-t').value;
    selTId = id || null;
    ['leaderboardCard','summaryCard','dangerCard'].forEach(c=>document.getElementById(c).style.display = id?'block':'none');
    if(!id) return;
    try{
      const fixtures = await api('GET',`/api/fixtures/tournament/${id}`);
      renderSummary(fixtures);
      buildLeaderboard(fixtures);
    }catch(e){ showToast(e.message,'error'); }
  }

  function buildLeaderboard(fixtures){
    // Collect all players/teams from fixtures
    const map = {};
    fixtures.forEach(f=>{
      const isSingles = f.competitionType==='SINGLES';
      [['p1',f.player1||f.team1],['p2',f.player2||f.team2]].forEach(([,p])=>{
        if(!p) return;
        if(!map[p.id]) map[p.id]={name:p.name,score:p.totalScore||0,won:p.matchesWon||0,played:p.matchesPlayed||0};
      });
    });
    const sorted = Object.values(map).sort((a,b)=>b.score-a.score);
    const tbody = document.getElementById('leaderboardBody');
    if(!sorted.length){ tbody.innerHTML='<tr><td colspan="6" class="text-muted" style="padding:1rem">No data yet.</td></tr>'; return; }
    tbody.innerHTML = sorted.map((p,i)=>`
      <tr class="leaderboard-row rank-${i+1}">
        <td>${i===0?'🥇':i===1?'🥈':i===2?'🥉':i+1}</td>
        <td><strong>${p.name}</strong></td>
        <td><strong style="color:var(--gold)">${p.score}</strong></td>
        <td>${p.won}</td>
        <td>${p.played}</td>
        <td>${p.played?Math.round(p.won/p.played*100)+'%':'—'}</td>
      </tr>`).join('');
  }

  function renderSummary(fixtures){
    const body = document.getElementById('summaryBody');
    if(!fixtures.length){ body.innerHTML='<p class="text-muted">No fixtures found.</p>'; return; }
    const levels = {};
    fixtures.forEach(f=>{ if(!levels[f.levelNumber]) levels[f.levelNumber]=[]; levels[f.levelNumber].push(f); });
    const total = fixtures.length;
    const done  = fixtures.filter(f=>f.status==='COMPLETED').length;
    body.innerHTML = `
      <div style="display:flex;gap:2rem;margin-bottom:1.2rem;flex-wrap:wrap">
        <div><span class="text-muted">Total Matches:</span> <strong>${total}</strong></div>
        <div><span class="text-muted">Completed:</span> <strong style="color:var(--success)">${done}</strong></div>
        <div><span class="text-muted">Pending:</span> <strong style="color:var(--rust)">${total-done}</strong></div>
      </div>` +
      Object.entries(levels).map(([lvl,fxs])=>`
        <div style="margin-bottom:1.2rem">
          <div style="font-family:'Bebas Neue',sans-serif;letter-spacing:.06em;color:var(--slate);margin-bottom:.5rem">Level ${lvl}</div>
          <div class="table-wrap"><table>
            <thead><tr><th>Match</th><th>Participant 1</th><th>Participant 2</th><th>Score</th><th>Winner</th><th>Status</th></tr></thead>
            <tbody>${fxs.map(f=>{
              const isSingles=f.competitionType==='SINGLES';
              const p1=isSingles?f.player1?.name:f.team1?.name;
              const p2=isSingles?f.player2?.name:f.team2?.name;
              const winner=isSingles?f.winnerPlayer?.name:f.winnerTeam?.name;
              return `<tr>
                <td class="text-muted">#${f.matchNumber}</td>
                <td>${p1||'—'}</td>
                <td>${p2||'—'}</td>
                <td>${f.status==='COMPLETED'?f.scoreParticipant1+' — '+f.scoreParticipant2:'—'}</td>
                <td>${winner?'<strong style="color:var(--success)">'+winner+'</strong>':'—'}</td>
                <td><span class="badge ${f.status==='COMPLETED'?'badge-completed':'badge-scheduled'}">${f.status}</span></td>
              </tr>`;
            }).join('')}</tbody>
          </table></div>
        </div>`).join('');
  }

  // ── Data cleanup ─────────────────────────────────────────────────
  async function resetScores(){
    if(!confirm('Reset ALL player scores to 0? This affects global player stats.'))return;
    try{
      const players = await api('GET','/api/players');
      await Promise.all(players.map(p=>api('PUT',`/api/players/${p.id}`,{name:p.name,skillLevel:p.skillLevel,achievements:p.achievements})));
      showToast('Scores reset (player profiles preserved)','info');
    }catch(e){showToast(e.message,'error');}
  }

  async function deleteFixtures(){
    if(!selTId){showToast('Select a tournament first','error');return;}
    if(!confirm('Delete ALL fixtures for this tournament?'))return;
    try{
      const fixtures = await api('GET',`/api/fixtures/tournament/${selTId}`);
      await Promise.all(fixtures.map(f=>fetch(`/api/fixtures/${f.id}`,{method:'DELETE'})));
      showToast('All fixtures deleted','info');
      loadResults();
    }catch(e){showToast(e.message,'error');}
  }

  async function deleteTournament(){
    if(!selTId){showToast('Select a tournament first','error');return;}
    if(!confirm('Delete the ENTIRE tournament including all fixtures? This cannot be undone.'))return;
    try{
      await api('DELETE',`/api/tournaments/${selTId}`);
      showToast('Tournament deleted','info');
      document.getElementById('sel-t').value='';
      selTId=null;
      ['leaderboardCard','summaryCard','dangerCard'].forEach(c=>document.getElementById(c).style.display='none');
      loadTournaments();
    }catch(e){showToast(e.message,'error');}
  }

  loadTournaments();
</script>
</body></html>
