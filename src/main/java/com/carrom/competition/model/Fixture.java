package com.carrom.competition.model;

import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.MatchStatus;
import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "fixtures")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Fixture {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "tournament_id", nullable = false)
    private Tournament tournament;

    @Column(name = "level_number", nullable = false)
    private Integer levelNumber;

    @Enumerated(EnumType.STRING)
    @Column(name = "competition_type", nullable = false)
    private CompetitionType competitionType;

    // ── SINGLES ──────────────────────────────────────────────────────
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "player1_id")
    private Player player1;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "player2_id")
    private Player player2;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "winner_player_id")
    private Player winnerPlayer;

    // ── DOUBLES ───────────────────────────────────────────────────────
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "team1_id")
    private Team team1;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "team2_id")
    private Team team2;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "winner_team_id")
    private Team winnerTeam;

    // ── SCORES ────────────────────────────────────────────────────────
    /** Carrom: points. Chess: 0/0.5/1. Badminton: games won. */
    @Column(name = "score_participant1")
    private Integer scoreParticipant1 = 0;

    @Column(name = "score_participant2")
    private Integer scoreParticipant2 = 0;

    /**
     * Badminton: full game scores as JSON string, e.g.
     * [{"g1p1":21,"g1p2":18},{"g2p1":19,"g2p2":21},{"g3p1":21,"g3p2":15}]
     * Null for chess and carrom.
     */
    @Column(name = "game_scores", columnDefinition = "TEXT")
    private String gameScores;

    /**
     * Chess only: time limit in minutes for this match (from level config).
     * Null for other sports.
     */
    @Column(name = "chess_time_minutes")
    private Integer chessTimeMinutes;

    /**
     * Chess only: result description (CHECKMATE / RESIGNATION / TIMEOUT /
     * STALEMATE / DRAW_AGREEMENT / INSUFFICIENT_MATERIAL / THREEFOLD_REPETITION /
     * FIFTY_MOVE_RULE / DRAW_BY_PERPETUAL_CHECK).
     */
    @Column(name = "chess_result_type", length = 50)
    private String chessResultType;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private MatchStatus status = MatchStatus.SCHEDULED;

    @Column(name = "is_bye", nullable = false)
    private Boolean isBye = false;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "match_number")
    private Integer matchNumber;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (status == null) status = MatchStatus.SCHEDULED;
        if (scoreParticipant1 == null) scoreParticipant1 = 0;
        if (scoreParticipant2 == null) scoreParticipant2 = 0;
        if (isBye == null) isBye = false;
    }

    @PreUpdate
    protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
