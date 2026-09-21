# ==============================================================================
# MERGE HISTORICAL DATA SCRIPT
# ==============================================================================
# Purpose: Consolidate DudesData from 2020-2025 into unified databases
# Author: Claude Code
# Date: 2026-03-08
#
# Sources:
#   - etl/2020/, etl/2021/, etl/2022/ (individual years 2020-2022)
#   - app/2023-24-25/ (merged years 2023-2025)
#
# Target: dataset/ (complete 2020-2025 unified databases)
# ==============================================================================

library(tidyverse)
library(dm)
library(glue)
library(lubridate)

# ==============================================================================
# SETUP
# ==============================================================================

# Set working directory
setwd("/Users/gsposito/Projects/DudesData")

# Create log file
log_file <- "dataset/merge_execution.log"
if (file.exists(log_file)) file.remove(log_file)

log_message <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_line <- glue("[{timestamp}] {msg}")
  cat(log_line, "\n")
  write(log_line, log_file, append = TRUE)
}

log_message("=== MERGE HISTORICAL DATA - START ===")
log_message("Consolidating DudesData 2020-2025")

# Initialize validation tracker
validation_results <- tibble(
  database = character(),
  table = character(),
  year = character(),
  rows = integer(),
  status = character()
)

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

# Load a database and extract its tables
load_database <- function(path, year) {
  log_message(glue("Loading {basename(path)} from year {year}..."))

  tryCatch({
    db <- readRDS(path)

    # Extract all tables from dm object
    if ("dm" %in% class(db)) {
      tables <- dm_get_tables(db)
      log_message(glue("  ✓ Loaded {length(tables)} tables from {year}"))
      return(tables)
    } else {
      log_message(glue("  ✗ WARNING: Not a dm object in {year}"))
      return(NULL)
    }
  }, error = function(e) {
    log_message(glue("  ✗ ERROR loading {year}: {e$message}"))
    return(NULL)
  })
}

# Merge tables across years
merge_tables <- function(table_name, tables_list) {
  log_message(glue("  Merging table: {table_name}"))

  # Extract the specific table from each year's data
  year_tables <- map(tables_list, function(year_data) {
    if (!is.null(year_data) && table_name %in% names(year_data)) {
      return(year_data[[table_name]])
    }
    return(NULL)
  })

  # Remove NULL entries
  year_tables <- compact(year_tables)

  if (length(year_tables) == 0) {
    log_message(glue("    ✗ No data found for {table_name}"))
    return(NULL)
  }

  # Get row counts before merge
  row_counts <- map_int(year_tables, nrow)
  total_rows_before <- sum(row_counts)
  log_message(glue("    Rows before merge: {total_rows_before} ({paste(row_counts, collapse = ', ')})"))

  # Merge tables
  tryCatch({
    merged <- bind_rows(year_tables)

    # Remove duplicates if primary keys are present
    # Check for common key columns
    key_cols <- c("season", "week", "id", "playerId", "teamId", "matchupId", "timestamp")
    available_keys <- intersect(key_cols, names(merged))

    if (length(available_keys) > 0) {
      merged <- merged %>% distinct(across(all_of(available_keys)), .keep_all = TRUE)
      log_message(glue("    Deduplicated using: {paste(available_keys, collapse = ', ')}"))
    }

    rows_after <- nrow(merged)
    duplicates_removed <- total_rows_before - rows_after

    log_message(glue("    Rows after merge: {rows_after}"))
    if (duplicates_removed > 0) {
      log_message(glue("    Duplicates removed: {duplicates_removed}"))
    }

    return(merged)
  }, error = function(e) {
    log_message(glue("    ✗ ERROR merging {table_name}: {e$message}"))
    return(NULL)
  })
}

