#!/usr/bin/env Rscript
# ==============================================================================
# Unified Dataset Creation - Multi-Year Fantasy Football Data Merger
# ==============================================================================
#
# Purpose: Merge data from etl/2020, etl/2021, etl/2022, etl/2023, and
#          app/2023-24-25 into a unified dataset following app schema standards.
#
# Output: ./dataset/ with 7 dm databases ready for data science analysis
#
# Author: DudesData
# Date: 2026-03-08
# ==============================================================================

library(tidyverse)
library(dm)
library(fs)
library(glue)
library(lubridate)

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

MERGE_CONFIG <- list(
  # Source directories (in order of preference)
  sources = list(
    list(year = 2023, dir = "app/2023-24-25", label = "unified_2023"),
    list(year = 2024, dir = "app/2023-24-25", label = "unified_2024"),
    list(year = 2025, dir = "app/2023-24-25", label = "unified_2025"),
    list(year = 2020, dir = "etl/2020", label = "etl_2020"),
    list(year = 2021, dir = "etl/2021", label = "etl_2021"),
    list(year = 2022, dir = "etl/2022", label = "etl_2022"),
    list(year = 2023, dir = "etl/2023", label = "etl_2023")
  ),

  # Output directory
  output_dir = "dataset",

  # Database filenames
  databases = c(
    "ffa_db.rds",
    "nfl_teams_db.rds",
    "nfl_players_db.rds",
    "nfl_stats_db.rds",
    "nfl_round_db.rds",
    "nfl_recap_db.rds",
    "dudes_simulation_db.rds"
  ),

  # Validation settings
  strict_mode = FALSE,
  allow_na_in_new_columns = TRUE,

  # Logging
  log_file = "dataset/MERGE_LOG.md",
  report_file = "dataset/MERGE_REPORT.md"
)

# ------------------------------------------------------------------------------
# Logging Functions
# ------------------------------------------------------------------------------

log_message <- function(message, level = "INFO", file = MERGE_CONFIG$log_file) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  prefix <- switch(level,
    "INFO" = "ℹ️",
    "SUCCESS" = "✅",
    "WARNING" = "⚠️",
    "ERROR" = "❌",
    "DEBUG" = "🔍",
    "ℹ️"
  )

  log_line <- glue("{timestamp} {prefix} [{level}] {message}\n")
  cat(log_line)

  if (!is.null(file) && dir.exists(dirname(file))) {
    cat(log_line, file = file, append = TRUE)
  }
}

start_section <- function(title) {
  cat("\n")
  cat(rep("=", 80), "\n", sep = "")
  cat(title, "\n")
  cat(rep("=", 80), "\n", sep = "")
  log_message(title, "INFO")
}

# ------------------------------------------------------------------------------
# Data Loading Functions
# ------------------------------------------------------------------------------

#' Load a database file with error handling
#'
#' @param file_path Path to .rds file
#' @param label Label for logging
#' @return dm object or NULL if failed
safe_load_db <- function(file_path, label) {
  tryCatch({
    if (!file.exists(file_path)) {
      log_message(glue("File not found: {file_path}"), "WARNING")
      return(NULL)
    }

    db <- readRDS(file_path)

    # Check if it's a dm object
    if (!inherits(db, "dm")) {
      log_message(glue("Not a dm object: {file_path}"), "WARNING")
      return(NULL)
    }

    log_message(glue("Loaded {label}: {file_path}"), "SUCCESS")
    return(db)

  }, error = function(e) {
    log_message(glue("Error loading {file_path}: {e$message}"), "ERROR")
    return(NULL)
  })
}

#' Load all databases for a given source
#'
#' @param source Source configuration list
#' @return Named list of dm objects
load_source_databases <- function(source) {
  log_message(glue("Loading databases for {source$label} (year {source$year})"), "INFO")

  databases <- list()

  for (db_file in MERGE_CONFIG$databases) {
    file_path <- file.path(source$dir, db_file)
    db_name <- str_remove(db_file, "\\.rds$")

    db <- safe_load_db(file_path, glue("{source$label}/{db_name}"))

    if (!is.null(db)) {
      databases[[db_name]] <- db
    }
  }

  log_message(glue("Loaded {length(databases)}/{length(MERGE_CONFIG$databases)} databases for {source$label}"), "INFO")

  return(databases)
}

