# =============================================================================
# TRANSFORMATION FUNCTIONS FOR DUDES → APP TRANSFORMATION
# =============================================================================
# Script: transform.R
# Purpose: Phase 2 - Transform extracted data to app/ format
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

library(tidyverse)
library(dm)
library(glue)

# Source utilities (but NOT config - it's passed as parameter)
source("R/etl_v2/utils_transform.R")

# Transform to ffa_db -----------------------------------------------------

transform_to_ffa_db <- function(extracted_data, config) {
  log_section("Transforming to ffa_db")

  scrapes <- extracted_data$scrapes
  projections <- extracted_data$projections
  proj_tables <- extracted_data$proj_tables

  # ✅ LEGACY FIX: Ensure ID columns are consistently integer type
  if (nrow(scrapes) > 0) {
    scrapes <- scrapes |> mutate(id = as.integer(id))
  }
  if (nrow(projections) > 0) {
    projections <- projections |> mutate(id = as.integer(id))
  }
  if (nrow(proj_tables) > 0) {
    proj_tables <- proj_tables |> mutate(id = as.integer(id))
  }

  # 1. ffa_scrape (metadata of scraping operations)
  log_message("Creating ffa_scrape...", "debug")

  ffa_scrape <- bind_rows(
    scrapes |> distinct(season, week, timestamp, source_file),
    projections |> distinct(season, week, timestamp, source_file)
  ) |>
    distinct(season, week, timestamp) |>
    mutate(
      tag = "final",  # Default tag - can be enhanced
      scrapeData = list(NULL)  # Placeholder for raw data
    ) |>
    arrange(season, week, timestamp)

  log_message(glue("ffa_scrape: {nrow(ffa_scrape)} records"), "info")

  # 2. ffa_player_ids (consolidate all player IDs with REAL mappings)
  log_message("Creating ffa_player_ids...", "debug")

  # Load master ID mappings from dudes/players_ids.rds
  player_ids_master_file <- "dudes/players_ids.rds"

  if (!file.exists(player_ids_master_file)) {
    log_message("WARNING: players_ids.rds not found - using placeholders", "warning")
    player_ids_master <- tibble(id = character())
  } else {
    player_ids_master <- safe_read_rds(player_ids_master_file, default = tibble(id = character()))
    log_message(glue("Loaded {nrow(player_ids_master)} player ID mappings from master file"), "info")
  }

  # Consolidate IDs from all sources (standardize to integer to match master)
  extracted_ids <- bind_rows(
    scrapes |> distinct(id) |> mutate(id = as.integer(id)),
    projections |> distinct(id) |> mutate(id = as.integer(id)),
    proj_tables |> distinct(id) |> mutate(id = as.integer(id))
  ) |>
    distinct(id) |>
    filter(!is.na(id))  # Remove any NAs from failed conversions

  # Ensure master IDs are also integer
  if (nrow(player_ids_master) > 0) {
    player_ids_master <- player_ids_master |>
      mutate(id = as.integer(id))
  }

  # Join with real mappings + fallback
  ffa_player_ids <- extracted_ids |>
    left_join(player_ids_master, by = "id") |>
    mutate(
      # Fallback: if nfl_id is NA, use id converted to character
      nfl_id = coalesce(as.character(nfl_id), as.character(id))
    )

  # ✅ F3 FIX: Check for duplicate nfl_id after fallback
  duplicated_nfl_ids <- ffa_player_ids |>
    count(nfl_id) |>
    filter(n > 1)

  if (nrow(duplicated_nfl_ids) > 0) {
    log_message(glue("WARNING: {nrow(duplicated_nfl_ids)} duplicated nfl_id values after fallback"), "warning")
    log_message("  This may cause foreign key constraint violations", "warning")
    # Log first few duplicates for debugging
    dup_examples <- duplicated_nfl_ids |> head(5) |> pull(nfl_id)
    log_message(glue("  Examples: {paste(dup_examples, collapse=', ')}"), "debug")
  }

  # Log coverage stats
  n_total <- nrow(ffa_player_ids)
  n_mapped <- sum(!is.na(player_ids_master$nfl_id[match(ffa_player_ids$id, player_ids_master$id)]))
  coverage_pct <- round(n_mapped / n_total * 100, 1)

  log_message(glue("ffa_player_ids: {n_total} records, {n_mapped} with real nfl_id ({coverage_pct}% coverage)"), "info")

  # 3. ffa_players (player metadata) - with name separation
  log_message("Creating ffa_players...", "debug")

  # Process scrapes: separate full name into first_name + last_name
  # ✅ F4 FIX: Handle single-word names and DST better
  scrapes_clean <- scrapes |>
    mutate(id = as.integer(id)) |>  # Ensure integer type
    select(id, player, pos, team) |>
    mutate(
      # For DST (position = "DST"), use full name as last_name
      is_dst = pos == "DST",
      # Split name
      name_parts = str_split(player, " ", n = 2),
      first_name = if_else(
        is_dst,
        NA_character_,
        map_chr(name_parts, ~ if (length(.x) >= 1) .x[1] else NA_character_)
      ),
      last_name = if_else(
        is_dst,
        player,  # DST: full name as last_name
        map_chr(name_parts, ~ if (length(.x) >= 2) .x[2] else .x[1])  # Single name: use as last_name
      )
    ) |>
    select(-player, -is_dst, -name_parts) |>
    mutate(source = "scrape")

  # Process proj_tables (already has first/last separated)
  # ✅ LEGACY FIX: proj_tables in legacy years may not have all these columns
  proj_tables_clean <- proj_tables |>
    mutate(id = as.integer(id)) |>  # Ensure integer type
    select(id, pos, any_of(c("first_name", "last_name", "team", "position", "age", "exp"))) |>
    mutate(
      # Add missing columns with NA if they don't exist
      first_name = if ("first_name" %in% names(proj_tables)) first_name else NA_character_,
      last_name = if ("last_name" %in% names(proj_tables)) last_name else NA_character_,
      team = if ("team" %in% names(proj_tables)) team else NA_character_,
      position = if ("position" %in% names(proj_tables)) position else NA_character_,
      age = if ("age" %in% names(proj_tables)) age else NA_integer_,
      exp = if ("exp" %in% names(proj_tables)) exp else NA_integer_,
      source = "proj_table"
    )

  # Projections (only has pos)
  projections_clean <- projections |>
    mutate(id = as.integer(id)) |>  # Ensure integer type
    select(id, pos) |>
    mutate(source = "projection")

  # Consolidate with priority: proj_table > scrape > projection
  ffa_players <- bind_rows(
    proj_tables_clean,
    scrapes_clean,
    projections_clean
  ) |>
    arrange(id, pos, desc(source == "proj_table"), desc(source == "scrape")) |>
    group_by(id, pos) |>
    summarise(
      first_name = first(first_name[!is.na(first_name)]),
      last_name = first(last_name[!is.na(last_name)]),
      team = first(team[!is.na(team)]),
      position = coalesce(first(position[!is.na(position)]), first(pos)),
      age = first(age[!is.na(age)]),
      exp = first(exp[!is.na(exp)]),
      .groups = "drop"
    )

  # Log name coverage
  n_with_first <- sum(!is.na(ffa_players$first_name))
  n_with_last <- sum(!is.na(ffa_players$last_name))
  name_coverage_pct <- round(n_with_first / nrow(ffa_players) * 100, 1)

  log_message(glue("ffa_players: {nrow(ffa_players)} records, {n_with_first} with first_name ({name_coverage_pct}%)"), "info")

  log_message(glue("ffa_players: {nrow(ffa_players)} records"), "info")

  # 4. ffa_proj_source_points (individual source projections)
  log_message("Creating ffa_proj_source_points...", "debug")

  ffa_proj_source_points <- projections |>
    select(season, week, timestamp, data_src, id, pos, points = pts.proj) |>
    mutate(tag = "final") |>
    arrange(season, week, timestamp, data_src, id)

  log_message(glue("ffa_proj_source_points: {nrow(ffa_proj_source_points)} records"), "info")

  # 5. ffa_projtable (aggregated projections with ranks/tiers)
  log_message("Creating ffa_projtable...", "debug")

  # Create average projections
  ffa_projtable_avg <- aggregate_projections_by_avg_type(
    projections,
    avg_type = "average"
  )

  # Create robust projections
  ffa_projtable_robust <- aggregate_projections_by_avg_type(
    projections,
    avg_type = "robust"
  )

  # Create weighted projections
  ffa_projtable_weighted <- aggregate_projections_by_avg_type(
    projections,
    avg_type = "weighted"
  )

  # Combine and calculate ranks/tiers (base projections)
  ffa_projtable_base <- bind_rows(
    ffa_projtable_avg,
    ffa_projtable_robust,
    ffa_projtable_weighted
  ) |>
    mutate(tag = "final") |>
    calculate_ranks_and_tiers(n_tiers = 10) |>
    # Add dropoff (difference to next player)
    group_by(season, week, timestamp, avg_type, pos) |>
    arrange(rank) |>
    mutate(
      dropoff = points - lead(points, default = 0)
    ) |>
    ungroup()

  # Extract stats from scrapes (week{X}_scrap.rds data)
  log_message("Extracting projected stats from scrapes...", "debug")

  # ✅ F5 FIX: Aggregate stats properly to avoid losing data
  # Instead of distinct() which keeps first row arbitrarily,
  # use summarise to combine stats across multiple scrapes
  scrapes_stats <- scrapes |>
    mutate(id = as.integer(id)) |>  # Ensure integer type for join
    select(
      id, pos,
      # Passing stats
      pass_att, pass_comp, pass_yds, pass_tds, pass_int,
      # Rushing stats
      rush_att, rush_yds, rush_tds,
      # Receiving stats
      rec_tgt, rec, rec_yds, rec_tds
    ) |>
    summarise(
      # Take median for most stats (more robust than mean)
      pass_att = median(pass_att, na.rm = TRUE),
      pass_comp = median(pass_comp, na.rm = TRUE),
      pass_yds = median(pass_yds, na.rm = TRUE),
      pass_tds = median(pass_tds, na.rm = TRUE),
      pass_int = median(pass_int, na.rm = TRUE),
      rush_att = median(rush_att, na.rm = TRUE),
      rush_yds = median(rush_yds, na.rm = TRUE),
      rush_tds = median(rush_tds, na.rm = TRUE),
      rec_tgt = median(rec_tgt, na.rm = TRUE),
      rec = median(rec, na.rm = TRUE),
      rec_yds = median(rec_yds, na.rm = TRUE),
      rec_tds = median(rec_tds, na.rm = TRUE),
      .by = c(id, pos)
    ) |>
    mutate(
      # Convert NaN (result of all-NA median) back to NA
      across(where(is.numeric), ~ if_else(is.nan(.x), NA_real_, .x))
    )

  # ✅ Join base projections with real stats from scrapes
  ffa_projtable <- ffa_projtable_base |>
    left_join(
      scrapes_stats,
      by = c("id", "pos")
    )

  # Log stats coverage
  n_with_pass_att <- sum(!is.na(ffa_projtable$pass_att))
  n_with_rush_yds <- sum(!is.na(ffa_projtable$rush_yds))
  n_with_rec_tgt <- sum(!is.na(ffa_projtable$rec_tgt))

  log_message(glue("ffa_projtable: {nrow(ffa_projtable)} records"), "info")
  log_message(glue("  Stats coverage: pass_att={n_with_pass_att}, rush_yds={n_with_rush_yds}, rec_tgt={n_with_rec_tgt}"), "debug")

  # Create dm object
  log_message("Creating dm object for ffa_db...", "info")

  ffa_dm <- dm(
    ffa_scrape,
    ffa_player_ids,
    ffa_players,
    ffa_projtable,
    ffa_proj_source_points
  ) |>
    # Add primary keys
    dm_add_pk(ffa_scrape, c(season, week, tag, timestamp)) |>
    dm_add_pk(ffa_player_ids, id) |>
    dm_add_pk(ffa_players, c(id, pos)) |>
    dm_add_pk(ffa_projtable, c(season, week, tag, timestamp, avg_type, id, pos)) |>
    dm_add_pk(ffa_proj_source_points, c(season, week, tag, timestamp, data_src, id, pos)) |>
    # Add foreign keys
    dm_add_fk(ffa_players, id, ffa_player_ids) |>
    dm_add_fk(ffa_projtable, c(id, pos), ffa_players) |>
    dm_add_fk(ffa_projtable, c(season, week, tag, timestamp), ffa_scrape) |>
    dm_add_fk(ffa_proj_source_points, c(id, pos), ffa_players) |>
    dm_add_fk(ffa_proj_source_points, c(season, week, tag, timestamp), ffa_scrape)

  log_message("ffa_db created successfully", "success")

  ffa_dm
}

