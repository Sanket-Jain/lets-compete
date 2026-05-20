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
     * Completed fixtures that have a winner assigned (includes byes auto-completed).
     */
    @Query("SELECT f FROM Fixture f WHERE f.tournament.id = :tournamentId " +
           "AND f.levelNumber = :level AND f.status = 'COMPLETED' " +
           "AND (f.winnerPlayer IS NOT NULL OR f.winnerTeam IS NOT NULL)")
    List<Fixture> findCompletedFixturesForLevel(
            @Param("tournamentId") Long tournamentId, @Param("level") Integer level);

    /**
     * Count fixtures that are not yet completed (SCHEDULED or IN_PROGRESS),
     * excluding byes (which are auto-completed immediately).
     */
    @Query("SELECT COUNT(f) FROM Fixture f WHERE f.tournament.id = :tournamentId " +
           "AND f.levelNumber = :level AND f.status != 'COMPLETED'")
    long countPendingFixturesForLevel(
            @Param("tournamentId") Long tournamentId, @Param("level") Integer level);

    /**
     * All fixtures (including byes) for a level.
     */
    List<Fixture> findByTournamentIdAndLevelNumberOrderByMatchNumberAsc(
            Long tournamentId, Integer levelNumber);
}
