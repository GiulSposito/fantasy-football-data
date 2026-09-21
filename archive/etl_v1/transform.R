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
source("R/etl/utils_transform.R")

# Transform to ffa_db -----------------------------------------------------

transform_to_ffa_db <- function(extracted_data, config) {
  log_section("Transforming to ffa_db")

  scrapes <- extracted_data$scrapes
  projections <- extracted_data$projections
  proj_tables <- extracted_data$proj_tables

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

  # 2. ffa_player_ids (consolidate all player IDs)
  log_message("Creating ffa_player_ids...", "debug")

  ffa_player_ids <- bind_rows(
    scrapes |> distinct(id),
    projections |> distinct(id),
    proj_tables |> distinct(id)
  ) |>
    distinct(id) |>
    mutate(
      # Map to other ID systems (placeholder - enhance with actual mappings)
      nfl_id = as.character(id),
      stats_id = NA_character_,
      cbs_id = NA_character_,
      fleaflicker_id = NA_character_,
      espn_id = NA_character_,
      fftoday_id = NA_character_,
      numfire_id = NA_character_,
      fantasypro_id = NA_character_,
      fantasydata_id = NA_character_,
      fantasynerd_id = NA_character_,
      rts_id = NA_character_,
      fantasypro_num_id = NA_character_,
      gsis_id = NA_character_,
      sleeper_id = NA_character_
    )

  log_message(glue("ffa_player_ids: {nrow(ffa_player_ids)} records"), "info")

  # 3. ffa_players (player metadata)
  log_message("Creating ffa_players...", "debug")

  ffa_players <- bind_rows(
    scrapes |> select(id, player, pos, team) |> rename(name = player),
    projections |> select(id, pos),
    proj_tables |> select(id, pos, first_name, last_name, team, position, age, exp)
  ) |>
    distinct(id, pos, .keep_all = TRUE) |>
    mutate(
      position = coalesce(position, pos),
      first_name = coalesce(first_name, NA_character_),
      last_name = coalesce(last_name, NA_character_),
      team = coalesce(team, NA_character_),
      age = coalesce(age, NA_integer_),
      exp = coalesce(exp, NA_integer_)
    ) |>
    select(id, pos, first_name, last_name, team, position, age, exp)

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

  # Combine and calculate ranks/tiers
  ffa_projtable <- bind_rows(
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
    ungroup() |>
    # Add stat columns as placeholders (can be enhanced)
    mutate(
      pass_att = NA_real_,
      pass_comp = NA_real_,
      pass_yds = NA_real_,
      pass_tds = NA_real_,
      pass_int = NA_real_,
      rush_att = NA_real_,
      rush_yds = NA_real_,
      rush_tds = NA_real_,
      rec_tgt = NA_real_,
      rec = NA_real_,
      rec_yds = NA_real_,
      rec_tds = NA_real_
    )

  log_message(glue("ffa_projtable: {nrow(ffa_projtable)} records"), "info")

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

  # 1. nfl_stat_dictionary (create lookup table)
  log_message("Creating nfl_stat_dictionary...", "debug")

  if (nrow(player_data$stats) > 0) {
    nfl_stat_dictionary <- player_data$stats |>
      distinct(statId, statCategory) |>
      mutate(
        abbr = statCategory,
        name = statCategory,
        shortName = statCategory,
        scoringType = "",
        isBonus = FALSE,
        groupName = NA_character_,
        positionCategory = NA_character_,
        n = row_number(),
        colName = statCategory
      ) |>
      select(-statCategory)
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

  nfl_players_stats <- player_data$stats |>
    select(playerId, season, week, statId, value) |>
    arrange(playerId, season, week, statId)

  log_message(glue("nfl_players_stats: {nrow(nfl_players_stats)} records"), "info")

  # 4. nfl_players_adv_stats
  log_message("Creating nfl_players_adv_stats...", "debug")

  if (nrow(player_data$advanced) > 0) {
    nfl_players_adv_stats <- player_data$advanced |>
      rename_with(~ str_remove(.x, "^advanced_"), starts_with("advanced_")) |>
      select(playerId, season, week, everything())
  } else {
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

  # 1. dudes_players_seeds
  log_message("Creating dudes_players_seeds...", "debug")

  # Extract seeds if available in simulations
  # Note: The actual structure depends on what's in players_sim
  # This is a placeholder - adjust based on actual data structure

  if ("seeds" %in% names(simulations)) {
    dudes_players_seeds <- simulations |>
      select(season, week, id, playerId, pos, tag, seeds) |>
      rename(simType = tag) |>
      distinct()
  } else {
    # Create from simulation data if seeds not directly available
    dudes_players_seeds <- simulations |>
      select(season, week, id, playerId, pos, tag) |>
      rename(simType = tag) |>
      mutate(seeds = list(numeric())) |>
      distinct()
  }

  log_message(glue("dudes_players_seeds: {nrow(dudes_players_seeds)} records"), "info")

  # 2. dudes_players_simulations
  log_message("Creating dudes_players_simulations...", "debug")

  if ("simulation" %in% names(simulations)) {
    dudes_players_simulations <- simulations |>
      select(season, week, id, playerId, pos, tag, simulation, simQuantiles) |>
      rename(simType = tag) |>
      distinct()
  } else {
    # Create placeholder
    dudes_players_simulations <- simulations |>
      select(season, week, id, playerId, pos, tag) |>
      rename(simType = tag) |>
      mutate(
        simulation = list(numeric()),
        simQuantiles = list(numeric())
      ) |>
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

# Transform to nfl_teams_db -----------------------------------------------

transform_to_nfl_teams_db <- function(extracted_data, config) {
  log_section("Transforming to nfl_teams_db")

  # Extract team data from simulations
  sim_files <- dir_ls(config$source_dir, regexp = "simulation_v5_week\\d+_.+\\.rds")

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

  # Transform to each database
  results$ffa_db <- transform_to_ffa_db(extracted_data, config)
  results$nfl_stats_db <- transform_to_nfl_stats_db(extracted_data, config)
  results$dudes_simulation_db <- transform_to_dudes_simulation_db(extracted_data, config)
  results$nfl_teams_db <- transform_to_nfl_teams_db(extracted_data, config)

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
  transform_to_nfl_teams_db = transform_to_nfl_teams_db
)