# Transform to nfl_stats_db -----------------------------------------------

transform_to_nfl_stats_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_stats_db")

  player_data <- extracted_data$player_data

  # ✅ LEGACY FIX: Standardize column names (may vary in older years)
  if (nrow(player_data$stats) > 0) {
    id_col <- intersect(c("playerId", "player_id", "id"), names(player_data$stats))[1]
    if (!is.na(id_col) && id_col != "playerId") {
      player_data$stats <- player_data$stats |> rename(playerId = !!id_col)
    }
  }
  if (nrow(player_data$advanced) > 0) {
    id_col <- intersect(c("playerId", "player_id", "id"), names(player_data$advanced))[1]
    if (!is.na(id_col) && id_col != "playerId") {
      player_data$advanced <- player_data$advanced |> rename(playerId = !!id_col)
    }
  }

  # 1. nfl_stat_dictionary (create lookup table)
  log_message("Creating nfl_stat_dictionary...", "debug")

  if (nrow(player_data$stats) > 0) {
    nfl_stat_dictionary <- player_data$stats |>
      distinct(statId) |>
      mutate(
        abbr = paste0("stat_", statId),
        name = paste0("Stat ", statId),
        shortName = paste0("S", statId),
        scoringType = "",
        isBonus = FALSE,
        groupName = NA_character_,
        positionCategory = NA_character_,
        n = row_number(),
        colName = paste0("stat_", statId)
      )
  } else {
    # Create empty dictionary
    nfl_stat_dictionary <- tibble(
      statId = integer(),
      abbr = character(),
      name = character(),
      shortName = character(),
      scoringType = character(),
      isBonus = logical(),
      groupName = character(),
      positionCategory = character(),
      n = integer(),
      colName = character()
    )
  }

  log_message(glue("nfl_stat_dictionary: {nrow(nfl_stat_dictionary)} records"), "info")

  # 2. nfl_players_points
  log_message("Creating nfl_players_points...", "debug")

  nfl_players_points <- player_data$points |>
    select(playerId, season, week, pts) |>
    arrange(playerId, season, week)

  log_message(glue("nfl_players_points: {nrow(nfl_players_points)} records"), "info")

  # 3. nfl_players_stats
  log_message("Creating nfl_players_stats...", "debug")

  if (nrow(player_data$stats) > 0 && all(c("playerId", "season", "week", "statId", "value") %in% names(player_data$stats))) {
    nfl_players_stats <- player_data$stats |>
      select(playerId, season, week, statId, value) |>
      arrange(playerId, season, week, statId)
  } else {
    # Create empty stats if data is missing or malformed
    nfl_players_stats <- tibble(
      playerId = integer(),
      season = integer(),
      week = integer(),
      statId = integer(),
      value = numeric()
    )
    if (nrow(player_data$stats) > 0) {
      log_message(glue("WARNING: Stats data exists but missing required columns. Available: {paste(names(player_data$stats), collapse=', ')}"), "warning")
    }
  }

  log_message(glue("nfl_players_stats: {nrow(nfl_players_stats)} records"), "info")

  # 4. nfl_players_adv_stats
  log_message("Creating nfl_players_adv_stats...", "debug")

  if (nrow(player_data$advanced) > 0) {
    nfl_players_adv_stats <- player_data$advanced |>
      # "advanced_week" duplicates the top-level "week" - drop before
      # stripping the prefix or rename_with collides on the name "week"
      select(-any_of("advanced_week")) |>
      rename_with(~ str_remove(.x, "^advanced_"), starts_with("advanced_")) |>
      mutate(season = config$season, .after = playerId) |>
      select(playerId, season, week, everything())
  } else{
    # Create empty advanced stats
    nfl_players_adv_stats <- tibble(
      playerId = integer(),
      season = integer(),
      week = integer()
    )
  }

  log_message(glue("nfl_players_adv_stats: {nrow(nfl_players_adv_stats)} records"), "info")

  # Create dm object
  log_message("Creating dm object for nfl_stats_db...", "info")

  nfl_stats_dm <- dm(
    nfl_stat_dictionary,
    nfl_players_points,
    nfl_players_stats,
    nfl_players_adv_stats
  ) |>
    # Add primary keys
    dm_add_pk(nfl_stat_dictionary, statId) |>
    dm_add_pk(nfl_players_points, c(playerId, season, week)) |>
    dm_add_pk(nfl_players_stats, c(playerId, season, week, statId)) |>
    dm_add_pk(nfl_players_adv_stats, c(playerId, season, week))

  # Add foreign key only if stats exist
  if (nrow(nfl_players_stats) > 0) {
    nfl_stats_dm <- nfl_stats_dm |>
      dm_add_fk(nfl_players_stats, statId, nfl_stat_dictionary)
  }

  log_message("nfl_stats_db created successfully", "success")

  nfl_stats_dm
}

