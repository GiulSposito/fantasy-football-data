# =============================================================================
# SIMPLE TEST SCRIPT - WEEK 1 ONLY
# =============================================================================
# Quick test of ETL pipeline with minimal data
# =============================================================================

library(tidyverse)
library(dm)
library(fs)
library(cli)
library(glue)
library(lubridate)

# Source modules
source("R/etl/config_transform.R")
source("R/etl/utils_transform.R")
source("R/etl/extract.R")
source("R/etl/transform.R")
source("R/etl/load.R")

# Test Configuration
test_config <- list(
  source_dir = "dudes/2025/",
  target_dir = "app/test/",
  checkpoint_dir = ".claude/etl_checkpoints/test/",
  season = 2025,
  weeks = 1,  # ONLY WEEK 1
  parallel = FALSE,
  n_cores = 1,
  batch_size = 1,
  strict_mode = FALSE,  # Don't fail on warnings
  validate_cardinality = FALSE,
  log_level = "info",
  save_intermediate = TRUE
)

# Create target directory
dir_create(test_config$target_dir)
dir_create(test_config$checkpoint_dir)

cli_h1("ETL TEST - Week 1 Only")
cli_alert_info("Source: {test_config$source_dir}")
cli_alert_info("Target: {test_config$target_dir}")
cli_alert_info("Weeks: {test_config$weeks}")

# Phase 1: Extraction
cli_h2("Phase 1: Extraction")
extracted_data <- extract_all(test_config)
cli_alert_success("Extraction complete!")
cli_alert_info("  Scrapes: {nrow(extracted_data$scrapes)} rows")
cli_alert_info("  Projections: {nrow(extracted_data$projections)} rows")
cli_alert_info("  Simulations: {nrow(extracted_data$simulations)} rows")

# Phase 2: Transformation
cli_h2("Phase 2: Transformation")
transformed_data <- transform_all(extracted_data, test_config)
cli_alert_success("Transformation complete!")
cli_alert_info("  Generated {length(transformed_data)} databases")

# Phase 3: Loading
cli_h2("Phase 3: Loading")
loading_results <- load_all(transformed_data, test_config)
cli_alert_success("Loading complete!")

# Summary
cli_rule()
cli_alert_success("TEST COMPLETE!")
cli_text("Check output in: {test_config$target_dir}")
cli_rule()
