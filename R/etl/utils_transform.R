# =============================================================================
# UTILITY FUNCTIONS FOR DUDES → APP TRANSFORMATION
# =============================================================================
# Script: utils_transform.R
# Purpose: Helper functions for ETL pipeline
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(fs)
library(glue)
library(cli)
library(rlang)

# Logging Functions -------------------------------------------------------

log_message <- function(msg, level = "info") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

  switch(level,
    debug = cli_alert_info(paste0("[DEBUG] ", msg)),
    info = cli_alert_info(msg),
    warning = cli_alert_warning(msg),
    error = cli_alert_danger(msg),
    success = cli_alert_success(msg)
  )
}

log_section <- function(title) {
  cli_rule(title)
}

log_progress <- function(current, total, prefix = "Processing") {
  pct <- round(current / total * 100, 1)
  cli_progress_step(
    glue("{prefix}: {current}/{total} ({pct}%)"),
    msg_done = glue("Completed {total} items")
  )
}

# File Operations ---------------------------------------------------------

safe_read_rds <- function(file_path, default = NULL) {
  tryCatch(
    {
      if (file_exists(file_path)) {
        readRDS(file_path)
      } else {
        log_message(glue("File not found: {file_path}"), "warning")
        default
      }
    },
    error = function(e) {
      log_message(glue("Error reading {file_path}: {e$message}"), "error")
      default
    }
  )
}

safe_write_rds <- function(object, file_path, compress = "xz") {
  tryCatch(
    {
      # Ensure directory exists
      dir_create(path_dir(file_path))

      saveRDS(object, file_path, compress = compress)

      size <- fs::file_size(file_path)
      log_message(glue("Saved {path_file(file_path)} ({format(size, units = 'MB')})"), "success")

      TRUE
    },
    error = function(e) {
      log_message(glue("Error writing {file_path}: {e$message}"), "error")
      FALSE
    }
  )
}

# Checkpoint Management ---------------------------------------------------

create_checkpoint <- function(name, data, checkpoint_dir) {
  if (!dir_exists(checkpoint_dir)) {
    dir_create(checkpoint_dir)
  }

  checkpoint_file <- path(checkpoint_dir, glue("{name}.rds"))
  safe_write_rds(data, checkpoint_file)

  log_message(glue("Checkpoint saved: {name}"), "debug")
}

load_checkpoint <- function(name, checkpoint_dir) {
  checkpoint_file <- path(checkpoint_dir, glue("{name}.rds"))

  if (file_exists(checkpoint_file)) {
    log_message(glue("Loading checkpoint: {name}"), "debug")
    safe_read_rds(checkpoint_file)
  } else {
    NULL
  }
}

list_checkpoints <- function(checkpoint_dir) {
  if (!dir_exists(checkpoint_dir)) {
    return(character(0))
  }

  dir_ls(checkpoint_dir, regexp = "\\.rds$") |>
    path_file() |>
    path_ext_remove()
}

clear_checkpoints <- function(checkpoint_dir) {
  if (dir_exists(checkpoint_dir)) {
    dir_delete(checkpoint_dir)
    log_message("All checkpoints cleared", "info")
  }
}

# Tag Inference -----------------------------------------------------------

infer_tag_from_filename <- function(filename, rules = TAG_INFERENCE_RULES) {
  for (i in seq_len(nrow(rules))) {
    pattern <- rules$pattern[i]
    tag <- rules$tag[i]

    if (str_detect(filename, fixed(pattern))) {
      return(tag)
    }
  }

  "unknown"
}

infer_tag_from_timestamp <- function(timestamp, week_start) {
  # Infer tag based on time of week
  # (Simple heuristic - can be enhanced)

  if (is.na(timestamp) || is.na(week_start)) {
    return("unknown")
  }

  day_of_week <- wday(timestamp, label = TRUE)
  hour <- hour(timestamp)

  case_when(
    day_of_week == "Thu" & hour < 20 ~ "preTNF",
    day_of_week == "Thu" & hour >= 20 ~ "posTNF",
    day_of_week == "Sun" & hour < 13 ~ "preSundayGames",
    day_of_week == "Sun" & hour >= 13 ~ "posSNF",
    day_of_week == "Mon" & hour < 20 ~ "preMNF",
    day_of_week == "Mon" & hour >= 20 ~ "posMNF",
    day_of_week == "Tue" ~ "final",
    TRUE ~ "unknown"
  )
}

