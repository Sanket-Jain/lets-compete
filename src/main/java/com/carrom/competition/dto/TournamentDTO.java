package com.carrom.competition.dto;

import com.carrom.competition.enums.CompetitionType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;

@Data
public class TournamentDTO {
    private Long id;

    @NotBlank(message = "Tournament name is required")
    private String name;

    @NotNull(message = "Competition type is required")
    private CompetitionType competitionType;

    private String description;
    private Integer currentLevel;
    private Integer totalLevels;
    private Boolean isActive;

    // Participant IDs for singles (player IDs) or doubles (team IDs)
    private List<Long> participantIds;
}
