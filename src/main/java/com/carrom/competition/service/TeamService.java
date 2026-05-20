package com.carrom.competition.service;

import com.carrom.competition.dto.PlayerDTO;
import com.carrom.competition.dto.TeamDTO;
import com.carrom.competition.model.Player;
import com.carrom.competition.model.Team;
import com.carrom.competition.repository.TeamRepository;
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

    public TeamService(TeamRepository teamRepository, PlayerService playerService) {
        this.teamRepository = teamRepository;
        this.playerService = playerService;
    }

    public List<TeamDTO> findAll() {
        return teamRepository.findAllByOrderByTotalScoreDesc()
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

        Team team = new Team();
        team.setName(dto.getName());
        team.setPlayer1(p1);
        team.setPlayer2(p2);
        team.setTotalScore(0);
        team.setMatchesPlayed(0);
        team.setMatchesWon(0);
        return toDTO(teamRepository.save(team));
    }

    public TeamDTO update(Long id, TeamDTO dto) {
        Team team = getTeam(id);
        team.setName(dto.getName());
        if (dto.getPlayer1Id() != null) team.setPlayer1(playerService.getPlayer(dto.getPlayer1Id()));
        if (dto.getPlayer2Id() != null) team.setPlayer2(playerService.getPlayer(dto.getPlayer2Id()));
        return toDTO(teamRepository.save(team));
    }

    public void delete(Long id) {
        teamRepository.deleteById(id);
    }

    public Team getTeam(Long id) {
        return teamRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Team not found with id: " + id));
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
        return dto;
    }
}
