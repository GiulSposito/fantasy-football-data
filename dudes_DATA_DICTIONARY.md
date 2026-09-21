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

**Description:** Complete simulation state at a specific point in the week. Contains all data needed to run Monte Carlo simulations.

**Structure:** List with 11 elements

**Elements:**

| Element | Type | Dimensions | Description |
|---------|------|------------|-------------|
| `week` | numeric | Single value | Current week number |
| `season` | numeric | Single value | Season year |
| `ptsproj` | data.frame | ~45,000 x 6 | All player projections with errors |
| `matchups` | data.frame | 8 x 13 | Weekly matchups |
| `teams` | data.frame | 16 x 14 | All team data |
| `proj_table` | data.frame | ~500 x 22 | Weekly projection table |
| `players_stats` | data.frame | ~1,100 x 28 | Player statistics |
| `players_id` | data.frame | ~5,300 x 15 | Player ID mappings |
| `players_sim` | data.frame | ~230 x 18 | Rostered players for simulation |
| `teams_sim` | data.frame | 16 x 3 | Team simulation results |
| `matchup_sim` | data.frame | 8 x 22 | Matchup simulation results |

**Phase Suffixes:**

The simulation system generates snapshots at different points throughout each NFL week. The available phases vary by week depending on the NFL schedule (Thursday night games, international games, holidays, etc.).

**Standard Phases (most weeks):**
- `preTNF` - Before Thursday Night Football
- `posTNF` - After Thursday Night Football
- `preSundayGames` - Before Sunday games
- `preSNF` - Before Sunday Night Football
- `posSNF` - After Sunday Night Football (varies by week)
- `preMNF` - Before Monday Night Football
- `posMNF` - After Monday Night Football (varies by week)
- `preWaivers` - Before waiver processing
- `posWaivers` - After waiver processing
- `final` - Week completed (always present)

**Event-Specific Phases:**

These phases appear in specific weeks based on the NFL schedule:

- `preBR` - Before Brazil Game (e.g., Week 1, 2025)
- `posBrasilGame` - After Brazil Game (e.g., Week 1, 2024)
- `preLondon` - Before London Game (e.g., Week 7, 2025)
- `preLondonGame` - Before London Game (e.g., Weeks 5-7, 2024)
- `preDublinGame` - Before Dublin Game (e.g., Week 4, 2025)
- `posThanksgiving` - After Thanksgiving (e.g., Week 13, 2025)
- `preXMAS` - Before Christmas (e.g., Week 17, 2024)

**Notes:**
- Not all weeks have all phases - the presence of phases depends on game scheduling
- International games (London, Dublin, Brazil) typically add special phases
- Holiday games (Thanksgiving, Christmas) may add special phases
- The `final` phase is always generated for every week after all games complete
- Total simulation files per season: typically **~140-145 files** across all weeks and phases

**Example phase distribution:**
```
Week 1 (Brazil Game):    preBR, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 phases)
Week 4 (Dublin Game):    preDublinGame, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 phases)
Week 7 (London Game):    preLondon, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 phases)
Week 13 (Thanksgiving):  preTNF, posTNF, posThanksgiving, preSundayGames, preMNF, preWaivers, posWaivers, final (8 phases)
Typical week:            preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (7 phases)
```

**To check available phases for a week:**
```r
# List all simulation phases for a specific week
week <- 13
files <- list.files("dudes/2025/", pattern = paste0("simulation_v\\d+_week", week, "_.*\\.rds$"))
phases <- gsub(paste0("simulation_v\\d+_week", week, "_"), "", files)
phases <- gsub("\\.rds$", "", phases)
sort(phases)
```

**Key Nested Structures:**

**`teams` columns:**
- `teamId`, `name`, `ownerUserId`, `coManagerUserId`
- `imageUrl`, `imageUrlLarge`
- `isActive`, `rank`
- `stats` (list): Team statistics
- `matchups` (list): Matchup schedule
- `rosters` (list): Full roster data
- `week.stats` (list): Current week stats
- `season.stats` (list): Season cumulative stats

**`teams_sim` columns:**
- `teamId`
- `simulation` (list): Simulated season outcomes
- `simulation.org` (list): Original simulation before updates

**`matchup_sim` columns:**
- `matchupId`, `week`
- `awayTeam.teamId`, `homeTeam.teamId`
- `awayTeam.simulation`, `homeTeam.simulation`
- `homeTeam.win`, `homeTeam.win.org`
- Various probability metrics

**Usage:** Primary file for running season simulations, playoff probabilities, and what-if scenarios.

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

> **⚠️ IMPORTANTE:** `week0` e `season_*` são **dois nomes diferentes para os mesmos dados**!
>
> Ambos representam estatísticas da **temporada completa** (soma das 17 semanas da temporada regular).
> A diferença está apenas na convenção de nomenclatura, não no conteúdo.