# ------------------------------------------------------------------------------
# Schema Compatibility Functions
# ------------------------------------------------------------------------------

#' Get column names for a table across multiple databases
#'
#' @param db_list List of dm objects
#' @param table_name Name of the table
#' @return Named list of column name vectors
get_table_columns <- function(db_list, table_name) {
  columns <- map(db_list, function(db) {
    if (table_name %in% dm_get_tables(db)) {
      names(db[[table_name]])
    } else {
      character(0)
    }
  })

  return(columns)
}

#' Find common columns across all databases
#'
#' @param db_list List of dm objects
#' @param table_name Name of the table
#' @return Character vector of common column names
find_common_columns <- function(db_list, table_name) {
  columns <- get_table_columns(db_list, table_name)

  # Remove empty entries
  columns <- compact(columns)

  if (length(columns) == 0) {
    return(character(0))
  }

  # Find intersection
  common_cols <- reduce(columns, intersect)

  return(common_cols)
}

#' Create schema report for a table
#'
#' @param db_list Named list of dm objects
#' @param table_name Name of the table
#' @return Tibble with schema information
analyze_table_schema <- function(db_list, table_name) {
  columns <- get_table_columns(db_list, table_name)

  # Get all unique columns
  all_cols <- unique(unlist(columns))

  # Create presence matrix
  presence <- map_dfc(columns, function(cols) {
    tibble(present = all_cols %in% cols)
  })

  schema_df <- tibble(
    column = all_cols,
    .before = 1
  ) %>%
    bind_cols(presence)

  return(schema_df)
}

# ------------------------------------------------------------------------------
# Data Merging Functions
# ------------------------------------------------------------------------------

#' Merge multiple tables with consistent columns
#'
#' @param db_list Named list of dm objects
#' @param table_name Name of the table to merge
#' @param source_labels Labels for each database
#' @return Merged tibble with source tracking
merge_table_safe <- function(db_list, table_name, source_labels) {
  log_message(glue("Merging table: {table_name}"), "INFO")

  # Extract tables
  tables <- map2(db_list, source_labels, function(db, label) {
    if (table_name %in% dm_get_tables(db)) {
      tbl <- db[[table_name]]

      # Add source tracking
      tbl <- tbl %>%
        mutate(
          data_source = label,
          merged_at = Sys.time()
        )

      return(tbl)
    } else {
      return(NULL)
    }
  })

  # Remove NULL entries
  tables <- compact(tables)

  if (length(tables) == 0) {
    log_message(glue("No tables found for {table_name}"), "WARNING")
    return(tibble())
  }

  # Find common columns
  common_cols <- reduce(
    map(tables, names),
    intersect
  )

  if (length(common_cols) == 0) {
    log_message(glue("No common columns found for {table_name}"), "ERROR")
    return(tibble())
  }

  log_message(glue("Using {length(common_cols)} common columns for {table_name}"), "INFO")

  # Select only common columns and bind
  merged <- map(tables, ~ select(.x, all_of(common_cols))) %>%
    bind_rows()

  log_message(glue("Merged {nrow(merged)} rows for {table_name}"), "SUCCESS")

  return(merged)
}

#' Merge databases with special handling for known issues
#'
#' @param db_list Named list of dm objects
#' @param table_name Name of the table to merge
#' @param source_labels Labels for each database
#' @return Merged tibble
merge_table_smart <- function(db_list, table_name, source_labels) {

  # Special handling for nfl_players_adv_stats
  if (table_name == "nfl_players_adv_stats") {
    return(merge_adv_stats_with_schema_version(db_list, source_labels))
  }

  # Special handling for nfl_teams
  if (table_name == "nfl_teams") {
    return(merge_with_missing_data_handling(db_list, table_name, source_labels))
  }

  # Standard merge for other tables
  return(merge_table_safe(db_list, table_name, source_labels))
}