# Validate merged data
validate_table <- function(table, table_name) {
  log_message(glue("  Validating {table_name}..."))

  issues <- character()

  # Check for temporal columns
  if ("season" %in% names(table)) {
    seasons <- sort(unique(table$season))
    log_message(glue("    Seasons: {paste(seasons, collapse = ', ')}"))

    # Verify temporal continuity
    expected_seasons <- 2020:2025
    missing_seasons <- setdiff(expected_seasons, seasons)
    if (length(missing_seasons) > 0) {
      msg <- glue("Missing seasons: {paste(missing_seasons, collapse = ', ')}")
      log_message(glue("    ⚠ {msg}"))
      issues <- c(issues, msg)
    }
  }

  # Check for week coverage
  if ("week" %in% names(table) && "season" %in% names(table)) {
    week_coverage <- table %>%
      group_by(season) %>%
      summarise(
        min_week = min(week, na.rm = TRUE),
        max_week = max(week, na.rm = TRUE),
        .groups = "drop"
      )
    log_message("    Week coverage by season:")
    for (i in 1:nrow(week_coverage)) {
      log_message(glue("      {week_coverage$season[i]}: weeks {week_coverage$min_week[i]}-{week_coverage$max_week[i]}"))
    }
  }

  # Check for NAs in critical columns
  critical_cols <- c("season", "week", "id", "playerId", "teamId")
  available_critical <- intersect(critical_cols, names(table))

  for (col in available_critical) {
    na_count <- sum(is.na(table[[col]]))
    if (na_count > 0) {
      msg <- glue("{col}: {na_count} NAs")
      log_message(glue("    ⚠ {msg}"))
      issues <- c(issues, msg)
    }
  }

  if (length(issues) == 0) {
    log_message("    ✓ Validation passed")
    return(list(status = "PASS", issues = NA))
  } else {
    return(list(status = "WARNINGS", issues = paste(issues, collapse = "; ")))
  }
}

# ==============================================================================
# LOAD SOURCE DATA
# ==============================================================================

log_message("\n=== LOADING SOURCE DATA ===")

# Define source paths
etl_years <- c("2020", "2021", "2022")
consolidated_path <- "app/2023-24-25"

# Database files to process
db_files <- c(
  "ffa_db.rds",
  "nfl_teams_db.rds",
  "nfl_players_db.rds",
  "nfl_stats_db.rds",
  "nfl_round_db.rds",
  "nfl_recap_db.rds",
  "dudes_simulation_db.rds"
)

# ==============================================================================
# MERGE EACH DATABASE
# ==============================================================================

log_message("\n=== MERGING DATABASES ===")

for (db_file in db_files) {
  log_message(glue("\n--- Processing {db_file} ---"))

  # Load data from all years
  all_years_data <- list()

  # Load ETL years (2020-2022)
  for (year in etl_years) {
    path <- glue("etl/{year}/{db_file}")
    if (file.exists(path)) {
      all_years_data[[year]] <- load_database(path, year)

      # Track validation
      if (!is.null(all_years_data[[year]])) {
        for (tbl_name in names(all_years_data[[year]])) {
          validation_results <- bind_rows(
            validation_results,
            tibble(
              database = db_file,
              table = tbl_name,
              year = year,
              rows = nrow(all_years_data[[year]][[tbl_name]]),
              status = "LOADED"
            )
          )
        }
      }
    } else {
      log_message(glue("  ✗ File not found: {path}"))
    }
  }

  # Load consolidated years (2023-2025)
  consolidated_path_full <- glue("{consolidated_path}/{db_file}")
  if (file.exists(consolidated_path_full)) {
    all_years_data[["2023-25"]] <- load_database(consolidated_path_full, "2023-25")

    # Track validation
    if (!is.null(all_years_data[["2023-25"]])) {
      for (tbl_name in names(all_years_data[["2023-25"]])) {
        validation_results <- bind_rows(
          validation_results,
          tibble(
            database = db_file,
            table = tbl_name,
            year = "2023-25",
            rows = nrow(all_years_data[["2023-25"]][[tbl_name]]),
            status = "LOADED"
          )
        )
      }
    }
  } else {
    log_message(glue("  ✗ File not found: {consolidated_path_full}"))
  }

  # Get all unique table names across years
  all_table_names <- all_years_data %>%
    map(names) %>%
    flatten_chr() %>%
    unique()

  log_message(glue("Tables to merge: {paste(all_table_names, collapse = ', ')}"))

  # Merge each table
  merged_tables <- list()
  for (tbl_name in all_table_names) {
    merged_table <- merge_tables(tbl_name, all_years_data)

    if (!is.null(merged_table)) {
      # Validate merged table
      validation <- validate_table(merged_table, tbl_name)

      merged_tables[[tbl_name]] <- merged_table

      # Track final validation
      validation_results <- bind_rows(
        validation_results,
        tibble(
          database = db_file,
          table = tbl_name,
          year = "2020-2025",
          rows = nrow(merged_table),
          status = validation$status
        )
      )
    }
  }

  # Create dm object
  if (length(merged_tables) > 0) {
    log_message(glue("Creating dm object for {db_file}..."))

    # Start with empty dm
    merged_dm <- dm()

    # Add tables
    for (tbl_name in names(merged_tables)) {
      merged_dm <- dm_add_tbl(merged_dm, !!sym(tbl_name) := merged_tables[[tbl_name]])
    }

    # Save to dataset/
    output_path <- glue("dataset/{db_file}")
    saveRDS(merged_dm, output_path)
    log_message(glue("✓ Saved {output_path}"))

    # Report file size
    file_size <- file.info(output_path)$size
    file_size_mb <- round(file_size / 1024^2, 2)
    log_message(glue("  File size: {file_size_mb} MB"))
  } else {
    log_message(glue("✗ No tables to save for {db_file}"))
  }
}