# Validation Functions ----------------------------------------------------

validate_required_columns <- function(df, required_cols, table_name) {
  missing_cols <- setdiff(required_cols, names(df))

  if (length(missing_cols) > 0) {
    log_message(
      glue("Missing required columns in {table_name}: {paste(missing_cols, collapse = ', ')}"),
      "error"
    )
    return(FALSE)
  }

  TRUE
}

validate_no_duplicates <- function(df, key_cols, table_name) {
  duplicates <- df |>
    group_by(across(all_of(key_cols))) |>
    filter(n() > 1) |>
    ungroup()

  if (nrow(duplicates) > 0) {
    log_message(
      glue("Found {nrow(duplicates)} duplicate rows in {table_name}"),
      "warning"
    )
    return(FALSE)
  }

  TRUE
}

validate_no_nulls <- function(df, non_null_cols, table_name) {
  null_summary <- df |>
    summarise(across(all_of(non_null_cols), ~ sum(is.na(.x)))) |>
    pivot_longer(everything(), names_to = "column", values_to = "null_count") |>
    filter(null_count > 0)

  if (nrow(null_summary) > 0) {
    log_message(
      glue("Found NULLs in non-nullable columns of {table_name}:"),
      "warning"
    )
    print(null_summary)
    return(FALSE)
  }

  TRUE
}

validate_count_threshold <- function(df, min_count, table_name) {
  actual_count <- nrow(df)

  if (actual_count < min_count) {
    log_message(
      glue("{table_name} has {actual_count} rows (expected >= {min_count})"),
      "warning"
    )
    return(FALSE)
  }

  TRUE
}

# ID Mapping Functions ----------------------------------------------------

extract_player_id_from_source <- function(id_string, id_type) {
  # Clean and convert ID based on type
  if (is.na(id_string) || id_string == "" || id_string == "0") {
    return(NA_character_)
  }

  switch(id_type,
    integer = as.character(as.integer(id_string)),
    character = as.character(id_string),
    as.character(id_string)
  )
}

consolidate_player_ids <- function(...) {
  # Combine multiple ID sources into single mapping table
  id_sources <- list(...)

  # Stack all sources
  all_ids <- bind_rows(id_sources, .id = "source") |>
    distinct()

  # Pivot to wide format
  id_map <- all_ids |>
    group_by(id) |>
    summarise(
      across(
        everything(),
        ~ first(na.omit(.x)),
        .names = "{.col}"
      ),
      .groups = "drop"
    )

  id_map
}

# Denormalization Functions -----------------------------------------------

unnest_week_stats <- function(df) {
  # Unnest nested weekStats column from players_points.rds
  # weekStats is a list of lists: list[[week]][[statId]] = value

  if (!"weekStats" %in% names(df)) {
    log_message("No weekStats column found", "warning")
    return(tibble())
  }

  df |>
    select(playerId, weekStats) |>
    filter(!map_lgl(weekStats, is.null)) |>
    mutate(
      # Convert weekStats list to long format
      stats_long = map(weekStats, function(week_list) {
        # week_list is a list of weeks, each week is a named list of stats
        map_dfr(seq_along(week_list), function(week_idx) {
          week_stats <- week_list[[week_idx]]
          if (is.null(week_stats) || length(week_stats) == 0) {
            return(tibble())
          }
          tibble(
            week = week_idx,
            statId = names(week_stats),
            value = as.character(week_stats)
          )
        })
      })
    ) |>
    select(-weekStats) |>
    unnest(stats_long) |>
    filter(!is.na(statId), statId != "pts") |>  # Remove pts (already in main table)
    mutate(
      statId = as.integer(statId),
      value = as.numeric(value)
    )
}

