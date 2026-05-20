package com.carrom.competition.controller;

import com.carrom.competition.dto.FixtureDTO;
import com.carrom.competition.dto.MatchResultDTO;
import com.carrom.competition.service.FixtureService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/fixtures")
@CrossOrigin(origins = "*")
public class FixtureController {

    private final FixtureService fixtureService;

    public FixtureController(FixtureService fixtureService) {
        this.fixtureService = fixtureService;
    }

    /**
     * Get all fixtures for a tournament.
     */
    @GetMapping("/tournament/{tournamentId}")
    public ResponseEntity<List<FixtureDTO>> getByTournament(@PathVariable Long tournamentId) {
        return ResponseEntity.ok(fixtureService.getFixturesByTournament(tournamentId));
    }

    /**
     * Get fixtures for a specific level of a tournament.
     */
    @GetMapping("/tournament/{tournamentId}/level/{level}")
    public ResponseEntity<List<FixtureDTO>> getByLevel(
            @PathVariable Long tournamentId,
            @PathVariable Integer level) {
        return ResponseEntity.ok(fixtureService.getFixturesByLevel(tournamentId, level));
    }

    /**
     * Generate Level 1 fixtures (random draw).
     * Body: list of participant IDs (player IDs for SINGLES, team IDs for DOUBLES)
     */
    @PostMapping("/tournament/{tournamentId}/generate-level1")
    public ResponseEntity<List<FixtureDTO>> generateLevel1(
            @PathVariable Long tournamentId,
            @RequestBody List<Long> participantIds) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(fixtureService.generateLevel1Fixtures(tournamentId, participantIds));
    }

    /**
     * Advance to next level — generates fixtures for winners of current level,
     * seeded by score (highest vs lowest).
     */
    @PostMapping("/tournament/{tournamentId}/advance-level")
    public ResponseEntity<List<FixtureDTO>> advanceLevel(@PathVariable Long tournamentId) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(fixtureService.generateNextLevelFixtures(tournamentId));
    }

    /**
     * Record the result of a match.
     */
    @PutMapping("/{fixtureId}/result")
    public ResponseEntity<FixtureDTO> recordResult(
            @PathVariable Long fixtureId,
            @Valid @RequestBody MatchResultDTO result) {
        return ResponseEntity.ok(fixtureService.recordResult(fixtureId, result));
    }
}