# Transform to dudes_simulation_db ----------------------------------------

transform_to_dudes_simulation_db <- function(extracted_data, config) {
  log_section("Transforming to dudes_simulation_db")

  simulations <- extracted_data$simulations

  if (nrow(simulations) == 0) {
    log_message("No simulation data to transform", "warning")

    # Return empty dm
    return(
      dm(
        dudes_players_seeds = tibble(
          season = integer(),
          week = integer(),
          id = character(),
          playerId = integer(),
          pos = character(),
          simType = character(),
          seeds = list()
        ),
        dudes_players_simulations = tibble(
          season = integer(),
          week = integer(),
          id = character(),
          playerId = integer(),
          pos = character(),
          simType = character(),
          simulation = list(),
          simQuantiles = list()
        )
      ) |>
        dm_add_pk(dudes_players_seeds, c(season, week, id, playerId, pos, simType)) |>
        dm_add_pk(dudes_players_simulations, c(season, week, id, playerId, pos, simType))
    )
  }

  # 1. dudes_players_seeds - use pts.proj (array of ~43 projections)
  log_message("Creating dudes_players_seeds...", "debug")

  # ✅ Seeds come from pts.proj (NOT a separate "seeds" column)
  if ("pts.proj" %in% names(simulations)) {
    dudes_players_seeds <- simulations |>
      select(
        season, week, id, playerId, pos, phase,
        seeds = pts.proj  # ✅ Rename pts.proj → seeds
      ) |>
      mutate(simType = phase) |>  # Use phase as simType (preTNF, final, etc)
      select(-phase) |>
      distinct()

    log_message(glue("dudes_players_seeds: {nrow(dudes_players_seeds)} records"), "info")

    # Validate seeds are not empty
    n_empty_seeds <- sum(map_lgl(dudes_players_seeds$seeds, ~ is.null(.x) || length(.x) == 0))
    if (n_empty_seeds > 0) {
      log_message(glue("WARNING: {n_empty_seeds} players have empty seeds"), "warning")
    }
  } else {
    log_message("WARNING: No pts.proj column in simulations - seeds will be empty", "error")
    dudes_players_seeds <- simulations |>
      select(season, week, id, playerId, pos, phase) |>
      mutate(
        simType = phase,
        seeds = list(numeric())
      ) |>
      select(-phase) |>
      distinct()
  }

  # 2. dudes_players_simulations - use simulation.org (KDE output, always 1000 samples)
  log_message("Creating dudes_players_simulations...", "debug")

  # ✅ Use simulation.org (always KDE) instead of simulation (hybrid)
  if ("simulation.org" %in% names(simulations)) {
    dudes_players_simulations <- simulations |>
      select(
        season, week, id, playerId, pos, phase,
        simulation = simulation.org  # ✅ Use .org (always KDE distribution)
      ) |>
      mutate(
        simType = phase,
        # Calculate quantiles on-the-fly from 1000 samples
        simQuantiles = map(simulation, ~ {
          if (is.null(.x) || length(.x) == 0) {
            list(q05 = NA, q15 = NA, q30 = NA, q50 = NA, q70 = NA, q85 = NA, q95 = NA)
          } else {
            list(
              q05 = quantile(.x, 0.05, na.rm = TRUE),
              q15 = quantile(.x, 0.15, na.rm = TRUE),
              q30 = quantile(.x, 0.30, na.rm = TRUE),
              q50 = quantile(.x, 0.50, na.rm = TRUE),
              q70 = quantile(.x, 0.70, na.rm = TRUE),
              q85 = quantile(.x, 0.85, na.rm = TRUE),
              q95 = quantile(.x, 0.95, na.rm = TRUE)
            )
          }
        })
      ) |>
      select(-phase) |>
      distinct()

    log_message(glue("dudes_players_simulations: {nrow(dudes_players_simulations)} records"), "info")

    # Validate simulations are not empty
    n_empty_sims <- sum(map_lgl(dudes_players_simulations$simulation, ~ is.null(.x) || length(.x) == 0))
    if (n_empty_sims > 0) {
      log_message(glue("WARNING: {n_empty_sims} players have empty simulations"), "warning")
    }
  } else {
    log_message("WARNING: No simulation.org column in simulations - simulations will be empty", "error")
    dudes_players_simulations <- simulations |>
      select(season, week, id, playerId, pos, phase) |>
      mutate(
        simType = phase,
        simulation = list(numeric()),
        simQuantiles = list(list(q05 = NA, q15 = NA, q30 = NA, q50 = NA, q70 = NA, q85 = NA, q95 = NA))
      ) |>
      select(-phase) |>
      distinct()
  }

  log_message(glue("dudes_players_simulations: {nrow(dudes_players_simulations)} records"), "info")

  # Create dm object
  log_message("Creating dm object for dudes_simulation_db...", "info")

  dudes_simulation_dm <- dm(
    dudes_players_seeds,
    dudes_players_simulations
  ) |>
    dm_add_pk(dudes_players_seeds, c(season, week, id, playerId, pos, simType)) |>
    dm_add_pk(dudes_players_simulations, c(season, week, id, playerId, pos, simType))

  log_message("dudes_simulation_db created successfully", "success")

  dudes_simulation_dm
}

