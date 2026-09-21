# =============================================================================
# EXTRACTION FUNCTIONS FOR DUDES → APP TRANSFORMATION
# =============================================================================
# Script: extract.R
# Purpose: Phase 1 - Extract data from dudes/ format
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(fs)
library(glue)
library(lubridate)

# Source utilities (but NOT config - it's passed as parameter)
source("R/etl/utils_transform.R")

# Extract Weekly Scrapes --------------------------------------------------

extract_weekly_scrapes <- function(source_dir, weeks, config) {
  log_section("Extracting Weekly Scrapes")

  # ✅ F6 FIX: Add progress feedback
  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse = ', ')}"), "info")

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("week{wk}_scrap.rds"))

      if (!file_exists(file)) {
        log_message(glue("  Week {wk}: File not found - skipping"), "warning")
        return(tibble())
      }

      log_message(glue("  Week {wk}: Reading scrapes..."), "info")

      scrape <- safe_read_rds(file, default = list())

      if (length(scrape) == 0) {
        log_message(glue("  Week {wk}: Empty scrape data"), "warning")
        return(tibble())
      }

      # scrape is a list of 6 data.frames (QB, RB, WR, TE, K, DST)
      result <- map_dfr(scrape, bind_rows, .id = "position_source") |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time,
          source_file = path_file(file)
        )

      log_message(glue("  Week {wk}: ✓ {nrow(result)} scrape records"), "success")
      result
    })
}

# Extract Weekly Projections ----------------------------------------------

extract_weekly_projections <- function(source_dir, weeks, config) {
  log_section("Extracting Weekly Projections")

  # ✅ F6 FIX: Add progress feedback
  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse = ', ')}"), "info")

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("weekly_proj_player_site_{wk}.rds"))

      if (!file_exists(file)) {
        log_message(glue("  Week {wk}: Projections file not found - skipping"), "warning")
        return(tibble())
      }

      log_message(glue("  Week {wk}: Reading projections..."), "info")

      result <- safe_read_rds(file, default = tibble()) |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time,
          source_file = path_file(file)
        )

      log_message(glue("  Week {wk}: ✓ {nrow(result)} projection records"), "success")
      result
    })
}

# Extract Weekly Projection Tables ----------------------------------------

extract_weekly_proj_tables <- function(source_dir, weeks, config) {
  log_section("Extracting Weekly Projection Tables")

  # ✅ F6 FIX: Add progress feedback
  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse = ', ')}"), "info")

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("weekly_proj_table_{wk}.rds"))

      if (!file_exists(file)) {
        log_message(glue("  Week {wk}: Projection table not found - skipping"), "warning")
        return(tibble())
      }

      log_message(glue("  Week {wk}: Reading projection table..."), "info")

      result <- safe_read_rds(file, default = tibble()) |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time
        )

      log_message(glue("  Week {wk}: ✓ {nrow(result)} projection table records"), "success")
      result
    })
}

# Extract Player Points ---------------------------------------------------

