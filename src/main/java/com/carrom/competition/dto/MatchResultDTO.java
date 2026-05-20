package com.carrom.competition.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class MatchResultDTO {

    @NotNull(message = "Score for participant 1 is required")
    @Min(value = 0, message = "Score cannot be negative")
    private Integer scoreParticipant1;

    @NotNull(message = "Score for participant 2 is required")
    @Min(value = 0, message = "Score cannot be negative")
    private Integer scoreParticipant2;

    // Optionally specify winner explicitly (useful for walkovers)
    private Long winnerPlayerId;
    private Long winnerTeamId;
}
