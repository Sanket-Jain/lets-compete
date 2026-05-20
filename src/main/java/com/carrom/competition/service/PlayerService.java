package com.carrom.competition.service;

import com.carrom.competition.dto.PlayerDTO;
import com.carrom.competition.model.Player;
import com.carrom.competition.repository.PlayerRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class PlayerService {

    private final PlayerRepository playerRepository;

    public PlayerService(PlayerRepository playerRepository) {
        this.playerRepository = playerRepository;
    }

    public List<PlayerDTO> findAll() {
        return playerRepository.findAllByOrderByTotalScoreDesc()
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public PlayerDTO findById(Long id) {
        return toDTO(getPlayer(id));
    }

    public PlayerDTO create(PlayerDTO dto) {
        Player player = new Player();
        player.setName(dto.getName());
        player.setSkillLevel(dto.getSkillLevel());
        player.setAchievements(dto.getAchievements());
        player.setTotalScore(0);
        player.setMatchesPlayed(0);
        player.setMatchesWon(0);
        return toDTO(playerRepository.save(player));
    }

    public PlayerDTO update(Long id, PlayerDTO dto) {
        Player player = getPlayer(id);
        player.setName(dto.getName());
        player.setSkillLevel(dto.getSkillLevel());
        player.setAchievements(dto.getAchievements());
        return toDTO(playerRepository.save(player));
    }

    public void delete(Long id) {
        playerRepository.deleteById(id);
    }

    public Player getPlayer(Long id) {
        return playerRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Player not found with id: " + id));
    }

    public PlayerDTO toDTO(Player p) {
        PlayerDTO dto = new PlayerDTO();
        dto.setId(p.getId());
        dto.setName(p.getName());
        dto.setSkillLevel(p.getSkillLevel());
        dto.setAchievements(p.getAchievements());
        dto.setTotalScore(p.getTotalScore());
        dto.setMatchesPlayed(p.getMatchesPlayed());
        dto.setMatchesWon(p.getMatchesWon());
        return dto;
    }
}
