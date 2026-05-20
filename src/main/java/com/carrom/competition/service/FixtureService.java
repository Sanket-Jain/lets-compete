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

    // ─── Generate Level 1 fixtures (random draw) ────────────────────────────────

    public List<FixtureDTO> generateLevel1Fixtures(Long tournamentId, List<Long> participantIds) {
        Tournament tournament = getTournament(tournamentId);

        if (tournament.getCurrentLevel() != 1) {
            throw new IllegalStateException("Level 1 fixtures already generated for this tournament");
        }

        long existingCount = fixtureRepository.countPendingFixturesForLevel(tournamentId, 1) +
                fixtureRepository.findCompletedFixturesForLevel(tournamentId, 1).size();
        if (existingCount > 0) {
            throw new IllegalStateException("Fixtures for Level 1 already exist");
        }

        List<Long> shuffled = new ArrayList<>(participantIds);
        Collections.shuffle(shuffled);

        return createFixtures(tournament, shuffled, 1);
    }

    // ─── Generate next level fixtures from winners (score-sorted seeding) ────────

    public List<FixtureDTO> generateNextLevelFixtures(Long tournamentId) {
        Tournament tournament = getTournament(tournamentId);
        int currentLevel = tournament.getCurrentLevel();

        // Validate all current level matches are done
        long pending = fixtureRepository.countPendingFixturesForLevel(tournamentId, currentLevel);
        if (pending > 0) {
            throw new IllegalStateException(
                    "Cannot advance: " + pending + " match(es) still pending in Level " + currentLevel);
        }

        List<Fixture> completed = fixtureRepository.findCompletedFixturesForLevel(tournamentId, currentLevel);
        if (completed.isEmpty()) {
            throw new IllegalStateException("No completed matches found for Level " + currentLevel);
        }

        // Collect winners
        List<Long> winnerIds;
        if (tournament.getCompetitionType() == CompetitionType.SINGLES) {
            winnerIds = completed.stream()
                    .filter(f -> f.getWinnerPlayer() != null)
                    .map(f -> f.getWinnerPlayer().getId())
                    .distinct()
                    .collect(Collectors.toList());
            // Sort by totalScore DESC
            List<Player> sortedWinners = playerRepository.findByIdInOrderByTotalScoreDesc(winnerIds);
            winnerIds = sortedWinners.stream().map(Player::getId).collect(Collectors.toList());
        } else {
            winnerIds = completed.stream()
                    .filter(f -> f.getWinnerTeam() != null)
                    .map(f -> f.getWinnerTeam().getId())
                    .distinct()
                    .collect(Collectors.toList());
            List<Team> sortedWinners = teamRepository.findByIdInOrderByTotalScoreDesc(winnerIds);
            winnerIds = sortedWinners.stream().map(Team::getId).collect(Collectors.toList());
        }

        if (winnerIds.size() < 2) {
            throw new IllegalStateException("Not enough winners to generate next level fixtures");
        }

        int nextLevel = currentLevel + 1;
        tournament.setCurrentLevel(nextLevel);
        tournamentRepository.save(tournament);

        return createFixtures(tournament, winnerIds, nextLevel);
    }

    // ─── Internal: pair participants and persist fixtures ─────────────────────────

    private List<FixtureDTO> createFixtures(Tournament tournament, List<Long> participantIds, int level) {
        // Score-based seeding: highest vs lowest, second-highest vs second-lowest
        // For random (level 1), participantIds are already shuffled, so pairing 0-1, 2-3 etc. works too
        List<Long> sorted = new ArrayList<>(participantIds);

        // For level > 1, pairing strategy: highest score vs lowest
        // Index 0 vs last, index 1 vs second-last ...
        List<long[]> pairs = new ArrayList<>();
        int left = 0, right = sorted.size() - 1;
        while (left < right) {
            pairs.add(new long[]{sorted.get(left), sorted.get(right)});
            left++;
            right--;
        }
        // If odd number of participants, last one gets a bye (not paired)

        List<Fixture> fixtures = new ArrayList<>();
        int matchNum = 1;
        for (long[] pair : pairs) {
            Fixture fixture = new Fixture();
            fixture.setTournament(tournament);
            fixture.setLevelNumber(level);
            fixture.setCompetitionType(tournament.getCompetitionType());
            fixture.setStatus(MatchStatus.SCHEDULED);
            fixture.setMatchNumber(matchNum++);
            fixture.setScoreParticipant1(0);
            fixture.setScoreParticipant2(0);

            if (tournament.getCompetitionType() == CompetitionType.SINGLES) {
                fixture.setPlayer1(playerService.getPlayer(pair[0]));
                fixture.setPlayer2(playerService.getPlayer(pair[1]));
            } else {
                fixture.setTeam1(teamService.getTeam(pair[0]));
                fixture.setTeam2(teamService.getTeam(pair[1]));
            }

            fixtures.add(fixture);
        }

        return fixtureRepository.saveAll(fixtures)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    // ─── Record match result ──────────────────────────────────────────────────────

    public FixtureDTO recordResult(Long fixtureId, MatchResultDTO result) {
        Fixture fixture = fixtureRepository.findById(fixtureId)
                .orElseThrow(() -> new EntityNotFoundException("Fixture not found with id: " + fixtureId));

        if (fixture.getStatus() == MatchStatus.COMPLETED) {
            throw new IllegalStateException("Match is already completed");
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
                // Tie-break: explicit winner provided
                if (result.getWinnerPlayerId() != null) {
                    winner = playerService.getPlayer(result.getWinnerPlayerId());
                    loser = winner.getId().equals(p1.getId()) ? p2 : p1;
                } else {
                    throw new IllegalArgumentException("Scores are tied — please specify a winner");
                }
            }

            fixture.setWinnerPlayer(winner);
            updatePlayerStats(winner, result.getScoreParticipant1() > result.getScoreParticipant2()
                    ? result.getScoreParticipant1() : result.getScoreParticipant2(), true);
            updatePlayerStats(loser, result.getScoreParticipant1() < result.getScoreParticipant2()
                    ? result.getScoreParticipant1() : result.getScoreParticipant2(), false);

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
                    loser = winner.getId().equals(t1.getId()) ? t2 : t1;
                } else {
                    throw new IllegalArgumentException("Scores are tied — please specify a winner team");
                }
            }

            fixture.setWinnerTeam(winner);
            updateTeamStats(winner, result.getScoreParticipant1() > result.getScoreParticipant2()
                    ? result.getScoreParticipant1() : result.getScoreParticipant2(), true);
            updateTeamStats(loser, result.getScoreParticipant1() < result.getScoreParticipant2()
                    ? result.getScoreParticipant1() : result.getScoreParticipant2(), false);
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
                .orElseThrow(() -> new EntityNotFoundException("Tournament not found with id: " + id));
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
        dto.setScoreParticipant1(f.getScoreParticipant1());
        dto.setScoreParticipant2(f.getScoreParticipant2());
        dto.setScheduledAt(f.getScheduledAt());
        dto.setCompletedAt(f.getCompletedAt());

        if (f.getPlayer1() != null) dto.setPlayer1(playerService.toDTO(f.getPlayer1()));
        if (f.getPlayer2() != null) dto.setPlayer2(playerService.toDTO(f.getPlayer2()));
        if (f.getWinnerPlayer() != null) dto.setWinnerPlayer(playerService.toDTO(f.getWinnerPlayer()));

        if (f.getTeam1() != null) dto.setTeam1(teamService.toDTO(f.getTeam1()));
        if (f.getTeam2() != null) dto.setTeam2(teamService.toDTO(f.getTeam2()));
        if (f.getWinnerTeam() != null) dto.setWinnerTeam(teamService.toDTO(f.getWinnerTeam()));

        return dto;
    }
}
