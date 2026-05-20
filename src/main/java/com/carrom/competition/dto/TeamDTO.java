package com.carrom.competition.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class TeamDTO {
    private Long id;

    @NotBlank(message = "Team name is required")
    private String name;

    @NotNull(message = "Player 1 ID is required")
    private Long player1Id;

    @NotNull(message = "Player 2 ID is required")
    private Long player2Id;

    private Integer totalScore;
    private Integer matchesPlayed;
    private Integer matchesWon;

    // For response
    private PlayerDTO player1;
    private PlayerDTO player2;
}
