#!/usr/bin/env Rscript
# =============================================================================
# MAIN ETL SCRIPT: DUDES → APP TRANSFORMATION
# =============================================================================
# Script: transform_dudes_to_app.R
# Purpose: Complete ETL pipeline to transform dudes/ format to app/ format
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
#
# Usage:
#   Rscript R/etl/transform_dudes_to_app.R
#   or source("R/etl/transform_dudes_to_app.R")
# =============================================================================

# Setup -------------------------------------------------------------------

# Load required packages
suppressPackageStartupMessages({
  library(tidyverse)
  library(dm)
  library(fs)
  library(glue)
  library(cli)
  library(lubridate)
})

# Set working directory to project root
if (interactive()) {
  setwd(here::here())
}

# Source all modules
source("R/etl/config_transform.R")
source("R/etl/utils_transform.R")
source("R/etl/extract.R")
source("R/etl/transform.R")
source("R/etl/load.R")

# Main Pipeline -----------------------------------------------------------

main <- function(config = ETL_CONFIG) {
  cli_h1("DUDES → APP ETL TRANSFORMATION PIPELINE")

  start_time <- Sys.time()

  # Display configuration
  cli_h2("Configuration")
  cli_ul(c(
    glue("Source: {config$source_dir}"),
    glue("Target: {config$target_dir}"),
    glue("Season: {config$season}"),
    glue("Weeks: {min(config$weeks)}-{max(config$weeks)}"),
    glue("Parallel: {config$parallel}"),
    glue("Strict mode: {config$strict_mode}")
  ))

  cli_text("")

  # Check if checkpoint exists
  if (config$save_intermediate) {
    checkpoints <- list_checkpoints(config$checkpoint_dir)

    if (length(checkpoints) > 0) {
      cli_alert_info("Found existing checkpoints:")
      cli_ul(checkpoints)

      if (interactive()) {
        response <- readline("Resume from checkpoint? (y/n): ")

        if (tolower(response) == "y") {
          checkpoint_name <- readline("Enter checkpoint name (extraction/transformation/loading): ")

          checkpoint_data <- load_checkpoint(checkpoint_name, config$checkpoint_dir)

          if (!is.null(checkpoint_data)) {
            cli_alert_success(glue("Resumed from checkpoint: {checkpoint_name}"))

            # Skip to appropriate phase
            if (checkpoint_name == "extraction") {
              extracted_data <- checkpoint_data
              goto_transform <- TRUE
            } else if (checkpoint_name == "transformation") {
              transformed_data <- checkpoint_data
              goto_load <- TRUE
            }
          }
        } else {
          clear_checkpoints(config$checkpoint_dir)
        }
      }
    }
  }

  # Phase 1: Extraction
  if (!exists("goto_transform")) {
    cli_h2("Phase 1: Extraction")

    tryCatch(
      {
        extracted_data <- extract_all(config)

        cli_alert_success("Extraction completed successfully")
        cli_text("")
      },
      error = function(e) {
        cli_alert_danger(glue("Extraction failed: {e$message}"))
        cli_text(e$trace)
        stop("Pipeline aborted due to extraction error")
      }
    )
  }

  # Phase 2: Transformation
  if (!exists("goto_load")) {
    cli_h2("Phase 2: Transformation")

    tryCatch(
      {
        transformed_data <- transform_all(extracted_data, config)

        cli_alert_success("Transformation completed successfully")
        cli_text("")
      },
      error = function(e) {
        cli_alert_danger(glue("Transformation failed: {e$message}"))
        cli_text(e$trace)
        stop("Pipeline aborted due to transformation error")
      }
    )
  }

  # Phase 3: Loading
  cli_h2("Phase 3: Loading & Validation")

  tryCatch(
    {
      loading_results <- load_all(transformed_data, config)

      cli_alert_success("Loading completed successfully")
      cli_text("")
    },
    error = function(e) {
      cli_alert_danger(glue("Loading failed: {e$message}"))
      cli_text(e$trace)
      stop("Pipeline aborted due to loading error")
    }
  )

  # Generate summary report
  cli_h2("Summary Report")

  report_file <- generate_summary_report(
    transformed_data,
    loading_results,
    config
  )

  cli_alert_success(glue("Summary report: {report_file}"))

  # Completion
  end_time <- Sys.time()
  duration <- as.numeric(difftime(end_time, start_time, units = "mins"))

  cli_text("")
  cli_rule()
  cli_alert_success(glue("Pipeline completed in {round(duration, 2)} minutes"))

  # Clean up checkpoints
  if (config$save_intermediate && interactive()) {
    response <- readline("Clear checkpoints? (y/n): ")

    if (tolower(response) == "y") {
      clear_checkpoints(config$checkpoint_dir)
      cli_alert_info("Checkpoints cleared")
    }
  }

  invisible(list(
    extracted = extracted_data,
    transformed = transformed_data,
    loaded = loading_results,
    report = report_file
  ))
}

# Batch Processing Function -----------------------------------------------

run_batch <- function(weeks, config = ETL_CONFIG) {
  # Process weeks in batches

  batch_size <- config$batch_size
  n_batches <- ceiling(length(weeks) / batch_size)

  cli_h2(glue("Running {n_batches} batches of {batch_size} weeks"))

  results <- list()

  for (i in seq_len(n_batches)) {
    start_idx <- (i - 1) * batch_size + 1
    end_idx <- min(i * batch_size, length(weeks))

    batch_weeks <- weeks[start_idx:end_idx]

    cli_alert_info(glue("Batch {i}/{n_batches}: weeks {paste(batch_weeks, collapse = ', ')}"))

    # Create batch config
    batch_config <- config
    batch_config$weeks <- batch_weeks

    # Run pipeline for batch
    results[[i]] <- main(batch_config)
  }

  results
}

# Test Mode ---------------------------------------------------------------

test_pipeline <- function() {
  # Run pipeline with a single week for testing

  cli_h1("TEST MODE - Single Week")

  test_config <- ETL_CONFIG
  test_config$weeks <- 1  # Only process week 1
  test_config$strict_mode <- FALSE  # Don't fail on validation errors

  # Debug: verify config
  cli_alert_info("DEBUG: test_config$weeks = {paste(test_config$weeks, collapse=', ')}")
  cli_alert_info("DEBUG: test_config$strict_mode = {test_config$strict_mode}")

  main(test_config)
}

# Run Pipeline ------------------------------------------------------------

# Only auto-run if called directly as Rscript, not when sourced
if (!interactive() && !exists(".etl_sourced")) {
  # Running as script
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) > 0 && args[1] == "--test") {
    test_pipeline()
  } else if (length(args) > 0 && args[1] == "--batch") {
    run_batch(ETL_CONFIG$weeks, ETL_CONFIG)
  } else {
    main(ETL_CONFIG)
  }
} else if (interactive()) {
  # Interactive mode - display help
  cli_h1("DUDES → APP ETL Pipeline")
  cli_text("Available functions:")
  cli_ul(c(
    "main() - Run full pipeline",
    "test_pipeline() - Test with week 1 only",
    "run_batch(weeks) - Process weeks in batches",
    "clear_checkpoints(ETL_CONFIG$checkpoint_dir) - Clear saved checkpoints"
  ))
  cli_text("")
  cli_text("To start: main()")
}

# Mark that this file has been sourced
.etl_sourced <- TRUE
