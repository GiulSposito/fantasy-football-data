#!/usr/bin/env Rscript
# Dataset Investigation Script
# Purpose: Analyze data integrity, completeness, and model compliance

library(tidyverse)
library(dm)
library(glue)

# Helper function to safely get table info
safe_table_info <- function(dm_obj, table_name) {
  tryCatch({
    tbl <- dm_obj[[table_name]]
    list(
      name = table_name,
      rows = nrow(tbl),
      cols = ncol(tbl),
      size_bytes = object.size(tbl),
      columns = names(tbl),
      success = TRUE
    )
  }, error = function(e) {
    list(
      name = table_name,
      error = as.character(e),
      success = FALSE
    )
  })
}

# Helper function to get data range
get_data_range <- function(dm_obj, table_name) {
  tryCatch({
    tbl <- dm_obj[[table_name]]

    result <- list(table = table_name)

    # Check for season column
    if ("season" %in% names(tbl)) {
      result$seasons <- tbl %>%
        pull(season) %>%
        unique() %>%
        sort()
      result$season_range <- paste(min(result$seasons), "-", max(result$seasons))
    }

    # Check for week column
    if ("week" %in% names(tbl)) {
      result$weeks <- tbl %>%
        pull(week) %>%
        unique() %>%
        sort()
      result$week_range <- paste(min(result$weeks), "-", max(result$weeks))
    }

    # Check for timestamp
    if ("timestamp" %in% names(tbl)) {
      timestamps <- tbl %>% pull(timestamp)
      result$first_timestamp <- min(timestamps, na.rm = TRUE)
      result$last_timestamp <- max(timestamps, na.rm = TRUE)
      result$unique_timestamps <- length(unique(timestamps))
    }

    result$success <- TRUE
    result
  }, error = function(e) {
    list(
      table = table_name,
      error = as.character(e),
      success = FALSE
    )
  })
}

# Helper function to calculate completeness
calculate_completeness <- function(dm_obj, table_name) {
  tryCatch({
    tbl <- dm_obj[[table_name]]

    na_counts <- tbl %>%
      summarise(across(everything(), ~sum(is.na(.)))) %>%
      pivot_longer(everything(), names_to = "column", values_to = "na_count")

    total_rows <- nrow(tbl)

    na_counts %>%
      mutate(
        table = table_name,
        total_rows = total_rows,
        completeness_pct = (1 - na_count / total_rows) * 100,
        na_pct = (na_count / total_rows) * 100
      ) %>%
      select(table, column, total_rows, na_count, na_pct, completeness_pct)
  }, error = function(e) {
    tibble(
      table = table_name,
      error = as.character(e)
    )
  })
}

# Main investigation function
investigate_database <- function(db_path, db_name) {
  cat("\n============================================================\n")
  cat(glue("Investigating: {db_name}\n"))
  cat(glue("Path: {db_path}\n"))
  cat("============================================================\n\n")

  if (!file.exists(db_path)) {
    cat(glue("❌ File not found: {db_path}\n"))
    return(NULL)
  }

  # Load database
  cat("Loading database...\n")
  db <- readRDS(db_path)

  # Get table names
  table_names <- names(db)
  cat(glue("Tables found: {length(table_names)}\n"))
  cat(glue("  {paste(table_names, collapse = ', ')}\n\n"))

  # Collect all information
  results <- list(
    database = db_name,
    path = db_path,
    file_size = file.size(db_path),
    tables = list()
  )

  # Process each table
  for (tbl_name in table_names) {
    cat(glue("\n--- Table: {tbl_name} ---\n"))

    # Basic info
    info <- safe_table_info(db, tbl_name)
    cat(glue("  Rows: {info$rows}\n"))
    cat(glue("  Columns: {info$cols}\n"))
    cat(glue("  Size: {format(info$size_bytes, units = 'auto')}\n"))

    # Data range
    range_info <- get_data_range(db, tbl_name)
    if (!is.null(range_info$season_range)) {
      cat(glue("  Seasons: {range_info$season_range}\n"))
    }
    if (!is.null(range_info$week_range)) {
      cat(glue("  Weeks: {range_info$week_range}\n"))
    }
    if (!is.null(range_info$unique_timestamps)) {
      cat(glue("  Timestamps: {range_info$unique_timestamps} unique\n"))
      cat(glue("  First: {range_info$first_timestamp}\n"))
      cat(glue("  Last: {range_info$last_timestamp}\n"))
    }

    # Completeness
    completeness <- calculate_completeness(db, tbl_name)
    avg_completeness <- mean(completeness$completeness_pct, na.rm = TRUE)
    cat(glue("  Avg Completeness: {round(avg_completeness, 2)}%\n"))

    # Columns with high NA %
    high_na_cols <- completeness %>%
      filter(na_pct > 50) %>%
      arrange(desc(na_pct))

    if (nrow(high_na_cols) > 0) {
      cat("  ⚠️  Columns with >50% NA:\n")
      high_na_cols %>%
        head(5) %>%
        mutate(msg = glue("     {column}: {round(na_pct, 1)}% NA")) %>%
        pull(msg) %>%
        walk(cat, "\n")
    }

    # Store results
    results$tables[[tbl_name]] <- list(
      info = info,
      range = range_info,
      completeness = completeness,
      avg_completeness = avg_completeness
    )
  }

  results
}

