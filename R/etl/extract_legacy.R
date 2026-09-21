# =============================================================================
# LEGACY EXTRACTION FUNCTIONS FOR 2019-2021
# =============================================================================
# Script: extract_legacy.R
# Purpose: Extract data from legacy format (2019-2021) where files have
#          different structure than modern format (2022+)
# Author: DudesData ETL Pipeline v2
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(fs)
library(glue)

# Source utilities
source("R/etl_v2/utils_transform.R")

# Extract Weekly Scrapes (Legacy Format) ---------------------------------

extract_weekly_scrapes_legacy <- function(config) {
  log_section("Extracting Weekly Scrapes (Legacy Format)")

  weeks <- config$weeks
  source_dir <- config$source_dir

  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse=', ')}"), "info")

  all_scrapes <- map_dfr(weeks, ~ {
    week_num <- .x
    filename <- path(source_dir, glue("week{week_num}_scrap.rds"))

    log_message(glue("  Week {week_num}: Reading scrapes..."), "debug")

    if (!file_exists(filename)) {
      log_message(glue("  Week {week_num}: File not found, skipping"), "warning")
      return(tibble())
    }

    # Legacy format: list with dataframes by position (QB, RB, WR, TE, K, DST)
    scrap_list <- safe_read_rds(filename, default = list())

    if (length(scrap_list) == 0) {
      log_message(glue("  Week {week_num}: Empty file"), "warning")
      return(tibble())
    }

    # Drop anonymous positional columns (e.g. "...38") - leftover scrape
    # artifacts whose column number varies by position, causing name
    # collisions / type clashes across positions and weeks when bound.
    scrap_list <- map(scrap_list, ~ select(.x, -matches("^\\.\\.\\.[0-9]+$")))

    # Convert list of dataframes to single dataframe
    result <- bind_rows(
      scrap_list,
      .id = "pos"  # Position becomes a column
    ) %>%
      mutate(
        week = week_num,
        season = config$season,
        # Infer timestamp from file modification time
        timestamp = as.POSIXct(file_info(filename)$modification_time),
        source_file = basename(filename)
      ) %>%
      # Rename columns to match modern format
      rename_with(~ if_else(.x == "position", "pos_detail", .x)) %>%
      mutate(pos = toupper(pos))  # Ensure uppercase

    log_message(glue("  Week {week_num}: ✓ {nrow(result)} scrape records"), "success")

    result
  })

  log_message(glue("Total scrapes extracted: {nrow(all_scrapes)}"), "info")

  all_scrapes
}

# Extract Weekly Projections (Legacy - from scrapes only) ----------------

extract_weekly_projections_legacy <- function(config) {
  log_section("Extracting Weekly Projections (Legacy - from scrapes)")

  # In legacy format, projections come from scrapes, not separate files
  # We'll extract them from the scrapes data

  weeks <- config$weeks
  source_dir <- config$source_dir

  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse=', ')}"), "info")

  all_projections <- map_dfr(weeks, ~ {
    week_num <- .x
    filename <- path(source_dir, glue("week{week_num}_scrap.rds"))

    log_message(glue("  Week {week_num}: Reading projections from scrapes..."), "debug")

    if (!file_exists(filename)) {
      log_message(glue("  Week {week_num}: File not found, skipping"), "warning")
      return(tibble())
    }

    scrap_list <- safe_read_rds(filename, default = list())

    if (length(scrap_list) == 0) {
      return(tibble())
    }

    # Convert to long format for projections
    df <- bind_rows(scrap_list, .id = "pos") %>%
      mutate(
        week = week_num,
        season = config$season,
        timestamp = as.POSIXct(file_info(filename)$modification_time)
      )

    # Find which projection column exists
    proj_cols <- c("site_pts", "fpts", "pts", "points", "misc_fppg")
    available_proj_col <- intersect(proj_cols, names(df))[1]

    if (is.na(available_proj_col) || length(available_proj_col) == 0) {
      log_message(glue("  Week {week_num}: No projection column found"), "warning")
      return(tibble())
    }

    result <- df %>%
      rename(pts.proj = !!available_proj_col) %>%
      select(
        season, week, timestamp,
        data_src, id, pos, player, team,
        pts.proj
      ) %>%
      filter(!is.na(pts.proj)) %>%
      mutate(source_file = basename(filename))

    log_message(glue("  Week {week_num}: ✓ {nrow(result)} projection records"), "success")

    result
  })

  log_message(glue("Total projections extracted: {nrow(all_projections)}"), "info")

  all_projections
}