#' Merge nfl_players_adv_stats with schema version tracking
#'
#' @param db_list Named list of dm objects
#' @param source_labels Labels for each database
#' @return Merged tibble with schema_version column
merge_adv_stats_with_schema_version <- function(db_list, source_labels) {
  log_message("Merging nfl_players_adv_stats with schema versioning", "INFO")

  tables <- map2(db_list, source_labels, function(db, label) {
    if ("nfl_players_adv_stats" %in% dm_get_tables(db)) {
      tbl <- db$nfl_players_adv_stats

      # Determine schema version based on columns
      if ("transactionBuysellAdd" %in% names(tbl)) {
        schema_ver <- "2025"
      } else if ("percentRostered" %in% names(tbl)) {
        schema_ver <- "2023"
      } else {
        schema_ver <- "unknown"
      }

      tbl <- tbl %>%
        mutate(
          schema_version = schema_ver,
          data_source = label,
          merged_at = Sys.time()
        )

      return(tbl)
    } else {
      return(NULL)
    }
  })

  tables <- compact(tables)

  if (length(tables) == 0) {
    return(tibble())
  }

  # Find common columns excluding schema-specific ones
  common_cols <- reduce(
    map(tables, names),
    intersect
  )

  # Merge
  merged <- map(tables, ~ select(.x, all_of(common_cols))) %>%
    bind_rows()

  log_message(glue("Merged {nrow(merged)} rows with {length(unique(merged$schema_version))} schema versions"), "SUCCESS")

  return(merged)
}

#' Merge tables with handling for completely missing data
#'
#' @param db_list Named list of dm objects
#' @param table_name Name of the table to merge
#' @param source_labels Labels for each database
#' @return Merged tibble
merge_with_missing_data_handling <- function(db_list, table_name, source_labels) {
  log_message(glue("Merging {table_name} with missing data handling"), "INFO")

  tables <- map2(db_list, source_labels, function(db, label) {
    if (table_name %in% dm_get_tables(db)) {
      tbl <- db[[table_name]]

      # Check if table is empty
      if (nrow(tbl) == 0) {
        log_message(glue("Empty table in {label}: {table_name}"), "WARNING")
        return(NULL)
      }

      tbl <- tbl %>%
        mutate(
          data_source = label,
          merged_at = Sys.time()
        )

      return(tbl)
    } else {
      return(NULL)
    }
  })

  tables <- compact(tables)

  if (length(tables) == 0) {
    log_message(glue("No non-empty tables found for {table_name}"), "WARNING")
    return(tibble())
  }

  # Standard merge
  common_cols <- reduce(map(tables, names), intersect)
  merged <- map(tables, ~ select(.x, all_of(common_cols))) %>%
    bind_rows()

  return(merged)
}

# ------------------------------------------------------------------------------
# Database Reconstruction Functions
# ------------------------------------------------------------------------------

#' Reconstruct a dm database from merged tables
#'
#' @param tables Named list of tibbles
#' @param db_name Name of the database
#' @return dm object
reconstruct_database <- function(tables, db_name) {
  log_message(glue("Reconstructing database: {db_name}"), "INFO")

  # Create dm from tables
  db_dm <- dm(!!!tables)

  # Add primary keys based on database type
  db_dm <- add_primary_keys(db_dm, db_name)

  # Add foreign keys (lenient mode due to known FK violations)
  if (MERGE_CONFIG$strict_mode) {
    db_dm <- add_foreign_keys(db_dm, db_name)
  }

  log_message(glue("Reconstructed {db_name} with {length(tables)} tables"), "SUCCESS")

  return(db_dm)
}

#' Add primary keys to dm object
#'
#' @param db_dm dm object
#' @param db_name Name of the database
#' @return dm object with primary keys
add_primary_keys <- function(db_dm, db_name) {

  tryCatch({
    if (db_name == "ffa_db") {
      if ("ffa_player_ids" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(ffa_player_ids, id)
      }
      if ("ffa_players" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(ffa_players, c(id, pos))
      }
      if ("ffa_projtable" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(ffa_projtable, c(season, week, id, pos, avg_type, tag, timestamp))
      }
      if ("ffa_proj_source_points" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(ffa_proj_source_points, c(season, week, id, pos, data_src, tag, timestamp))
      }
    }

    if (db_name == "nfl_teams_db") {
      if ("nfl_teams" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_teams, teamId)
      }
      if ("nfl_owners" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_owners, ownerUserId)
      }
    }

    if (db_name == "nfl_players_db") {
      if ("nfl_players" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_players, playerId)
      }
      if ("nfl_player_injury_status" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_player_injury_status, c(playerId, timestamp))
      }
    }

    if (db_name == "nfl_stats_db") {
      if ("nfl_players_points" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_players_points, c(season, week, playerId))
      }
      if ("nfl_players_stats" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_players_stats, c(season, week, playerId, statId))
      }
    }

    if (db_name == "nfl_round_db") {
      if ("matchups_games" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(matchups_games, c(season, week, matchupId))
      }
      if ("nfl_teams_rosters" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(nfl_teams_rosters, c(season, week, teamId, playerId, tag, timestamp))
      }
    }

    if (db_name == "dudes_simulation_db") {
      if ("dudes_players_seeds" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(dudes_players_seeds, c(season, week, id, playerId, pos, simType))
      }
      if ("dudes_players_simulations" %in% dm_get_tables(db_dm)) {
        db_dm <- db_dm %>% dm_add_pk(dudes_players_simulations, c(season, week, id, playerId, pos, simType))
      }
    }

  }, error = function(e) {
    log_message(glue("Error adding primary keys for {db_name}: {e$message}"), "WARNING")
  })

  return(db_dm)
}

