#!/usr/bin/env Rscript
# =============================================================================
# ETL Pipeline Runner - LEGACY FORMAT (2019-2021)
# =============================================================================
# Script: run_etl_pipeline_legacy.R
# Purpose: Execute ETL pipeline for legacy data format (2019-2021)
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

extract_legacy_module <- source("R/etl_v2/extract_legacy.R")$value
transform_module <- source("R/etl_v2/transform.R")$value
load_module <- source("R/etl_v2/load.R")$value

# Main execution function
main_legacy <- function(season, test_mode = TRUE) {
  log_section("ETL PIPELINE v2 - LEGACY FORMAT (2019-2021)")

  # Configure
  config <- ETL_CONFIG
  config$season <- season
  config$test_mode <- test_mode

  # Determine weeks based on year
  if (test_mode) {
    config$weeks <- 1  # Test mode: apenas week 1
    config$strict_mode <- FALSE
    log_message("Running in TEST MODE (week 1 only, non-strict validation)", "info")
  } else {
    # Legacy years may have fewer weeks
    if (season == 2019) {
      config$weeks <- 1:16  # 2019 tinha 16 semanas
    } else {
      config$weeks <- 1:17  # 2020-2021 tinham 17 semanas
    }
    config$strict_mode <- FALSE  # Less strict for legacy data
    log_message(glue("Running in PRODUCTION MODE (weeks {min(config$weeks)}-{max(config$weeks)}, lenient validation)"), "info")
  }

  # Update paths dynamically
  config$source_dir <- glue("dudes/{season}/")
  config$target_dir <- glue("./etl/{season}/")

  # Validate paths
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

  # EXTRACT (LEGACY FORMAT)
  extract_start <- Sys.time()
  log_section("PHASE 1: EXTRACTION (LEGACY)")
  extracted_data <- extract_legacy_module$extract_all_legacy(config)
  extract_time <- as.numeric(difftime(Sys.time(), extract_start, units = "secs"))
  log_message(glue("Extract phase completed in {round(extract_time, 1)}s"), "success")

  # TRANSFORM (same as modern)
  transform_start <- Sys.time()
  log_section("PHASE 2: TRANSFORMATION")
  transformed_data <- transform_module$transform_all(extracted_data, config)
  transform_time <- as.numeric(difftime(Sys.time(), transform_start, units = "secs"))
  log_message(glue("Transform phase completed in {round(transform_time, 1)}s"), "success")

  # LOAD (same as modern)
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

  season <- 2020  # Default to 2020
  test_mode <- TRUE

  if (length(args) > 0) {
    season_arg <- suppressWarnings(as.integer(args[1]))
    if (is.na(season_arg)) {
      cat("\n")
      cat("❌ Invalid season argument: must be integer (e.g., 2020)\n")
      cat("Usage: Rscript run_etl_pipeline_legacy.R [season] [test_mode]\n")
      cat("  season (default: 2020) - integer year (2019-2021)\n")
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
      quit(status = 1)
    }
    test_mode <- test_arg %in% c("true", "t")
  }

  # Validate year range
  if (season < 2019 || season > 2021) {
    cat("\n")
    cat("⚠️  Warning: This script is for legacy years 2019-2021\n")
    cat("   For 2022+ use run_etl_pipeline.R instead\n")
    cat("\n")
    if (season < 2019 || season > 2025) {
      quit(status = 1)
    }
  }

  cat("\n")
  cat("╔═══════════════════════════════════════════════════════╗\n")
  cat("║    ETL Pipeline v2 - LEGACY FORMAT (2019-2021)       ║\n")
  cat("╚═══════════════════════════════════════════════════════╝\n")
  cat("\n")
  cat(glue("Season: {season}\n"))
  cat(glue("Mode: {if(test_mode) 'TEST (week 1 only)' else 'PRODUCTION (all weeks)'}\n"))
  cat("\n")

  results <- tryCatch(
    {
      main_legacy(season, test_mode)
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
  cat("╔═══════════════════════════════════════════════════════╗\n")
  cat("║   ✅ Pipeline completed successfully!                ║\n")
  cat("╚═══════════════════════════════════════════════════════╝\n")
  cat("\n")
  cat(glue("Output: {results$config$target_dir}\n"))
  cat(glue("Databases: {length(results$transformed)}\n"))
}
