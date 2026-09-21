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

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("week{wk}_scrap.rds"))

      if (!file_exists(file)) {
        log_message(glue("Skipping week {wk} - file not found"), "warning")
        return(tibble())
      }

      log_message(glue("Reading week {wk} scrapes..."), "debug")

      scrape <- safe_read_rds(file, default = list())

      if (length(scrape) == 0) {
        return(tibble())
      }

      # scrape is a list of 6 data.frames (QB, RB, WR, TE, K, DST)
      map_dfr(scrape, bind_rows, .id = "position_source") |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time,
          source_file = path_file(file)
        )
    })
}

# Extract Weekly Projections ----------------------------------------------

extract_weekly_projections <- function(source_dir, weeks, config) {
  log_section("Extracting Weekly Projections")

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("weekly_proj_player_site_{wk}.rds"))

      if (!file_exists(file)) {
        log_message(glue("Skipping week {wk} projections - file not found"), "warning")
        return(tibble())
      }

      log_message(glue("Reading week {wk} projections..."), "debug")

      safe_read_rds(file, default = tibble()) |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time,
          source_file = path_file(file)
        )
    })
}

# Extract Weekly Projection Tables ----------------------------------------

extract_weekly_proj_tables <- function(source_dir, weeks, config) {
  log_section("Extracting Weekly Projection Tables")

  weeks |>
    map_dfr(function(wk) {
      file <- path(source_dir, glue("weekly_proj_table_{wk}.rds"))

      if (!file_exists(file)) {
        return(tibble())
      }

      log_message(glue("Reading week {wk} projection table..."), "debug")

      safe_read_rds(file, default = tibble()) |>
        mutate(
          week = wk,
          season = config$season,
          timestamp = file_info(file)$modification_time
        )
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

  # Extract basic points
  points <- players |>
    select(playerId, week, weekPts) |>
    mutate(season = config$season) |>
    rename(pts = weekPts)

  log_message(glue("Extracted {nrow(points)} player point records"), "info")

  # Unnest weekStats if available
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

  # Unnest advanced stats if available
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

  log_message(glue("Found {length(sim_files_filtered)} simulation files for weeks {paste(weeks, collapse=', ')}"), "info")

  sim_files_filtered |>
    map_dfr(function(file) {
      # Parse filename to extract week and phase
      filename <- path_file(file)
      parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")

      if (is.na(parts[1, 2])) {
        log_message(glue("Could not parse filename: {filename}"), "warning")
        return(tibble())
      }

      week <- as.integer(parts[1, 2])
      phase <- parts[1, 3]

      log_message(glue("Reading simulation week {week} phase {phase}..."), "debug")

      sim <- safe_read_rds(file, default = list())

      if (length(sim) == 0) {
        return(tibble())
      }

      # Extract players_sim if available
      if ("players_sim" %in% names(sim)) {
        sim$players_sim |>
          mutate(
            season = sim$season %||% config$season,
            week = sim$week %||% week,
            tag = phase,
            timestamp = file_info(file)$modification_time,
            source_file = filename
          )
      } else {
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