#' Add foreign keys to dm object (lenient mode)
#'
#' @param db_dm dm object
#' @param db_name Name of the database
#' @return dm object with foreign keys
add_foreign_keys <- function(db_dm, db_name) {
  log_message(glue("Adding foreign keys to {db_name} (lenient mode)"), "INFO")

  # Foreign keys are not strictly enforced due to known violations
  # This function is a placeholder for future strict mode

  return(db_dm)
}

# ------------------------------------------------------------------------------
# Reporting Functions
# ------------------------------------------------------------------------------

#' Generate comprehensive merge report
#'
#' @param merged_databases List of dm objects
#' @param source_stats Statistics from source loading
generate_merge_report <- function(merged_databases, source_stats) {
  report_path <- MERGE_CONFIG$report_file

  cat("# Unified Dataset Merge Report\n\n", file = report_path)
  cat(glue("**Generated:** {format(Sys.time(), '%Y-%m-%d %H:%M:%S')}\n\n"), file = report_path, append = TRUE)
  cat("---\n\n", file = report_path, append = TRUE)

  # Source summary
  cat("## Source Data Summary\n\n", file = report_path, append = TRUE)
  cat("| Year | Directory | Databases Loaded | Status |\n", file = report_path, append = TRUE)
  cat("|------|-----------|------------------|--------|\n", file = report_path, append = TRUE)

  for (source in MERGE_CONFIG$sources) {
    dbs_loaded <- source_stats[[source$label]]$databases_loaded
    total_dbs <- length(MERGE_CONFIG$databases)
    status <- if (dbs_loaded == total_dbs) "✅ Complete" else glue("⚠️ Partial ({dbs_loaded}/{total_dbs})")

    cat(glue("| {source$year} | `{source$dir}` | {dbs_loaded}/{total_dbs} | {status} |\n"),
        file = report_path, append = TRUE)
  }

  cat("\n---\n\n", file = report_path, append = TRUE)

  # Database statistics
  cat("## Merged Database Statistics\n\n", file = report_path, append = TRUE)

  for (db_name in names(merged_databases)) {
    cat(glue("### {db_name}\n\n"), file = report_path, append = TRUE)

    db <- merged_databases[[db_name]]
    tables <- dm_get_tables(db)

    cat("| Table | Rows | Columns | Data Sources |\n", file = report_path, append = TRUE)
    cat("|-------|------|---------|-------------|\n", file = report_path, append = TRUE)

    for (table_name in tables) {
      tbl <- db[[table_name]]
      rows <- nrow(tbl)
      cols <- ncol(tbl)

      # Count unique data sources
      if ("data_source" %in% names(tbl)) {
        sources <- length(unique(tbl$data_source))
      } else {
        sources <- "N/A"
      }

      cat(glue("| {table_name} | {format(rows, big.mark=',')} | {cols} | {sources} |\n"),
          file = report_path, append = TRUE)
    }

    cat("\n", file = report_path, append = TRUE)
  }

  cat("---\n\n", file = report_path, append = TRUE)
  cat("**Report Complete**\n", file = report_path, append = TRUE)

  log_message(glue("Merge report saved to: {report_path}"), "SUCCESS")
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------

#' Main merge function
main_merge <- function() {
  start_time <- Sys.time()

  start_section("UNIFIED DATASET CREATION - MULTI-YEAR MERGER")

  # Create output directory
  if (!dir.exists(MERGE_CONFIG$output_dir)) {
    dir_create(MERGE_CONFIG$output_dir)
    log_message(glue("Created output directory: {MERGE_CONFIG$output_dir}"), "SUCCESS")
  }

  # Initialize log
  cat("# Merge Log\n\n", file = MERGE_CONFIG$log_file)
  cat(glue("**Started:** {format(start_time, '%Y-%m-%d %H:%M:%S')}\n\n"),
      file = MERGE_CONFIG$log_file, append = TRUE)

  # ------------------------------------------------------------------------------
  # Phase 1: Load source databases
  # ------------------------------------------------------------------------------

  start_section("PHASE 1: Loading Source Databases")

  all_databases <- list()
  source_stats <- list()

  for (source in MERGE_CONFIG$sources) {
    databases <- load_source_databases(source)

    all_databases[[source$label]] <- databases
    source_stats[[source$label]] <- list(
      year = source$year,
      dir = source$dir,
      databases_loaded = length(databases)
    )
  }

  log_message(glue("Loaded databases from {length(MERGE_CONFIG$sources)} sources"), "SUCCESS")

  # ------------------------------------------------------------------------------
  # Phase 2: Merge databases by type
  # ------------------------------------------------------------------------------

  start_section("PHASE 2: Merging Databases")

  merged_databases <- list()

  for (db_file in MERGE_CONFIG$databases) {
    db_name <- str_remove(db_file, "\\.rds$")

    log_message(glue("Processing database: {db_name}"), "INFO")

    # Extract specific database from all sources
    db_list <- map(all_databases, ~ .x[[db_name]]) %>% compact()
    source_labels <- names(db_list)

    if (length(db_list) == 0) {
      log_message(glue("No databases found for {db_name}, skipping"), "WARNING")
      next
    }

    # Get all tables from this database type
    all_tables <- unique(unlist(map(db_list, dm_get_tables)))

    log_message(glue("Found {length(all_tables)} unique tables in {db_name}"), "INFO")

    # Merge each table
    merged_tables <- list()

    for (table_name in all_tables) {
      merged_tbl <- merge_table_smart(db_list, table_name, source_labels)

      if (nrow(merged_tbl) > 0) {
        merged_tables[[table_name]] <- merged_tbl
      }
    }

    # Reconstruct dm object
    if (length(merged_tables) > 0) {
      merged_db <- reconstruct_database(merged_tables, db_name)
      merged_databases[[db_name]] <- merged_db

      # Save to disk
      output_path <- file.path(MERGE_CONFIG$output_dir, db_file)
      saveRDS(merged_db, output_path)
      log_message(glue("Saved merged database: {output_path}"), "SUCCESS")
    } else {
      log_message(glue("No data to merge for {db_name}"), "WARNING")
    }
  }

  # ------------------------------------------------------------------------------
  # Phase 3: Generate reports
  # ------------------------------------------------------------------------------

  start_section("PHASE 3: Generating Reports")

  generate_merge_report(merged_databases, source_stats)

  # ------------------------------------------------------------------------------
  # Completion
  # ------------------------------------------------------------------------------

  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "mins"))

  start_section("MERGE COMPLETE")

  log_message(glue("Duration: {round(duration, 2)} minutes"), "INFO")
  log_message(glue("Output directory: {MERGE_CONFIG$output_dir}"), "INFO")
  log_message(glue("Databases created: {length(merged_databases)}"), "SUCCESS")

  cat("\n")
  cat("📊 Summary:\n")
  cat(glue("   - {length(merged_databases)} databases merged\n"))
  cat(glue("   - {length(MERGE_CONFIG$sources)} source directories processed\n"))
  cat(glue("   - Output: {MERGE_CONFIG$output_dir}/\n"))
  cat(glue("   - Duration: {round(duration, 2)} minutes\n"))
  cat("\n")

  return(merged_databases)
}

# ------------------------------------------------------------------------------
# Execute if run as script
# ------------------------------------------------------------------------------

if (!interactive()) {
  result <- tryCatch({
    main_merge()
  }, error = function(e) {
    log_message(glue("FATAL ERROR: {e$message}"), "ERROR")
    cat("\n❌ Merge failed\n")
    cat(glue("Error: {e$message}\n"))
    quit(status = 1)
  })

  cat("\n✅ Merge completed successfully\n")
  quit(status = 0)
}
