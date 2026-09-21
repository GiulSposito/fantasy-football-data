# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This repository contains **two separate R projects** for Fantasy Football analytics:

1. **app/** - DudesApp: NFL Fantasy app using the **NFL Fantasy API**
2. **dudes/** - DudesFFA: ESPN Fantasy league app using the **ESPN Fantasy API**

Both projects use R with tidyverse, dm (data modeling), and extensive data pipelines. The projects share similar architecture but have different data sources and APIs.

This repo holds **data only** — the production pipeline code (`R/api/`, `R/import/`, `R/simulation/`, `R/pipeline/` described in the READMEs) lives in a separate repo. What is here: the RDS databases, an ETL layer that reshapes `dudes/` into the `app/` schema, and one-off merge/validation scripts.

### Repository scope (what's versioned)

Only the canonical converted output (`dataset/`) plus code and docs are tracked in git — see `.gitignore`. Raw and intermediate data (`dudes/`, `app/`, `etl/`) live on disk for local analysis but are **not** committed; a fresh clone gets the pipeline and the canonical dataset, and needs to obtain or regenerate the raw/intermediate data separately (source scrapes/league exports for `dudes/`, the external native pipeline for `app/2025-24/`, `Rscript R/etl/...` for `etl/`). Superseded code and one-time migration artifacts live under `archive/` (kept for provenance, not part of the active pipeline).

## Data catalog

**`DATA_CATALOG.md`** is the generated inventory of every `.rds` (season/week ranges, row counts, sources). Regenerate after data changes with `Rscript catalog_rds.R`. Headline numbers: ~1,800 rds files / ~2.6 GB; `dataset/` covers 2020–2025; 11 projection sources (CBS, ESPN, FanDuel, FantasyPros, FantasySharks, FFToday, FleaFlicker, NFL, NumberFire, RTSports, WalterFootball).

## Project Structure

```
DudesData/
├── app/                     # DudesApp — NFL Fantasy API, dm databases (7 per folder) — not versioned
│   ├── 2025-24/             # Native app pipeline output — 2024–2025
│   ├── 2023_compliance/     # archive/app-2023-raw re-emitted to current schema
│   ├── 2023-24-25/          # 2023–2025 merged
│   └── temp/                # Point-in-time scrape/projection snapshots (157 files)
│
├── dudes/                   # DudesFFA — ESPN Fantasy API, file-per-week, 2019–2025 — not versioned
│
├── etl/{2020..2025}/        # dudes/ reshaped into the app/ dm schema, one folder per season — not versioned
├── dataset/                 # Canonical unified dm dataset 2020–2025 (for analysis) — versioned
│
├── R/etl/                   # ETL pipeline: transform_dudes_to_app.R (dudes → app schema)
├── R/merge_datasets.R       # etl/2020-2022 + app/2023-24-25 → dataset/
├── catalog_rds.R            # regenerates DATA_CATALOG.md
├── archive/                 # superseded code & one-time migration artifacts (see below)
└── .claude/, _bmad/, _bmad-output/  # local tooling — gitignored, not part of the public repo
```

### `archive/`

```
archive/
├── etl_v1/              # original ETL pipeline, superseded by R/etl (see R/etl/MIGRATION_GUIDE.md)
├── migration-scripts/   # merge_unified_database.R, transform_2023_to_compliance.R, validate_unified_schema.R
├── migration-logs/      # etl_2019.log … etl_2024.log
├── migration-reports/   # ETL_*_REPORT.md, LEGACY_*.md, DISCREPANCY_REPORT_2025.*
├── dudes-stray-docs/    # DOCUMENTATION_CORRECTIONS.md, IMPLEMENTED_CORRECTIONS.md
└── app-2023-raw/        # original app/2023/ (pre-compliance), gitignored — data, not code
```

### Data lineage

```
dudes/{year}/  ──R/etl/transform_dudes_to_app.R──▶  etl/{2020..2025}/
archive/app-2023-raw/  ──archive/migration-scripts/transform_2023_to_compliance.R──▶  app/2023_compliance/  ┐
app/2025-24/  (native NFL-API pipeline, external repo) ───────────────────────────────────────────────────┤
                                              ├─archive/migration-scripts/merge_unified_database.R─▶ app/2023-24-25/
                                            etl/2020..2022/ ──────────────R/merge_datasets.R──────▶ dataset/
```

For analysis prefer **`dataset/`** (widest coverage, harmonized schema — and the only piece versioned in git). Use `app/2025-24/` only when you need the freshest 2024–2025 rows. `etl/*` and `archive/app-2023-raw/` are intermediate/superseded build products — do not treat them as independent sources.

## Commands

No build/lint/test-suite. Everything is `Rscript` or `source()` from the repo root (R with `tidyverse`, `dm`, `fs`, `glue`, `lubridate` on the path).

```bash
Rscript catalog_rds.R                                    # regenerate DATA_CATALOG.md
Rscript archive/migration-scripts/validate_unified_schema.R  # schema-check app/2023-24-25/
Rscript R/etl/transform_dudes_to_app.R --test            # ETL, week 1 only (smoke test)
Rscript R/etl/transform_dudes_to_app.R --batch           # ETL, all weeks
Rscript R/etl/test_etl.R                                 # ETL unit checks
```

```r
# Inspect any dm database
library(dm); d <- readRDS("dataset/ffa_db.rds"); dm_draw(d)
dm_get_tables(d)$ffa_projtable        # extract a table
readRDS("dataset/ffa_db.rds") |> dm_examine_constraints()
```

`etl/{year}/ETL_SUMMARY.md`, `dataset/MERGE_COMPLETE_REPORT.md`, and the root `ETL_*_REPORT.md` files document each build's row counts and known gaps.

## DudesApp (app/) Architecture

### Data Model (dm-based)

The app uses **7 relational databases** (RDS files with dm objects):

1. **ffa_db.rds** (7.4 MB)
   - `ffa_scrape`: Raw scraping metadata with timestamps
   - `ffa_player_ids`: ID mapping between systems (PK: id)
   - `ffa_players`: Player metadata (PK: id, pos)
   - `ffa_projtable`: Aggregated projections (PK: season, week, id, pos, avg_type, tag, timestamp)
   - `ffa_proj_source_points`: Individual source projections (PK: season, week, id, pos, data_src, tag, timestamp)

2. **nfl_teams_db.rds** (1.4 KB)
   - `nfl_teams`: Fantasy league teams (PK: teamId)
   - `nfl_owners`: Team owners (PK: ownerUserId)

3. **nfl_players_db.rds** (164 KB)
   - `nfl_players`: NFL player roster (PK: playerId)
   - `nfl_player_injury_status`: Temporal injury tracking (PK: playerId, timestamp)

4. **nfl_stats_db.rds** (453 KB)
   - `nfl_players_points`: Weekly point totals (PK: season, week, playerId)
   - `nfl_players_stats`: Detailed statistics by statId (PK: season, week, playerId, statId)

5. **nfl_round_db.rds** (39 KB)
   - `matchups_games`: Weekly matchups (PK: season, week, matchupId)
   - `nfl_teams_rosters`: Roster composition (PK: season, week, teamId, playerId, tag, timestamp)
   - `nfl_teams_week_stats`: Weekly team stats
   - `nfl_teams_season_stats`: Season aggregates

6. **nfl_recap_db.rds** (934 KB)
   - Match narratives and recaps

7. **dudes_simulation_db.rds** (25 MB)
   - `dudes_players_seeds`: Base simulation values (PK: season, week, id, playerId, pos, simType)
   - `dudes_players_simulations`: 1000 Monte Carlo samples per player (PK: season, week, id, playerId, pos, simType)

### Key Concepts

**Temporal Versioning:**
- Many tables include `timestamp` for historical tracking
- Use `tag` to distinguish data moments: `"preview"`, `"final"`
- **Always filter by latest timestamp or final tag** for current analysis

**Simulation Types:**
The system implements **15 different simulation strategies** (simType):
- Simple projections: `NFL`, `proj_table_average`, `proj_table_robust`, `proj_table_weighted`
- Monte Carlo: `proj_src`, `proj_src_errors`, `proj_src_w_errors`, `hist_data`, `current_season_his`, `proj_src_w_errors_balanced`
- Density sampling: `*_density` variants of above

**Data Flow:**
1. Web scraping (ffanalytics) → `ffa_db.rds`
2. NFL API calls → `nfl_*_db.rds`
3. Simulation engine → `dudes_simulation_db.rds`
4. Analysis scripts consume all databases

### Common Workflows

**Load databases:**
```r
# All databases are in app/2025-24/ for current season
ffa_db <- readRDS("app/2025-24/ffa_db.rds")
nfl_players_db <- readRDS("app/2025-24/nfl_players_db.rds")
# ... etc

# Extract tables from dm object
library(dm)
ffa_players <- ffa_db$ffa_players
nfl_players <- nfl_players_db$nfl_players
```

**Get latest data for a week:**
```r
# Always filter for most recent snapshot
latest_projections <- ffa_db$ffa_projtable |>
  filter(season == 2025, week == 17, tag == "final") |>
  filter(timestamp == max(timestamp))
```

**Join across databases:**
```r
# Use ffa_player_ids as the bridge between systems
# id (ffanalytics) <-> nfl_id (NFL API) <-> playerId (league)
player_stats <- ffa_db$ffa_player_ids |>
  left_join(nfl_players_db$nfl_players, by = c("nfl_id" = "playerId"))
```

## DudesFFA (dudes/) Architecture

### ESPN Fantasy API Project

This is a **file-per-week** system with historical data going back to 2019.

**Weekly files pattern:**
```
dudes/2025/
├── dudesffa_projpoints_week1.rds
├── dudesffa_projpoints_week2.rds
├── ...
├── simulation_v6_week15_preTNF.rds
├── simulation_v6_week15_final.rds
├── week1_scrap.rds (raw web scrape)
└── weekly_proj_table_1.rds (aggregated projections)
```

**File naming conventions:**
- `dudesffa_projpoints_week{X}.rds` - Player projections with confidence intervals
- `simulation_v6_week{X}_{phase}.rds` - Monte Carlo simulation results
- `week{X}_scrap.rds` - Raw scraped data from multiple sources
- `weekly_proj_table_{X}.rds` - Aggregated projection table

**Phases within a week:**
- `preTNF` - Before Thursday Night Football
- `posTNF` - After Thursday games
- `preSunday` - Sunday morning update
- `preMNF` - After Sunday, before Monday
- `final` - Week complete

### Data Sources

**Both projects scrape from 11+ sources:**
- CBS Sports, ESPN, FantasyPros, FantasySharks, FFToday
- FleaFlicker, NumberFire, NFL.com, RTSports, Walterfootball, Yahoo

**ffanalytics package:**
The primary scraping tool. Both projects use it extensively.

## R Environment & Dependencies

**Core packages:**
```r
library(tidyverse)      # Data manipulation (ALWAYS use tidyverse patterns)
library(dm)             # Relational data modeling (app/ only)
library(lubridate)      # Date handling
library(glue)           # String interpolation
library(httr2)          # HTTP requests for APIs
library(jsonlite)       # JSON parsing
library(ffanalytics)    # Fantasy Football scraping
```

**Reporting & visualization:**
```r
library(flexdashboard)  # Interactive dashboards
library(rmarkdown)      # Report generation
library(blogdown)       # Static site generation (dudes/ only)
```

**Statistical modeling:**
```r
library(tidymodels)     # ML framework
library(broom)          # Tidy model outputs
```

## Development Guidelines

### Code Style

Follow **tidyverse style guide** (see `.claude/skills/r-style-guide/`):
- Use `snake_case` for variables and functions
- Prefer pipes (`|>` or `%>%`) for data transformations
- 2-space indentation (configured in .Rproj)
- Explicit about column selection with `dplyr::select()`

### Working with dm Objects

The app/ project uses `dm` extensively for type-safe relationships:

```r
# Access tables from dm
table <- dm_object$table_name

# Add to dm
dm_object <- dm_object |>
  dm_add_pk(table_name, c(key1, key2)) |>
  dm_add_fk(child_table, c(fk_cols), parent_table)

# Validate relationships
dm_object |> dm_examine_constraints()
```

### Temporal Data Patterns

When working with timestamped data:

```r
# ALWAYS filter to latest snapshot first
data |>
  group_by(season, week, id) |>
  filter(timestamp == max(timestamp)) |>
  ungroup()

# Or use tag for finalized data
data |> filter(tag == "final")
```

### Simulation Analysis

The simulation system uses **list columns** extensively:

```r
# Seeds are stored as list columns
dudes_players_seeds$seeds  # List of numeric vectors

# Expand list columns for analysis
seeds_expanded <- dudes_players_seeds |>
  unnest(seeds)

# Quantiles stored as list
simulations$simQuantiles  # List with names: q05, q15, q30, q50, q70, q85, q95
```

## Common Tasks

### Update Weekly Data (app/)

**Location:** external repo. The native `app/` pipeline (web scraping → `ffa_db.rds`, NFL API → `nfl_*_db.rds`, simulation → `dudes_simulation_db.rds`) is not in this repo; only its RDS output is (`app/2025-24/`).

### Rebuild the derived datasets (in this repo)

After new `dudes/` or `app/2025-24/` data lands, re-run the lineage bottom-up: `archive/migration-scripts/transform_2023_to_compliance.R` → `archive/migration-scripts/merge_unified_database.R` → `R/etl/transform_dudes_to_app.R --batch` (per legacy year) → `R/merge_datasets.R` → `archive/migration-scripts/validate_unified_schema.R` → `catalog_rds.R`.

### Update Weekly Data (dudes/)

**Location:** `dudes/R/pipeline/update_pipe.R` (not present in this repo snapshot)

Based on README, the workflow:
1. `scrapPlayersPredictions()` - Collect projections
2. `calcPlayersProjections()` - Aggregate sources
3. `importPlayerStatistics()` - Get actual stats
4. `importMatchups()` - Get matchups and rosters
5. `projectErrorPoints()` - Apply error corrections
6. `simulateGames()` - Monte Carlo simulation
7. Generate reports and publish

### Reading Documentation

**Always start here:**
- `app_README.md` - DudesApp comprehensive guide
- `dudes_README.md` - DudesFFA comprehensive guide
- `app_DATAMODEL.md` - Complete schema reference for app/
- `dudes_DATAMODEL.md` - Schema reference for dudes/
- `data_DATA_DICTIONARY.md` - Additional data dictionary

### Analyzing Player Performance

```r
# Load latest stats
stats <- readRDS("app/2025-24/nfl_stats_db.rds")

# Get weekly points
weekly_points <- stats$nfl_players_points |>
  filter(season == 2025) |>
  arrange(week)

# Join with player names
players <- readRDS("app/2025-24/nfl_players_db.rds")
weekly_with_names <- weekly_points |>
  left_join(players$nfl_players, by = "playerId")
```

### Working with Simulations

```r
# Load simulation database
sim_db <- readRDS("app/2025-24/dudes_simulation_db.rds")

# Extract specific simulation type
proj_src_sims <- sim_db$dudes_players_simulations |>
  filter(season == 2025, week == 17, simType == "proj_src")

# Get quantiles
quantiles <- proj_src_sims |>
  select(playerId, simQuantiles) |>
  unnest_wider(simQuantiles)  # Expands to q05, q15, q30, q50, q70, q85, q95
```

## Configuration Files

**config/config.yml** - League configuration (both projects have separate configs):
- `leagueId`: League identifier
- `teamId`: User's team ID
- `season`: Current season
- `authToken`: API authentication (stored securely, not in repo)

**config/score_settings.yml** - Scoring rules:
- PPR (Point Per Reception) settings
- Position-specific scoring (QB, RB, WR, TE, K, DEF)
- Defines how stats convert to fantasy points

## RStudio Project Settings

**Encoding:** UTF-8
**Indentation:** 2 spaces (no tabs)
**RMarkdown:** Uses Sweave/pdfLaTeX

## Git Workflow

**Commit patterns for dudes/ project:**
```bash
git commit -m "w17 preTNF"   # Thursday before games
git commit -m "w17 posTNF"   # Thursday night update
git commit -m "w17 preSunday" # Sunday morning
git commit -m "w17 preMNF"   # Monday before MNF
git commit -m "w17 final"    # Complete week data
```

## Important Notes

### File Access

**DO NOT use Read/Grep/Edit tools on .rds files** - they are binary R data files.
Always load with `readRDS()` in R code.

### Project Separation

The two projects (app/ and dudes/) are **independent**:
- Different APIs (NFL Fantasy vs ESPN Fantasy)
- Different data models (dm-based vs file-per-week)
- Different pipelines
- Share similar analysis approaches

When working on one, don't assume patterns from the other apply directly.

### Data Freshness

Both projects have **historical data** going back multiple seasons. Always confirm which season/week you're analyzing.

**Coverage:** `dudes/` 2019–2025; `app/`/`etl/`/`dataset/` 2020–2025, weeks 0–17. Latest full season: 2025, week 17. See `DATA_CATALOG.md` for per-file ranges.

## Historical Data Compatibility

### Schema Evolution (app/ project)

The database schemas have evolved across seasons. **Not all columns are comparable** between 2023 and 2025.

#### ffa_db.rds Changes

**Added in 2024+:**
- `ffa_player_ids`: Added `gsis_id` (Game Statistics and Information System ID)
- `ffa_player_ids`: Added `sleeper_id` (Sleeper App ID)
- `ffa_projtable`: Added player metadata columns (`first_name`, `last_name`, `team`, `position`, `age`, `exp`)

**Removed from 2023:**
- `ffa_projtable`: Removed VOR (Value Over Replacement) analysis columns:
  - `points_vor`, `floor_vor`, `ceiling_vor`
  - `floor_rank`, `ceiling_rank`
  - `pos_ecr`, `sd_ecr`, `uncertainty`

**Impact:** VOR analysis system was deprecated. Player metadata is now joined directly from `ffa_players` instead of being duplicated in projections.

#### nfl_players_db.rds Changes

**Added in 2024+:**
- `nfl_players`: Added `lastNoteTimestamp` (timestamp of latest news/notes)

#### nfl_stats_db.rds Changes - **BREAKING CHANGE** ⚠️

**`nfl_players_adv_stats` schema completely changed between 2023 and 2025:**

**2023 schema (rostered/target metrics):**
```r
# Columns: percentRostered, percentRosteredChange, targets,
# redzoneTargets, redzoneGoalToGo, touches, receptionPercentage,
# rushingYardsPerAttempt, redzoneTouches, passingPercentage
```

**2025 schema (transaction/league metrics):**
```r
# Columns: transactionBuysellAdd, transactionBuysellDrop,
# transactionBuysellNet, auctionTeamCount, avgPointsAgainst,
# avgPointsAgainstRank, leaguesAvailable, leaguesOwned, leaguesStarted
```

**Impact:** **Cannot compare advanced stats across seasons.** The NFL API fundamentally changed what metrics are exposed.

**Mitigation:**
```r
# Always check column existence before using
if ("percentRostered" %in% names(adv_stats)) {
  # 2023 logic
} else if ("percentOwned" %in% names(adv_stats)) {
  # 2025 logic
}
```

### Legacy Files

Historical season folders may contain deprecated files. The original, pre-compliance `app/2023/` was archived to `archive/app-2023-raw/` (superseded by `app/2023_compliance/`); paths below reflect that move.

#### archive/app-2023-raw/dudes_simulation.rds - **OBSOLETE**

- Old simulation format with single table: `dudes_simSeeds`
- Replaced by modern `dudes_simulation_db.rds` with two tables: `dudes_players_seeds` + `dudes_players_simulations`
- **Action:** Ignore this file in analysis; use only `dudes_simulation_db.rds`

#### archive/app-2023-raw/missing_player_ids.rds - **AUXILIARY FILE**

- Manual ID mappings for players not automatically detected by ffanalytics
- Simple tibble (not dm object) with same schema as `ffa_player_ids`
- **Usage pattern:**
```r
# Consolidate IDs
main_ids <- ffa_db$ffa_player_ids
manual_ids <- readRDS("archive/app-2023-raw/missing_player_ids.rds")
all_ids <- bind_rows(main_ids, manual_ids)
```

### Cross-Season Analysis Guidelines

When analyzing data across multiple seasons:

1. **Check schema compatibility first:**
```r
# Get column names for both seasons
cols_2023 <- names(readRDS("archive/app-2023-raw/ffa_db.rds")$ffa_projtable)
cols_2025 <- names(readRDS("app/2025-24/ffa_db.rds")$ffa_projtable)

# Find common columns
common_cols <- intersect(cols_2023, cols_2025)
```

2. **Use defensive coding:**
```r
# Check before using potentially missing columns
if ("gsis_id" %in% names(player_ids)) {
  # Use gsis_id for matching
} else {
  # Fallback to nfl_id only
}
```

3. **Document assumptions:**
```r
# When joining across seasons, be explicit
player_history <- bind_rows(
  data_2023 %>% select(all_of(common_cols)),  # Only common columns
  data_2025 %>% select(all_of(common_cols))
) %>%
  mutate(note = "VOR metrics not available for 2025+")
```

4. **Avoid advanced stats comparisons:**
```r
# ❌ DON'T DO THIS - columns don't exist
adv_stats %>%
  group_by(season) %>%
  summarise(avg_rostered = mean(percentRostered))  # Fails for 2025

# ✅ DO THIS - use only stable columns
adv_stats %>%
  group_by(season) %>%
  summarise(avg_adp = mean(averageDraftPosition, na.rm = TRUE))
```

### Stable Columns Across Seasons

These core columns are **consistently available** in all seasons:

**ffa_db.rds:**
- `ffa_player_ids`: `id`, `nfl_id`, `stats_id`, `cbs_id`, `espn_id`
- `ffa_projtable`: `season`, `week`, `id`, `pos`, `points`, `sd_pts`, `floor`, `ceiling`, `rank`, `tier`

**nfl_players_db.rds:**
- `nfl_players`: `playerId`, `name`, `firstName`, `lastName`, `position`, `nflTeamAbbr`

**nfl_stats_db.rds:**
- `nfl_players_points`: `playerId`, `season`, `week`, `pts`
- `nfl_players_stats`: `playerId`, `season`, `week`, `statId`, `value`
- `nfl_players_adv_stats`: `playerId`, `season`, `week`, `averageDraftPosition` (use this for cross-season analysis)

Use these stable columns as the foundation for historical comparisons.

### Skills Available

40+ R and BMAD skills are installed under `.claude/skills/`. Most relevant here: `r-style-guide`, `tidyverse-patterns`/`tidyverse-expert`, `dm-relational`, `r-datascience`, `r-tidymodels`, `ggplot2`, `rlang-patterns`, `r-performance`, `tdd-workflow`. Use them when appropriate for R work.

## External Resources

**Websites:**
- DudesFFA: https://dudesfootball.netlify.app (ESPN league)
- Reports are published as static HTML to these sites

**APIs:**
- NFL Fantasy API: Official NFL API (app/)
- ESPN Fantasy API v2: Undocumented ESPN API (dudes/)
- ffanalytics: R package for scraping projections (both)

## Key Files to Understand Before Major Changes

1. **app_README.md** - Complete documentation of app/ architecture
2. **dudes_README.md** - Complete documentation of dudes/ architecture
3. **app_DATAMODEL.md** - Full schema with all table definitions
4. **dudes_DATAMODEL.md** - Schema for dudes project
5. Current season data directories (app/2025-24/, dudes/2025/)
