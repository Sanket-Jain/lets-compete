package com.carrom.competition.model;

import com.carrom.competition.enums.CompetitionType;
import com.carrom.competition.enums.DoublesType;
import com.carrom.competition.enums.SportType;
import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "tournaments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Tournament {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "Tournament name is required")
    @Column(nullable = false, length = 150)
    private String name;

    @NotNull(message = "Sport type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "sport_type", nullable = false)
    private SportType sportType;

    @NotNull(message = "Competition type is required")
    @Enumerated(EnumType.STRING)
    @Column(name = "competition_type", nullable = false)
    private CompetitionType competitionType;

    /**
     * For Badminton doubles: SAME_GENDER or MIXED.
     * Null for singles and carrom doubles.
     */
    @Enumerated(EnumType.STRING)
    @Column(name = "doubles_type")
    private DoublesType doublesType;

    @Column(name = "current_level")
    private Integer currentLevel = 1;

    @Column(name = "total_levels")
    private Integer totalLevels;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_active")
    private Boolean isActive = true;

    /**
     * Chess only: JSON map of level→minutes e.g. {"1":10,"2":15,"3":20}
     * Stored as a simple string; parsed in service layer.
     */
    @Column(name = "chess_time_config", columnDefinition = "TEXT")
    private String chessTimeConfig;

    @OneToMany(mappedBy = "tournament", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Fixture> fixtures = new ArrayList<>();

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
        if (currentLevel == null) currentLevel = 1;
        if (isActive == null) isActive = true;
    }

    @PreUpdate
    protected void onUpdate() { updatedAt = LocalDateTime.now(); }
}
