package com.carrom.competition.service;

import com.carrom.competition.dto.TournamentDTO;
import com.carrom.competition.model.Tournament;
import com.carrom.competition.repository.TournamentRepository;
import jakarta.persistence.EntityNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class TournamentService {

    private final TournamentRepository tournamentRepository;

    public TournamentService(TournamentRepository tournamentRepository) {
        this.tournamentRepository = tournamentRepository;
    }

    public List<TournamentDTO> findAll() {
        return tournamentRepository.findAll()
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public List<TournamentDTO> findActive() {
        return tournamentRepository.findByIsActiveTrue()
                .stream().map(this::toDTO).collect(Collectors.toList());
    }

    public TournamentDTO findById(Long id) {
        return toDTO(getTournament(id));
    }

    public TournamentDTO create(TournamentDTO dto) {
        Tournament t = new Tournament();
        t.setName(dto.getName());
        t.setCompetitionType(dto.getCompetitionType());
        t.setDescription(dto.getDescription());
        t.setCurrentLevel(1);
        t.setTotalLevels(dto.getTotalLevels());
        t.setIsActive(true);
        return toDTO(tournamentRepository.save(t));
    }

    public TournamentDTO update(Long id, TournamentDTO dto) {
        Tournament t = getTournament(id);
        t.setName(dto.getName());
        t.setDescription(dto.getDescription());
        t.setTotalLevels(dto.getTotalLevels());
        if (dto.getIsActive() != null) t.setIsActive(dto.getIsActive());
        return toDTO(tournamentRepository.save(t));
    }

    public void delete(Long id) {
        tournamentRepository.deleteById(id);
    }

    private Tournament getTournament(Long id) {
        return tournamentRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Tournament not found: " + id));
    }

    public TournamentDTO toDTO(Tournament t) {
        TournamentDTO dto = new TournamentDTO();
        dto.setId(t.getId());
        dto.setName(t.getName());
        dto.setCompetitionType(t.getCompetitionType());
        dto.setDescription(t.getDescription());
        dto.setCurrentLevel(t.getCurrentLevel());
        dto.setTotalLevels(t.getTotalLevels());
        dto.setIsActive(t.getIsActive());
        return dto;
    }
}