# Transform to nfl_players_db ---------------------------------------------

transform_to_nfl_players_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_players_db")

  # Extract from simulations (players_stats has all player info)
  # NOTE: Pattern varies by year - be flexible
  # 2019: simulation_*_evaluation_week*.rds (old format, limited)
  # 2020+: simulation_v5_week*_*.rds (modern format)
  sim_files <- dir_ls(config$source_dir, regexp = "simulation.*\\.rds")

  if (length(sim_files) == 0) {
    log_message("No simulation files for player extraction", "warning")

    return(
      dm(
        nfl_players = tibble(
          playerId = integer(),
          nflGlobalEntityId = character(),
          esbId = character(),
          name = character(),
          firstName = character(),
          lastName = character(),
          position = character(),
          nflTeamAbbr = character(),
          nflTeamId = integer(),
          imageUrl = character(),
          smallImageUrl = character(),
          largeImageUrl = character(),
          byeWeek = integer(),
          cancelledWeeks = logical(),
          archetypes = logical(),
          isUndroppable = logical(),
          isReserveStatus = logical(),
          lastNoteTimestamp = character(),
          lastVideoTimestamp = logical()
        ),
        nfl_player_injury_status = tibble(
          playerId = integer(),
          timestamp = as.POSIXct(character()),
          injuryGameStatus = character()
        )
      ) |>
        dm_add_pk(nfl_players, playerId) |>
        dm_add_pk(nfl_player_injury_status, c(playerId, timestamp)) |>
        dm_add_fk(nfl_player_injury_status, playerId, nfl_players)
    )
  }

  log_message(glue("Processing {length(sim_files)} simulation files for player data"), "info")

  # Extract nfl_players from all simulation files (use most recent per player)
  # NOTE: Schema varies by year - use defensive selection
  all_players <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      if ("players_stats" %in% names(sim)) {
        # Required columns (always present)
        required_cols <- c("playerId", "name", "position")

        # Optional columns (may not exist in older years)
        optional_cols <- c(
          "nflGlobalEntityId", "esbId", "firstName", "lastName",
          "nflTeamAbbr", "nflTeamId", "imageUrl", "smallImageUrl",
          "largeImageUrl", "byeWeek", "cancelledWeeks", "archetypes",
          "isUndroppable", "isReserveStatus", "lastNoteTimestamp", "lastVideoTimestamp"
        )

        # Select only columns that exist
        available_cols <- intersect(
          c(required_cols, optional_cols),
          names(sim$players_stats)
        )

        sim$players_stats |>
          select(all_of(available_cols)) |>
          distinct(playerId, .keep_all = TRUE)
      } else {
        tibble()
      }
    })

  # Keep most recent player record (last file processed)
  # Add missing columns with NA values to match schema
  expected_cols <- c(
    "playerId", "nflGlobalEntityId", "esbId", "name", "firstName", "lastName",
    "position", "nflTeamAbbr", "nflTeamId", "imageUrl", "smallImageUrl",
    "largeImageUrl", "byeWeek", "cancelledWeeks", "archetypes",
    "isUndroppable", "isReserveStatus", "lastNoteTimestamp", "lastVideoTimestamp"
  )

  # Keep most recent player record and ensure all columns exist
  nfl_players <- all_players |>
    group_by(playerId) |>
    slice_tail(n = 1) |>
    ungroup()

  # Add missing columns with appropriate types
  for (col in expected_cols) {
    if (!col %in% names(nfl_players)) {
      # Infer type from column name
      if (grepl("Id$", col) || col == "byeWeek") {
        nfl_players[[col]] <- NA_integer_
      } else if (col %in% c("cancelledWeeks", "archetypes", "isUndroppable",
                            "isReserveStatus", "lastVideoTimestamp")) {
        nfl_players[[col]] <- NA
      } else {
        nfl_players[[col]] <- NA_character_
      }
    }
  }

  nfl_players <- nfl_players |>
    select(all_of(expected_cols)) |>
    arrange(playerId)

  log_message(glue("nfl_players: {nrow(nfl_players)} records"), "info")

  # Extract injury history with timestamps
  all_injury_history <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())

      # Extract file timestamp from filename (e.g., simulation_v5_week1_final.rds)
      filename <- basename(.x)
      week_num <- as.integer(str_extract(filename, "(?<=week)\\d+"))
      phase <- str_extract(filename, "(?<=_)[^.]+(?=\\.rds)")

      # Create timestamp (use config season and approximate dates)
      # Week 1 starts ~Sep 10, each week is 7 days apart
      base_date <- as.POSIXct(glue("{config$season}-09-10 19:00:00"), tz = "America/New_York")
      week_offset <- (week_num - 1) * 7

      # Adjust by phase (preTNF = Thu 00:00, final = Tue 19:00)
      if (!is.na(phase)) {
        if (phase == "preTNF") {
          phase_offset <- 0  # Thursday start of week
        } else if (phase == "final") {
          phase_offset <- 5  # Tuesday after games
        } else {
          phase_offset <- 3  # Default mid-week
        }
      } else {
        phase_offset <- 3
      }

      timestamp <- base_date + days(week_offset + phase_offset)

      if ("players_stats" %in% names(sim)) {
        sim$players_stats |>
          mutate(timestamp = timestamp) |>
          select(playerId, timestamp, injuryGameStatus) |>  # Correct column order
          distinct()
      } else {
        tibble()
      }
    })

  nfl_player_injury_status <- all_injury_history |>
    arrange(playerId, timestamp) |>
    distinct(playerId, timestamp, .keep_all = TRUE)

  log_message(glue("nfl_player_injury_status: {nrow(nfl_player_injury_status)} records"), "info")

  # Create dm object
  log_message("Creating dm object for nfl_players_db...", "info")

  nfl_players_dm <- dm(
    nfl_players,
    nfl_player_injury_status
  ) |>
    dm_add_pk(nfl_players, playerId) |>
    dm_add_pk(nfl_player_injury_status, c(playerId, timestamp)) |>
    dm_add_fk(nfl_player_injury_status, playerId, nfl_players)

  log_message("nfl_players_db created successfully", "success")

  nfl_players_dm
}

