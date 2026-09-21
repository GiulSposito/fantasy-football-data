# 📊 Unified Dataset - Multi-Year Fantasy Football Data

**Created:** 2026-03-08
**Script:** `R/merge_datasets.R`
**Coverage:** 2020-2025 (6 seasons)

---

## Overview

This unified dataset merges data from multiple sources into a single, comprehensive collection following the `app/` schema standards. It combines:

- **app/2023-24-25/** - Pre-merged 2023-2025 data
- **etl/2020/** - Legacy 2020 season conversion
- **etl/2021/** - Legacy 2021 season conversion
- **etl/2022/** - Legacy 2022 season conversion
- **etl/2023/** - Legacy 2023 season conversion

**Total Coverage:** 6 NFL seasons (2020-2025), ~100 weeks of data

---

## Dataset Structure

The dataset contains **7 relational databases** (dm objects) in RDS format:

```
dataset/
├── ffa_db.rds                    # Fantasy projections & player IDs
├── nfl_teams_db.rds              # League teams & owners
├── nfl_players_db.rds            # Player roster & injury tracking
├── nfl_stats_db.rds              # Official NFL statistics
├── nfl_round_db.rds              # Weekly matchups & rosters
├── nfl_recap_db.rds              # Match narratives & recaps
├── dudes_simulation_db.rds       # Monte Carlo simulations
├── MERGE_REPORT.md               # Detailed merge statistics
└── MERGE_LOG.md                  # Processing log
```

---

## Database Schemas

### 1. ffa_db.rds - Fantasy Projections

**Tables:**
- `ffa_scrape` - Raw scraping metadata with timestamps
- `ffa_player_ids` - ID mapping between systems (PK: id)
- `ffa_players` - Player metadata (PK: id, pos)
- `ffa_projtable` - Aggregated projections (PK: season, week, id, pos, avg_type, tag, timestamp)
- `ffa_proj_source_points` - Individual source projections (PK: season, week, id, pos, data_src, tag, timestamp)

**Key Columns:**
- `season` - NFL season year (2020-2025)
- `week` - Week number (1-17)
- `id` - ffanalytics player ID
- `pos` - Position (QB, RB, WR, TE, K, DST)
- `points` - Projected fantasy points
- `data_source` - Origin (etl_2020, unified_2023, etc.)
- `merged_at` - Merge timestamp

### 2. nfl_teams_db.rds - League Configuration

**Tables:**
- `nfl_teams` - Fantasy league teams (PK: teamId)
- `nfl_owners` - Team owners (PK: ownerUserId)

**Known Issues:**
- ⚠️ 2022 has no team data (etl/2022/nfl_teams_db.rds was empty)

### 3. nfl_players_db.rds - Player Information

**Tables:**
- `nfl_players` - NFL player roster (PK: playerId)
- `nfl_player_injury_status` - Temporal injury tracking (PK: playerId, timestamp)

**Key Columns:**
- `playerId` - NFL player ID
- `name` - Full player name
- `position` - NFL position
- `nflTeamAbbr` - Team abbreviation
- `injuryStatus` - Injury designation (IR, OUT, DOUBTFUL, QUESTIONABLE, ACTIVE)

### 4. nfl_stats_db.rds - Official Statistics

**Tables:**
- `nfl_stat_dictionary` - Stat definitions (PK: statId)
- `nfl_players_points` - Weekly point totals (PK: season, week, playerId)
- `nfl_players_stats` - Detailed statistics by statId (PK: season, week, playerId, statId)
- `nfl_players_adv_stats` - Advanced statistics (⚠️ schema varies by year)

**Schema Version Notes:**

⚠️ **`nfl_players_adv_stats` has incompatible schemas across years:**

| Schema Version | Years | Key Columns |
|----------------|-------|-------------|
| **2023 schema** | 2021-2023 | `percentRostered`, `targets`, `redzoneTargets`, `touches` |
| **2025 schema** | 2024-2025 | `transactionBuysellAdd`, `leaguesOwned`, `avgPointsAgainst` |

**Usage:**
```r
# Filter by schema version
adv_stats_2023 <- nfl_stats_db$nfl_players_adv_stats %>%
  filter(schema_version == "2023")

adv_stats_2025 <- nfl_stats_db$nfl_players_adv_stats %>%
  filter(schema_version == "2025")
```

### 5. nfl_round_db.rds - Weekly Matchups

**Tables:**
- `matchups_games` - Weekly matchups (PK: season, week, matchupId)
- `nfl_teams_rosters` - Roster composition (PK: season, week, teamId, playerId, tag, timestamp)
- `nfl_teams_week_stats` - Weekly team stats
- `nfl_teams_season_stats` - Season aggregates

### 6. nfl_recap_db.rds - Match Narratives

**Tables:**
- `nfl_recap` - Match recaps and narratives

**Note:** Early years (2020-2022) have minimal recap data.

### 7. dudes_simulation_db.rds - Monte Carlo Simulations

**Tables:**
- `dudes_players_seeds` - Base simulation values (PK: season, week, id, playerId, pos, simType)
- `dudes_players_simulations` - 1000 Monte Carlo samples per player (PK: season, week, id, playerId, pos, simType)

**Simulation Types:**
- Simple: `NFL`, `proj_table_average`, `proj_table_robust`, `proj_table_weighted`
- Monte Carlo: `proj_src`, `proj_src_errors`, `proj_src_w_errors`, `hist_data`
- Density: `*_density` variants

---

## Loading the Data

```r
library(tidyverse)
library(dm)

# Load databases
ffa_db <- readRDS("dataset/ffa_db.rds")
nfl_stats_db <- readRDS("dataset/nfl_stats_db.rds")
nfl_players_db <- readRDS("dataset/nfl_players_db.rds")
nfl_round_db <- readRDS("dataset/nfl_round_db.rds")
nfl_teams_db <- readRDS("dataset/nfl_teams_db.rds")
nfl_recap_db <- readRDS("dataset/nfl_recap_db.rds")
dudes_simulation_db <- readRDS("dataset/dudes_simulation_db.rds")

# Extract tables
projections <- ffa_db$ffa_projtable
player_stats <- nfl_stats_db$nfl_players_stats
players <- nfl_players_db$nfl_players
```

---

## Common Analysis Patterns

### 1. Cross-Season Player Performance

```r
# Compare player performance across seasons
player_history <- nfl_stats_db$nfl_players_points %>%
  left_join(nfl_players_db$nfl_players, by = "playerId") %>%
  group_by(name, position, season) %>%
  summarise(
    weeks_played = n(),
    total_points = sum(pts, na.rm = TRUE),
    avg_points = mean(pts, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(name, season)
```

### 2. Projection Accuracy Over Time

```r
# Analyze projection accuracy by season
accuracy <- ffa_db$ffa_projtable %>%
  filter(avg_type == "average", tag == "final") %>%
  left_join(
    nfl_stats_db$nfl_players_points,
    by = c("id" = "playerId", "season", "week")
  ) %>%
  mutate(
    error = points - pts,
    abs_error = abs(error),
    pct_error = abs_error / pts * 100
  ) %>%
  group_by(season, pos) %>%
  summarise(
    mean_abs_error = mean(abs_error, na.rm = TRUE),
    median_abs_error = median(abs_error, na.rm = TRUE),
    .groups = "drop"
  )
```

### 3. Injury Impact Analysis

```r
# Analyze how injuries affect performance
injury_impact <- nfl_players_db$nfl_player_injury_status %>%
  left_join(
    nfl_stats_db$nfl_players_points,
    by = c("playerId", "season" = "season")
  ) %>%
  group_by(injuryStatus) %>%
  summarise(
    n_games = n(),
    avg_points = mean(pts, na.rm = TRUE),
    sd_points = sd(pts, na.rm = TRUE)
  )
```

### 4. COVID-19 Season Analysis (2020)

```r
# Compare 2020 (COVID) vs normal seasons
covid_comparison <- nfl_stats_db$nfl_players_points %>%
  left_join(nfl_players_db$nfl_players, by = "playerId") %>%
  mutate(covid_season = if_else(season == 2020, "COVID (2020)", "Normal")) %>%
  group_by(covid_season, position) %>%
  summarise(
    total_players = n_distinct(playerId),
    avg_points_per_game = mean(pts, na.rm = TRUE),
    scoring_variance = sd(pts, na.rm = TRUE),
    .groups = "drop"
  )
```

### 5. Temporal Analysis (Using data_source)

```r
# Track data lineage
data_sources <- ffa_db$ffa_projtable %>%
  count(season, data_source) %>%
  pivot_wider(names_from = data_source, values_from = n, values_fill = 0)

# Most recent data per season
latest_data <- ffa_db$ffa_projtable %>%
  group_by(season, week) %>%
  filter(timestamp == max(timestamp)) %>%
  ungroup()
```

---

## Data Quality Notes

### Known Issues

1. **2022 Team Data Missing**
   - `nfl_teams_db` has 0 rows for 2022 season
   - Team roster and owner information unavailable
   - Impact: Cannot analyze team-level metrics for 2022

2. **Advanced Stats Schema Incompatibility**
   - 2020: No advanced stats (table doesn't exist or empty)
   - 2021-2023: Schema with `percentRostered`, `targets`, etc.
   - 2024-2025: Complete schema rewrite
   - **Solution:** Use `schema_version` column to filter

3. **Empty Recap Data (2020-2022)**
   - `nfl_recap_db` has minimal data for early years
   - Rich narratives available for 2023-2025 only

4. **Foreign Key Violations**
   - Some player IDs in stats don't match player roster
   - Use `left_join()` instead of `inner_join()` to preserve data
   - Documented in source `app/2023-24-25/FK_VIOLATIONS.md`

### Column Availability

**Added in 2024+ (NA for earlier years):**
- `ffa_player_ids`: `gsis_id`, `sleeper_id`
- `nfl_players`: `lastNoteTimestamp`

**Always check for NA:**
```r
# Handle missing columns gracefully
if ("gsis_id" %in% names(player_ids)) {
  # Use gsis_id
} else {
  # Fallback to nfl_id
}
```

### Temporal Versioning

Many tables include temporal tracking:
- `timestamp` - When data was captured
- `tag` - Data moment: "preview", "final"
- `data_source` - Origin: "etl_2020", "unified_2023", etc.
- `merged_at` - When record was merged into unified dataset

**Best Practice:** Always filter to most recent snapshot:
```r
latest <- data %>%
  group_by(season, week, playerId) %>%
  filter(timestamp == max(timestamp)) %>%
  ungroup()
```

---

## Validation

### Schema Compatibility

All databases follow `app_DATAMODEL.md` standards:
- Primary keys defined per schema
- Foreign keys validated (lenient mode due to known violations)
- Column types consistent within each table
- NA values handled gracefully

### Data Integrity Checks

```r
# Check for duplicate primary keys
ffa_db$ffa_projtable %>%
  count(season, week, id, pos, avg_type, tag, timestamp) %>%
  filter(n > 1)

# Check data source distribution
ffa_db$ffa_projtable %>%
  count(season, data_source)

# Validate season coverage
nfl_stats_db$nfl_players_points %>%
  distinct(season) %>%
  arrange(season)
```

---

## Merge Process

The unified dataset was created using `R/merge_datasets.R`:

### Process Steps:

1. **Load Source Databases**
   - Read all 7 databases from each source directory
   - Handle missing files gracefully
   - Track loading statistics

2. **Schema Analysis**
   - Identify common columns across all sources
   - Detect schema variations (e.g., `nfl_players_adv_stats`)
   - Document incompatibilities

3. **Smart Merging**
   - Use only common columns for binding
   - Add `data_source` tracking
   - Add `merged_at` timestamp
   - Special handling for schema-versioned tables
   - Skip empty tables (e.g., 2022 nfl_teams)

4. **Database Reconstruction**
   - Rebuild dm objects from merged tibbles
   - Add primary keys per schema
   - Validate structure (lenient mode)

5. **Reporting**
   - Generate `MERGE_REPORT.md` with statistics
   - Create `MERGE_LOG.md` with detailed logs
   - Document data sources and coverage

### Merge Statistics

See `MERGE_REPORT.md` for:
- Row counts per table
- Column counts per table
- Data source distribution
- Primary key validation results

---

## Usage Guidelines

### For Machine Learning

**Recommended:**
- Use 2020-2022 for training (3 seasons)
- Use 2023-2024 for validation (2 seasons)
- Use 2025 for testing (1 season)

**Features Available:**
- Player projections (11+ sources)
- Historical statistics (80+ stat types)
- Monte Carlo simulations (1000 samples)
- Injury status (temporal tracking)
- Matchup context (opponent, home/away)

### For Time Series Analysis

**Temporal Granularity:**
- Season-level (2020-2025)
- Week-level (1-17 per season)
- Multiple timestamps per week (preview, final)

**Recommended Filters:**
```r
# Use only final data for cleaner time series
time_series_data <- nfl_stats_db$nfl_players_points %>%
  filter(season >= 2020, season <= 2025) %>%
  arrange(season, week, playerId)
```

### For Cross-Season Comparisons

**Stable Metrics (Available All Years):**
- `nfl_players_points`: `pts` (fantasy points)
- `ffa_projtable`: `points`, `floor`, `ceiling`, `rank`, `tier`
- `nfl_players`: `name`, `position`, `nflTeamAbbr`

**Avoid Comparing:**
- `nfl_players_adv_stats` - Schema changed completely
- `nfl_teams` - Missing for 2022
- Columns added in 2024+ (`gsis_id`, `sleeper_id`)

---

## Performance Tips

### Memory Management

Full dataset is ~350 MB (all databases combined). For large analyses:

```r
# Load only needed databases
ffa_db <- readRDS("dataset/ffa_db.rds")
nfl_stats_db <- readRDS("dataset/nfl_stats_db.rds")
# Skip others if not needed

# Filter early
recent_data <- ffa_db$ffa_projtable %>%
  filter(season >= 2023) %>%  # Reduce dataset size
  filter(pos == "QB")          # Focus on specific position
```

### Query Optimization

```r
# Use indices for joins
setkey(projections, season, week, id)
setkey(stats, season, week, playerId)

# Group operations efficiently
player_summary <- stats %>%
  group_by(playerId) %>%
  summarise(across(where(is.numeric), mean, na.rm = TRUE))
```

---

## References

- **Schema Documentation:** `app_DATAMODEL.md`
- **Data Dictionary:** `app_DATA_DICTIONARY.md`
- **Legacy Conversion:** `LEGACY_YEARS_FINAL_SUMMARY.md`
- **Merge Script:** `R/merge_datasets.R`

---

## Support

For issues or questions:
1. Check `MERGE_LOG.md` for merge warnings
2. Review `MERGE_REPORT.md` for data coverage
3. Consult `app_DATAMODEL.md` for schema details

---

**Dataset Version:** 1.0
**Created:** 2026-03-08
**Maintained by:** DudesData
**Status:** ✅ Ready for Analysis
