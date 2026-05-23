package com.carrom.competition.dto;

import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.DoublesType;
import com.carrom.competition.enums.SportType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class TournamentDTO {
    private Long id;

    @NotBlank(message = "Tournament name is required")
    private String name;

    @NotNull(message = "Sport type is required")
    private SportType sportType;

    @NotNull(message = "Competition type is required")
    private CompetitionType competitionType;

    /** Badminton doubles: SAME_GENDER or MIXED. Null otherwise. */
    private DoublesType doublesType;

    private String description;
    private Integer currentLevel;
    private Integer totalLevels;
    private Boolean isActive;

    /**
     * Chess only: map of level number → time in minutes.
     * e.g. {"1": 10, "2": 15, "3": 20}
     */
    private Map<String, Integer> chessTimeLimits;

    private List<Long> participantIds;
}