# Transform to nfl_round_db -----------------------------------------------

transform_to_nfl_round_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_round_db")

  # Extract from simulations
  sim_files <- dir_ls(config$source_dir, regexp = "simulation.*\\.rds")

  if (length(sim_files) == 0) {
    log_message("No simulation files for round data extraction", "warning")

    return(
      dm(
        nfl_teams_round = tibble(season = integer(), week = integer(), teamId = integer(),
                                 rank = integer(), imageUrl = character(), imageUrlLarge = character()),
        nfl_teams_rosters = tibble(season = integer(), week = integer(), tag = character(),
                                   timestamp = as.POSIXct(character()), teamId = integer(),
                                   slotPosition = character(), rosterSlotId = integer(),
                                   playerId = integer(), isEditable = logical(), isReserveStatus = logical()),
        nfl_teams_week_stats = tibble(season = integer(), week = integer(), tag = character(),
                                      timestamp = as.POSIXct(character()), teamId = integer(),
                                      statId = character(), value = numeric()),
        nfl_teams_season_stats = tibble(season = integer(), week = integer(), tag = character(),
                                        timestamp = as.POSIXct(character()), teamId = integer(),
                                        name = character(), value = character()),
        matchups_games = tibble(season = integer(), week = integer(), matchupId = character(),
                               previewUrl = character(), recapUrl = character(),
                               bracketType = character(), bracketTitle = character(),
                               hasMatchupTeams = logical(), awayTeamTeamId = integer(),
                               awayTeamOutcome = character(), awayTeamPlayoffSeeding = integer(),
                               homeTeamTeamId = integer(), homeTeamOutcome = character(),
                               homeTeamPlayoffSeeding = integer())
      ) |>
        dm_add_pk(nfl_teams_round, c(season, week, teamId)) |>
        dm_add_pk(nfl_teams_rosters, c(season, week, tag, timestamp, teamId, rosterSlotId, playerId)) |>
        dm_add_pk(nfl_teams_week_stats, c(season, week, tag, timestamp, teamId, statId)) |>
        dm_add_pk(nfl_teams_season_stats, c(season, week, tag, timestamp, teamId, name)) |>
        dm_add_pk(matchups_games, c(season, week, matchupId))
    )
  }

  log_message(glue("Processing {length(sim_files)} simulation files for round data"), "info")

  # Helper to extract timestamp from filename
  extract_timestamp <- function(filepath, config) {
    filename <- basename(filepath)
    week_num <- as.integer(str_extract(filename, "(?<=week)\\d+"))
    phase <- str_extract(filename, "(?<=_)[^.]+(?=\\.rds)")

    base_date <- as.POSIXct(glue("{config$season}-09-10 19:00:00"), tz = "America/New_York")
    week_offset <- (week_num - 1) * 7

    if (!is.na(phase)) {
      if (phase == "preTNF") {
        phase_offset <- 0
      } else if (phase == "final") {
        phase_offset <- 5
      } else {
        phase_offset <- 3
      }
    } else {
      phase_offset <- 3
    }

    list(
      week = week_num,
      timestamp = base_date + days(week_offset + phase_offset),
      tag = ifelse(!is.na(phase) && phase == "final", "final", "preview")
    )
  }

  # 1. Extract matchups_games
  all_matchups <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      meta <- extract_timestamp(.x, config)

      if ("matchups" %in% names(sim)) {
        df <- sim$matchups |>
          mutate(
            season = config$season,
            week = meta$week
          )

        # Handle nested columns (may vary by year) - DEFENSIVE
        if ("awayTeam.teamId" %in% names(df)) {
          df <- df |> mutate(
            awayTeamTeamId = as.integer(`awayTeam.teamId`),
            awayTeamOutcome = if ("awayTeam.outcome" %in% names(df)) as.character(`awayTeam.outcome`) else NA_character_,
            awayTeamPlayoffSeeding = if ("awayTeam.playoffSeeding" %in% names(df)) as.integer(`awayTeam.playoffSeeding`) else NA_integer_,
            homeTeamTeamId = as.integer(`homeTeam.teamId`),
            homeTeamOutcome = if ("homeTeam.outcome" %in% names(df)) as.character(`homeTeam.outcome`) else NA_character_,
            homeTeamPlayoffSeeding = if ("homeTeam.playoffSeeding" %in% names(df)) as.integer(`homeTeam.playoffSeeding`) else NA_integer_
          )
        }

        # Select available columns
        required_cols <- c("season", "week", "matchupId")
        optional_cols <- c(
          "previewUrl", "recapUrl", "bracketType", "bracketTitle",
          "hasMatchupTeams", "awayTeamTeamId", "awayTeamOutcome",
          "awayTeamPlayoffSeeding", "homeTeamTeamId", "homeTeamOutcome",
          "homeTeamPlayoffSeeding"
        )

        available <- intersect(c(required_cols, optional_cols), names(df))
        df |> select(all_of(available))
      } else {
        tibble()
      }
    })

  # Ensure all expected columns exist
  expected_matchup_cols <- c(
    "season", "week", "matchupId", "previewUrl", "recapUrl",
    "bracketType", "bracketTitle", "hasMatchupTeams",
    "awayTeamTeamId", "awayTeamOutcome", "awayTeamPlayoffSeeding",
    "homeTeamTeamId", "homeTeamOutcome", "homeTeamPlayoffSeeding"
  )

  # Ensure all expected columns exist
  matchups_games <- all_matchups |>
    distinct(season, week, matchupId, .keep_all = TRUE)

  for (col in expected_matchup_cols) {
    if (!col %in% names(matchups_games)) {
      if (grepl("TeamId$", col) || grepl("Seeding$", col)) {
        matchups_games[[col]] <- NA_integer_
      } else if (col == "hasMatchupTeams") {
        matchups_games[[col]] <- NA
      } else {
        matchups_games[[col]] <- NA_character_
      }
    }
  }

  matchups_games <- matchups_games |>
    select(all_of(expected_matchup_cols)) |>
    arrange(season, week, matchupId)

  log_message(glue("matchups_games: {nrow(matchups_games)} records"), "info")

  # 2. Extract nfl_teams_round (weekly team rankings)
  all_teams_round <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      meta <- extract_timestamp(.x, config)

      if ("teams" %in% names(sim)) {
        sim$teams |>
          select(teamId, any_of(c("rank", "imageUrl", "imageUrlLarge"))) |>
          mutate(
            season = config$season,
            week = meta$week,
            rank = if ("rank" %in% names(sim$teams)) as.integer(rank) else NA_integer_,
            imageUrl = if ("imageUrl" %in% names(sim$teams)) imageUrl else NA_character_,
            imageUrlLarge = if ("imageUrlLarge" %in% names(sim$teams)) imageUrlLarge else NA_character_
          ) |>
          select(season, week, teamId, rank, imageUrl, imageUrlLarge)
      } else {
        tibble()
      }
    })

  nfl_teams_round <- all_teams_round |>
    distinct(season, week, teamId, .keep_all = TRUE) |>
    arrange(season, week, teamId)

  log_message(glue("nfl_teams_round: {nrow(nfl_teams_round)} records"), "info")

  # 3. Extract nfl_teams_rosters (nested in teams$rosters)
  all_rosters <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      meta <- extract_timestamp(.x, config)

      if ("teams" %in% names(sim) && "rosters" %in% names(sim$teams)) {
        # Unnest rosters from each team
        sim$teams |>
          select(teamId, rosters) |>
          unnest(rosters) |>
          mutate(
            season = config$season,
            week = meta$week,
            tag = meta$tag,
            timestamp = meta$timestamp
          ) |>
          select(
            season, week, tag, timestamp, teamId,
            slotPosition, rosterSlotId, playerId,
            isEditable, isReserveStatus
          )
      } else {
        tibble()
      }
    })

  nfl_teams_rosters <- all_rosters |>
    distinct(season, week, tag, timestamp, teamId, rosterSlotId, playerId, .keep_all = TRUE) |>
    arrange(season, week, teamId, playerId)

  log_message(glue("nfl_teams_rosters: {nrow(nfl_teams_rosters)} records"), "info")

  # 4. Extract nfl_teams_week_stats (nested in teams$week.stats)
  # Note: week.stats is wide format (pts column), need to convert to long
  all_week_stats <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      meta <- extract_timestamp(.x, config)

      if ("teams" %in% names(sim) && "week.stats" %in% names(sim$teams)) {
        sim$teams |>
          select(teamId, `week.stats`) |>
          unnest(`week.stats`) |>
          # Convert to long format: only pts column is meaningful
          pivot_longer(
            cols = c(pts),  # Only pts column
            names_to = "statId",
            values_to = "value"
          ) |>
          mutate(
            season = config$season,
            week = meta$week,
            tag = meta$tag,
            timestamp = meta$timestamp
          ) |>
          select(season, week, tag, timestamp, teamId, statId, value)
      } else {
        tibble()
      }
    })

  nfl_teams_week_stats <- all_week_stats |>
    distinct(season, week, tag, timestamp, teamId, statId, .keep_all = TRUE) |>
    arrange(season, week, teamId, statId)

  log_message(glue("nfl_teams_week_stats: {nrow(nfl_teams_week_stats)} records"), "info")

  # 5. Extract nfl_teams_season_stats (nested in teams$season.stats)
  # Note: season.stats is wide format with many columns, need to pivot to long
  all_season_stats <- sim_files |>
    map_dfr(~ {
      sim <- safe_read_rds(.x, default = list())
      meta <- extract_timestamp(.x, config)

      if ("teams" %in% names(sim) && "season.stats" %in% names(sim$teams)) {
        sim$teams |>
          select(teamId, `season.stats`) |>
          unnest(`season.stats`) |>
          # Convert all columns to character before pivoting (mixed types)
          mutate(across(everything(), as.character)) |>
          # Convert to long format
          pivot_longer(
            cols = -c(teamId),
            names_to = "name",
            values_to = "value"
          ) |>
          mutate(
            season = config$season,
            week = meta$week,
            tag = meta$tag,
            timestamp = meta$timestamp
          ) |>
          select(season, week, tag, timestamp, teamId, name, value)
      } else {
        tibble()
      }
    })

  nfl_teams_season_stats <- all_season_stats |>
    distinct(season, week, tag, timestamp, teamId, name, .keep_all = TRUE) |>
    arrange(season, week, teamId, name)

  log_message(glue("nfl_teams_season_stats: {nrow(nfl_teams_season_stats)} records"), "info")

  # Create dm object
  log_message("Creating dm object for nfl_round_db...", "info")

  nfl_round_dm <- dm(
    nfl_teams_round,
    nfl_teams_rosters,
    nfl_teams_week_stats,
    nfl_teams_season_stats,
    matchups_games
  ) |>
    dm_add_pk(nfl_teams_round, c(season, week, teamId)) |>
    dm_add_pk(nfl_teams_rosters, c(season, week, tag, timestamp, teamId, rosterSlotId, playerId)) |>
    dm_add_pk(nfl_teams_week_stats, c(season, week, tag, timestamp, teamId, statId)) |>
    dm_add_pk(nfl_teams_season_stats, c(season, week, tag, timestamp, teamId, name)) |>
    dm_add_pk(matchups_games, c(season, week, matchupId))

  log_message("nfl_round_db created successfully", "success")

  nfl_round_dm
}

