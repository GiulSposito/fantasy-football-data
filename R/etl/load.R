# =============================================================================
# LOADING FUNCTIONS FOR DUDES → APP TRANSFORMATION
# =============================================================================
# Script: load.R
# Purpose: Phase 3 - Load and validate dm objects to app/ directory
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(dm)
library(fs)
library(glue)

# Source utilities (but NOT config - it's passed as parameter)
source("R/etl_v2/utils_transform.R")

# Validate dm Object ------------------------------------------------------

validate_dm_object <- function(dm_obj, db_name, config) {
  log_message(glue("Validating {db_name}..."), "info")

  validation_passed <- TRUE

  # 1. Check constraints
  log_message("  Checking constraints...", "debug")

  tryCatch(
    {
      constraints <- dm_examine_constraints(dm_obj)

      failed_constraints <- constraints |>
        filter(!ok)

      if (nrow(failed_constraints) > 0) {
        log_message(glue("  {nrow(failed_constraints)} constraint violations in {db_name}:"), "warning")
        print(failed_constraints)

        if (config$strict_mode && !config$test_mode) {
          validation_passed <- FALSE
        }
      } else {
        log_message("  All constraints valid", "success")
      }
    },
    error = function(e) {
      log_message(glue("  Constraint check failed: {e$message}"), "warning")
      log_message(glue("  Full error: {conditionMessage(e)}"), "debug")

      if (config$strict_mode && !config$test_mode) {
        validation_passed <- FALSE
      }
    }
  )

  # 2. Check cardinalities (ALWAYS - no longer optional)
  log_message("  Checking cardinalities...", "debug")

  tryCatch(
    {
      cardinalities <- dm_examine_cardinalities(dm_obj)

      cardinality_issues <- cardinalities |>
        filter(all_many_to_many)  # Identify problematic many-to-many relationships

      if (nrow(cardinality_issues) > 0) {
        log_message(glue("  {nrow(cardinality_issues)} cardinality issues in {db_name}:"), "warning")
        print(cardinality_issues)

        # ✅ F11 FIX: Provide correction hints for cardinality issues
        for (i in seq_len(nrow(cardinality_issues))) {
          issue <- cardinality_issues[i, ]
          log_message(
            glue("  → {issue$child_table} -> {issue$parent_table}: Check for duplicate keys or missing compound PK"),
            "warning"
          )
          log_message(
            glue("     To investigate: dm_enum_pk_candidates({issue$child_table})"),
            "info"
          )
        }

        # In test_mode: warning only
        # In production strict_mode: fail
        if (config$strict_mode && !config$test_mode) {
          validation_passed <- FALSE
        }
      } else {
        log_message("  All cardinalities valid", "success")
      }
    },
    error = function(e) {
      log_message(glue("  Cardinality check failed: {e$message}"), "error")

      # In test_mode: warning only
      # In production strict_mode: fail
      if (config$strict_mode && !config$test_mode) {
        validation_passed <- FALSE
      }
    }
  )

  # 3. Check record counts
  log_message("  Checking record counts...", "debug")

  table_names <- names(dm_obj)
  counts <- map_int(table_names, ~ nrow(dm_obj[[.x]]))
  names(counts) <- table_names

  for (table_name in table_names) {
    count <- counts[[table_name]]

    threshold_name <- paste0(db_name, "_", table_name)
    threshold <- config$validation$min_records[[threshold_name]]

    if (!is.null(threshold) && count < threshold) {
      log_message(
        glue("  {table_name} has {count} rows (expected >= {threshold})"),
        "warning"
      )

      if (config$strict_mode) {
        validation_passed <- FALSE
      }
    }
  }

  log_message(glue("  Record counts: {paste(names(counts), counts, sep = '=', collapse = ', ')}"), "debug")

  # Return validation result
  list(
    passed = validation_passed,
    constraints = constraints,
    counts = counts
  )
}

# Load Single Database ----------------------------------------------------

load_database <- function(dm_obj, db_name, target_dir, config) {
  log_section(glue("Loading {db_name}"))

  # Validate first
  validation <- validate_dm_object(dm_obj, db_name, config)

  if (!validation$passed && config$strict_mode) {
    log_message(glue("Validation failed for {db_name} in strict mode - aborting"), "error")
    return(FALSE)
  }

  # Save to target directory
  output_file <- path(target_dir, glue("{db_name}.rds"))

  success <- safe_write_rds(dm_obj, output_file, compress = "xz")

  if (success) {
    # Log summary
    file_size <- fs::file_size(output_file)
    table_count <- length(dm_obj)
    row_count <- sum(validation$counts)

    log_message(
      glue("{db_name}: {table_count} tables, {row_count} total rows, {format(file_size, units = 'MB')}"),
      "success"
    )
  }

  success
}

# Load All Databases ------------------------------------------------------

load_all <- function(transformed_data, config) {
  log_section("PHASE 3: LOADING")

  target_dir <- config$target_dir

  # Ensure target directory exists
  if (!dir_exists(target_dir)) {
    log_message(glue("Creating target directory: {target_dir}"), "info")
    dir_create(target_dir)
  }

  # ✅ Modern purrr: map instead of for loop
  databases <- names(transformed_data)

  results <- set_names(databases) |>
    map(\(db_name) {
      dm_obj <- transformed_data[[db_name]]
      load_database(dm_obj, db_name, target_dir, config)
    })

  # Summary
  successes <- sum(unlist(results))
  total <- length(results)

  if (successes == total) {
    log_message(glue("All {total} databases loaded successfully!"), "success")
  } else {
    log_message(glue("{successes}/{total} databases loaded successfully"), "warning")
  }

  # Save checkpoint
  if (config$save_intermediate) {
    create_checkpoint("loading", results, config$checkpoint_dir)
  }

  results
}

# Generate Summary Report -------------------------------------------------

generate_summary_report <- function(transformed_data, loading_results, config) {
  log_section("Generating Summary Report")

  report_lines <- c()

  report_lines <- c(
    report_lines,
    "# ETL Transformation Summary Report",
    "",
    glue("**Generated:** {Sys.time()}"),
    glue("**Source:** {config$source_dir}"),
    glue("**Target:** {config$target_dir}"),
    glue("**Season:** {config$season}"),
    "",
    "## Database Summary",
    ""
  )

  for (db_name in names(transformed_data)) {
    dm_obj <- transformed_data[[db_name]]
    loaded <- loading_results[[db_name]]

    table_names <- names(dm_obj)
    counts <- map_int(table_names, ~ nrow(dm_obj[[.x]]))

    total_rows <- sum(counts)

    status <- if (loaded) "✅" else "❌"

    report_lines <- c(
      report_lines,
      glue("### {status} {db_name}"),
      ""
    )

    report_lines <- c(
      report_lines,
      "| Table | Rows |",
      "|-------|------|"
    )

    for (i in seq_along(table_names)) {
      report_lines <- c(
        report_lines,
        glue("| `{table_names[i]}` | {format(counts[i], big.mark = ',')} |")
      )
    }

    report_lines <- c(
      report_lines,
      glue("| **Total** | **{format(total_rows, big.mark = ',')}** |"),
      ""
    )
  }

  # Write report
  report_file <- path(config$target_dir, "ETL_SUMMARY.md")
  writeLines(report_lines, report_file)

  log_message(glue("Summary report saved to {report_file}"), "success")

  report_file
}

# Export ------------------------------------------------------------------

list(
  load_all = load_all,
  load_database = load_database,
  validate_dm_object = validate_dm_object,
  generate_summary_report = generate_summary_report
)
