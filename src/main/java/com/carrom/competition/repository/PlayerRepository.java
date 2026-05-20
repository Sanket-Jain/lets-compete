package com.carrom.competition.repository;

import com.carrom.competition.model.Player;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlayerRepository extends JpaRepository<Player, Long> {

    List<Player> findAllByOrderByTotalScoreDesc();

    @Query("SELECT p FROM Player p WHERE p.id IN :ids ORDER BY p.totalScore DESC")
    List<Player> findByIdInOrderByTotalScoreDesc(List<Long> ids);

    boolean existsByName(String name);
}
