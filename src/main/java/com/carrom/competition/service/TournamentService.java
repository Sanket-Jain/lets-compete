package com.carrom.competition.service;

import com.carrom.competition.dto.TournamentDTO;
import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.SportType;
import com.carrom.competition.model.Tournament;
import com.carrom.competition.repository.TournamentRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Transactional
public class TournamentService {

    private final TournamentRepository tournamentRepository;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public TournamentService(TournamentRepository tournamentRepository) {
        this.tournamentRepository = tournamentRepository;
    }

    public List<TournamentDTO> findAll() {
        return tournamentRepository.findAll().stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<TournamentDTO> findActive() {
        return tournamentRepository.findByIsActiveTrue().stream().map(this::toDTO).collect(Collectors.toList());
    }

    public TournamentDTO findById(Long id) {
        return toDTO(getTournament(id));
    }

    public TournamentDTO create(TournamentDTO dto) {
        validateTournamentRules(dto);

        Tournament t = new Tournament();
        t.setName(dto.getName());
        t.setSportType(dto.getSportType());
        t.setCompetitionType(dto.getCompetitionType());
        t.setDoublesType(dto.getDoublesType());
        t.setDescription(dto.getDescription());
        t.setCurrentLevel(1);
        t.setTotalLevels(dto.getTotalLevels());
        t.setIsActive(true);
        t.setChessTimeConfig(encodeChessConfig(dto.getChessTimeLimits()));
        return toDTO(tournamentRepository.save(t));
    }

    public TournamentDTO update(Long id, TournamentDTO dto) {
        Tournament t = getTournament(id);
        t.setName(dto.getName());
        t.setDescription(dto.getDescription());
        t.setTotalLevels(dto.getTotalLevels());
        if (dto.getIsActive() != null) t.setIsActive(dto.getIsActive());
        if (dto.getChessTimeLimits() != null) t.setChessTimeConfig(encodeChessConfig(dto.getChessTimeLimits()));
        if (dto.getDoublesType() != null) t.setDoublesType(dto.getDoublesType());
        return toDTO(tournamentRepository.save(t));
    }

    public void delete(Long id) {
        tournamentRepository.deleteById(id);
    }

    private void validateTournamentRules(TournamentDTO dto) {
        // Chess is singles only
        if (dto.getSportType() == SportType.CHESS && dto.getCompetitionType() != CompetitionType.SINGLES) {
            throw new IllegalArgumentException("Chess is a singles-only sport");
        }
        // Carrom doesn't support mixed doubles
        if (dto.getSportType() == SportType.CARROM
                && dto.getCompetitionType() == CompetitionType.DOUBLES
                && dto.getDoublesType() != null) {
            // Carrom doubles doesn't need a doublesType — just ignore it
        }
        // Badminton doubles must have a doublesType
        if (dto.getSportType() == SportType.BADMINTON
                && dto.getCompetitionType() == CompetitionType.DOUBLES
                && dto.getDoublesType() == null) {
            throw new IllegalArgumentException("Badminton doubles requires a doubles type (SAME_GENDER or MIXED)");
        }
    }

    public Tournament getTournament(Long id) {
        return tournamentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Tournament not found: " + id));
    }

    /** Get chess time limit in minutes for a specific level */
    public Integer getChessTimeForLevel(Tournament tournament, int level) {
        if (tournament.getChessTimeConfig() == null) return null;
        try {
            Map<String, Integer> config = objectMapper.readValue(
                    tournament.getChessTimeConfig(), new TypeReference<>() {});
            // Try exact level first, then fall back to closest lower level
            Integer time = config.get(String.valueOf(level));
            if (time != null) return time;
            for (int i = level - 1; i >= 1; i--) {
                time = config.get(String.valueOf(i));
                if (time != null) return time;
            }
            return null;
        } catch (Exception e) { return null; }
    }

    private String encodeChessConfig(Map<String, Integer> map) {
        if (map == null || map.isEmpty()) return null;
        try { return objectMapper.writeValueAsString(map); }
        catch (Exception e) { return null; }
    }

    public TournamentDTO toDTO(Tournament t) {
        TournamentDTO dto = new TournamentDTO();
        dto.setId(t.getId());
        dto.setName(t.getName());
        dto.setSportType(t.getSportType());
        dto.setCompetitionType(t.getCompetitionType());
        dto.setDoublesType(t.getDoublesType());
        dto.setDescription(t.getDescription());
        dto.setCurrentLevel(t.getCurrentLevel());
        dto.setTotalLevels(t.getTotalLevels());
        dto.setIsActive(t.getIsActive());
        if (t.getChessTimeConfig() != null) {
            try {
                dto.setChessTimeLimits(objectMapper.readValue(t.getChessTimeConfig(),
                        new TypeReference<>() {}));
            } catch (Exception ignored) {}
        }
        return dto;
    }
}
