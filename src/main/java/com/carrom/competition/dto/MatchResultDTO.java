package com.carrom.competition.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class MatchResultDTO {

    @NotNull(message = "Score for participant 1 is required")
    @Min(value = 0, message = "Score cannot be negative")
    private Integer scoreParticipant1;

    @NotNull(message = "Score for participant 2 is required")
    @Min(value = 0, message = "Score cannot be negative")
    private Integer scoreParticipant2;

    /** Explicit winner for tie-breaks (singles) */
    private Long winnerPlayerId;
    private Long winnerTeamId;

    /**
     * Badminton: list of per-game scores.
     * Each map has keys: g1p1, g1p2 (game 1 player 1/2), g2p1, g2p2, g3p1, g3p2
     * Stored as JSON string on the fixture.
     */
    private List<Map<String, Integer>> badmintonGameScores;

    /**
     * Chess: result type — one of:
     * CHECKMATE, RESIGNATION, TIMEOUT, STALEMATE, DRAW_AGREEMENT,
     * INSUFFICIENT_MATERIAL, THREEFOLD_REPETITION, FIFTY_MOVE_RULE,
     * DRAW_BY_PERPETUAL_CHECK
     */
    private String chessResultType;
}