# Transform to nfl_recap_db -----------------------------------------------

transform_to_nfl_recap_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_recap_db")

  log_message("WARNING: Recap narratives require external API calls (not available in dudes/ files)", "warning")
  log_message("Creating empty nfl_recap_db structure", "info")

  # Create empty structure matching app/ schema
  nfl_recap <- tibble(
    leagueId = integer(),
    season = integer(),
    week = integer(),
    matchupId = character(),
    title = character(),
    paragraphs = list(),
    type = character(),
    written_at = character(),
    weekday = character(),
    playoff = logical(),
    standard_scheduling = logical(),
    standard_scoring = logical(),
    teams = list(),
    free_agent_target_touch_leaders = list(),
    league_notes = list()
  )

  log_message("nfl_recap: 0 records (requires API integration)", "info")

  # Create dm object
  nfl_recap_dm <- dm(
    nfl_recap
  ) |>
    dm_add_pk(nfl_recap, c(leagueId, season, week, matchupId))

  log_message("nfl_recap_db created successfully (empty)", "success")

  nfl_recap_dm
}

# Transform to nfl_teams_db -----------------------------------------------

transform_to_nfl_teams_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_teams_db")

  # Extract team data from simulations
  sim_files <- dir_ls(config$source_dir, regexp = "simulation.*\\.rds")

  if (length(sim_files) == 0) {
    log_message("No simulation files for team extraction", "warning")

    return(
      dm(
        nfl_teams = tibble(
          teamId = integer(),
          name = character(),
          ownerUserId = integer(),
          imageUrl = character()
        ),
        nfl_owners = tibble(
          ownerUserId = integer(),
          name = character()
        )
      ) |>
        dm_add_pk(nfl_teams, teamId) |>
        dm_add_pk(nfl_owners, ownerUserId) |>
        dm_add_fk(nfl_teams, ownerUserId, nfl_owners)
    )
  }

  # Read first simulation to get team structure
  sim <- safe_read_rds(sim_files[1], default = list())

  if (!"teams" %in% names(sim)) {
    log_message("No teams data in simulation files", "warning")
    return(dm(
      nfl_teams = tibble(),
      nfl_owners = tibble()
    ))
  }

  # Extract teams
  nfl_teams <- sim$teams |>
    distinct(teamId, name, ownerUserId, imageUrl)

  log_message(glue("nfl_teams: {nrow(nfl_teams)} records"), "info")

  # Extract owners
  nfl_owners <- nfl_teams |>
    distinct(ownerUserId) |>
    mutate(name = paste("Owner", ownerUserId))  # Placeholder

  log_message(glue("nfl_owners: {nrow(nfl_owners)} records"), "info")

  # Create dm object
  nfl_teams_dm <- dm(
    nfl_teams,
    nfl_owners
  ) |>
    dm_add_pk(nfl_teams, teamId) |>
    dm_add_pk(nfl_owners, ownerUserId) |>
    dm_add_fk(nfl_teams, ownerUserId, nfl_owners)

  log_message("nfl_teams_db created successfully", "success")

  nfl_teams_dm
}

