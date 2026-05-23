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
    private String sportType;
    private Integer levelNumber;
    private CompetitionType competitionType;
    private Integer matchNumber;
    private MatchStatus status;
    private Boolean isBye;

    private PlayerDTO player1;
    private PlayerDTO player2;
    private PlayerDTO winnerPlayer;

    private TeamDTO team1;
    private TeamDTO team2;
    private TeamDTO winnerTeam;

    private Integer scoreParticipant1;
    private Integer scoreParticipant2;

    /** Badminton game-by-game scores JSON */
    private String gameScores;

    /** Chess: time limit in minutes for this fixture */
    private Integer chessTimeMinutes;

    /** Chess: result type string */
    private String chessResultType;

    private LocalDateTime scheduledAt;
    private LocalDateTime completedAt;
}