# Extract Weekly Projection Tables (Legacy - create from aggregates) -----

extract_weekly_proj_tables_legacy <- function(config) {
  log_section("Extracting Weekly Projection Tables (Legacy - aggregated from scrapes)")

  # In legacy years, weekly_proj_table_*.rds files don't exist
  # We need to create them by aggregating the scrapes

  weeks <- config$weeks
  source_dir <- config$source_dir

  log_message(glue("Processing {length(weeks)} week(s): {paste(weeks, collapse=', ')}"), "info")

  all_proj_tables <- map_dfr(weeks, ~ {
    week_num <- .x
    filename <- path(source_dir, glue("week{week_num}_scrap.rds"))

    log_message(glue("  Week {week_num}: Aggregating projection table..."), "debug")

    if (!file_exists(filename)) {
      log_message(glue("  Week {week_num}: File not found, skipping"), "warning")
      return(tibble())
    }

    scrap_list <- safe_read_rds(filename, default = list())

    if (length(scrap_list) == 0) {
      return(tibble())
    }

    # Aggregate by player
    result <- bind_rows(scrap_list, .id = "pos") %>%
      mutate(
        week = week_num,
        season = config$season
      ) %>%
      group_by(season, week, id, pos, player, team) %>%
      summarise(
        # Aggregate projections across sources
        points = mean(site_pts, na.rm = TRUE),
        sd_pts = sd(site_pts, na.rm = TRUE),
        floor = quantile(site_pts, 0.25, na.rm = TRUE),
        ceiling = quantile(site_pts, 0.75, na.rm = TRUE),
        n_sources = n(),
        .groups = "drop"
      ) %>%
      # Add rankings
      group_by(season, week, pos) %>%
      arrange(desc(points)) %>%
      mutate(
        rank = row_number(),
        pos_rank = row_number()
      ) %>%
      ungroup()

    log_message(glue("  Week {week_num}: ✓ {nrow(result)} projection table records"), "success")

    result
  })

  log_message(glue("Total projection table records: {nrow(all_proj_tables)}"), "info")

  all_proj_tables
}

# Main Extract Function (Legacy) -----------------------------------------

extract_all_legacy <- function(config) {
  log_section("PHASE 1: EXTRACTION (LEGACY FORMAT)")

  results <- list()

  # Extract scrapes (legacy format: list by position)
  results$scrapes <- extract_weekly_scrapes_legacy(config)

  # Extract projections (from scrapes)
  results$projections <- extract_weekly_projections_legacy(config)

  # Create projection tables (aggregate from scrapes)
  results$proj_tables <- extract_weekly_proj_tables_legacy(config)

  # Extract player data (use modern extractor - should work)
  extract_module <- source("R/etl_v2/extract.R")$value
  results$player_data <- extract_module$extract_player_points(config$source_dir, config)

  # Extract simulations (use modern extractor - should work for 2020-2021)
  results$simulations <- extract_module$extract_simulations(config$source_dir, config$weeks, config)

  # Season and draft data (if available)
  tryCatch({
    results$season_data <- extract_module$extract_season_data(config)
  }, error = function(e) {
    log_message("Season data not available for this year (expected for legacy)", "info")
    results$season_data <<- list()
  })

  tryCatch({
    results$draft_data <- extract_module$extract_draft_data(config)
  }, error = function(e) {
    log_message("Draft data not available for this year (expected for legacy)", "info")
    results$draft_data <<- list()
  })

  # Save checkpoint
  if (config$save_intermediate) {
    create_checkpoint("extraction_legacy", results, config$checkpoint_dir)
  }

  log_message("Extraction phase complete (legacy format)!", "success")

  results
}

# Export ------------------------------------------------------------------

list(
  extract_all_legacy = extract_all_legacy,
  extract_weekly_scrapes_legacy = extract_weekly_scrapes_legacy,
  extract_weekly_projections_legacy = extract_weekly_projections_legacy,
  extract_weekly_proj_tables_legacy = extract_weekly_proj_tables_legacy
)
