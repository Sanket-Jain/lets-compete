package com.carrom.competition.dto;

import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.MatchStatus;
import lombok.Data;

import java.time.LocalDateTime;

@Data
public class FixtureDTO {
    private Long id;
    private Long tournamentId;
    private String tournamentName;
    private Integer levelNumber;
    private CompetitionType competitionType;
    private Integer matchNumber;
    private MatchStatus status;

    // Singles
    private PlayerDTO player1;
    private PlayerDTO player2;
    private PlayerDTO winnerPlayer;

    // Doubles
    private TeamDTO team1;
    private TeamDTO team2;
    private TeamDTO winnerTeam;

    // Scores
    private Integer scoreParticipant1;
    private Integer scoreParticipant2;

    private LocalDateTime scheduledAt;
    private LocalDateTime completedAt;
}