# Main Transform Function -------------------------------------------------

transform_all <- function(extracted_data, config) {
  log_section("PHASE 2: TRANSFORMATION")

  results <- list()

  # Transform to each database (all 7 databases)
  results$ffa_db <- transform_to_ffa_db(extracted_data, config)
  results$nfl_stats_db <- transform_to_nfl_stats_db(extracted_data, config)
  results$dudes_simulation_db <- transform_to_dudes_simulation_db(extracted_data, config)
  results$nfl_teams_db <- transform_to_nfl_teams_db(extracted_data, config)
  results$nfl_players_db <- transform_to_nfl_players_db(extracted_data, config)
  results$nfl_round_db <- transform_to_nfl_round_db(extracted_data, config)
  results$nfl_recap_db <- transform_to_nfl_recap_db(extracted_data, config)

  # Save checkpoint
  if (config$save_intermediate) {
    create_checkpoint("transformation", results, config$checkpoint_dir)
  }

  log_message("Transformation phase complete!", "success")

  results
}

# Export ------------------------------------------------------------------

list(
  transform_all = transform_all,
  transform_to_ffa_db = transform_to_ffa_db,
  transform_to_nfl_stats_db = transform_to_nfl_stats_db,
  transform_to_dudes_simulation_db = transform_to_dudes_simulation_db,
  transform_to_nfl_teams_db = transform_to_nfl_teams_db,
  transform_to_nfl_players_db = transform_to_nfl_players_db,
  transform_to_nfl_round_db = transform_to_nfl_round_db,
  transform_to_nfl_recap_db = transform_to_nfl_recap_db
)
