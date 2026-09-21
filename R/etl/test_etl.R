# =============================================================================
# TEST SCRIPT FOR ETL PIPELINE
# =============================================================================
# Script: test_etl.R
# Purpose: Quick tests to validate ETL pipeline structure
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(fs)
library(glue)
library(testthat)

# Test 1: Check all required files exist ------------------------------

test_that("All ETL files exist", {
  required_files <- c(
    "R/etl/config_transform.R",
    "R/etl/utils_transform.R",
    "R/etl/extract.R",
    "R/etl/transform.R",
    "R/etl/load.R",
    "R/etl/transform_dudes_to_app.R",
    "R/etl/README.md"
  )

  for (file in required_files) {
    expect_true(
      file_exists(file),
      info = glue("Missing file: {file}")
    )
  }
})

# Test 2: Check configuration loads ------------------------------------

test_that("Configuration loads without errors", {
  expect_error(
    source("R/etl/config_transform.R"),
    NA  # No error expected
  )

  # Check key config elements exist
  expect_true(exists("ETL_CONFIG"))
  expect_true(exists("FILE_PATTERNS"))
  expect_true(exists("SIMULATION_PHASES"))
  expect_true(exists("TAG_INFERENCE_RULES"))
})

# Test 3: Check source directories exist -------------------------------

test_that("Source directory exists", {
  source("R/etl/config_transform.R")

  expect_true(
    dir_exists(ETL_CONFIG$source_dir),
    info = glue("Source directory not found: {ETL_CONFIG$source_dir}")
  )
})

# Test 4: Check sample files exist -------------------------------------

test_that("Sample source files exist", {
  source("R/etl/config_transform.R")

  # Check at least one weekly file exists
  sample_files <- c(
    path(ETL_CONFIG$source_dir, "week1_scrap.rds"),
    path(ETL_CONFIG$source_dir, "players_points.rds"),
    path(ETL_CONFIG$source_dir, "weekly_proj_player_site_1.rds")
  )

  files_exist <- map_lgl(sample_files, file_exists)

  expect_true(
    any(files_exist),
    info = glue("No source files found in {ETL_CONFIG$source_dir}")
  )
})

# Test 5: Check utilities load -----------------------------------------

test_that("Utility functions load", {
  source("R/etl/config_transform.R")

  expect_error(
    source("R/etl/utils_transform.R"),
    NA
  )

  # Check key functions exist
  utils <- source("R/etl/utils_transform.R")$value

  expected_functions <- c(
    "log_message",
    "safe_read_rds",
    "safe_write_rds",
    "create_checkpoint",
    "infer_tag_from_filename",
    "validate_required_columns"
  )

  for (func_name in expected_functions) {
    expect_true(
      func_name %in% names(utils),
      info = glue("Missing utility function: {func_name}")
    )
  }
})

# Test 6: Check extraction module --------------------------------------

test_that("Extraction module loads", {
  source("R/etl/config_transform.R")
  source("R/etl/utils_transform.R")

  expect_error(
    source("R/etl/extract.R"),
    NA
  )

  extract_funcs <- source("R/etl/extract.R")$value

  expected_functions <- c(
    "extract_all",
    "extract_weekly_scrapes",
    "extract_weekly_projections",
    "extract_player_points"
  )

  for (func_name in expected_functions) {
    expect_true(
      func_name %in% names(extract_funcs),
      info = glue("Missing extraction function: {func_name}")
    )
  }
})

# Test 7: Check transformation module ----------------------------------

test_that("Transformation module loads", {
  source("R/etl/config_transform.R")
  source("R/etl/utils_transform.R")

  expect_error(
    source("R/etl/transform.R"),
    NA
  )

  transform_funcs <- source("R/etl/transform.R")$value

  expected_functions <- c(
    "transform_all",
    "transform_to_ffa_db",
    "transform_to_nfl_stats_db",
    "transform_to_dudes_simulation_db"
  )

  for (func_name in expected_functions) {
    expect_true(
      func_name %in% names(transform_funcs),
      info = glue("Missing transformation function: {func_name}")
    )
  }
})

# Test 8: Check loading module -----------------------------------------

test_that("Loading module loads", {
  source("R/etl/config_transform.R")
  source("R/etl/utils_transform.R")

  expect_error(
    source("R/etl/load.R"),
    NA
  )

  load_funcs <- source("R/etl/load.R")$value

  expected_functions <- c(
    "load_all",
    "load_database",
    "validate_dm_object",
    "generate_summary_report"
  )

  for (func_name in expected_functions) {
    expect_true(
      func_name %in% names(load_funcs),
      info = glue("Missing loading function: {func_name}")
    )
  }
})

# Test 9: Check main script loads --------------------------------------

test_that("Main script loads", {
  expect_error(
    source("R/etl/transform_dudes_to_app.R"),
    NA
  )

  # Check main functions exist
  expect_true(exists("main"))
  expect_true(exists("test_pipeline"))
  expect_true(exists("run_batch"))
})

# Test 10: Dry run of extraction (week 1 only) ------------------------

test_that("Can extract week 1 data", {
  skip_if_not(
    file_exists("dudes/2025/week1_scrap.rds"),
    "Week 1 source data not available"
  )

  source("R/etl/config_transform.R")
  source("R/etl/utils_transform.R")
  source("R/etl/extract.R")

  extract_funcs <- source("R/etl/extract.R")$value

  test_config <- ETL_CONFIG
  test_config$weeks <- 1
  test_config$save_intermediate <- FALSE

  # Try extraction
  result <- tryCatch(
    {
      extract_funcs$extract_weekly_scrapes(
        test_config$source_dir,
        test_config$weeks,
        test_config
      )
    },
    error = function(e) {
      NULL
    }
  )

  expect_true(
    !is.null(result),
    info = "Extraction returned NULL"
  )

  if (!is.null(result) && is.data.frame(result)) {
    expect_true(
      nrow(result) > 0,
      info = "Extraction returned empty data.frame"
    )
  }
})

# Run all tests -----------------------------------------------------------

cat("\n")
cat("=" %R% 70, "\n")
cat("ETL PIPELINE TEST SUITE\n")
cat("=" %R% 70, "\n")
cat("\n")

test_results <- test_dir("R/etl", reporter = "summary")

cat("\n")
cat("=" %R% 70, "\n")

if (all(test_results$passed)) {
  cat("✅ ALL TESTS PASSED\n")
  cat("\nETL pipeline is ready to use!\n")
  cat("Run: source('R/etl/transform_dudes_to_app.R'); test_pipeline()\n")
} else {
  cat("❌ SOME TESTS FAILED\n")
  cat("\nPlease fix errors before running the full pipeline.\n")
}

cat("=" %R% 70, "\n")
