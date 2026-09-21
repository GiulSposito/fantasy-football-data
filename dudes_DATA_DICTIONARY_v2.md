# Data Dictionary - DudesFantasyFootball RDS Files

This document provides comprehensive documentation for all RDS files in the data/ directory of the DudesFantasyFootball_claude project.

**Last Updated:** 2026-03-06
**Total RDS Files:** 245 (including historical data in subdirectories)

---

## Table of Contents

1. [File Organization Structure](#file-organization-structure)
2. [Player Data Files](#player-data-files)
3. [Projection Files](#projection-files)
4. [Weekly Data Files](#weekly-data-files)
5. [Simulation Files](#simulation-files)
6. [Draft Files](#draft-files)
7. [Season Aggregated Files](#season-aggregated-files)
8. [Ranking Files](#ranking-files)
9. [Lookup/Reference Files](#lookupreference-files)
10. [Data Relationships](#data-relationships)
11. [Key Field Definitions](#key-field-definitions)

---

## File Organization Structure

### Root Data Directory (`data/`)
Contains current season (2025) data files

### Historical Subdirectories
- `data/2022/` - 2022 season historical data (mirrors current structure)
- Additional year directories as needed

### File Naming Patterns

| Pattern | Purpose | Example | Frequency |
|---------|---------|---------|-----------|
| `week{X}_*.rds` | Weekly data files | `week3_scrap.rds` | Per week (0-17), where 0=full season |
| `weekly_*_{X}.rds` | Processed weekly data | `weekly_webscrapes_3.rds` | Per week (1-17) |
| `simulation_v5_week{X}_{phase}.rds` | Simulation snapshots | `simulation_v5_week3_preTNF.rds` | Multiple per week |
| `rank_week{X}.rds` | Team rankings | `rank_week3.rds` | Per week (1-17) |
| `rankAgainstPosition_week{X}.rds` | Position rankings | `rankAgainstPosition_week3.rds` | Per week (1-17) |
| `dudesffa_projpoints_week{X}.rds` | Custom projections | `dudesffa_projpoints_week3.rds` | Per week (1-17) |
| `draft_*.rds` | Draft-related data | `draft_picks.rds` | One-time per season |
| `season_*.rds` | Season aggregates | `season_scrap.rds` | Full season data (equivalent to week0) |

---

## Player Data Files

### `players_points.rds`

**Description:** Comprehensive player statistics including actual points scored, weekly breakdown, and all player metadata.

**Structure:** Tibble (data.frame)
**Dimensions:** ~14,000 rows x 42 columns

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `playerId` | integer | NFL.com player ID (primary identifier) |
| `nflGlobalEntityId` | character | Global entity identifier |
| `esbId` | character | ESB identifier |
| `name` | character | Player full name |
| `firstName` | character | Player first name |
| `lastName` | character | Player last name |
| `position` | character | Player position (QB, RB, WR, TE, K, DST) |
| `nflTeamAbbr` | character | Team abbreviation (e.g., "SF", "BUF") |
| `nflTeamId` | integer | NFL team ID |
| `injuryGameStatus` | character | Injury status (see `injuryGameStatusAbbr.rds`) |
| `imageUrl` | character | Standard player image URL |
| `smallImageUrl` | character | Small player image URL |
| `largeImageUrl` | character | Large player image URL |
| `byeWeek` | integer | Bye week number (1-17) |
| `cancelledWeeks` | logical | Cancelled weeks indicator |
| `archetypes` | logical | Player archetype data |
| `isReserveStatus` | logical | Reserve status flag |
| `lastNoteTimestamp` | character | Timestamp of last news update |
| `lastVideoTimestamp` | logical | Video timestamp |
| `seasonPts` | logical | Season total points |
| `weekStats` | list | Nested list of weekly statistics |
| `stats` | list | Aggregated season statistics |
| `rankAgainstPosition` | integer | Position-based ranking |
| `advanced` | list | Advanced statistics |
| `researchStatsWeek` | list | Research stats by week |
| `researchStats` | list | Aggregated research stats |
| `week` | integer | Week number (for weekly data) |
| `weekPts` | numeric | Points scored in specific week |
| `weekSeasonPts` | numeric | Cumulative season points through week |
| `id` | integer | Internal player ID (links to projection files) |
| `stats_id` | character | Stats provider ID |
| `cbs_id` | character | CBS Sports ID |
| `fleaflicker_id` | character | FleaFlicker ID |
| `espn_id` | character | ESPN ID |
| `fftoday_id` | character | FFToday ID |
| `numfire_id` | character | NumberFire ID |
| `fantasypro_id` | character | FantasyPros ID |
| `fantasydata_id` | character | FantasyData ID |
| `fantasynerd_id` | character | FantasyNerd ID |
| `rts_id` | character | RotoSports ID |
| `fantasypro_num_id` | character | FantasyPros numeric ID |
| `nfl_id` | integer | NFL.com ID |

**Data Granularity:** One row per player per week (players repeat across weeks)

**Usage:** Primary source for actual player performance data. Links to projection files via `id` field.

---

## Projection Files

### `points_projection.rds`

**Description:** Raw weekly point projections from multiple data sources WITHOUT error corrections.

**Structure:** Tibble
**Dimensions:** ~37,000 rows x 6 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `week` | integer | Week number (1-17) |
| `data_src` | glue/character | Data source (CBS, ESPN, FantasyPros, FleaFlicker, NFL) |
| `id` | integer | Player ID (links to players_points) |
| `pos` | character | Position |
| `pts.proj` | numeric | Projected fantasy points |
| `season` | numeric | Season year |

**Data Sources:** CBS, ESPN, FantasyPros, FleaFlicker, NFL
**Data Granularity:** One row per player per week per data source

---

### `points_projection_and_errors.rds`

**Description:** Weekly point projections WITH historical error corrections applied. This is the enhanced version used for analysis.

**Structure:** Tibble
**Dimensions:** ~90,000 rows x 6 columns (more rows due to error-corrected versions)

**Columns:** Same as `points_projection.rds`

**Key Difference:** Includes error-corrected projections based on historical projection accuracy from previous seasons/weeks.

**Usage:** Primary projection file for decision-making and simulations.

---

### `week{X}_players_projections.rds`

**Description:** Comprehensive weekly player projections with all metadata, rankings, and tiers.

**Structure:** Tibble
**Dimensions:** ~1,400 rows x 65 columns

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `avg_type` | character | Averaging method (e.g., "robust") |
| `id` | integer | Player ID |
| `pos` | character | Position |
| `points` | numeric | Projected points |
| `sd_pts` | numeric | Standard deviation of projections |
| `dropoff` | numeric | Point dropoff to next player |
| `floor` | numeric | Projected floor (low estimate) |
| `ceiling` | numeric | Projected ceiling (high estimate) |
| `points_vor` | numeric | Value Over Replacement |
| `floor_vor` | numeric | Floor VOR |
| `ceiling_vor` | numeric | Ceiling VOR |
| `rank` | integer | Overall rank |
| `floor_rank` | integer | Rank by floor |
| `ceiling_rank` | integer | Rank by ceiling |
| `pos_rank` | integer | Position rank |
| `tier` | integer | Tier number |
| `teamId` | integer | Fantasy team ID (if rostered) |
| `fantasy.team` | character | Fantasy team name (if rostered) |

Plus all player metadata columns from `players_points.rds`.

**Data Granularity:** One row per player per week (with multiple entries if player appears on multiple fantasy teams)

**Usage:** Weekly decision-making, start/sit analysis, waiver wire targets.

---

### `dudesffa_projpoints_week{X}.rds`

**Description:** Custom ensemble projections using machine learning models trained on historical projection errors.

**Structure:** Tibble
**Dimensions:** ~470 rows x 5 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `id` | integer | Player ID |
| `estimate` | numeric | Point estimate |
| `conf.low` | numeric | Lower confidence interval |
| `conf.high` | numeric | Upper confidence interval |
| `data` | list | Training data including historical errors |

**Data in `data` column includes:**
- Source projections (CBS, ESPN, FantasyPros, FleaFlicker, NFL)
- Error lag features (LAG_1, LAG_2 for each source)
- Historical weekly errors by source

**Usage:** Custom projections that incorporate historical accuracy patterns.

---

## Weekly Data Files

### `week{X}_scrap.rds`

**Description:** Raw weekly scraped data from fantasy projection websites, organized by position.

**Special Case - week0_scrap.rds:**
- `week0` contains **full season projections** (aggregate of all 17 weeks)
- Same structure as weekly files but with season-total statistics
- Equivalent to `season_scrap.rds` but in `week{X}` format for pipeline compatibility

**Structure:** List of 6 data.frames (one per position)
**Elements:** QB, RB, WR, TE, K, DST

**Structure per position (example QB):**

| Column | Type | Description |
|--------|------|-------------|
| `player` | character | Player name |
| `pos` | character | Position |
| `team` | character | Team abbreviation |
| `games` | numeric | Games played/projected |
| `pass_att` | numeric | Pass attempts |
| `pass_comp` | numeric | Completions |
| `pass_yds` | numeric | Passing yards |
| `pass_yds_g` | numeric | Passing yards per game |
| `pass_tds` | numeric | Passing touchdowns |
| `pass_int` | numeric | Interceptions |
| `pass_rate` | numeric | Passer rating |
| `rush_att` | numeric | Rush attempts |
| `rush_yds` | numeric | Rushing yards |
| `rush_avg` | numeric | Yards per carry |
| `rush_tds` | numeric | Rushing touchdowns |
| `fumbles_lost` | numeric | Fumbles lost |
| `site_pts` | numeric | Site projected points |
| `site_fppg` | numeric | Points per game |
| `src_id` | character | Source player ID |
| `data_src` | character | Data source |
| `id` | integer | Internal player ID |
| `bye` | integer | Bye week |
| `opp` | character | Opponent |
| `draft_rank` | character | Draft rank |
| `pass_comp_pct` | character | Completion percentage |
| `pct_owned` | character | Ownership percentage |
| `fumble_TD` | logical | Fumble return TD |

**Position-specific columns:**
- **RB:** `rec_tgt`, `rec`, `rec_yds`, `rec_avg`, `rec_tds`, `misc_tds`, `misc_yds`, `return_tds`
- **WR:** Similar to RB
- **TE:** Similar to RB
- **K:** `fg_att`, `fg_made`, `fg_pct`, `xp_att`, `xp_made`
- **DST:** `sacks`, `int`, `fum_rec`, `td`, `safety`, `pts_allowed`

**Data Granularity:** One row per player per position

---

### `weekly_webscrapes_{X}.rds`

**Description:** Similar to `week{X}_scrap.rds` but processed and standardized.

**Structure:** List of 6 data.frames (one per position)
**Usage:** Same as weekly scrapes, alternate format.

---

### `weekly_proj_table_{X}.rds`

**Description:** Processed weekly projection table with rankings and tiers.

**Structure:** Tibble
**Dimensions:** ~500 rows x 22 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `avg_type` | character | Averaging method |
| `id` | integer | Player ID |
| `pos` | character | Position |
| `points` | numeric | Projected points |
| `sd_pts` | numeric | Standard deviation |
| `dropoff` | numeric | Point dropoff |
| `floor` | numeric | Floor projection |
| `ceiling` | numeric | Ceiling projection |
| `points_vor` | numeric | Value Over Replacement |
| `floor_vor` | numeric | Floor VOR |
| `ceiling_vor` | numeric | Ceiling VOR |
| `rank` | integer | Overall rank |
| `floor_rank` | integer | Floor rank |
| `ceiling_rank` | integer | Ceiling rank |
| `pos_rank` | integer | Position rank |
| `tier` | integer | Tier assignment |
| `first_name` | character | First name |
| `last_name` | character | Last name |
| `team` | character | Team abbreviation |
| `position` | character | Position |
| `age` | integer | Player age |
| `exp` | integer | Years of experience |

---

### `weekly_proj_player_site_{X}.rds`

**Description:** Individual site projections by player for a specific week.

**Structure:** Tibble
**Dimensions:** ~2,000 rows x 4 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `pos` | character | Position |
| `data_src` | character | Data source (CBS, ESPN, FantasyPros, FleaFlicker, NFL) |
| `id` | integer | Player ID |
| `pts.proj` | numeric | Projected points |

**Data Granularity:** One row per player per data source per week

---

## Simulation Files

### `simulation_v5_week{X}_{phase}.rds`

**Description:** Complete simulation state at a specific point in the week. Contains all data needed to run Monte Carlo simulations with 1,000 iterations per matchup.

**Structure:** List with 11 elements

**Simulation Methodology:**
- **Monte Carlo simulation:** 1,000 iterations per matchup
- **Distribution generation:** Uses kernel density estimation on aggregated projections from multiple sources
- **Real vs Projected:** Incorporates actual points for completed games, projections for future games
- **Error correction:** Projections include historical error corrections

---

#### Element 1: `week`

**Type:** numeric (single value)
**Description:** Current NFL week (1-17)
**Example:** `17`

---

#### Element 2: `season`

**Type:** numeric (single value)
**Description:** Season year
**Example:** `2025`

---

#### Element 3: `ptsproj`

**Type:** data.frame
**Dimensions:** ~90,202 rows × 6 columns
**Description:** All player projections from all sources with error corrections applied

**Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `week` | integer | Week number (1-17) | `17` |
| `data_src` | character/glue | Data source with error correction variant | `"CBS"`, `"ESPN_s2024_w3_error"` |
| `id` | integer | Internal player ID | `14783` |
| `pos` | character | Position | `"QB"`, `"RB"`, `"WR"`, `"TE"`, `"K"`, `"DST"` |
| `pts.proj` | numeric | Projected points (with corrections) | `24.5`, `18.2` |
| `season` | numeric | Season year | `2025` |

**Data Sources:** CBS, ESPN, FantasyPros, FleaFlicker, NFL (+ error-corrected variants)

**Granularity:** One row per player per source per error variant per week

**Usage:** Base data for generating probability distributions in simulation

---

#### Element 4: `matchups`

**Type:** data.frame
**Dimensions:** 8 rows × 13 columns
**Description:** Weekly matchup information from NFL.com API

**Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `matchupId` | character | Unique matchup identifier | `"w17_a5_h7"` |
| `week` | integer | Week number | `17` |
| `previewUrl` | character | NFL.com preview URL | `"https://nfl.com/..."` |
| `recapUrl` | character | NFL.com recap URL | `"https://nfl.com/..."` |
| `bracketType` | character | Playoff bracket type | `"championship"`, `"consolation"` |
| `bracketTitle` | character | Game title/description | `"Championship"`, `"9th Place Game"` |
| `hasMatchupTeams` | logical | If matchup has teams assigned | `TRUE`, `FALSE` |
| `awayTeam.teamId` | integer | Away team ID | `5` |
| `awayTeam.outcome` | character | Away team outcome | `"W"`, `"L"`, `NULL` |
| `awayTeam.playoffSeeding` | character | Away team playoff seed | `"1"`, `"2"`, etc. |
| `homeTeam.teamId` | integer | Home team ID | `7` |
| `homeTeam.outcome` | character | Home team outcome | `"W"`, `"L"`, `NULL` |
| `homeTeam.playoffSeeding` | character | Home team playoff seed | `"1"`, `"2"`, etc. |

**Cardinality:** 8 matchups per week (16 teams / 2)

---

#### Element 5: `teams`

**Type:** data.frame
**Dimensions:** 16 rows × 14 columns
**Description:** Complete team data including rosters and statistics

**Scalar Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `teamId` | integer | Unique team ID | `5`, `7`, `16` |
| `name` | character | Team name | `"Sorocaba Steelers"` |
| `ownerUserId` | integer | Owner's NFL.com user ID | `12023425` |
| `coManagerUserId` | character | Co-manager user ID | `NULL`, `"98765"` |
| `imageUrl` | character | Team logo URL (standard) | `"https://static.nfl.com/..."` |
| `imageUrlLarge` | character | Team logo URL (large) | `"https://static.nfl.com/..."` |
| `isActive` | logical | If team is active | `TRUE`, `FALSE` |
| `rank` | character | Current rank | `"12"`, `"1"` |
| `imageId` | character | Image identifier | `"27-nfl-shield"` |

**Nested List Columns:**

**`rosters` (data.frame):** Complete roster for the week

| Column | Type | Description |
|--------|------|-------------|
| `slotPosition` | character | Slot position code (`"O"`, `"O/F"`, `"D"`, etc.) |
| `rosterSlotId` | integer | Slot ID (1-19 = starters, 20 = bench) |
| `playerId` | integer | NFL.com player ID |
| `isEditable` | logical | If player can be edited (FALSE after game starts) |
| `isReserveStatus` | logical | If player is on IR/suspended |

**`stats` (list):** Hierarchical team statistics structure

- `week` (list): Weekly statistics by season/week
  - `[season]` (list): e.g., `"2025"`
    - `[week]` (list): e.g., `"17"`
      - `pts` (character): Points scored that week, e.g., `"69.20"`

- `season` (list): Season-level statistics
  - `[season]` (list): e.g., `"2025"`
    - `rank` (character): Overall rank, e.g., `"12"`
    - `rankChange` (character): Change from previous week, e.g., `"0"`, `"+2"`, `"-1"`
    - `divisionRank` (character): Division rank, e.g., `"12"`
    - `record` (character): Win-Loss-Tie record, e.g., `"5-9-0"`
    - `wins` (character): Total wins, e.g., `"5"`
    - `losses` (character): Total losses, e.g., `"9"`
    - `ties` (character): Total ties, e.g., `"0"`
    - `streak` (character): Current streak, e.g., `"W2"`, `"L1"`
    - `waiverPriority` (character): Waiver wire priority, e.g., `"4"`
    - `pts` (character): Total points, e.g., `"1390.48"`
    - `ptsAgainst` (character): Points against, e.g., `"1394.94"`
    - `playoffSeed` (character): Playoff seed, e.g., `"4"`
    - `playoffBracketType` (character): Bracket type, e.g., `"consolation"`
    - `place` (character): Final place, e.g., `"10"`
    - `transactionAddCount` (integer): Number of adds, e.g., `16`
    - `transactionTradeCount` (integer): Number of trades, e.g., `0`
    - `trophyImageUrl` (NULL/character): Trophy image URL

**`matchups` (list):** Matchup schedule by week
- `[week]` (character): Matchup ID for that week, e.g., `"w17_a5_h7"`

**`week.stats` (list):** Current week statistics (same structure as `stats$week`)

**`season.stats` (list):** Season statistics (same structure as `stats$season`)

---

#### Element 6: `proj_table`

**Type:** data.frame
**Dimensions:** ~491 rows × 22 columns
**Description:** Processed projection table with rankings and tiers

**Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `avg_type` | character | Aggregation method | `"robust"` |
| `id` | integer | Player ID | `501`, `14783` |
| `pos` | character | Position | `"QB"`, `"RB"`, `"DST"` |
| `points` | numeric | Projected points | `24.5`, `18.2` |
| `sd_pts` | numeric | Standard deviation | `3.2`, `5.1` |
| `dropoff` | numeric | Points to next player | `0.107`, `2.5` |
| `floor` | numeric | 25th percentile projection | `21.0`, `15.0` |
| `ceiling` | numeric | 75th percentile projection | `28.0`, `22.0` |
| `points_vor` | numeric | Value Over Replacement | `-1.01`, `8.5` |
| `floor_vor` | numeric | Floor VOR | `-0.316`, `6.2` |
| `ceiling_vor` | numeric | Ceiling VOR | `1.5`, `11.3` |
| `rank` | integer | Overall rank | `1`, `150` |
| `floor_rank` | integer | Rank by floor | `1`, `145` |
| `ceiling_rank` | integer | Rank by ceiling | `1`, `155` |
| `pos_rank` | integer | Position rank | `1`, `25` |
| `tier` | integer | Tier number | `1`, `2`, `3` |
| `first_name` | character | First name | `"Christian"` |
| `last_name` | character | Last name | `"McCaffrey"` |
| `team` | character | NFL team | `"SF"`, `"BUF"` |
| `position` | character | Position | `"RB"` |
| `age` | integer | Age | `28` |
| `exp` | integer | Years experience | `7` |

---

#### Element 7: `players_stats`

**Type:** data.frame
**Dimensions:** ~1,126 rows × 28 columns
**Description:** Actual player statistics (identical structure to `players_points.rds`)

**Key Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `playerId` | integer | NFL.com player ID |
| `name` | character | Full name |
| `position` | character | Position |
| `nflTeamAbbr` | character | Team abbreviation |
| `injuryGameStatus` | character | Injury status |
| `weekPts` | numeric | Points scored that week |
| `weekStats` | list | Nested weekly statistics |
| `stats` | list | Nested season statistics |
| `isUndroppable` | logical | If player cannot be dropped |

**Note:** Field `isUndroppable` may not be present in early-week imports and is auto-generated if missing.

**See:** Complete column documentation in `players_points.rds` section

---

#### Element 8: `players_id`

**Type:** data.frame
**Dimensions:** ~5,395 rows × 13 columns
**Description:** Cross-platform player ID mappings

**Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `id` | integer | Internal player ID (PRIMARY KEY) | `501`, `14783` |
| `stats_id` | character | Stats provider ID | `"100002"` |
| `cbs_id` | character | CBS Sports ID | `"1904"` |
| `fleaflicker_id` | character | FleaFlicker ID | `"2331"` |
| `nfl_id` | integer | NFL.com ID | `100003` |
| `espn_id` | character | ESPN ID | `"60002"` |
| `fftoday_id` | character | FFToday ID | `"9000"` |
| `numfire_id` | character | NumberFire ID | `"buffalo-dst"` |
| `fantasypro_id` | character | FantasyPros ID | `"BUF-D"` |
| `fantasydata_id` | character | FantasyData ID | `"BUF"` |
| `fantasynerd_id` | character | FantasyNerds ID | `"100003"` |
| `rts_id` | character | RotoSports ID | `"100003"` |
| `fantasypro_num_id` | character | FantasyPros numeric ID | `"60002"` |

**Usage:** Join key to link projections across different fantasy platforms

---

#### Element 9: `players_sim`

**Type:** data.frame
**Dimensions:** ~219 rows × 18 columns
**Description:** Rostered players with simulation arrays (1,000 iterations each)

**Scalar Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `teamId` | integer | Fantasy team ID | `5`, `7` |
| `teamName` | character | Team name | `"Sorocaba Steelers"` |
| `slotPosition` | character | Roster slot position | `"O"`, `"O/F"`, `"D"` |
| `rosterSlotId` | integer | Slot ID (< 20 = starter, 20 = bench) | `1`, `2`, `20` |
| `playerId` | integer | NFL.com player ID | `2557997` |
| `isEditable` | logical | If player is still editable | `TRUE`, `FALSE` |
| `isReserveStatus` | logical | If on IR/suspended | `TRUE`, `FALSE` |
| `id` | integer | Internal player ID | `14783` |
| `byeWeek` | integer | Bye week | `9`, `11` |
| `isUndroppable` | logical | If cannot be dropped | `TRUE`, `FALSE` |
| `injuryGameStatus` | character | Injury status | `"Q"`, `"Out"`, `"D"`, `NULL` |
| `week` | integer | Current week | `17` |
| `weekPts` | numeric | Actual points (if game completed) | `24.5`, `0.0`, `NA` |
| `seasonPts` | logical/numeric | Season points | `245.8` |

**Array Columns (list of numeric vectors):**

| Column | Type | Description | Vector Length |
|--------|------|-------------|---------------|
| `pts.proj` | list<numeric[]> | Array of projections from all sources | ~43 elements |
| `weekPts.sim` | list<numeric[1000]> | Actual points replicated 1,000 times | 1,000 |
| `simulation.org` | list<numeric[1000]> | Original simulation (projection distribution) | 1,000 |
| `simulation` | list<numeric[1000]> | Final simulation (real or projected) | 1,000 |

**Simulation Logic:**
```r
simulation = if(isEditable == FALSE) {
  weekPts.sim   # Use actual points (game completed)
} else {
  simulation.org  # Use probability distribution (game pending)
}
```

**Distribution Generation (simulation.org):**
1. Takes all projections from `pts.proj` (~43 values from different sources)
2. Applies kernel density estimation (KDE) to create smooth probability distribution
3. Samples 1,000 values from this distribution
4. Result: 1,000 possible point outcomes based on projection consensus

**Example:**
- Player has projections: [24.5, 23.6, 25.1, 24.0, ...]
- KDE creates smooth curve centered around ~24.3
- Sample 1,000 times: [23.8, 25.2, 24.1, 23.5, 26.0, ...]
- Each value represents one simulation iteration

---

#### Element 10: `teams_sim`

**Type:** data.frame
**Dimensions:** 16 rows × 3 columns
**Description:** Aggregated simulation results by team

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `teamId` | integer | Team ID |
| `simulation` | list<numeric[1000]> | Array of 1,000 total team point simulations |
| `simulation.org` | list<numeric[1000]> | Array using only original projections |

**Calculation Process:**

For each of 1,000 iterations:
1. Get all starters on team (rosterSlotId < 20)
2. Sum their simulated points for that iteration
3. Result: Total team points for that iteration

**Example:**
```r
# Iteration 1:
QB: 24.5 + RB1: 18.2 + RB2: 12.0 + WR1: 16.5 + ... = 102.3

# Iteration 2:
QB: 26.1 + RB1: 15.8 + RB2: 14.2 + WR1: 19.1 + ... = 105.8

# ... (998 more iterations)

# Result: [102.3, 105.8, 98.5, 110.2, ...]
```

**Derived Statistics:**
- `mean(simulation)`: Expected points
- `median(simulation)`: Most likely points
- `sd(simulation)`: Variability/risk
- `quantile(simulation, c(0.25, 0.75))`: Floor and ceiling
- `min/max(simulation)`: Range of outcomes

**Difference between simulation and simulation.org:**
- `simulation`: Uses actual points for completed games + projections for pending
- `simulation.org`: Uses only projections (ignores actuals) - useful for "what if" analysis

---

#### Element 11: `matchup_sim`

**Type:** data.frame
**Dimensions:** 8 rows × 22 columns
**Description:** Matchup-level simulation results with win probabilities

**Scalar Columns:**

| Column | Type | Description | Example Values |
|--------|------|-------------|----------------|
| `matchupId` | character | Matchup identifier | `"w17_a5_h7"` |
| `week` | integer | Week number | `17` |
| `awayTeam.teamId` | integer | Away team ID | `5` |
| `homeTeam.teamId` | integer | Home team ID | `7` |
| `homeTeam.winProb` | numeric | Home win probability (0-1) | `0.652`, `1.000` |
| `awayTeam.winProb` | numeric | Away win probability (0-1) | `0.348`, `0.000` |
| `homeTeam.winProb.org` | numeric | Win prob (orig projections) | `0.621` |
| `awayTeam.winProb.org` | numeric | Win prob (orig projections) | `0.379` |
| `homeTeam.totalPts` | numeric | Home projected pts (median) | `105.8` |
| `awayTeam.totalPts` | numeric | Away projected pts (median) | `98.2` |
| `homeTeam.totalPts.org` | numeric | Projected pts (orig) | `104.5` |
| `awayTeam.totalPts.org` | numeric | Projected pts (orig) | `99.1` |

**Array Columns (list vectors):**

| Column | Type | Vector Length | Description |
|--------|------|---------------|-------------|
| `awayTeam.simulation` | list<numeric[1000]> | 1,000 | Away team simulated points |
| `homeTeam.simulation` | list<numeric[1000]> | 1,000 | Home team simulated points |
| `awayTeam.simulation.org` | list<numeric[1000]> | 1,000 | Away (orig projections) |
| `homeTeam.simulation.org` | list<numeric[1000]> | 1,000 | Home (orig projections) |
| `homeTeam.win` | list<logical[1000]> | 1,000 | Home win outcomes (TRUE/FALSE) |
| `homeTeam.win.org` | list<logical[1000]> | 1,000 | Home win (orig) |
| `awayTeam.win` | list<logical[1000]> | 1,000 | Away win outcomes |
| `awayTeam.win.org` | list<logical[1000]> | 1,000 | Away win (orig) |
| `homeTeam.ptsdiff` | list<numeric[1000]> | 1,000 | Point differential (home - away) |
| `homeTeam.ptsdiff.org` | list<numeric[1000]> | 1,000 | Point diff (orig) |

**Calculation Process:**

```r
# For each iteration i (1 to 1,000):

# 1. Get team totals from teams_sim
awayTeam.simulation[i] = teams_sim$simulation[awayTeam.teamId][i]
homeTeam.simulation[i] = teams_sim$simulation[homeTeam.teamId][i]

# 2. Determine winner
homeTeam.win[i] = (homeTeam.simulation[i] > awayTeam.simulation[i])
awayTeam.win[i] = !homeTeam.win[i]

# 3. Calculate point differential
homeTeam.ptsdiff[i] = homeTeam.simulation[i] - awayTeam.simulation[i]

# After all iterations:
# 4. Calculate win probabilities
homeTeam.winProb = mean(homeTeam.win)  # % of simulations home won
awayTeam.winProb = mean(awayTeam.win)  # % of simulations away won

# 5. Calculate projected points
homeTeam.totalPts = median(homeTeam.simulation)
awayTeam.totalPts = median(awayTeam.simulation)
```

**Interpretation Example:**
```
homeTeam.winProb = 0.652
```
- Home team won 652 out of 1,000 simulations
- 65.2% chance of winning
- Away team has 34.8% chance

**Use Cases:**
- **Pre-game analysis:** Which team is favored?
- **Close matchups:** Identify toss-up games (winProb ≈ 0.50)
- **Confidence levels:** High winProb = confident pick
- **Point spread:** Use ptsdiff distribution
- **What-if scenarios:** Compare simulation vs simulation.org to see impact of actual results

---

### Phase Suffixes

**Temporal progression through the week:**

| Phase | When | Description | Example File |
|-------|------|-------------|--------------|
| `preTNF` | Thursday ~6pm ET | Before Thursday Night Football | `simulation_v5_week17_preTNF.rds` |
| `posTNF` | Thursday ~11pm ET | After TNF (TNF games have actuals) | `simulation_v5_week17_posTNF.rds` |
| `preSundayGames` | Sunday ~12pm ET | Before early Sunday games | `simulation_v5_week17_preSundayGames.rds` |
| `preSNF` | Sunday ~7pm ET | Before Sunday Night Football | `simulation_v5_week17_preSNF.rds` |
| `posSNF` | Sunday ~11pm ET | After SNF (most games complete) | `simulation_v5_week17_posSNF.rds` |
| `preMNF` | Monday ~7pm ET | Before Monday Night Football | `simulation_v5_week17_preMNF.rds` |
| `posMNF` | Monday ~11pm ET | After MNF (almost all games done) | `simulation_v5_week17_posMNF.rds` |
| `preWaivers` | Tuesday ~11am ET | Before waiver processing | `simulation_v5_week17_preWaivers.rds` |
| `posWaivers` | Wednesday ~3am ET | After waivers (rosters updated) | `simulation_v5_week17_posWaivers.rds` |
| `final` | Tuesday/Wednesday | Week complete (all games finished) | `simulation_v5_week17_final.rds` |

**Key Transition Points:**
- **isEditable changes:** Players become uneditable (FALSE) once their game starts
- **Projection → Actual:** Simulation switches from using projections to actual points
- **Waiver impact:** Rosters change between preWaivers and posWaivers

---

### Usage Patterns

**Common Operations:**

1. **Get win probability for a matchup:**
```r
sim <- readRDS("data/simulation_v5_week17_final.rds")
matchup <- sim$matchup_sim %>% filter(matchupId == "w17_a5_h7")
print(matchup$homeTeam.winProb)  # 0.652 = 65.2% chance
```

2. **Analyze team's range of outcomes:**
```r
team_results <- sim$teams_sim %>% filter(teamId == 5)
team_pts <- team_results$simulation[[1]]
quantile(team_pts, c(0.1, 0.25, 0.5, 0.75, 0.9))
# 10th, 25th, 50th, 75th, 90th percentiles
```

3. **Find close matchups:**
```r
close_games <- sim$matchup_sim %>%
  filter(homeTeam.winProb > 0.4 & homeTeam.winProb < 0.6)
```

4. **Compare projection accuracy:**
```r
# Difference between original projections and actual-adjusted
matchup <- sim$matchup_sim[1,]
prob_shift <- matchup$homeTeam.winProb - matchup$homeTeam.winProb.org
# Positive = team improved after actuals
```

**File Size:** 100-500 KB per file (varies by phase due to nested data structures)

**Total Files:** ~90 files across season (5-7 phases × 17 weeks)

---

## Draft Files

### `draft_picks.rds`

**Description:** Record of all picks made in the draft.

**Structure:** Tibble
**Dimensions:** 240 rows x 6 columns (16 teams x 15 rounds)

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `round` | integer | Draft round (1-15) |
| `pick` | integer | Overall pick number (1-240) |
| `player.id` | integer | Player NFL ID |
| `player.name` | character | Player name |
| `team.id` | integer | Fantasy team ID |
| `team.name` | character | Fantasy team name |

---

### `draft_pick_projections.rds`

**Description:** Draft picks with pre-draft season projections.

**Structure:** Tibble
**Dimensions:** 240 rows x 37 columns

**Columns:** All columns from `draft_picks.rds` PLUS all columns from `season_projtable.rds`

**Key Additional Columns:**
- `points`, `floor`, `ceiling` - Season projections
- `rank`, `pos_rank`, `tier` - Rankings
- `overall_ecr`, `pos_ecr` - Expert consensus rankings
- `adp`, `adp_diff` - Average draft position analysis
- `aav` - Average auction value

**Usage:** Analyze draft performance, reaches, and steals.

---

### `draft_teams_projections.rds`

**Description:** Subset of draft picks showing only players actually drafted by each team with projections.

**Structure:** Tibble
**Dimensions:** 144 rows x 38 columns

**Columns:** Similar to `draft_pick_projections.rds` with additional `team_id` field

---

### `draft_recap_data.rds`

**Description:** NFL.com generated draft recap for each team including grades, probabilities, and recommendations.

**Structure:** List of 16 elements (one per team)

**Each team element contains:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | character | "DraftRecap" |
| `written_at` | character | Timestamp |
| `league_id` | integer | League ID |
| `team_id` | integer | Team ID |
| `season` | integer | Season year |
| `title` | character | Recap title |
| `paragraphs` | data.frame | Draft summary text |
| `notes` | list | Draft notes and highlights |
| `draft_grade` | character | Letter grade (A, A-, B, etc.) |
| `trade_targets` | list | Suggested trade targets |
| `fa_targets` | list | Suggested free agent pickups |
| `probabilities` | list | Season outcome probabilities |
| `projected_outcomes` | list | Win/loss projections |

**Probabilities included:**
- `first_place` - Championship probability
- `last_place` - Last place probability
- `playoff` - Playoff probability
- `playoff_bye` - First round bye probability
- `title_game` - Championship game probability
- `champ` - Win championship probability

---

### `draft_recap_rank.rds`

**Description:** Summary table of all teams' draft recaps with key metrics.

**Structure:** Tibble
**Dimensions:** 16 rows x 17 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `teamId` | integer | Team ID |
| `teamName` | character | Team name |
| `imageUrl` | character | Team logo |
| `grade` | character | Draft grade |
| `title` | character | Recap title |
| `text` | character | Summary text |
| `first_place` | numeric | Championship probability |
| `last_place` | numeric | Last place probability |
| `playoff` | numeric | Playoff probability |
| `playoff_bye` | numeric | Bye probability |
| `title_game` | numeric | Championship game probability |
| `champ` | numeric | Championship probability |
| `wins` | integer | Projected wins |
| `losses` | integer | Projected losses |
| `ties` | integer | Projected ties |
| `rank_with_t` | character | Rank with tie notation |
| `rank` | integer | Overall rank |

---

## Season Aggregated Files

> **Important:** All `season_*.rds` files contain **full season data** (sum/aggregate of all 17 weeks of the regular season). These files are functionally equivalent to `week0_*` files but follow the `season_` naming convention.

### `season_scrap.rds`

**Description:** Season-long scraped projections by position. Contains aggregate statistics for the entire 17-week regular season.

**Equivalent File:** `week0_scrap.rds` (same data, different naming convention)

**Structure:** List of 6 data.frames (QB, RB, WR, TE, DST, K)

**Columns per position (example QB):**

| Column | Type | Description |
|--------|------|-------------|
| `player` | character | Player name |
| `pos` | character | Position |
| `team` | character | Team |
| `games` | numeric | Projected games |
| Position-specific stats | numeric | Season totals |
| `site_pts` | numeric | Projected season points |
| `site_fppg` | numeric | Points per game |
| `src_id` | character | Source ID |
| `data_src` | character | Data source |
| `id` | integer | Player ID |
| `bye` | integer | Bye week |
| `fumble_TD` | logical | Fumble return TD |

**Dimensions:**
- QB: ~375 players
- RB: ~450 players
- WR: ~550 players
- TE: ~250 players
- K: ~35 players
- DST: ~32 teams

---

### `season_projtable.rds`

**Description:** Comprehensive season-long projection table with rankings, tiers, and market data. Contains full season totals for all 17 weeks.

**Use Case:** Pre-season analysis, draft preparation, season-long player rankings

**Structure:** Tibble
**Dimensions:** ~1,800 rows x 31 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `avg_type` | character | Average type |
| `id` | integer | Player ID |
| `pos` | character | Position |
| `points` | numeric | Season projected points |
| `sd_pts` | numeric | Standard deviation |
| `dropoff` | numeric | Point dropoff |
| `floor` | numeric | Season floor |
| `ceiling` | numeric | Season ceiling |
| `points_vor` | numeric | Season VOR |
| `floor_vor` | numeric | Floor VOR |
| `ceiling_vor` | numeric | Ceiling VOR |
| `rank` | integer | Overall rank |
| `floor_rank` | integer | Floor rank |
| `ceiling_rank` | integer | Ceiling rank |
| `pos_rank` | integer | Position rank |
| `tier` | integer | Tier |
| `overall_ecr` | numeric | Expert consensus rank |
| `pos_ecr` | numeric | Position ECR |
| `sd_ecr` | numeric | ECR standard deviation |
| `adp` | numeric | Average draft position |
| `adp_sd` | numeric | ADP standard deviation |
| `adp_diff` | numeric | Rank - ADP difference |
| `aav` | numeric | Average auction value |
| `aav_sd` | numeric | AAV standard deviation |
| `uncertainty` | numeric | Uncertainty metric |
| `first_name` | character | First name |
| `last_name` | character | Last name |
| `team` | character | Team |
| `position` | character | Position |
| `age` | integer | Age |
| `exp` | integer | Experience |

---

### `season_player_proj_sites.rds`

**Description:** Season projections from individual fantasy sites. Contains full season point totals from each projection source.

**Use Case:** Compare projection sources, identify consensus vs. outliers for season-long rankings

**Structure:** Tibble
**Dimensions:** ~3,000 rows x 4 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `data_src` | character | Source (CBS, ESPN, FantasyPros, FFToday, NFL, RTSports, WalterFootball) |
| `id` | integer | Player ID |
| `pos` | character | Position |
| `points` | numeric | Projected season points (17-week total) |

---

### `season_2024_projections_errors.rds`

**Description:** Historical projection errors from the 2024 season (or specified season), used for error correction modeling.

**Structure:** Tibble
**Dimensions:** ~74,000 rows x 10 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `playerId` | integer | Player ID |
| `id` | integer | Internal ID |
| `data_src` | character | Projection source |
| `name` | character | Player name |
| `pos` | character | Position |
| `week` | integer | Week number |
| `weekPts` | numeric | Actual points scored |
| `pts.proj` | numeric | Projected points |
| `proj.error` | numeric | Projection error (actual - projected) |
| `season` | integer | Season year |

**Usage:** Training data for error correction models in `dudesffa_projpoints_week{X}.rds`

---

### `weeklies_scraps.rds`

**Description:** Collection of all weekly scrapes across the season.

**Structure:** List of 17 elements (one per week)
**Each element:** List of 6 data.frames (one per position)

**Usage:** Historical reference for weekly projections throughout the season.

---

### Understanding Week 0 vs Season Files

**Two naming conventions for the same data:**

| Week 0 Format | Season Format | Content |
|---------------|---------------|---------|
| `week0_scrap.rds` | `season_scrap.rds` | Full season scrapes (17-week totals) |
| N/A | `season_projtable.rds` | Full season projection table |
| N/A | `season_player_proj_sites.rds` | Full season projections by site |

**Key Points:**
- **week0** = Special "week" number representing **full season aggregate**
- **season_*** = Files specifically for season-long data
- `week0_scrap.rds` exists to maintain consistency with the `week{X}_scrap.rds` pattern in data pipelines
- Both formats contain the **sum of all 17 regular season weeks**
- Use `season_*` files for pre-season analysis and draft preparation
- Use `week0` when your pipeline expects a `week{X}` format

**When to use each:**
- **Draft analysis**: Use `season_projtable.rds` for comprehensive season rankings
- **Pipeline processing**: Use `week0_scrap.rds` if your code loops through `week{X}` files
- **Source comparison**: Use `season_player_proj_sites.rds` to compare full-season projections across sources

---

## Ranking Files

### `rank_week{X}.rds`

**Description:** Fantasy team standings and statistics for a specific week.

**Structure:** Tibble
**Dimensions:** 16 rows x 22 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `teamId` | integer | Team ID |
| `name` | character | Team name |
| `imageUrl` | character | Team logo |
| `week` | integer | Week number |
| `week.pts` | numeric | Points scored this week |
| `rank` | integer | Current rank |
| `rankChange` | integer | Change from previous week |
| `divisionRank` | integer | Division rank |
| `record` | character | Win-Loss-Tie record |
| `wins` | integer | Total wins |
| `losses` | integer | Total losses |
| `ties` | integer | Total ties |
| `streak` | character | Current streak (e.g., "W3", "L2") |
| `waiverPriority` | integer | Waiver priority position |
| `season.pts` | numeric | Season total points |
| `season.ptsAgainst` | numeric | Season points against |
| `playoffSeed` | integer | Playoff seed |
| `playoffBracketType` | character | Bracket type (championship/consolation) |
| `place` | integer | Final place (if season complete) |
| `transactionAddCount` | integer | Number of adds |
| `transactionTradeCount` | integer | Number of trades |
| `trophyImageUrl` | character | Trophy image (if applicable) |

---

### `rankAgainstPosition_week{X}.rds`

**Description:** Player rankings against their position for a specific week.

**Structure:** Tibble
**Dimensions:** ~800 rows x 4 columns

**Columns:**

| Column | Type | Description |
|--------|------|-------------|
| `week` | integer | Week number |
| `playerId` | integer | Player ID |
| `position` | character | Position |
| `rankAgainstPosition` | integer | Rank within position for that week |

**Usage:** Performance tracking, identifying over/underperformers relative to position.

---

## Lookup/Reference Files

### `injuryGameStatusAbbr.rds`

**Description:** Lookup table for injury status abbreviations.

**Structure:** Tibble
**Dimensions:** 7 rows x 2 columns

**Data:**

| injuryGameStatus | injuryAbbr |
|------------------|------------|
| Doubtful | D |
| Inactive | IA |
| Injured Reserve | IR |
| Out | Out |
| Questionable | Q |
| Reserve - Covid-19 | CVD |
| NA | NA |

---

## Data Relationships

### Primary Key Relationships

```
players_points.rds
  ├─ id (integer) → Primary player identifier
  │   ├→ points_projection.rds [id]
  │   ├→ points_projection_and_errors.rds [id]
  │   ├→ week{X}_players_projections.rds [id]
  │   ├→ dudesffa_projpoints_week{X}.rds [id]
  │   ├→ weekly_proj_player_site_{X}.rds [id]
  │   ├→ season_player_proj_sites.rds [id]
  │   └→ season_projtable.rds [id]
  │
  ├─ playerId (integer) → NFL.com player ID
  │   ├→ rankAgainstPosition_week{X}.rds [playerId]
  │   └→ season_2024_projections_errors.rds [playerId]
  │
  └─ External IDs (character)
      ├─ cbs_id
      ├─ espn_id
      ├─ fleaflicker_id
      ├─ fantasypro_id
      └─ etc.

simulation_v5_week{X}_{phase}.rds
  ├─ teams.teamId → rank_week{X}.rds [teamId]
  ├─ players_sim.id → players_points.rds [id]
  └─ ptsproj → points_projection_and_errors.rds

draft_picks.rds
  ├─ player.id → players_points.rds [playerId]
  └─ team.id → teams [teamId]
```

### Data Flow Pipeline

```
1. Web Scraping
   ├─ week{X}_scrap.rds (raw scraped data)
   └─ weekly_webscrapes_{X}.rds (processed)

2. Projection Processing
   ├─ weekly_proj_player_site_{X}.rds (individual sites)
   ├─ points_projection.rds (aggregated, no errors)
   └─ points_projection_and_errors.rds (with error correction)

3. Enhanced Projections
   ├─ dudesffa_projpoints_week{X}.rds (custom ML projections)
   └─ weekly_proj_table_{X}.rds (ranked/tiered)

4. Integration
   ├─ week{X}_players_projections.rds (full player profiles)
   └─ players_points.rds (actual results)

5. Simulation
   ├─ simulation_v5_week{X}_{phase}.rds (snapshot states)
   └─ rank_week{X}.rds (outcomes)

6. Season Aggregation
   ├─ season_scrap.rds
   ├─ season_projtable.rds
   └─ season_2024_projections_errors.rds (for next season)
```

---

## Key Field Definitions

### Fantasy Scoring

**weekPts / points** - Fantasy points based on standard scoring:
- Passing: 1 pt per 25 yards, 4 pts per TD, -2 per INT
- Rushing: 1 pt per 10 yards, 6 pts per TD
- Receiving: 1 pt per 10 yards, 6 pts per reception, 6 pts per TD
- Kickers: 3 pts per FG, 1 pt per XP
- Defense/ST: Points based on points allowed, turnovers, sacks, TDs

### Projection Metrics

**floor** - 25th percentile projection (conservative estimate)
**ceiling** - 75th percentile projection (optimistic estimate)
**points / estimate** - Expected value (mean projection)
**sd_pts** - Standard deviation of projection (uncertainty)

### Value Metrics

**points_vor (VOR)** - Value Over Replacement
- Difference between player's projection and the replacement-level player at that position
- Replacement baseline varies by position based on roster construction

**dropoff** - Point difference to next-ranked player
- Useful for draft/trade decisions
- High dropoff indicates tier break

### Ranking Metrics

**rank** - Overall rank across all positions
**pos_rank** - Rank within position
**tier** - Tiered grouping (players in same tier are roughly equivalent)

### Market Metrics (Season files only)

**overall_ecr** - Expert Consensus Ranking (overall)
**pos_ecr** - Expert Consensus Ranking (by position)
**adp** - Average Draft Position across platforms
**adp_diff** - Difference between projection rank and ADP (positive = value, negative = reach)
**aav** - Average Auction Value
**uncertainty** - Metric combining projection variance and expert disagreement

### Error Correction

**proj.error** - Actual points minus projected points
- Positive: Under-projection (player did better)
- Negative: Over-projection (player did worse)

**ERROR_LAG_1, ERROR_LAG_2** - Historical errors from previous weeks
- Used as features in ML models to adjust current week projections

---

## Data Quality Notes

### Missing Data Patterns

1. **New Players:** May lack historical IDs from some platforms (espn_id, cbs_id, etc.)
2. **Injured Players:** May have NULL projections in some weeks
3. **Practice Squad:** May appear in scrapes but not in official rosters
4. **Defense/Special Teams:** Have different stat categories than skill positions

### Data Refresh Schedule

- **Weekly Scrapes:** Tuesday afternoon (after MNF)
- **Actual Points:** Updated real-time during games
- **Simulations:** Updated multiple times per week (pre-TNF, pre-Sunday, pre-MNF, post-waivers)
- **Rankings:** Updated after each full week completes

### File Size Considerations

- Simulation files (100-500 KB each): Include nested lists and full roster data
- Player points file (~2 MB): Largest single file due to nested statistics
- Historical data: Keep previous seasons in subdirectories to manage size

---

## Usage Examples

### Finding a Player's Weekly Projection

```r
# Load projections
proj <- readRDS("data/week3_players_projections.rds")

# Find player by name
player <- proj[proj$name == "Christian McCaffrey", ]
print(player$points)  # Projected points
print(player$tier)    # Tier assignment
```

### Comparing Projection Sources

```r
# Load multi-source projections
proj_sites <- readRDS("data/weekly_proj_player_site_3.rds")

# Get all projections for player ID 13130 (CMC)
cmc_proj <- proj_sites[proj_sites$id == 13130, ]
print(cmc_proj[, c("data_src", "pts.proj")])
```

### Analyzing Projection Accuracy

```r
# Load historical errors
errors <- readRDS("data/season_2024_projections_errors.rds")

# Calculate mean absolute error by source
library(dplyr)
mae_by_source <- errors %>%
  group_by(data_src) %>%
  summarize(mae = mean(abs(proj.error), na.rm = TRUE))
```

### Running What-If Scenarios

```r
# Load simulation state
sim <- readRDS("data/simulation_v5_week3_preTNF.rds")

# Access team data
teams <- sim$teams

# Access current projections
current_proj <- sim$ptsproj

# Modify projections and re-run simulation
# (simulation logic would go here)
```

---

## Version History

- **v1.0** (2026-03-06): Initial comprehensive documentation
- Future versions will include schema changes and new file types

---

## Contact

For questions about data structure or access, contact the project maintainer.
