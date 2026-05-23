package com.carrom.competition.service;

import com.carrom.competition.dto.PlayerDTO;
import com.carrom.competition.dto.TeamDTO;
import com.carrom.competition.enums.DoublesType;
import com.carrom.competition.enums.GenderType;
import com.carrom.competition.model.Player;
import com.carrom.competition.model.Team;
import com.carrom.competition.model.Tournament;
import com.carrom.competition.repository.TeamRepository;
import com.carrom.competition.repository.TournamentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class TeamService {

    private final TeamRepository teamRepository;
    private final PlayerService playerService;
    private final TournamentRepository tournamentRepository;

    public TeamService(TeamRepository teamRepository,
                       PlayerService playerService,
                       TournamentRepository tournamentRepository) {
        this.teamRepository       = teamRepository;
        this.playerService        = playerService;
        this.tournamentRepository = tournamentRepository;
    }

    public List<TeamDTO> findAll() {
        return teamRepository.findAllByOrderByTotalScoreDesc()
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<TeamDTO> findByTournament(Long tournamentId) {
        return teamRepository.findByTournamentId(tournamentId)
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public TeamDTO findById(Long id) {
        return toDTO(getTeam(id));
    }

    public TeamDTO create(TeamDTO dto) {
        Player p1 = playerService.getPlayer(dto.getPlayer1Id());
        Player p2 = playerService.getPlayer(dto.getPlayer2Id());

        if (p1.getId().equals(p2.getId())) {
            throw new IllegalArgumentException("A team cannot have the same player twice");
        }

        Tournament tournament = null;
        if (dto.getTournamentId() != null) {
            tournament = tournamentRepository.findById(dto.getTournamentId())
                    .orElseThrow(() -> new EntityNotFoundException("Tournament not found: " + dto.getTournamentId()));

            // ── Rule: one team per player per tournament ──────────────────────
            validatePlayerNotInTournament(p1.getId(), dto.getTournamentId(), null);
            validatePlayerNotInTournament(p2.getId(), dto.getTournamentId(), null);

            // ── Rule: Badminton mixed doubles — one male + one female ──────────
            if (tournament.getDoublesType() == DoublesType.MIXED) {
                boolean hasMale   = p1.getGender() == GenderType.MALE   || p2.getGender() == GenderType.MALE;
                boolean hasFemale = p1.getGender() == GenderType.FEMALE || p2.getGender() == GenderType.FEMALE;
                if (!hasMale || !hasFemale) {
                    throw new IllegalArgumentException(
                            "Mixed doubles requires exactly one male and one female player");
                }
            }
        }

        Team team = new Team();
        team.setName(dto.getName());
        team.setPlayer1(p1);
        team.setPlayer2(p2);
        team.setTournament(tournament);
        team.setTotalScore(0);
        team.setMatchesPlayed(0);
        team.setMatchesWon(0);
        return toDTO(teamRepository.save(team));
    }

    public TeamDTO update(Long id, TeamDTO dto) {
        Team team = getTeam(id);
        team.setName(dto.getName());
        if (dto.getPlayer1Id() != null) {
            Player p1 = playerService.getPlayer(dto.getPlayer1Id());
            Player p2 = dto.getPlayer2Id() != null ? playerService.getPlayer(dto.getPlayer2Id()) : team.getPlayer2();
            if (p1.getId().equals(p2.getId())) {
                throw new IllegalArgumentException("A team cannot have the same player twice");
            }
            Long tournamentId = team.getTournament() != null ? team.getTournament().getId() : null;
            if (tournamentId != null) {
                validatePlayerNotInTournament(p1.getId(), tournamentId, id);
                validatePlayerNotInTournament(p2.getId(), tournamentId, id);
            }
            team.setPlayer1(p1);
            team.setPlayer2(p2);
        }
        return toDTO(teamRepository.save(team));
    }

    public void delete(Long id) {
        teamRepository.deleteById(id);
    }

    /**
     * Validates the given player is not already in another team in this tournament.
     * @param excludeTeamId team being edited (null for create) — exclude self from check
     */
    private void validatePlayerNotInTournament(Long playerId, Long tournamentId, Long excludeTeamId) {
        List<Team> existing = teamRepository.findByTournamentId(tournamentId).stream()
                .filter(t -> !t.getId().equals(excludeTeamId))
                .filter(t -> t.getPlayer1().getId().equals(playerId)
                          || t.getPlayer2().getId().equals(playerId))
                .collect(Collectors.toList());
        if (!existing.isEmpty()) {
            Team conflict = existing.get(0);
            Player conflictPlayer = conflict.getPlayer1().getId().equals(playerId)
                    ? conflict.getPlayer1() : conflict.getPlayer2();
            throw new IllegalArgumentException(
                    "Player '" + conflictPlayer.getName() + "' is already in team '"
                    + conflict.getName() + "' for this tournament. " +
                    "A player can only be in one team per tournament.");
        }
    }

    public Team getTeam(Long id) {
        return teamRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Team not found: " + id));
    }

    public TeamDTO toDTO(Team t) {
        TeamDTO dto = new TeamDTO();
        dto.setId(t.getId());
        dto.setName(t.getName());
        dto.setPlayer1Id(t.getPlayer1().getId());
        dto.setPlayer2Id(t.getPlayer2().getId());
        dto.setPlayer1(playerService.toDTO(t.getPlayer1()));
        dto.setPlayer2(playerService.toDTO(t.getPlayer2()));
        dto.setTotalScore(t.getTotalScore());
        dto.setMatchesPlayed(t.getMatchesPlayed());
        dto.setMatchesWon(t.getMatchesWon());
        if (t.getTournament() != null) dto.setTournamentId(t.getTournament().getId());
        return dto;
    }
}
