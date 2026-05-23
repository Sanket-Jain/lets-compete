package com.carrom.competition.service;

import com.carrom.competition.dto.FixtureDTO;
import com.carrom.competition.dto.MatchResultDTO;
import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.MatchStatus;
import com.carrom.competition.enums.SportType;
import com.carrom.competition.model.*;
import com.carrom.competition.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
public class FixtureService {

    private final FixtureRepository    fixtureRepository;
    private final TournamentRepository tournamentRepository;
    private final PlayerRepository     playerRepository;
    private final TeamRepository       teamRepository;
    private final PlayerService        playerService;
    private final TeamService          teamService;
    private final TournamentService    tournamentService;
    private final ObjectMapper         objectMapper = new ObjectMapper();

    public FixtureService(FixtureRepository fixtureRepository,
                          TournamentRepository tournamentRepository,
                          PlayerRepository playerRepository,
                          TeamRepository teamRepository,
                          PlayerService playerService,
                          TeamService teamService,
                          TournamentService tournamentService) {
        this.fixtureRepository   = fixtureRepository;
        this.tournamentRepository = tournamentRepository;
        this.playerRepository     = playerRepository;
        this.teamRepository       = teamRepository;
        this.playerService        = playerService;
        this.teamService          = teamService;
        this.tournamentService    = tournamentService;
    }

    // ─── Bracket helpers ──────────────────────────────────────────────────────────
    private int nextPowerOfTwo(int n) { if (n<=1) return 1; int p=1; while(p<n) p<<=1; return p; }
    private int byesNeeded(int n)     { return nextPowerOfTwo(n) - n; }

