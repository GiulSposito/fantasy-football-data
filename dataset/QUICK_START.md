# Quick Start Guide - Unified DudesData (2020-2025)

## Load Any Database

```r
library(tidyverse)
library(dm)

# Load a database
ffa_db <- readRDS("dataset/ffa_db.rds")
stats_db <- readRDS("dataset/nfl_stats_db.rds")
players_db <- readRDS("dataset/nfl_players_db.rds")
simulation_db <- readRDS("dataset/dudes_simulation_db.rds")

# Extract a table
projections <- ffa_db$ffa_projtable
player_points <- stats_db$nfl_players_points
player_roster <- players_db$nfl_players
```

## Get Latest Data for a Week

```r
# Always filter for most recent timestamp
week17_projections <- ffa_db$ffa_projtable |>
  filter(season == 2025, week == 17) |>
  group_by(id) |>
  filter(timestamp == max(timestamp)) |>
  ungroup()
```

## Join Player Data Across Databases

```r
# Use ffa_player_ids as the bridge
player_ids <- ffa_db$ffa_player_ids

# Get projections with actual stats
analysis <- ffa_db$ffa_projtable |>
  filter(season == 2025, week == 10) |>
  left_join(player_ids, by = "id") |>
  left_join(
    stats_db$nfl_players_points |>
      filter(season == 2025, week == 10),
    by = c("nfl_id" = "playerId", "season", "week")
  )
```

## Access Simulation Data

```r
# Get simulation quantiles
week15_sims <- simulation_db$dudes_players_simulations |>
  filter(season == 2024, week == 15)

# Expand quantiles
sims_with_quantiles <- week15_sims |>
  select(season, week, id, playerId, pos, simQuantiles) |>
  unnest_wider(simQuantiles)
  # Now you have: q05, q15, q30, q50, q70, q85, q95

# Get simulation samples
seeds <- simulation_db$dudes_players_seeds |>
  filter(season == 2024, week == 15)

# Expand seeds
seeds_expanded <- seeds |>
  select(season, week, id, playerId, pos, seeds) |>
  unnest(seeds)
  # Now each seed is a separate row
```

## Multi-Season Analysis

```r
# Get player performance across all seasons
player_history <- stats_db$nfl_players_points |>
  filter(playerId == "4241479") |>
  arrange(season, week) |>
  group_by(season) |>
  summarise(
    weeks_played = n(),
    total_points = sum(pts, na.rm = TRUE),
    avg_points = mean(pts, na.rm = TRUE),
    .groups = "drop"
  )
```

## Available Databases

| Database | Tables | Size | Coverage |
|----------|--------|------|----------|
| ffa_db.rds | 5 | 9.7 MB | 2020-2025 (limited 2021) |
| nfl_stats_db.rds | 4 | 1.0 MB | 2019-2025 |
| nfl_players_db.rds | 2 | 0.3 MB | 2019-2025 |
| nfl_round_db.rds | 5 | 0.1 MB | 2020-2025 |
| dudes_simulation_db.rds | 2 | 17.2 MB | 2020-2024 |
| nfl_recap_db.rds | 1 | 1.3 MB | 2023-2025 |
| nfl_teams_db.rds | 2 | 1.5 KB | 2020-2025 |

## Important Notes

### Type Changes
All player IDs are now **character type** (converted from integer in older seasons)

```r
# Always use character for filtering
player_data <- stats_db$nfl_players_points |>
  filter(playerId == "4241479")  # character, not integer
```

### Schema Compatibility
Some columns exist only in certain years. Check before using:

```r
# Safe cross-season code
if ("gsis_id" %in% names(ffa_db$ffa_player_ids)) {
  # Use gsis_id
} else {
  # Fallback approach
}
```

### Missing Data Awareness

- **2021 projections:** Only week 1 available
- **2020 advanced stats:** Not available
- **2022 teams data:** Not available
- **2020-2022 recaps:** Feature didn't exist
- **2025 simulations:** Not yet generated

See `CLAUDE.md` for complete schema compatibility documentation.

## Common Queries

### Top Scorers by Season
```r
top_scorers <- stats_db$nfl_players_points |>
  group_by(season, playerId) |>
  summarise(total_pts = sum(pts, na.rm = TRUE), .groups = "drop") |>
  group_by(season) |>
  slice_max(total_pts, n = 10) |>
  left_join(players_db$nfl_players, by = "playerId")
```

### Projection Accuracy
```r
accuracy <- ffa_db$ffa_projtable |>
  filter(season == 2024, week <= 17) |>
  left_join(ffa_db$ffa_player_ids, by = "id") |>
  left_join(
    stats_db$nfl_players_points,
    by = c("nfl_id" = "playerId", "season", "week")
  ) |>
  mutate(
    error = pts - points,
    abs_error = abs(error),
    pct_error = abs_error / pts * 100
  )
```

### Injury Impact
```r
injuries <- players_db$nfl_player_injury_status |>
  filter(season == 2025, !is.na(injuryStatus)) |>
  left_join(
    stats_db$nfl_players_points,
    by = c("playerId", "season", "week" = "week")
  ) |>
  group_by(injuryStatus) |>
  summarise(
    player_weeks = n(),
    avg_points = mean(pts, na.rm = TRUE)
  )
```

## Help & Documentation

- **Full Report:** `dataset/MERGE_COMPLETE_REPORT.md`
- **Project Guide:** `/Users/gsposito/Projects/DudesData/CLAUDE.md`
- **Validation Data:** `dataset/merge_validation.csv`
- **Execution Log:** `dataset/merge_execution_v2.log`

## Need More Help?

1. Check if your question is about schema compatibility → see `CLAUDE.md`
2. Check data availability → see `MERGE_COMPLETE_REPORT.md`
3. Check validation issues → see `merge_validation.csv`
4. Check column names → use `names(db$table_name)`

---

**Last Updated:** 2026-03-08
**Dataset Version:** 2020-2025 Unified (v1)
