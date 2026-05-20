package com.carrom.competition.service;

import com.carrom.competition.dto.FixtureDTO;
import com.carrom.competition.dto.MatchResultDTO;
import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.MatchStatus;
import com.carrom.competition.model.*;
import com.carrom.competition.repository.*;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@Transactional
public class FixtureService {

    private final FixtureRepository fixtureRepository;
    private final TournamentRepository tournamentRepository;
    private final PlayerRepository playerRepository;
    private final TeamRepository teamRepository;
    private final PlayerService playerService;
    private final TeamService teamService;

    public FixtureService(FixtureRepository fixtureRepository,
                          TournamentRepository tournamentRepository,
                          PlayerRepository playerRepository,
                          TeamRepository teamRepository,
                          PlayerService playerService,
                          TeamService teamService) {
        this.fixtureRepository = fixtureRepository;
        this.tournamentRepository = tournamentRepository;
        this.playerRepository = playerRepository;
        this.teamRepository = teamRepository;
        this.playerService = playerService;
        this.teamService = teamService;
    }

    // ─── Bracket sizing helpers ───────────────────────────────────────────────────

    /**
     * Returns the smallest power of 2 >= n.
     * e.g. 5 → 8, 6 → 8, 7 → 8, 8 → 8, 9 → 16
     */
    private int nextPowerOfTwo(int n) {
        if (n <= 1) return 1;
        int p = 1;
        while (p < n) p <<= 1;
        return p;
    }

    /**
     * Number of byes needed so the bracket is always a power-of-2 after Level 1.
     * byes = nextPowerOfTwo(n) - n
     * e.g. 6 players → 8 - 6 = 2 byes in Level 1 → Level 2 always has 4 (even).
     */
    private int byesNeeded(int n) {
        return nextPowerOfTwo(n) - n;
    }

    // ─── Generate Level 1 fixtures (random draw + byes) ─────────────────────────