# ==============================================================================
# SAVE VALIDATION RESULTS
# ==============================================================================

log_message("\n=== SAVING VALIDATION RESULTS ===")

validation_path <- "dataset/merge_validation.csv"
write_csv(validation_results, validation_path)
log_message(glue("✓ Saved validation results to {validation_path}"))

# ==============================================================================
# GENERATE SUMMARY STATISTICS
# ==============================================================================

log_message("\n=== SUMMARY STATISTICS ===")

# Calculate totals by database
summary_by_db <- validation_results %>%
  filter(year == "2020-2025") %>%
  group_by(database) %>%
  summarise(
    tables = n(),
    total_rows = sum(rows),
    .groups = "drop"
  ) %>%
  arrange(desc(total_rows))

log_message("\nFinal database sizes:")
for (i in 1:nrow(summary_by_db)) {
  log_message(glue("  {summary_by_db$database[i]}: {summary_by_db$tables[i]} tables, {format(summary_by_db$total_rows[i], big.mark = ',')} rows"))
}

# Calculate totals by year (pre-merge)
summary_by_year <- validation_results %>%
  filter(year != "2020-2025") %>%
  group_by(year) %>%
  summarise(
    total_rows = sum(rows),
    .groups = "drop"
  ) %>%
  arrange(year)

log_message("\nRows by source year:")
for (i in 1:nrow(summary_by_year)) {
  log_message(glue("  {summary_by_year$year[i]}: {format(summary_by_year$total_rows[i], big.mark = ',')} rows"))
}

# Check for any validation issues
issues <- validation_results %>%
  filter(year == "2020-2025", status != "PASS") %>%
  select(database, table, status)

if (nrow(issues) > 0) {
  log_message("\n⚠ VALIDATION WARNINGS:")
  for (i in 1:nrow(issues)) {
    log_message(glue("  {issues$database[i]} / {issues$table[i]}: {issues$status[i]}"))
  }
} else {
  log_message("\n✓ All tables passed validation")
}

# ==============================================================================
# COMPLETION
# ==============================================================================

log_message("\n=== MERGE COMPLETE ===")
log_message(glue("Total databases merged: {length(db_files)}"))
log_message("All output files saved to dataset/")
log_message("Check dataset/merge_execution.log for full details")
log_message("Check dataset/merge_validation.csv for validation data")

# Print completion timestamp
log_message(glue("Completed at: {format(Sys.time(), '%Y-%m-%d %H:%M:%S')}"))
