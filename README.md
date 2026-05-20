# 🎯 Carrom Competition Fixture Management System

A Spring Boot + Hibernate + MySQL REST API for managing Carrom tournaments — supports both **Singles** and **Doubles** competitions with multi-level fixture generation.

---

## 🚀 Quick Start (GitHub Codespaces)

1. Open this repo in GitHub Codespaces — the devcontainer will automatically:
   - Install Java 21, Maven, and MySQL 8
   - Create the `carrom_db` database
   - Build the project

2. Run the application:
   ```bash
   mvn spring-boot:run
   ```

3. The API is available at `http://localhost:8080`

---

## 🗄️ Database Setup (local)

```sql
CREATE DATABASE carrom_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

Set environment variables:
```bash
export DB_HOST=localhost
export DB_PORT=3306
export DB_NAME=carrom_db
export DB_USERNAME=root
export DB_PASSWORD=yourpassword
export SPRING_PROFILES_ACTIVE=dev
```

---

## 🏗️ Architecture

```
src/main/java/com/carrom/competition/
├── model/          # JPA Entities (Player, Team, Tournament, Fixture)
├── repository/     # Spring Data repositories
├── service/        # Business logic (fixture generation, seeding)
├── controller/     # REST controllers
├── dto/            # Data Transfer Objects
├── enums/          # SkillLevel, CompetitionType, MatchStatus
└── config/         # Global exception handler
```

---

## 📊 Data Model

### Player
| Field         | Type        | Description                      |
|---------------|-------------|----------------------------------|
| id            | Long        | Auto-generated primary key       |
| name          | String      | Player's full name               |
| skillLevel    | Enum        | BEGINNER / INTERMEDIATE / PRO    |
| achievements  | Text        | Free-text achievements log       |
| totalScore    | Integer     | Cumulative score across matches  |
| matchesPlayed | Integer     | Total matches played             |
| matchesWon    | Integer     | Total matches won                |

### Tournament
| Field           | Type   | Description                      |
|-----------------|--------|----------------------------------|
| name            | String | Tournament name                  |
| competitionType | Enum   | SINGLES / DOUBLES                |
| currentLevel    | Int    | Current active level             |
| totalLevels     | Int    | Total levels planned             |
| isActive        | Bool   | Whether tournament is ongoing    |

### Fixture (Match)
Each match links two players (singles) or two teams (doubles), tracks scores, winner, and status.

---

## 🔀 Fixture Generation Rules

### Level 1 — Random Draw
Players/teams are randomly shuffled and paired.

### Level 2+ — Score-Based Seeding
Winners from the previous level are sorted by **total score descending**, then paired:
- **Rank 1 vs Rank N** (highest score vs lowest)
- **Rank 2 vs Rank N-1**
- And so on…

This ensures the strongest players eventually face each other in later rounds.

---

## 📡 API Reference

### Players

| Method | Endpoint             | Description              |
|--------|----------------------|--------------------------|
| GET    | /api/players         | List all players (sorted by score) |
| GET    | /api/players/{id}    | Get a player             |
| POST   | /api/players         | Create a player          |
| PUT    | /api/players/{id}    | Update a player          |
| DELETE | /api/players/{id}    | Delete a player          |

**Create Player body:**
```json
{
  "name": "Rahul Sharma",
  "skillLevel": "PRO",
  "achievements": "State champion 2023, District champion 2022"
}
```

### Teams (Doubles only)

| Method | Endpoint          | Description  |
|--------|-------------------|--------------|
| GET    | /api/teams        | List all teams |
| GET    | /api/teams/{id}   | Get a team   |
| POST   | /api/teams        | Create a team |
| PUT    | /api/teams/{id}   | Update a team |
| DELETE | /api/teams/{id}   | Delete a team |

**Create Team body:**
```json
{
  "name": "Thunder Duo",
  "player1Id": 1,
  "player2Id": 2
}
```

### Tournaments

| Method | Endpoint                  | Description              |
|--------|---------------------------|--------------------------|
| GET    | /api/tournaments          | List all tournaments     |
| GET    | /api/tournaments/active   | List active tournaments  |
| GET    | /api/tournaments/{id}     | Get a tournament         |
| POST   | /api/tournaments          | Create a tournament      |
| PUT    | /api/tournaments/{id}     | Update a tournament      |
| DELETE | /api/tournaments/{id}     | Delete a tournament      |

**Create Tournament body:**
```json
{
  "name": "Club Championship 2025",
  "competitionType": "SINGLES",
  "description": "Annual singles championship",
  "totalLevels": 3
}
```

### Fixtures

| Method | Endpoint                                          | Description                        |
|--------|---------------------------------------------------|------------------------------------|
| GET    | /api/fixtures/tournament/{id}                     | All fixtures for a tournament      |
| GET    | /api/fixtures/tournament/{id}/level/{level}       | Fixtures for a specific level      |
| POST   | /api/fixtures/tournament/{id}/generate-level1     | Generate Level 1 (random) fixtures |
| POST   | /api/fixtures/tournament/{id}/advance-level       | Advance to next level (winners only) |
| PUT    | /api/fixtures/{fixtureId}/result                  | Record match result                |

**Generate Level 1 (Singles) — body is list of player IDs:**
```json
[1, 2, 3, 4, 5, 6, 7, 8]
```

**Generate Level 1 (Doubles) — body is list of team IDs:**
```json
[1, 2, 3, 4]
```

**Record match result:**
```json
{
  "scoreParticipant1": 25,
  "scoreParticipant2": 18
}
```

**Tied match — specify winner:**
```json
{
  "scoreParticipant1": 20,
  "scoreParticipant2": 20,
  "winnerPlayerId": 3
}
```

---

## 🔄 Typical Workflow

```
1. POST /api/players          → Register all players
2. POST /api/tournaments       → Create a tournament (SINGLES or DOUBLES)
3. POST /api/teams             → (Doubles only) Form teams
4. POST /api/fixtures/tournament/{id}/generate-level1  → Random Level 1 draw
5. PUT  /api/fixtures/{id}/result  → Record each match result
6. POST /api/fixtures/tournament/{id}/advance-level    → Generate Level 2 (score-seeded)
7. Repeat steps 5-6 for each level
```

---

## 🛠 Tech Stack

| Component   | Technology             |
|-------------|------------------------|
| Framework   | Spring Boot 4.0.6      |
| ORM         | Hibernate (via JPA)    |
| Database    | MySQL 8.0              |
| Java        | Java 21 (LTS)          |
| Build       | Maven 3.9              |
| Deployment  | GitHub Codespaces      |