# Main execution
cat("\n")
cat("#############################################################\n")
cat("#           DATASET INVESTIGATION REPORT                   #\n")
cat("#############################################################\n")

# Define databases to investigate
databases <- tribble(
  ~name,                    ~path,
  "app_2023-24-25_ffa",     "app/2023-24-25/ffa_db.rds",
  "app_2023-24-25_nfl_teams",     "app/2023-24-25/nfl_teams_db.rds",
  "app_2023-24-25_nfl_players",   "app/2023-24-25/nfl_players_db.rds",
  "app_2023-24-25_nfl_stats",     "app/2023-24-25/nfl_stats_db.rds",
  "app_2023-24-25_nfl_round",     "app/2023-24-25/nfl_round_db.rds",
  "app_2023-24-25_nfl_recap",     "app/2023-24-25/nfl_recap_db.rds",
  "app_2023-24-25_dudes_simulation", "app/2023-24-25/dudes_simulation_db.rds",
  "etl_2023_ffa",           "etl/2023/ffa_db.rds",
  "etl_2023_nfl_teams",     "etl/2023/nfl_teams_db.rds",
  "etl_2023_nfl_players",   "etl/2023/nfl_players_db.rds",
  "etl_2023_nfl_stats",     "etl/2023/nfl_stats_db.rds",
  "etl_2023_nfl_round",     "etl/2023/nfl_round_db.rds",
  "etl_2023_nfl_recap",     "etl/2023/nfl_recap_db.rds",
  "etl_2023_dudes_simulation", "etl/2023/dudes_simulation_db.rds"
)

# Process each database
all_results <- list()
for (i in seq_len(nrow(databases))) {
  db_info <- databases[i, ]
  result <- investigate_database(db_info$path, db_info$name)
  all_results[[db_info$name]] <- result
}

# Save results
saveRDS(all_results, "dataset/investigation_results.rds")

cat("\n\n")
cat("✅ Investigation complete!\n")
cat("Results saved to: dataset/investigation_results.rds\n")

# Generate summary report
cat("\n")
cat("#############################################################\n")
cat("#                   SUMMARY REPORT                          #\n")
cat("#############################################################\n\n")

# Create summary table
summary_df <- map_dfr(names(all_results), function(db_name) {
  result <- all_results[[db_name]]
  if (is.null(result)) return(NULL)

  map_dfr(names(result$tables), function(tbl_name) {
    tbl_info <- result$tables[[tbl_name]]
    tibble(
      database = db_name,
      table = tbl_name,
      rows = tbl_info$info$rows,
      cols = tbl_info$info$cols,
      avg_completeness = round(tbl_info$avg_completeness, 2),
      season_range = tbl_info$range$season_range %||% "N/A",
      week_range = tbl_info$range$week_range %||% "N/A"
    )
  })
})

print(summary_df)

# Save as CSV
write_csv(summary_df, "dataset/investigation_summary.csv")
cat("\n\n✅ Summary saved to: dataset/investigation_summary.csv\n")
