#!/usr/bin/env Rscript
# =============================================================================
# ETL Pipeline Runner - dudes/ → app/ transformation
# =============================================================================
# Script: run_etl_pipeline.R
# Purpose: Execute complete ETL pipeline (Extract → Transform → Load)
# Author: DudesData ETL Pipeline v2
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(dm)
library(fs)
library(glue)

# Source all ETL modules
source("R/etl_v2/config_transform.R")
source("R/etl_v2/utils_transform.R")

extract_module <- source("R/etl_v2/extract.R")$value
transform_module <- source("R/etl_v2/transform.R")$value
load_module <- source("R/etl_v2/load.R")$value

# Main execution function
main <- function(season = 2025, test_mode = TRUE) {
  log_section("ETL PIPELINE v2 - DUDES → APP")

  # Configure
  config <- ETL_CONFIG
  config$season <- season
  config$test_mode <- test_mode

  if (test_mode) {
    config$weeks <- 1  # Test mode: apenas week 1
    config$strict_mode <- FALSE  # Tolerante em teste
    log_message("Running in TEST MODE (week 1 only, non-strict validation)", "info")
  } else {
    config$weeks <- 1:17  # Production: todas as semanas
    config$strict_mode <- TRUE
    log_message("Running in PRODUCTION MODE (weeks 1-17, strict validation)", "info")
  }

  # Update paths dynamically
  config$source_dir <- glue("dudes/{season}/")
  config$target_dir <- glue("./etl/{season}/")

  # ✅ F10 FIX: Validate paths before proceeding
  tryCatch(
    {
      validate_etl_paths(config)
    },
    error = function(e) {
      cat("\n")
      cat("❌ Configuration Error:\n")
      cat(glue("   {e$message}\n"))
      cat("\n")
      quit(status = 1)
    }
  )

  # Timer
  start_time <- Sys.time()

  # EXTRACT
  extract_start <- Sys.time()
  log_section("PHASE 1: EXTRACTION")
  extracted_data <- extract_module$extract_all(config)
  extract_time <- as.numeric(difftime(Sys.time(), extract_start, units = "secs"))
  log_message(glue("Extract phase completed in {round(extract_time, 1)}s"), "success")

  # TRANSFORM
  transform_start <- Sys.time()
  log_section("PHASE 2: TRANSFORMATION")
  transformed_data <- transform_module$transform_all(extracted_data, config)
  transform_time <- as.numeric(difftime(Sys.time(), transform_start, units = "secs"))
  log_message(glue("Transform phase completed in {round(transform_time, 1)}s"), "success")

  # LOAD
  load_start <- Sys.time()
  log_section("PHASE 3: LOADING")
  loading_results <- load_module$load_all(transformed_data, config)
  load_time <- as.numeric(difftime(Sys.time(), load_start, units = "secs"))
  log_message(glue("Load phase completed in {round(load_time, 1)}s"), "success")

  # REPORT
  log_section("PHASE 4: SUMMARY")
  report_file <- load_module$generate_summary_report(transformed_data, loading_results, config)
  log_message(glue("Summary report: {report_file}"), "info")

  total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  log_message(glue("Total pipeline time: {round(total_time, 1)}s"), "success")

  # Return results
  list(
    extracted = extracted_data,
    transformed = transformed_data,
    loaded = loading_results,
    config = config
  )
}

# Execute if running as script (not sourced)
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)

  # ✅ F7 FIX: Validate arguments with helpful messages
  season <- 2025
  test_mode <- TRUE

  if (length(args) > 0) {
    season_arg <- suppressWarnings(as.integer(args[1]))
    if (is.na(season_arg)) {
      cat("\n")
      cat("❌ Invalid season argument: must be integer (e.g., 2025)\n")
      cat("Usage: Rscript run_etl_pipeline.R [season] [test_mode]\n")
      cat("  season (default: 2025) - integer year\n")
      cat("  test_mode (default: TRUE) - TRUE or FALSE\n")
      cat("\n")
      quit(status = 1)
    }
    season <- season_arg
  }

  if (length(args) > 1) {
    test_arg <- tolower(args[2])
    if (!test_arg %in% c("true", "false", "t", "f")) {
      cat("\n")
      cat("❌ Invalid test_mode argument: must be TRUE or FALSE\n")
      cat("Usage: Rscript run_etl_pipeline.R [season] [test_mode]\n")
      cat("\n")
      quit(status = 1)
    }
    test_mode <- test_arg %in% c("true", "t")
  }

  cat("\n")
  cat("╔═══════════════════════════════════════════════════════╗\n")
  cat("║          ETL Pipeline v2 - DudesData                  ║\n")
  cat("╚═══════════════════════════════════════════════════════╝\n")
  cat("\n")
  cat(glue("Season: {season}\n"))
  cat(glue("Mode: {if(test_mode) 'TEST (week 1 only)' else 'PRODUCTION (weeks 1-17)'}\n"))
  cat("\n")

  results <- tryCatch(
    {
      main(season, test_mode)
    },
    error = function(e) {
      cat("\n")
      cat("❌ Pipeline failed with error:\n")
      cat(glue("   {e$message}\n"))
      cat("\n")
      cat("Error details:\n")
      print(e)
      cat("\n")
      cat("Traceback:\n")
      print(sys.calls())
      cat("\n")
      quit(status = 1)
    }
  )

  cat("\n")
  if (all(unlist(results$loaded))) {
    cat("╔═══════════════════════════════════════════════════════╗\n")
    cat("║   ✅ Pipeline completed successfully!                ║\n")
    cat("╚═══════════════════════════════════════════════════════╝\n")
    cat("\n")
    cat(glue("Output: {results$config$target_dir}\n"))
    cat(glue("Databases: {length(results$loaded)}\n"))
    cat("\n")
    quit(status = 0)
  } else {
    failed_dbs <- names(results$loaded)[!unlist(results$loaded)]
    cat("╔═══════════════════════════════════════════════════════╗\n")
    cat("║   ⚠️  Pipeline completed with warnings               ║\n")
    cat("╚═══════════════════════════════════════════════════════╝\n")
    cat("\n")
    cat("Failed databases:\n")
    for (db in failed_dbs) {
      cat(glue("  - {db}\n"))
    }
    cat("\n")
    quit(status = 2)
  }
}