    // ─── Generate Level 1 (random draw + byes) ────────────────────────────────────
    public List<FixtureDTO> generateLevel1Fixtures(Long tournamentId, List<Long> participantIds) {
        Tournament tournament = tournamentService.getTournament(tournamentId);

        if (tournament.getCurrentLevel() != 1)
            throw new IllegalStateException("Level 1 fixtures already generated");

        long existing = fixtureRepository.countPendingFixturesForLevel(tournamentId, 1)
                + fixtureRepository.findCompletedFixturesForLevel(tournamentId, 1).size();
        if (existing > 0) throw new IllegalStateException("Level 1 fixtures already exist");
        if (participantIds.size() < 2) throw new IllegalArgumentException("At least 2 participants required");

        List<Long> shuffled = new ArrayList<>(participantIds);
        Collections.shuffle(shuffled);

        int n    = shuffled.size();
        int byes = byesNeeded(n);
        int real = n - byes;

        List<Fixture> fixtures = new ArrayList<>();
        int matchNum = 1;
        for (int i = 0; i < real; i += 2)
            fixtures.add(buildMatch(tournament, shuffled.get(i), shuffled.get(i+1), 1, matchNum++));
        for (int i = real; i < n; i++)
            fixtures.add(buildBye(tournament, shuffled.get(i), 1, matchNum++));

        return fixtureRepository.saveAll(fixtures).stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Advance to next level ────────────────────────────────────────────────────
    public List<FixtureDTO> generateNextLevelFixtures(Long tournamentId) {
        Tournament tournament = tournamentService.getTournament(tournamentId);
        int currentLevel = tournament.getCurrentLevel();

        long pending = fixtureRepository.countPendingFixturesForLevel(tournamentId, currentLevel);
        if (pending > 0)
            throw new IllegalStateException("Cannot advance: " + pending + " match(es) still pending in Level " + currentLevel);

        List<Fixture> completed = fixtureRepository.findCompletedFixturesForLevel(tournamentId, currentLevel);
        if (completed.isEmpty()) throw new IllegalStateException("No completed matches for Level " + currentLevel);

        List<Long> winnerIds;
        if (tournament.getCompetitionType() == CompetitionType.SINGLES) {
            List<Long> ids = completed.stream().filter(f -> f.getWinnerPlayer() != null)
                    .map(f -> f.getWinnerPlayer().getId()).distinct().collect(Collectors.toList());
            winnerIds = playerRepository.findByIdInOrderByTotalScoreDesc(ids)
                    .stream().map(Player::getId).collect(Collectors.toList());
        } else {
            List<Long> ids = completed.stream().filter(f -> f.getWinnerTeam() != null)
                    .map(f -> f.getWinnerTeam().getId()).distinct().collect(Collectors.toList());
            winnerIds = teamRepository.findByIdInOrderByTotalScoreDesc(ids)
                    .stream().map(Team::getId).collect(Collectors.toList());
        }

        if (winnerIds.size() < 2)
            throw new IllegalStateException("Not enough winners to generate next level");
        if (winnerIds.size() % 2 != 0)
            throw new IllegalStateException("Unexpected odd number of winners — ensure Level 1 was generated by this system");

        int nextLevel = currentLevel + 1;
        tournament.setCurrentLevel(nextLevel);
        tournamentRepository.save(tournament);

        List<Fixture> fixtures = new ArrayList<>();
        int matchNum = 1;
        int left = 0, right = winnerIds.size() - 1;
        while (left < right)
            fixtures.add(buildMatch(tournament, winnerIds.get(left++), winnerIds.get(right--), nextLevel, matchNum++));

        return fixtureRepository.saveAll(fixtures).stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Fixture builders ─────────────────────────────────────────────────────────
    private Fixture buildMatch(Tournament t, Long id1, Long id2, int level, int matchNum) {
        Fixture f = new Fixture();
        f.setTournament(t);
        f.setLevelNumber(level);
        f.setCompetitionType(t.getCompetitionType());
        f.setStatus(MatchStatus.SCHEDULED);
        f.setMatchNumber(matchNum);
        f.setScoreParticipant1(0);
        f.setScoreParticipant2(0);
        f.setIsBye(false);
        // Chess: attach time limit for this level
        if (t.getSportType() == SportType.CHESS) {
            f.setChessTimeMinutes(tournamentService.getChessTimeForLevel(t, level));
        }
        if (t.getCompetitionType() == CompetitionType.SINGLES) {
            f.setPlayer1(playerService.getPlayer(id1));
            f.setPlayer2(playerService.getPlayer(id2));
        } else {
            f.setTeam1(teamService.getTeam(id1));
            f.setTeam2(teamService.getTeam(id2));
        }
        return f;
    }

    private Fixture buildBye(Tournament t, Long participantId, int level, int matchNum) {
        Fixture f = new Fixture();
        f.setTournament(t);
        f.setLevelNumber(level);
        f.setCompetitionType(t.getCompetitionType());
        f.setMatchNumber(matchNum);
        f.setScoreParticipant1(0);
        f.setScoreParticipant2(0);
        f.setIsBye(true);
        f.setStatus(MatchStatus.WALKOVER);
        f.setCompletedAt(LocalDateTime.now());
        if (t.getCompetitionType() == CompetitionType.SINGLES) {
            Player p = playerService.getPlayer(participantId);
            f.setPlayer1(p); f.setWinnerPlayer(p);
        } else {
            Team team = teamService.getTeam(participantId);
            f.setTeam1(team); f.setWinnerTeam(team);
        }
        return f;
    }

    // ─── Record match result ──────────────────────────────────────────────────────
    public FixtureDTO recordResult(Long fixtureId, MatchResultDTO result) {
        Fixture fixture = fixtureRepository.findById(fixtureId)
                .orElseThrow(() -> new EntityNotFoundException("Fixture not found: " + fixtureId));

        if (fixture.getStatus() == MatchStatus.COMPLETED || fixture.getStatus() == MatchStatus.WALKOVER)
            throw new IllegalStateException("Match is already completed");
        if (Boolean.TRUE.equals(fixture.getIsBye()))
            throw new IllegalStateException("Cannot record result for a bye match");

        SportType sport = fixture.getTournament().getSportType();

        // ── Sport-specific validation ─────────────────────────────────────────
        switch (sport) {
            case CHESS  -> validateChessResult(result);
            case BADMINTON -> {
                validateBadmintonResult(result);
                if (result.getBadmintonGameScores() != null) {
                    try {
                        fixture.setGameScores(objectMapper.writeValueAsString(result.getBadmintonGameScores()));
                    } catch (Exception ignored) {}
                }
                if (result.getChessResultType() != null) fixture.setChessResultType(result.getChessResultType());
            }
            default -> {} // Carrom — no extra rules
        }

        if (sport == SportType.CHESS && result.getChessResultType() != null)
            fixture.setChessResultType(result.getChessResultType());

        fixture.setScoreParticipant1(result.getScoreParticipant1());
        fixture.setScoreParticipant2(result.getScoreParticipant2());
        fixture.setStatus(MatchStatus.COMPLETED);
        fixture.setCompletedAt(LocalDateTime.now());

        // ── Determine winner ──────────────────────────────────────────────────
        if (fixture.getCompetitionType() == CompetitionType.SINGLES) {
            Player p1 = fixture.getPlayer1(), p2 = fixture.getPlayer2();
            Player winner, loser;
            if      (result.getScoreParticipant1() > result.getScoreParticipant2()) { winner=p1; loser=p2; }
            else if (result.getScoreParticipant2() > result.getScoreParticipant1()) { winner=p2; loser=p1; }
            else {
                // Chess draws: player with score > 0 after tiebreak, or explicit
                if (sport == SportType.CHESS && isChessDraw(result.getChessResultType())) {
                    throw new IllegalArgumentException("Chess draw — no winner. Record as draw with equal scores.");
                }
                if (result.getWinnerPlayerId() == null)
                    throw new IllegalArgumentException("Tied scores — please specify a winner");
                winner = playerService.getPlayer(result.getWinnerPlayerId());
                loser  = winner.getId().equals(p1.getId()) ? p2 : p1;
            }
            fixture.setWinnerPlayer(winner);
            updatePlayerStats(winner, Math.max(result.getScoreParticipant1(), result.getScoreParticipant2()), true);
            updatePlayerStats(loser,  Math.min(result.getScoreParticipant1(), result.getScoreParticipant2()), false);
        } else {
            Team t1 = fixture.getTeam1(), t2 = fixture.getTeam2();
            Team winner, loser;
            if      (result.getScoreParticipant1() > result.getScoreParticipant2()) { winner=t1; loser=t2; }
            else if (result.getScoreParticipant2() > result.getScoreParticipant1()) { winner=t2; loser=t1; }
            else {
                if (result.getWinnerTeamId() == null)
                    throw new IllegalArgumentException("Tied scores — please specify a winner team");
                winner = teamService.getTeam(result.getWinnerTeamId());
                loser  = winner.getId().equals(t1.getId()) ? t2 : t1;
            }
            fixture.setWinnerTeam(winner);
            updateTeamStats(winner, Math.max(result.getScoreParticipant1(), result.getScoreParticipant2()), true);
            updateTeamStats(loser,  Math.min(result.getScoreParticipant1(), result.getScoreParticipant2()), false);
        }

        return toDTO(fixtureRepository.save(fixture));
    }

    // ─── Chess validation (FIDE rules) ────────────────────────────────────────────
    private static final Set<String> VALID_CHESS_RESULTS = Set.of(
            "CHECKMATE", "RESIGNATION", "TIMEOUT",
            "STALEMATE", "DRAW_AGREEMENT", "INSUFFICIENT_MATERIAL",
            "THREEFOLD_REPETITION", "FIFTY_MOVE_RULE", "DRAW_BY_PERPETUAL_CHECK"
    );
    private static final Set<String> CHESS_DRAW_RESULTS = Set.of(
            "STALEMATE", "DRAW_AGREEMENT", "INSUFFICIENT_MATERIAL",
            "THREEFOLD_REPETITION", "FIFTY_MOVE_RULE", "DRAW_BY_PERPETUAL_CHECK"
    );

    private void validateChessResult(MatchResultDTO r) {
        if (r.getChessResultType() == null)
            throw new IllegalArgumentException("Chess result type is required (e.g. CHECKMATE, RESIGNATION, TIMEOUT, STALEMATE, DRAW_AGREEMENT)");
        if (!VALID_CHESS_RESULTS.contains(r.getChessResultType().toUpperCase()))
            throw new IllegalArgumentException("Invalid chess result type: " + r.getChessResultType() +
                    ". Valid values: " + String.join(", ", VALID_CHESS_RESULTS));
        // Score must be 0 or 1 (draws encoded as 0-0 or both 0, wins as 1-0 or 0-1)
        boolean s1ok = r.getScoreParticipant1() == 0 || r.getScoreParticipant1() == 1;
        boolean s2ok = r.getScoreParticipant2() == 0 || r.getScoreParticipant2() == 1;
        if (!s1ok || !s2ok)
            throw new IllegalArgumentException("Chess scores must be 0 (loss/draw) or 1 (win)");
        boolean isDraw = CHESS_DRAW_RESULTS.contains(r.getChessResultType().toUpperCase());
        if (isDraw && (r.getScoreParticipant1() + r.getScoreParticipant2()) > 0)
            throw new IllegalArgumentException("Draw result must have scores 0-0");
        if (!isDraw && r.getScoreParticipant1().equals(r.getScoreParticipant2()))
            throw new IllegalArgumentException("Non-draw result must have a clear winner (1-0 or 0-1)");
    }

    private boolean isChessDraw(String resultType) {
        return resultType != null && CHESS_DRAW_RESULTS.contains(resultType.toUpperCase());
    }

    // ─── Badminton validation (BWF rules) ────────────────────────────────────────
    private void validateBadmintonResult(MatchResultDTO r) {
        if (r.getBadmintonGameScores() == null || r.getBadmintonGameScores().isEmpty())
            throw new IllegalArgumentException("Badminton game-by-game scores are required");

        int gamesP1 = 0, gamesP2 = 0;
        List<Map<String, Integer>> games = r.getBadmintonGameScores();

        if (games.size() < 1 || games.size() > 3)
            throw new IllegalArgumentException("Badminton: 1–3 games expected");

        for (int i = 0; i < games.size(); i++) {
            Map<String, Integer> g = games.get(i);
            int p1 = g.getOrDefault("p1", 0), p2 = g.getOrDefault("p2", 0);

            // BWF: first to 21, win by 2; at 29-29 next point wins (cap 30)
            boolean p1wins = isBadmintonGameWin(p1, p2);
            boolean p2wins = isBadmintonGameWin(p2, p1);
            if (!p1wins && !p2wins)
                throw new IllegalArgumentException("Game " + (i+1) + " scores " + p1 + "-" + p2
                        + " are invalid. BWF: first to 21, win by 2 (cap 30)");

            if (p1wins) gamesP1++; else gamesP2++;
        }

        // Best of 3: first to win 2 games
        if (gamesP1 != 2 && gamesP2 != 2)
            throw new IllegalArgumentException("Badminton match must have a clear winner (first to win 2 games)");

        // Scores must reflect games won
        int expectedP1 = gamesP1, expectedP2 = gamesP2;
        if (!r.getScoreParticipant1().equals(expectedP1) || !r.getScoreParticipant2().equals(expectedP2))
            throw new IllegalArgumentException("Badminton scores must equal games won: "
                    + expectedP1 + "-" + expectedP2);
    }

    private boolean isBadmintonGameWin(int winner, int loser) {
        if (winner < 21) return false;
        if (winner == 30) return loser == 29; // deuce cap
        return winner - loser >= 2;
    }

    // ─── Stats helpers ────────────────────────────────────────────────────────────
    private void updatePlayerStats(Player p, int score, boolean won) {
        p.setMatchesPlayed(p.getMatchesPlayed() + 1);
        p.setTotalScore(p.getTotalScore() + score);
        if (won) p.setMatchesWon(p.getMatchesWon() + 1);
        playerRepository.save(p);
    }

    private void updateTeamStats(Team t, int score, boolean won) {
        t.setMatchesPlayed(t.getMatchesPlayed() + 1);
        t.setTotalScore(t.getTotalScore() + score);
        if (won) t.setMatchesWon(t.getMatchesWon() + 1);
        teamRepository.save(t);
    }

    public void deleteById(Long id) { fixtureRepository.deleteById(id); }

    public List<FixtureDTO> getFixturesByTournament(Long tournamentId) {
        return fixtureRepository.findByTournamentIdOrderByLevelNumberAscMatchNumberAsc(tournamentId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<FixtureDTO> getFixturesByLevel(Long tournamentId, Integer level) {
        return fixtureRepository.findByTournamentIdAndLevelNumber(tournamentId, level)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public FixtureDTO toDTO(Fixture f) {
        FixtureDTO dto = new FixtureDTO();
        dto.setId(f.getId());
        dto.setTournamentId(f.getTournament().getId());
        dto.setTournamentName(f.getTournament().getName());
        dto.setSportType(f.getTournament().getSportType().name());
        dto.setLevelNumber(f.getLevelNumber());
        dto.setCompetitionType(f.getCompetitionType());
        dto.setMatchNumber(f.getMatchNumber());
        dto.setStatus(f.getStatus());
        dto.setIsBye(f.getIsBye());
        dto.setScoreParticipant1(f.getScoreParticipant1());
        dto.setScoreParticipant2(f.getScoreParticipant2());
        dto.setGameScores(f.getGameScores());
        dto.setChessTimeMinutes(f.getChessTimeMinutes());
        dto.setChessResultType(f.getChessResultType());
        dto.setScheduledAt(f.getScheduledAt());
        dto.setCompletedAt(f.getCompletedAt());
        if (f.getPlayer1()      != null) dto.setPlayer1(playerService.toDTO(f.getPlayer1()));
        if (f.getPlayer2()      != null) dto.setPlayer2(playerService.toDTO(f.getPlayer2()));
        if (f.getWinnerPlayer() != null) dto.setWinnerPlayer(playerService.toDTO(f.getWinnerPlayer()));
        if (f.getTeam1()        != null) dto.setTeam1(teamService.toDTO(f.getTeam1()));
        if (f.getTeam2()        != null) dto.setTeam2(teamService.toDTO(f.getTeam2()));
        if (f.getWinnerTeam()   != null) dto.setWinnerTeam(teamService.toDTO(f.getWinnerTeam()));
        return dto;
    }
}
