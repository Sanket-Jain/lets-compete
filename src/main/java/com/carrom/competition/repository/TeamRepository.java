package com.carrom.competition.repository;

import com.carrom.competition.model.Team;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamRepository extends JpaRepository<Team, Long> {

    @Query("SELECT t FROM Team t WHERE t.id IN :ids ORDER BY t.totalScore DESC")
    List<Team> findByIdInOrderByTotalScoreDesc(@Param("ids") List<Long> ids);

    List<Team> findAllByOrderByTotalScoreDesc();

    @Query("SELECT t FROM Team t WHERE t.player1.id = :playerId OR t.player2.id = :playerId")
    List<Team> findByPlayerId(@Param("playerId") Long playerId);

    /** Find all teams registered in a specific tournament */
    @Query("SELECT t FROM Team t WHERE t.tournament.id = :tournamentId")
    List<Team> findByTournamentId(@Param("tournamentId") Long tournamentId);

    /**
     * Check if a player is already in a team for a given tournament.
     * Used to enforce: one team per player per tournament.
     */
    @Query("SELECT COUNT(t) FROM Team t WHERE t.tournament.id = :tournamentId " +
           "AND (t.player1.id = :playerId OR t.player2.id = :playerId)")
    long countPlayerInTournament(@Param("tournamentId") Long tournamentId,
                                  @Param("playerId") Long playerId);
}
