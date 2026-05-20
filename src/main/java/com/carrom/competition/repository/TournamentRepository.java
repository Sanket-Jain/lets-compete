package com.carrom.competition.repository;

import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.model.Tournament;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TournamentRepository extends JpaRepository<Tournament, Long> {
    List<Tournament> findByCompetitionType(CompetitionType type);
    List<Tournament> findByIsActiveTrue();
}