extract_player_points <- function(source_dir, config) {
  log_section("Extracting Player Points")

  file <- path(source_dir, "players_points.rds")

  if (!file_exists(file)) {
    log_message("players_points.rds not found", "error")
    return(list(points = tibble(), stats = tibble(), advanced = tibble()))
  }

  log_message("Reading players_points.rds...", "info")
  players <- safe_read_rds(file, default = tibble())

  if (nrow(players) == 0) {
    return(list(points = tibble(), stats = tibble(), advanced = tibble()))
  }

  # ✅ FILTER EARLY - Before unnesting (Performance optimization)
  if (!is.null(config$weeks) && length(config$weeks) < 17) {
    log_message(glue("Filtering to weeks: {paste(config$weeks, collapse = ', ')}"), "debug")

    # ✅ F2 FIX: Validate nested structure before filtering
    # Filter nested list columns BEFORE unnest to avoid processing all 17 weeks
    filter_week_list <- function(week_list, weeks) {
      if (is.null(week_list) || length(week_list) == 0) return(week_list)
      # Check if it's numeric-indexed list (expected structure)
      if (is.list(week_list) && !is.null(names(week_list))) {
        # Named list - try to filter by valid indices
        valid_weeks <- intersect(weeks, seq_along(week_list))
        if (length(valid_weeks) > 0) {
          return(week_list[valid_weeks])
        } else {
          return(week_list)
        }
      }
      # Standard numeric-indexed list
      week_list[weeks]
    }

    # Apply filtering only to columns that exist
    if ("weekStats" %in% names(players)) {
      players <- players |>
        mutate(weekStats = map(weekStats, filter_week_list, weeks = config$weeks))
    }

    if ("weekAdvancedStats" %in% names(players)) {
      players <- players |>
        mutate(weekAdvancedStats = map(weekAdvancedStats, filter_week_list, weeks = config$weeks))
    } else if ("advanced" %in% names(players)) {
      # Alternative column name
      players <- players |>
        mutate(advanced = map(advanced, filter_week_list, weeks = config$weeks))
    }

    if ("weekPoints" %in% names(players)) {
      players <- players |>
        mutate(weekPoints = map(weekPoints, filter_week_list, weeks = config$weeks))
    }

    log_message(glue("Filtered nested data to {length(config$weeks)} week(s) before unnest"), "info")
  }

  # Extract basic points
  # ✅ LEGACY FIX: Try different column names for player ID and points
  id_col <- intersect(c("playerId", "player_id", "id"), names(players))[1]
  pts_col <- intersect(c("weekPts", "week_pts", "pts", "points"), names(players))[1]
  week_col <- intersect(c("week"), names(players))[1]

  if (is.na(id_col) || is.na(week_col)) {
    log_message("ERROR: Cannot find player ID or week column in players_points", "error")
    return(list(points = tibble(), stats = tibble(), advanced = tibble()))
  }

  points <- players |>
    select(all_of(c(id_col, week_col, pts_col))) |>
    rename(playerId = !!id_col, week = !!week_col, pts = !!pts_col) |>
    mutate(season = config$season)

  log_message(glue("Extracted {nrow(points)} player point records"), "info")

  # Unnest weekStats if available (now only filtered weeks)
  stats <- tryCatch(
    {
      if ("weekStats" %in% names(players)) {
        unnest_week_stats(players) |>
          mutate(season = config$season)
      } else {
        tibble()
      }
    },
    error = function(e) {
      log_message(glue("Error unnesting weekStats: {e$message}"), "warning")
      tibble()
    }
  )

  log_message(glue("Extracted {nrow(stats)} detailed stat records"), "info")

  # Unnest advanced stats if available (now only filtered weeks)
  advanced <- tryCatch(
    {
      if ("advanced" %in% names(players)) {
        unnest_advanced_stats(players) |>
          mutate(season = config$season)
      } else {
        tibble()
      }
    },
    error = function(e) {
      log_message(glue("Error unnesting advanced: {e$message}"), "warning")
      tibble()
    }
  )

  log_message(glue("Extracted {nrow(advanced)} advanced stat records"), "info")

  list(
    points = points,
    stats = stats,
    advanced = advanced
  )
}

# Extract Simulations -----------------------------------------------------

