package com.carrom.competition.repository;

import com.carrom.competition.enums.MatchStatus;
import com.carrom.competition.model.Fixture;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FixtureRepository extends JpaRepository<Fixture, Long> {

    List<Fixture> findByTournamentIdOrderByLevelNumberAscMatchNumberAsc(Long tournamentId);

    List<Fixture> findByTournamentIdAndLevelNumber(Long tournamentId, Integer levelNumber);

    List<Fixture> findByTournamentIdAndLevelNumberAndStatus(
            Long tournamentId, Integer levelNumber, MatchStatus status);

    /**
     * Fixtures that are finished — COMPLETED (real match) or WALKOVER (bye).
     * Both have a winner and count as done for bracket advancement.
     */
    @Query("SELECT f FROM Fixture f WHERE f.tournament.id = :tournamentId " +
           "AND f.levelNumber = :level " +
           "AND (f.status = 'COMPLETED' OR f.status = 'WALKOVER') " +
           "AND (f.winnerPlayer IS NOT NULL OR f.winnerTeam IS NOT NULL)")
    List<Fixture> findCompletedFixturesForLevel(
            @Param("tournamentId") Long tournamentId,
            @Param("level") Integer level);

    /**
     * Count only genuinely pending fixtures (SCHEDULED or IN_PROGRESS).
     * WALKOVER (bye) fixtures are already done and must NOT be counted as pending.
     */
    @Query("SELECT COUNT(f) FROM Fixture f WHERE f.tournament.id = :tournamentId " +
           "AND f.levelNumber = :level " +
           "AND f.status IN ('SCHEDULED', 'IN_PROGRESS')")
    long countPendingFixturesForLevel(
            @Param("tournamentId") Long tournamentId,
            @Param("level") Integer level);

    List<Fixture> findByTournamentIdAndLevelNumberOrderByMatchNumberAsc(
            Long tournamentId, Integer levelNumber);
}