    public List<FixtureDTO> generateLevel1Fixtures(Long tournamentId, List<Long> participantIds) {
        Tournament tournament = getTournament(tournamentId);

        if (tournament.getCurrentLevel() != 1) {
            throw new IllegalStateException("Level 1 fixtures already generated for this tournament");
        }

        long existingCount = fixtureRepository.countPendingFixturesForLevel(tournamentId, 1)
                + fixtureRepository.findCompletedFixturesForLevel(tournamentId, 1).size();
        if (existingCount > 0) {
            throw new IllegalStateException("Fixtures for Level 1 already exist");
        }

        if (participantIds.size() < 2) {
            throw new IllegalArgumentException("At least 2 participants are required");
        }

        // Random shuffle for Level 1
        List<Long> shuffled = new ArrayList<>(participantIds);
        Collections.shuffle(shuffled);

        int n    = shuffled.size();
        int byes = byesNeeded(n);

        List<Fixture> fixtures = new ArrayList<>();
        int matchNum = 1;

        /*
         * Bye strategy for Level 1:
         * ─ Byes are assigned to the LAST participants in the shuffled list
         *   (positions n-byes .. n-1).  Being at the end after a random shuffle
         *   means the bye assignment is itself random — no participant gets an
         *   unfair seeding advantage at this stage.
         * ─ The remaining participants (positions 0 .. n-byes-1) are paired
         *   sequentially: 0 vs 1, 2 vs 3, …
         * ─ This guarantees exactly nextPowerOfTwo(n)/2 winners advance to
         *   Level 2, so Level 2 and all subsequent levels are even.
         */

        // Real matches first
        int realPlayers = n - byes;
        for (int i = 0; i < realPlayers; i += 2) {
            fixtures.add(buildMatch(tournament, shuffled.get(i), shuffled.get(i + 1), 1, matchNum++, false));
        }

        // Bye fixtures — auto-completed immediately, winner = the single participant
        for (int i = realPlayers; i < n; i++) {
            fixtures.add(buildBye(tournament, shuffled.get(i), 1, matchNum++));
        }

        return fixtureRepository.saveAll(fixtures)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Generate next-level fixtures from winners (score-seeded) ────────────────

    public List<FixtureDTO> generateNextLevelFixtures(Long tournamentId) {
        Tournament tournament = getTournament(tournamentId);
        int currentLevel = tournament.getCurrentLevel();

        long pending = fixtureRepository.countPendingFixturesForLevel(tournamentId, currentLevel);
        if (pending > 0) {
            throw new IllegalStateException(
                    "Cannot advance: " + pending + " match(es) still pending in Level " + currentLevel);
        }

        List<Fixture> completed = fixtureRepository.findCompletedFixturesForLevel(tournamentId, currentLevel);
        if (completed.isEmpty()) {
            throw new IllegalStateException("No completed matches found for Level " + currentLevel);
        }

        // Collect winner IDs (sorted by score DESC — highest vs lowest seeding)
        List<Long> winnerIds;
        if (tournament.getCompetitionType() == CompetitionType.SINGLES) {
            List<Long> ids = completed.stream()
                    .filter(f -> f.getWinnerPlayer() != null)
                    .map(f -> f.getWinnerPlayer().getId())
                    .distinct()
                    .collect(Collectors.toList());
            winnerIds = playerRepository.findByIdInOrderByTotalScoreDesc(ids)
                    .stream().map(Player::getId).collect(Collectors.toList());
        } else {
            List<Long> ids = completed.stream()
                    .filter(f -> f.getWinnerTeam() != null)
                    .map(f -> f.getWinnerTeam().getId())
                    .distinct()
                    .collect(Collectors.toList());
            winnerIds = teamRepository.findByIdInOrderByTotalScoreDesc(ids)
                    .stream().map(Team::getId).collect(Collectors.toList());
        }

        if (winnerIds.size() < 2) {
            throw new IllegalStateException("Not enough winners to generate next level fixtures");
        }

        /*
         * Because Level 1 already padded to a power-of-2, the number of winners
         * here is always a power of 2 (4, 8, 16 …) and therefore always even.
         * No byes should ever be needed from Level 2 onward.
         * We assert this and pair highest-score vs lowest-score.
         */
        if (winnerIds.size() % 2 != 0) {
            // Safety-net: should never happen after correct Level 1 generation
            throw new IllegalStateException(
                    "Unexpected odd number of winners (" + winnerIds.size() + ") in Level " + currentLevel +
                    ". Ensure Level 1 was generated via this system.");
        }

        int nextLevel = currentLevel + 1;
        tournament.setCurrentLevel(nextLevel);
        tournamentRepository.save(tournament);

        // Seed: rank 1 vs rank N, rank 2 vs rank N-1, …
        List<Fixture> fixtures = new ArrayList<>();
        int matchNum = 1;
        int left = 0, right = winnerIds.size() - 1;
        while (left < right) {
            fixtures.add(buildMatch(tournament, winnerIds.get(left), winnerIds.get(right),
                    nextLevel, matchNum++, false));
            left++;
            right--;
        }

        return fixtureRepository.saveAll(fixtures)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Fixture builders ─────────────────────────────────────────────────────────

    private Fixture buildMatch(Tournament t, Long id1, Long id2, int level, int matchNum, boolean bye) {
        Fixture f = new Fixture();
        f.setTournament(t);
        f.setLevelNumber(level);
        f.setCompetitionType(t.getCompetitionType());
        f.setStatus(MatchStatus.SCHEDULED);
        f.setMatchNumber(matchNum);
        f.setScoreParticipant1(0);
        f.setScoreParticipant2(0);
        f.setIsBye(bye);

        if (t.getCompetitionType() == CompetitionType.SINGLES) {
            f.setPlayer1(playerService.getPlayer(id1));
            f.setPlayer2(playerService.getPlayer(id2));
        } else {
            f.setTeam1(teamService.getTeam(id1));
            f.setTeam2(teamService.getTeam(id2));
        }
        return f;
    }

    /**
     * Creates a bye fixture: one participant, no opponent, auto-completed immediately.
     * Winner = the participant. Score = 0 (default bye score).
     */
    private Fixture buildBye(Tournament t, Long participantId, int level, int matchNum) {
        Fixture f = new Fixture();
        f.setTournament(t);
        f.setLevelNumber(level);
        f.setCompetitionType(t.getCompetitionType());
        f.setMatchNumber(matchNum);
        f.setScoreParticipant1(0);
        f.setScoreParticipant2(0);
        f.setIsBye(true);
        f.setStatus(MatchStatus.WALKOVER);    // immediately "done"
        f.setCompletedAt(LocalDateTime.now());

        if (t.getCompetitionType() == CompetitionType.SINGLES) {
            Player p = playerService.getPlayer(participantId);
            f.setPlayer1(p);
            f.setWinnerPlayer(p);             // auto-advance
        } else {
            Team team = teamService.getTeam(participantId);
            f.setTeam1(team);
            f.setWinnerTeam(team);
        }
        return f;
    }

    // ─── Record match result ──────────────────────────────────────────────────────

    public FixtureDTO recordResult(Long fixtureId, MatchResultDTO result) {
        Fixture fixture = fixtureRepository.findById(fixtureId)
                .orElseThrow(() -> new EntityNotFoundException("Fixture not found: " + fixtureId));

        if (fixture.getStatus() == MatchStatus.COMPLETED || fixture.getStatus() == MatchStatus.WALKOVER) {
            throw new IllegalStateException("Match is already completed");
        }
        if (Boolean.TRUE.equals(fixture.getIsBye())) {
            throw new IllegalStateException("Cannot record result for a bye match");
        }

        fixture.setScoreParticipant1(result.getScoreParticipant1());
        fixture.setScoreParticipant2(result.getScoreParticipant2());
        fixture.setStatus(MatchStatus.COMPLETED);
        fixture.setCompletedAt(LocalDateTime.now());

        if (fixture.getCompetitionType() == CompetitionType.SINGLES) {
            Player p1 = fixture.getPlayer1();
            Player p2 = fixture.getPlayer2();
            Player winner, loser;

            if (result.getScoreParticipant1() > result.getScoreParticipant2()) {
                winner = p1; loser = p2;
            } else if (result.getScoreParticipant2() > result.getScoreParticipant1()) {
                winner = p2; loser = p1;
            } else {
                if (result.getWinnerPlayerId() != null) {
                    winner = playerService.getPlayer(result.getWinnerPlayerId());
                    loser  = winner.getId().equals(p1.getId()) ? p2 : p1;
                } else {
                    throw new IllegalArgumentException("Scores are tied — please specify a winner");
                }
            }

            fixture.setWinnerPlayer(winner);
            updatePlayerStats(winner, Math.max(result.getScoreParticipant1(), result.getScoreParticipant2()), true);
            updatePlayerStats(loser,  Math.min(result.getScoreParticipant1(), result.getScoreParticipant2()), false);

        } else {
            Team t1 = fixture.getTeam1();
            Team t2 = fixture.getTeam2();
            Team winner, loser;

            if (result.getScoreParticipant1() > result.getScoreParticipant2()) {
                winner = t1; loser = t2;
            } else if (result.getScoreParticipant2() > result.getScoreParticipant1()) {
                winner = t2; loser = t1;
            } else {
                if (result.getWinnerTeamId() != null) {
                    winner = teamService.getTeam(result.getWinnerTeamId());
                    loser  = winner.getId().equals(t1.getId()) ? t2 : t1;
                } else {
                    throw new IllegalArgumentException("Scores are tied — please specify a winner team");
                }
            }

            fixture.setWinnerTeam(winner);
            updateTeamStats(winner, Math.max(result.getScoreParticipant1(), result.getScoreParticipant2()), true);
            updateTeamStats(loser,  Math.min(result.getScoreParticipant1(), result.getScoreParticipant2()), false);
        }

        return toDTO(fixtureRepository.save(fixture));
    }

    // ─── Stats helpers ────────────────────────────────────────────────────────────

    private void updatePlayerStats(Player player, int score, boolean won) {
        player.setMatchesPlayed(player.getMatchesPlayed() + 1);
        player.setTotalScore(player.getTotalScore() + score);
        if (won) player.setMatchesWon(player.getMatchesWon() + 1);
        playerRepository.save(player);
    }

    private void updateTeamStats(Team team, int score, boolean won) {
        team.setMatchesPlayed(team.getMatchesPlayed() + 1);
        team.setTotalScore(team.getTotalScore() + score);
        if (won) team.setMatchesWon(team.getMatchesWon() + 1);
        teamRepository.save(team);
    }

    public void deleteById(Long id) {
        fixtureRepository.deleteById(id);
    }

    // ─── Queries ──────────────────────────────────────────────────────────────────

    public List<FixtureDTO> getFixturesByTournament(Long tournamentId) {
        return fixtureRepository.findByTournamentIdOrderByLevelNumberAscMatchNumberAsc(tournamentId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<FixtureDTO> getFixturesByLevel(Long tournamentId, Integer level) {
        return fixtureRepository.findByTournamentIdAndLevelNumber(tournamentId, level)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────────

    private Tournament getTournament(Long id) {
        return tournamentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Tournament not found: " + id));
    }

    public FixtureDTO toDTO(Fixture f) {
        FixtureDTO dto = new FixtureDTO();
        dto.setId(f.getId());
        dto.setTournamentId(f.getTournament().getId());
        dto.setTournamentName(f.getTournament().getName());
        dto.setLevelNumber(f.getLevelNumber());
        dto.setCompetitionType(f.getCompetitionType());
        dto.setMatchNumber(f.getMatchNumber());
        dto.setStatus(f.getStatus());
        dto.setIsBye(f.getIsBye());
        dto.setScoreParticipant1(f.getScoreParticipant1());
        dto.setScoreParticipant2(f.getScoreParticipant2());
        dto.setScheduledAt(f.getScheduledAt());
        dto.setCompletedAt(f.getCompletedAt());

        if (f.getPlayer1() != null)      dto.setPlayer1(playerService.toDTO(f.getPlayer1()));
        if (f.getPlayer2() != null)      dto.setPlayer2(playerService.toDTO(f.getPlayer2()));
        if (f.getWinnerPlayer() != null) dto.setWinnerPlayer(playerService.toDTO(f.getWinnerPlayer()));

        if (f.getTeam1() != null)        dto.setTeam1(teamService.toDTO(f.getTeam1()));
        if (f.getTeam2() != null)        dto.setTeam2(teamService.toDTO(f.getTeam2()));
        if (f.getWinnerTeam() != null)   dto.setWinnerTeam(teamService.toDTO(f.getWinnerTeam()));

        return dto;
    }
}