extract_simulations <- function(source_dir, weeks, config) {
  log_section("Extracting Simulations")

  # Find all simulation files
  sim_pattern <- "simulation_v5_week\\d+_.+\\.rds"
  sim_files <- dir_ls(source_dir, regexp = sim_pattern)

  if (length(sim_files) == 0) {
    log_message("No simulation files found", "warning")
    return(tibble())
  }

  # Filter files to only requested weeks
  sim_files_filtered <- sim_files |>
    keep(function(file) {
      filename <- path_file(file)
      parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")
      if (is.na(parts[1, 2])) return(FALSE)
      week <- as.integer(parts[1, 2])
      week %in% weeks
    })

  if (length(sim_files_filtered) == 0) {
    log_message("No simulation files found for requested weeks", "warning")
    return(tibble())
  }

  # ✅ F6 FIX: Add progress feedback per simulation file
  log_message(glue("Found {length(sim_files_filtered)} simulation file(s) for weeks {paste(weeks, collapse=', ')}"), "info")

  sim_files_filtered |>
    map_dfr(function(file) {
      # Parse filename to extract week and phase
      filename <- path_file(file)
      parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")

      if (is.na(parts[1, 2])) {
        log_message(glue("  Could not parse filename: {filename}"), "warning")
        return(tibble())
      }

      week <- as.integer(parts[1, 2])
      phase <- parts[1, 3]

      log_message(glue("  Week {week}/{phase}: Reading simulation..."), "info")

      sim <- safe_read_rds(file, default = list())

      if (length(sim) == 0) {
        return(tibble())
      }

      # Extract players_sim WITH list columns (seeds and simulations)
      if ("players_sim" %in% names(sim)) {
        players_sim_df <- sim$players_sim

        # ✅ F1 FIX: Verify required columns exist before selecting
        required_cols <- c("teamId", "playerId", "id", "slotPosition")
        list_cols <- c("pts.proj", "simulation.org", "simulation")

        missing_required <- setdiff(required_cols, names(players_sim_df))
        missing_list <- setdiff(list_cols, names(players_sim_df))

        if (length(missing_required) > 0) {
          log_message(glue("ERROR: Missing required columns in {filename}: {paste(missing_required, collapse=', ')}"), "error")
          return(tibble())
        }

        if (length(missing_list) > 0) {
          log_message(glue("WARNING: Missing list columns in {filename}: {paste(missing_list, collapse=', ')} - simulations may be incomplete"), "warning")
        }

        # Select available columns (use any_of for optional columns)
        result <- players_sim_df |>
          select(
            # Required scalar columns
            teamId, playerId, id, slotPosition,
            # Optional scalar columns
            any_of(c("teamName", "rosterSlotId", "isEditable", "byeWeek")),
            # List columns (critical but may be missing)
            any_of(c("pts.proj", "weekPts.sim", "simulation.org", "simulation"))
          ) |>
          mutate(
            season = sim$season %||% config$season,
            week = sim$week %||% week,
            phase = phase,    # preTNF, final, etc
            pos = slotPosition,  # Alias for consistency
            timestamp = file_info(file)$modification_time,
            source_file = filename
          )

        # ✅ F6 FIX: Log success with counts
        log_message(glue("  Week {week}/{phase}: ✓ {nrow(result)} simulation records"), "success")
        result
      } else {
        log_message(glue("  No players_sim in {filename}"), "warning")
        tibble()
      }
    })
}

# Extract Matchups --------------------------------------------------------

extract_matchups <- function(source_dir, weeks, config) {
  log_section("Extracting Matchups")

  sim_files <- dir_ls(source_dir, regexp = "simulation_v5_week\\d+_.+\\.rds")

  if (length(sim_files) == 0) {
    return(tibble())
  }

  sim_files |>
    map_dfr(function(file) {
      filename <- path_file(file)
      parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")

      if (is.na(parts[1, 2])) {
        return(tibble())
      }

      week <- as.integer(parts[1, 2])
      phase <- parts[1, 3]

      sim <- safe_read_rds(file, default = list())

      if (length(sim) == 0 || !"matchups" %in% names(sim)) {
        return(tibble())
      }

      sim$matchups |>
        mutate(
          season = sim$season %||% config$season,
          week = sim$week %||% week,
          tag = phase,
          timestamp = file_info(file)$modification_time
        )
    })
}

# Extract Rosters ---------------------------------------------------------

