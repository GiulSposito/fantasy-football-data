# DATA_CATALOG.md

Inventory of every `.rds` in the DudesData repo: what each database holds, the season/week range it covers, and headline counts. Regenerate with `Rscript catalog_rds.R`.

_Generated 2026-09-21. 1803 rds files, 2596.8 MB on disk._

## 1. Top-level layout

| Dir | Files | Size | What it is |
|---|---|---|---|
| `dudes/` | 1562 | 1636.8 MB | DudesFFA (ESPN league). File-per-week, seasons 2019-2025. Raw + derived. |
| `etl/` | 42 | 422.8 MB | Legacy-year conversions: `dudes/` reshaped into `app/` dm schema, one folder per season 2020-2025. |
| `app/` | 181 | 355.7 MB | DudesApp (NFL Fantasy API). dm databases per season-set + `temp/` scrape cache. |
| `archive/` | 11 | 151.9 MB |  |
| `dataset/` | 7 | 29.5 MB | Unified historical dm dataset 2020-2025 (merge of app/2023-24-25 + etl/*). |

## 2. Canonical dm databases (detail)

`players` = distinct player-id values in the table; `data_src` = distinct projection sources.

### `dataset/`

| DB / table | Rows | Cols | Season | Week | Players | data_src |
|---|---|---|---|---|---|---|
| **dudes_simulation_db.rds** | | | | | | |
| &nbsp;&nbsp;`dudes_players_seeds` | 16,473 | 7 | 2020-2024 | 1-17 | 951 | - |
| &nbsp;&nbsp;`dudes_players_simulations` | 16,471 | 8 | 2020-2024 | 1-17 | 951 | - |
| **ffa_db.rds** | | | | | | |
| &nbsp;&nbsp;`ffa_scrape` | 123 | 5 | 2020-2025 | 0-17 | - | - |
| &nbsp;&nbsp;`ffa_player_ids` | 5,429 | 15 | - | - | 5,429 | - |
| &nbsp;&nbsp;`ffa_players` | 1,689 | 8 | - | - | 1,689 | - |
| &nbsp;&nbsp;`ffa_projtable` | 63,622 | 38 | 2020-2025 | 0-17 | 1,688 | - |
| &nbsp;&nbsp;`ffa_proj_source_points` | 63,637 | 8 | 2020-2025 | 0-17 | 1,688 | 11 |
| **nfl_players_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_players` | 2,309 | 19 | - | - | 2,309 | - |
| &nbsp;&nbsp;`nfl_player_injury_status` | 120,052 | 3 | - | - | 2,309 | - |
| **nfl_recap_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_recap` | 311 | 15 | 2023-2025 | 1-17 | - | - |
| **nfl_round_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_teams_round` | 1,416 | 6 | 2020-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`nfl_teams_rosters` | 31,492 | 10 | 2020-2025 | 1-17 | 677 | - |
| &nbsp;&nbsp;`nfl_teams_week_stats` | 1,698 | 7 | 2020-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`nfl_teams_season_stats` | 1,964 | 7 | 2020-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`matchups_games` | 724 | 14 | 2020-2025 | 1-17 | - | - |
| **nfl_stats_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_stat_dictionary` | 95 | 10 | - | - | - | - |
| &nbsp;&nbsp;`nfl_players_points` | 68,757 | 4 | 2019-2025 | 0-17 | 1,594 | - |
| &nbsp;&nbsp;`nfl_players_stats` | 236,612 | 5 | 2019-2025 | 0-17 | 1,295 | - |
| &nbsp;&nbsp;`nfl_players_adv_stats` | 69,513 | 25 | 2019-2025 | 0-17 | 1,975 | - |
| **nfl_teams_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_teams` | 16 | 4 | - | - | - | - |
| &nbsp;&nbsp;`nfl_owners` | 44 | 2 | - | - | - | - |

### `app/2025-24/`

| DB / table | Rows | Cols | Season | Week | Players | data_src |
|---|---|---|---|---|---|---|
| **dudes_simulation_db.rds** | | | | | | |
| &nbsp;&nbsp;`dudes_players_seeds` | 21,809 | 7 | 2024 | 2-4 | 570 | - |
| &nbsp;&nbsp;`dudes_players_simulations` | 15,799 | 8 | 2024 | 2-4 | 570 | - |
| **ffa_db.rds** | | | | | | |
| &nbsp;&nbsp;`ffa_player_ids` | 5,395 | 15 | - | - | 5,395 | - |
| &nbsp;&nbsp;`ffa_players` | 858 | 8 | - | - | 849 | - |
| &nbsp;&nbsp;`ffa_projtable` | 61,332 | 26 | 2024-2025 | 0-17 | 849 | - |
| &nbsp;&nbsp;`ffa_proj_source_points` | 103,266 | 8 | 2024-2025 | 0-17 | 849 | 11 |
| &nbsp;&nbsp;`ffa_scrape` | 39 | 5 | 2024-2025 | 0-17 | - | - |
| **nfl_players_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_players` | 1,398 | 19 | - | - | 1,398 | - |
| &nbsp;&nbsp;`nfl_player_injury_status` | 43,430 | 3 | - | - | 1,398 | - |
| **nfl_recap_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_recap` | 220 | 15 | 2024-2025 | 1-17 | - | - |
| **nfl_round_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_teams_round` | 510 | 6 | 2024-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`nfl_teams_rosters` | 8,744 | 10 | 2024-2025 | 1-17 | 414 | - |
| &nbsp;&nbsp;`nfl_teams_week_stats` | 540 | 7 | 2024-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`nfl_teams_season_stats` | 8,760 | 7 | 2024-2025 | 1-17 | - | - |
| &nbsp;&nbsp;`matchups_games` | 257 | 14 | 2024-2025 | 1-17 | - | - |
| **nfl_stats_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_stat_dictionary` | 95 | 10 | - | - | - | - |
| &nbsp;&nbsp;`nfl_players_points` | 12,593 | 4 | 2024-2025 | 0-17 | 767 | - |
| &nbsp;&nbsp;`nfl_players_stats` | 75,596 | 5 | 2024-2025 | 0-17 | 832 | - |
| &nbsp;&nbsp;`nfl_players_adv_stats` | 19,816 | 21 | 2024-2025 | 0-17 | 1,398 | - |
| **nfl_teams_db.rds** | | | | | | |
| &nbsp;&nbsp;`nfl_teams` | 16 | 4 | - | - | - | - |
| &nbsp;&nbsp;`nfl_owners` | 16 | 2 | - | - | - | - |

## 3. Other dm database folders (per-file rollup)

Same 7-database schema. Rows = summed across tables in the file.

| Folder | DB file | Tables | Rows | Season | Week |
|---|---|---|---|---|---|
| `app/2023-24-25/` | dudes_simulation_db.rds | 2 | 194,140 | 2023-2024 | 1-11 |
| `app/2023-24-25/` | ffa_db.rds | 5 | 316,932 | 2023-2025 | 0-17 |
| `app/2023-24-25/` | nfl_players_db.rds | 2 | 70,181 | - | - |
| `app/2023-24-25/` | nfl_recap_db.rds | 1 | 311 | 2023-2025 | 1-17 |
| `app/2023-24-25/` | nfl_round_db.rds | 5 | 41,338 | 2023-2025 | 1-17 |
| `app/2023-24-25/` | nfl_stats_db.rds | 4 | 307,249 | 2019-2025 | 0-17 |
| `app/2023-24-25/` | nfl_teams_db.rds | 2 | 32 | - | - |
| `app/2023_compliance/` | dudes_simulation_db.rds | 2 | 156,532 | 2023 | 1-11 |
| `app/2023_compliance/` | ffa_db.rds | 5 | 151,253 | 2023 | 1-17 |
| `app/2023_compliance/` | nfl_players_db.rds | 2 | 26,187 | - | - |
| `app/2023_compliance/` | nfl_recap_db.rds | 1 | 91 | 2023 | 1-14 |
| `app/2023_compliance/` | nfl_round_db.rds | 5 | 22,527 | 2023 | 1-17 |
| `app/2023_compliance/` | nfl_stats_db.rds | 4 | 199,244 | 2019-2023 | 0-17 |
| `app/2023_compliance/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `archive/app-2023-raw/` | dudes_simulation_db.rds | 2 | 156,532 | 2023 | 1-11 |
| `archive/app-2023-raw/` | ffa_db.rds | 5 | 151,253 | 2023 | 1-17 |
| `archive/app-2023-raw/` | nfl_players_db.rds | 2 | 26,187 | - | - |
| `archive/app-2023-raw/` | nfl_recap_db.rds | 1 | 91 | 2023 | 1-14 |
| `archive/app-2023-raw/` | nfl_round_db.rds | 5 | 22,527 | 2023 | 1-17 |
| `archive/app-2023-raw/` | nfl_stats_db.rds | 4 | 199,244 | 2019-2023 | 0-17 |
| `archive/app-2023-raw/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `etl/2020/` | dudes_simulation_db.rds | 2 | 49,226 | 2020 | 1-16 |
| `etl/2020/` | ffa_db.rds | 5 | 95,754 | 2020 | 1-16 |
| `etl/2020/` | nfl_players_db.rds | 2 | 19,018 | - | - |
| `etl/2020/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2020/` | nfl_round_db.rds | 5 | 7,727 | 2020 | 1-16 |
| `etl/2020/` | nfl_stats_db.rds | 4 | 464,737 | 2020 | 1-16 |
| `etl/2020/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `etl/2021/` | dudes_simulation_db.rds | 2 | 49,152 | 2021 | 1-17 |
| `etl/2021/` | ffa_db.rds | 5 | 110,951 | 2021 | 1-17 |
| `etl/2021/` | nfl_players_db.rds | 2 | 18,506 | - | - |
| `etl/2021/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2021/` | nfl_round_db.rds | 5 | 8,875 | 2021 | 1-17 |
| `etl/2021/` | nfl_stats_db.rds | 4 | 563,954 | 2021 | 1-17 |
| `etl/2021/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `etl/2022/` | dudes_simulation_db.rds | 2 | 47,946 | 2022 | 1-17 |
| `etl/2022/` | ffa_db.rds | 5 | 86,443 | 2022 | 1-17 |
| `etl/2022/` | nfl_players_db.rds | 2 | 17,082 | - | - |
| `etl/2022/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2022/` | nfl_round_db.rds | 5 | 9,106 | 2022 | 1-17 |
| `etl/2022/` | nfl_stats_db.rds | 4 | 561,011 | 2022 | 1-17 |
| `etl/2022/` | nfl_teams_db.rds | 2 | 0 | - | - |
| `etl/2023/` | dudes_simulation_db.rds | 2 | 47,882 | 2023 | 1-17 |
| `etl/2023/` | ffa_db.rds | 5 | 80,252 | 2023 | 1-17 |
| `etl/2023/` | nfl_players_db.rds | 2 | 18,858 | - | - |
| `etl/2023/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2023/` | nfl_round_db.rds | 5 | 9,315 | 2023 | 1-17 |
| `etl/2023/` | nfl_stats_db.rds | 4 | 565,497 | 2023 | 1-17 |
| `etl/2023/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `etl/2024/` | dudes_simulation_db.rds | 2 | 37,068 | 2024 | 1-17 |
| `etl/2024/` | ffa_db.rds | 5 | 75,051 | 2024 | 1-17 |
| `etl/2024/` | nfl_players_db.rds | 2 | 19,931 | - | - |
| `etl/2024/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2024/` | nfl_round_db.rds | 5 | 9,009 | 2024 | 1-17 |
| `etl/2024/` | nfl_stats_db.rds | 4 | 564,632 | 2024 | 1-17 |
| `etl/2024/` | nfl_teams_db.rds | 2 | 28 | - | - |
| `etl/2025/` | dudes_simulation_db.rds | 2 | 39,744 | 2025 | 1-17 |
| `etl/2025/` | ffa_db.rds | 5 | 64,284 | 2025 | 1-17 |
| `etl/2025/` | nfl_players_db.rds | 2 | 20,183 | - | - |
| `etl/2025/` | nfl_recap_db.rds | 1 | 0 | - | - |
| `etl/2025/` | nfl_round_db.rds | 5 | 10,301 | 2025 | 1-17 |
| `etl/2025/` | nfl_stats_db.rds | 4 | 556,456 | 2025 | 1-17 |
| `etl/2025/` | nfl_teams_db.rds | 2 | 32 | - | - |

## 4. Projection sources (`data_src`)

- **`ffa_proj_source_points`**: CBS, ESPN, FanDuel, FantasyPros, FantasySharks, FFToday, FleaFlicker, NFL, NumberFire, RTSports, WalterFootball

## 5. `dudes/` (ESPN league) - file-per-week

| Season | RDS files | Size | Week range | Distinct in-week phases |
|---|---|---|---|---|
| 2019 | 98 | 169.1 MB | 1-16 | 1 |
| 2020 | 180 | 177.7 MB | 1-16 | 26 |
| 2021 | 238 | 200.0 MB | 1-17 | 17 |
| 2022 | 278 | 190.0 MB | 1-17 | 14 |
| 2023 | 275 | 379.3 MB | 1-17 | 16 |
| 2024 | 247 | 337.8 MB | 1-17 | 13 |
| 2025 | 244 | 182.7 MB | 0-17 | 13 |

Phase tags (`week{N}_{phase}.rds`) evolve each year around the real NFL schedule - e.g. 2023: final, posSunday1stGames, posThanksGiving, posTNF, posWaivers, preGermanGame, preLondonGame, preMNF, preMonday, preSaturday, preSNF, preSunday, preSundayGames, preTNF, preWaivers, scrap

### Files by group x season

| Group | 2019 | 2020 | 2021 | 2022 | 2023 | 2024 | 2025 |
|---|---|---|---|---|---|---|---|
| simulation_v3-6 (weekly, per phase) | 0 | 123 | 127 | 115 | 123 | 96 | 91 |
| projections / proj tables | 17 | 18 | 41 | 78 | 73 | 71 | 72 |
| raw web scrape | 17 | 17 | 19 | 37 | 36 | 35 | 37 |
| rank / rankAgainstPosition | 0 | 14 | 31 | 34 | 34 | 34 | 34 |
| other | 25 | 2 | 12 | 5 | 0 | 2 | 4 |
| actuals / matchups | 35 | 1 | 2 | 1 | 1 | 1 | 1 |
| draft | 0 | 2 | 3 | 6 | 4 | 6 | 5 |
| id maps / lookups | 0 | 3 | 3 | 2 | 4 | 2 | 0 |
| sim evaluation | 4 | 0 | 0 | 0 | 0 | 0 | 0 |

### Content stats (representative file per season)

| Season | players_points rows | distinct players | weeks | weekly_proj_table_1 rows | dudesffa_projpoints wk-file rows |
|---|---|---|---|---|---|
| 2019 | 7,712 | 482 | 1-16 | - | - |
| 2020 | 14,416 | 901 | 1-16 | - | - |
| 2021 | 15,453 | 909 | 1-17 | - | 478 |
| 2022 | 14,824 | 872 | 1-17 | 626 | 549 |
| 2023 | 13,974 | 822 | 1-17 | 684 | 558 |
| 2024 | 15,045 | 885 | 1-17 | 574 | 519 |
| 2025 | 14,042 | 826 | 1-17 | 527 | 492 |

## 6. `app/temp/` - scrape cache

- 157 files, 27.6 MB. Seasons 2023-2025, weeks 0-17. Kinds: ffa_db, ffa_scrape_db, Teste.
- Filename pattern: `{kind}_s{season}w{week}_{phase}_{timestamp}.rds` - point-in-time snapshots of the weekly scrape/projection build.

## 7. Notes

- `app/2023/dudes_simulation.rds` (single table `dudes_simSeeds`, 21 MB) is the **obsolete** pre-dm simulation format - ignore it, use `dudes_simulation_db.rds` (two tables: seeds + 1000-sample simulations).
- `etl/*/nfl_recap_db.rds` is empty (0 rows) for every legacy year; recaps only exist 2023+ (see `dataset/nfl_recap`, 311 rows). `etl/2022/nfl_teams_db.rds` is also empty.
- `dudes_players_seeds` / `dudes_players_simulations` row counts differ slightly per file - seeds carry a few players that never made a simulated roster.
- `missing_player_ids.rds` / `missing_player_id.rds` (app/2023*, dudes/2023-24): hand-maintained ID patches, plain tibbles matching `ffa_player_ids` schema - `bind_rows()` onto the main table.
- `app/2023_compliance/` = `app/2023/` re-emitted to the current schema; `app/2023-24-25/` merges 2023-2025; `dataset/` adds legacy 2020-2022 on top.