unnest_advanced_stats <- function(df) {
  # Unnest nested advanced stats column

  if (!"advanced" %in% names(df)) {
    log_message("No advanced column found", "warning")
    return(tibble())
  }

  df |>
    select(playerId, week, advanced) |>
    filter(!map_lgl(advanced, is.null)) |>
    unnest_wider(advanced, names_sep = "_") |>
    # Remove advanced_week column to prevent conflict with existing week column
    # after rename_with() strips "advanced_" prefix in transform.R
    select(-any_of("advanced_week"))
}

unnest_rosters <- function(df) {
  # Unnest nested rosters from teams data

  if (!"rosters" %in% names(df)) {
    log_message("No rosters column found", "warning")
    return(tibble())
  }

  df |>
    select(teamId, week, rosters) |>
    filter(!map_lgl(rosters, is.null)) |>
    unnest(rosters)
}

# Data Aggregation Functions ----------------------------------------------

aggregate_projections_by_avg_type <- function(projections, avg_type = "average") {
  # Aggregate projections using different methods

  grouped <- projections |>
    group_by(season, week, timestamp, id, pos)

  result <- switch(avg_type,
    average = grouped |>
      summarise(
        points = mean(pts.proj, na.rm = TRUE),
        sd_pts = sd(pts.proj, na.rm = TRUE),
        floor = quantile(pts.proj, 0.25, na.rm = TRUE),
        ceiling = quantile(pts.proj, 0.75, na.rm = TRUE),
        .groups = "drop"
      ),

    robust = grouped |>
      summarise(
        points = median(pts.proj, na.rm = TRUE),
        sd_pts = IQR(pts.proj, na.rm = TRUE) / 1.349,  # Robust SD
        floor = quantile(pts.proj, 0.15, na.rm = TRUE),
        ceiling = quantile(pts.proj, 0.85, na.rm = TRUE),
        .groups = "drop"
      ),

    weighted = {
      # Simplified weighted average (can be enhanced with actual weights)
      grouped |>
        summarise(
          points = mean(pts.proj, na.rm = TRUE),
          sd_pts = sd(pts.proj, na.rm = TRUE),
          floor = quantile(pts.proj, 0.25, na.rm = TRUE),
          ceiling = quantile(pts.proj, 0.75, na.rm = TRUE),
          .groups = "drop"
        )
    },

    # Default to average
    grouped |>
      summarise(
        points = mean(pts.proj, na.rm = TRUE),
        sd_pts = sd(pts.proj, na.rm = TRUE),
        floor = quantile(pts.proj, 0.25, na.rm = TRUE),
        ceiling = quantile(pts.proj, 0.75, na.rm = TRUE),
        .groups = "drop"
      )
  )

  result |>
    mutate(avg_type = avg_type)
}

calculate_ranks_and_tiers <- function(projections, n_tiers = 10) {
  # Calculate ranks and tiers within each position

  projections |>
    group_by(season, week, timestamp, avg_type, pos) |>
    mutate(
      rank = dense_rank(desc(points)),
      pos_rank = row_number(desc(points)),
      tier = ntile(desc(points), n_tiers)
    ) |>
    ungroup()
}

# Export functions --------------------------------------------------------

list(
  log_message = log_message,
  log_section = log_section,
  log_progress = log_progress,
  safe_read_rds = safe_read_rds,
  safe_write_rds = safe_write_rds,
  create_checkpoint = create_checkpoint,
  load_checkpoint = load_checkpoint,
  list_checkpoints = list_checkpoints,
  clear_checkpoints = clear_checkpoints,
  infer_tag_from_filename = infer_tag_from_filename,
  infer_tag_from_timestamp = infer_tag_from_timestamp,
  validate_required_columns = validate_required_columns,
  validate_no_duplicates = validate_no_duplicates,
  validate_no_nulls = validate_no_nulls,
  validate_count_threshold = validate_count_threshold,
  extract_player_id_from_source = extract_player_id_from_source,
  consolidate_player_ids = consolidate_player_ids,
  unnest_week_stats = unnest_week_stats,
  unnest_advanced_stats = unnest_advanced_stats,
  unnest_rosters = unnest_rosters,
  aggregate_projections_by_avg_type = aggregate_projections_by_avg_type,
  calculate_ranks_and_tiers = calculate_ranks_and_tiers
)
