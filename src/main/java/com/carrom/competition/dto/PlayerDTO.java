package com.carrom.competition.dto;

import com.carrom.competition.enums.GenderType;
import com.carrom.competition.enums.SkillLevel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PlayerDTO {
    private Long id;

    @NotBlank(message = "Player name is required")
    private String name;

    @NotNull(message = "Skill level is required")
    private SkillLevel skillLevel;

    @NotNull(message = "Gender is required")
    private GenderType gender;

    private String achievements;
    private Integer totalScore;
    private Integer matchesPlayed;
    private Integer matchesWon;
}