extract_rosters <- function(source_dir, weeks, config) {
  log_section("Extracting Rosters")

  sim_files <- dir_ls(source_dir, regexp = "simulation_v5_week\\d+_.+\\.rds")

  if (length(sim_files) == 0) {
    return(tibble())
  }

  sim_files |>
    map_dfr(function(file) {
      filename <- path_file(file)
      parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")

      if (is.na(parts[1, 2])) {
        return(tibble())
      }

      week <- as.integer(parts[1, 2])
      phase <- parts[1, 3]

      sim <- safe_read_rds(file, default = list())

      if (length(sim) == 0 || !"teams" %in% names(sim)) {
        return(tibble())
      }

      # Extract rosters from teams
      tryCatch(
        {
          sim$teams |>
            select(teamId, rosters) |>
            filter(!map_lgl(rosters, is.null)) |>
            unnest(rosters) |>
            mutate(
              season = sim$season %||% config$season,
              week = sim$week %||% week,
              tag = phase,
              timestamp = file_info(file)$modification_time
            )
        },
        error = function(e) {
          log_message(glue("Error extracting rosters from {filename}: {e$message}"), "warning")
          tibble()
        }
      )
    })
}

# Extract Season Data -----------------------------------------------------

extract_season_data <- function(source_dir, config) {
  log_section("Extracting Season Data")

  season_files <- c(
    "season_scrap.rds",
    "season_projtable.rds",
    "season_player_proj_sites.rds"
  )

  season_data <- list()

  for (file_name in season_files) {
    file <- path(source_dir, file_name)

    if (file_exists(file)) {
      log_message(glue("Reading {file_name}..."), "debug")
      season_data[[file_name]] <- safe_read_rds(file, default = NULL)
    } else {
      log_message(glue("Season file not found: {file_name}"), "warning")
    }
  }

  season_data
}

# Extract Draft Data ------------------------------------------------------

extract_draft_data <- function(source_dir, config) {
  log_section("Extracting Draft Data")

  draft_files <- c(
    "draft_picks.rds",
    "draft_pick_projections.rds",
    "draft_teams_projections.rds",
    "draft_recap_data.rds",
    "draft_recap_rank.rds"
  )

  draft_data <- list()

  for (file_name in draft_files) {
    file <- path(source_dir, file_name)

    if (file_exists(file)) {
      log_message(glue("Reading {file_name}..."), "debug")
      draft_data[[file_name]] <- safe_read_rds(file, default = NULL)
    } else {
      log_message(glue("Draft file not found: {file_name}"), "warning")
    }
  }

  draft_data
}

# Main Extraction Function ------------------------------------------------

extract_all <- function(config) {
  log_section("PHASE 1: EXTRACTION")

  source_dir <- config$source_dir
  weeks <- config$weeks

  results <- list()

  # Extract projections
  results$scrapes <- extract_weekly_scrapes(source_dir, weeks, config)
  results$projections <- extract_weekly_projections(source_dir, weeks, config)
  results$proj_tables <- extract_weekly_proj_tables(source_dir, weeks, config)

  # Extract stats
  results$player_data <- extract_player_points(source_dir, config)

  # Extract simulations
  results$simulations <- extract_simulations(source_dir, weeks, config)
  results$matchups <- extract_matchups(source_dir, weeks, config)
  results$rosters <- extract_rosters(source_dir, weeks, config)

  # Extract season and draft data
  results$season_data <- extract_season_data(source_dir, config)
  results$draft_data <- extract_draft_data(source_dir, config)

  # Save checkpoint
  if (config$save_intermediate) {
    create_checkpoint("extraction", results, config$checkpoint_dir)
  }

  log_message("Extraction phase complete!", "success")

  results
}

# Export ------------------------------------------------------------------

list(
  extract_all = extract_all,
  extract_weekly_scrapes = extract_weekly_scrapes,
  extract_weekly_projections = extract_weekly_projections,
  extract_player_points = extract_player_points,
  extract_simulations = extract_simulations,
  extract_matchups = extract_matchups,
  extract_rosters = extract_rosters
)