**Equivalências de nomenclatura:**

| Week 0 Format | Season Format | Content |
|---------------|---------------|---------|
| `week0_scrap.rds` | `season_scrap.rds` | **IDÊNTICOS:** Full season scrapes (17-week totals) |
| `week0_players_projections.rds` | `season_projtable.rds` | **IDÊNTICOS:** Full season projection table |
| `week0_proj_player_site.rds` | `season_player_proj_sites.rds` | **IDÊNTICOS:** Full season projections by site |

**Por que existem duas convenções?**

1. **`week0_*.rds`**: Permite que pipelines que processam `week{X}` (onde X = 0-17) incluam dados de temporada completa sem código especial
2. **`season_*.rds`**: Nome mais semântico e auto-explicativo para análises de temporada completa

**Quando usar cada formato:**

| Use `week0_*.rds` se... | Use `season_*.rds` se... |
|------------------------|--------------------------|
| Seu código faz loop por `week{0-17}` | Análise explícita de temporada completa |
| Pipeline automatizado que processa todas as semanas | Draft preparation e rankings pré-temporada |
| Compatibilidade com código legado | Clareza semântica é importante |
| Estrutura week{X} é mandatória | Documentação e relatórios para usuários |

**Exemplos de uso:**

```r
# Abordagem 1: Loop por todas as semanas (0-17) - usa week0
for (week in 0:17) {
  filename <- paste0("dudes/2025/week", week, "_scrap.rds")
  data <- readRDS(filename)
  # week 0 = temporada completa
  # weeks 1-17 = semanas individuais
}

# Abordagem 2: Análise específica de temporada - usa season
season_data <- readRDS("dudes/2025/season_scrap.rds")
draft_rankings <- readRDS("dudes/2025/season_projtable.rds")

# Ambos têm conteúdo idêntico:
week0_data <- readRDS("dudes/2025/week0_scrap.rds")
season_data <- readRDS("dudes/2025/season_scrap.rds")
identical(week0_data, season_data)  # TRUE
```

**Resumo:**
- ✅ `week0` = `season` (mesmo conteúdo)
- ✅ Ambos = soma de todas as 17 semanas da temporada regular
- ✅ Escolha baseada em contexto de uso, não em diferença de dados

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

**Location:** `dudes/injuryGameStatusAbbr.rds` (root directory, not in year subdirectories)

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

**Usage:**
```r
# Load injury status lookup
injury_lookup <- readRDS("dudes/injuryGameStatusAbbr.rds")

# Join with player data
players <- readRDS("dudes/2025/players_points.rds")
players_with_status <- players %>%
  left_join(injury_lookup, by = "injuryGameStatus")
```

---

## Auxiliary Files

These files provide supplementary data or exports that support the main data pipeline.

### `missing_player_ids.rds`

**Description:** Manual player ID mappings for players not automatically detected by ffanalytics scraping.

**Location:** Season directories (e.g., `dudes/2024/missing_player_ids.rds`)

**Presence:** Created ad-hoc when needed; not present in all seasons

**Structure:** Tibble (same schema as player ID mapping tables)

**Columns:**
- `id` - Internal player ID
- `nfl_id` - NFL.com ID
- `stats_id` - Stats provider ID
- `cbs_id` - CBS Sports ID
- `espn_id` - ESPN ID
- `fleaflicker_id` - FleaFlicker ID
- `fantasypro_id` - FantasyPros ID
- Other platform-specific IDs

**Usage:**
```r
# These IDs are typically already merged into the main projection files
# But can be used to supplement automated ID detection

manual_ids <- readRDS("dudes/2024/missing_player_ids.rds")

# Consolidate with scraped IDs if needed
all_ids <- bind_rows(
  scraped_ids,
  manual_ids
) %>% distinct(id, .keep_all = TRUE)
```

**Note:** This file is generated manually when the automated scraping fails to identify certain players (rookies, practice squad, etc.).

---

### `draft_picks.html`

**Description:** HTML export of draft picks for human-readable viewing in web browser.

**Location:** Season directories (e.g., `dudes/2025/draft_picks.html`)

**Content:** Formatted table of draft data with styling

**Usage:** Open in browser for quick visual review of draft results

**Relationship:** Visual representation of data in `draft_picks.rds`

```r
# Generate HTML export from RDS (example)
library(knitr)
library(kableExtra)

draft_picks <- readRDS("dudes/2025/draft_picks.rds")

draft_picks %>%
  kable(format = "html") %>%
  kable_styling() %>%
  save_kable("dudes/2025/draft_picks.html")
```

**Note:** Not used in data pipelines; purely for human consumption.

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
