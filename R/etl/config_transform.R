# =============================================================================
# CONFIGURATION FOR DUDES → APP TRANSFORMATION
# =============================================================================
# Script: config_transform.R
# Purpose: Configuration settings for ETL pipeline
# Author: DudesData ETL Pipeline
# Created: 2026-03-07
# =============================================================================

# ETL Configuration --------------------------------------------------------

ETL_CONFIG <- list(
  # Directories (dynamic by season)
  source_dir = NULL,  # Set via glue("dudes/{season}/")
  target_dir = NULL,  # Set via glue("./etl/{season}/")
  checkpoint_dir = ".claude/etl_checkpoints/",

  # Season parameters
  season = 2025,
  weeks = 1:17,

  # Test mode
  test_mode = FALSE,  # TRUE = week 1 only, FALSE = all weeks

  # Processing options
  parallel = TRUE,
  n_cores = 4,
  batch_size = 5,  # Process 5 weeks at a time

  # Validation
  strict_mode = TRUE,  # Fail on constraint violations
  # validate_cardinality removed - always validates now

  # Logging
  log_level = "info",  # debug, info, warning, error
  save_intermediate = TRUE  # Save intermediate results
)

# Initialize dynamic paths
ETL_CONFIG$source_dir <- glue::glue("dudes/{ETL_CONFIG$season}/")
ETL_CONFIG$target_dir <- glue::glue("./etl/{ETL_CONFIG$season}/")

# ✅ F10 FIX: Validate paths helper function (called at pipeline start)
validate_etl_paths <- function(config) {
  # Check source directory exists
  if (!dir.exists(config$source_dir)) {
    stop(glue::glue(
      "Source directory does not exist: {config$source_dir}\n",
      "Available seasons: {paste(list.dirs('dudes', full.names=FALSE, recursive=FALSE), collapse=', ')}"
    ))
  }

  # Create target directory if needed
  if (!dir.exists(config$target_dir)) {
    message(glue::glue("Creating target directory: {config$target_dir}"))
    dir.create(config$target_dir, recursive = TRUE)
  }

  invisible(TRUE)
}

# File Patterns -----------------------------------------------------------

FILE_PATTERNS <- list(
  # Source patterns (dudes/)
  week_scrap = "week{week}_scrap.rds",
  week_projections = "week{week}_players_projections.rds",
  weekly_proj_site = "weekly_proj_player_site_{week}.rds",
  weekly_proj_table = "weekly_proj_table_{week}.rds",
  weekly_webscrapes = "weekly_webscrapes_{week}.rds",
  dudesffa_projpoints = "dudesffa_projpoints_week{week}.rds",
  simulation = "simulation_v5_week{week}_{phase}.rds",
  players_points = "players_points.rds",
  rank_week = "rank_week{week}.rds",
  rank_against_position = "rankAgainstPosition_week{week}.rds",

  # Season files
  season_scrap = "season_scrap.rds",
  season_projtable = "season_projtable.rds",
  season_player_proj_sites = "season_player_proj_sites.rds",
  season_errors = "season_2024_projections_errors.rds",

  # Draft files
  draft_picks = "draft_picks.rds",
  draft_pick_projections = "draft_pick_projections.rds",
  draft_teams_projections = "draft_teams_projections.rds",
  draft_recap_data = "draft_recap_data.rds",
  draft_recap_rank = "draft_recap_rank.rds",

  # Target patterns (app/)
  ffa_db = "ffa_db.rds",
  nfl_teams_db = "nfl_teams_db.rds",
  nfl_players_db = "nfl_players_db.rds",
  nfl_stats_db = "nfl_stats_db.rds",
  nfl_round_db = "nfl_round_db.rds",
  nfl_recap_db = "nfl_recap_db.rds",
  dudes_simulation_db = "dudes_simulation_db.rds"
)

# Simulation Phases -------------------------------------------------------

SIMULATION_PHASES <- c(
  "preBR",           # Before Brazil game
  "preTNF",          # Before Thursday Night Football
  "posTNF",          # After Thursday Night Football
  "preSundayGames",  # Before Sunday games
  "preSNF",          # Before Sunday Night Football
  "posSNF",          # After Sunday Night Football
  "preMNF",          # Before Monday Night Football
  "posMNF",          # After Monday Night Football
  "preDublinGame",   # Before Dublin game
  "preLondon",       # Before London game
  "posThanksgiving", # After Thanksgiving
  "preXMAS",         # Before Christmas
  "preWaivers",      # Before waiver processing
  "posWaivers",      # After waiver processing
  "final"            # Week complete
)

# Tag Inference Rules -----------------------------------------------------

TAG_INFERENCE_RULES <- tribble(
  ~pattern,           ~tag,            ~priority,
  "final",            "final",         10,
  "posWaivers",       "posWaivers",    9,
  "preWaivers",       "preWaivers",    8,
  "posMNF",           "posMNF",        7,
  "preMNF",           "preMNF",        6,
  "posSNF",           "posSNF",        5,
  "preSNF",           "preSNF",        4,
  "preSundayGames",   "preSundayGames",3,
  "posTNF",           "posTNF",        2,
  "preTNF",           "preTNF",        1
) |>
  arrange(desc(priority))

# ID Mapping Configuration ------------------------------------------------

ID_MAPPING_CONFIG <- list(
  # Sources for player ID mapping
  sources = c(
    "nfl_id", "stats_id", "cbs_id", "espn_id", "fleaflicker_id",
    "fftoday_id", "numfire_id", "fantasypro_id", "fantasydata_id",
    "fantasynerd_id", "rts_id", "fantasypro_num_id", "gsis_id", "sleeper_id"
  ),

  # Primary ID (used as main identifier)
  primary_id = "nfl_id",

  # ID type conversions
  conversions = list(
    nfl_id = "integer",
    stats_id = "character",
    cbs_id = "character",
    espn_id = "character",
    fleaflicker_id = "character"
  )
)

# Validation Thresholds ---------------------------------------------------

VALIDATION_THRESHOLDS <- list(
  # Maximum acceptable difference between source and target counts
  max_count_diff_pct = 5,  # 5%

  # Minimum expected records per table
  min_records = list(
    ffa_projtable = 10000,
    ffa_proj_source_points = 50000,
    nfl_players_points = 5000,
    nfl_players_stats = 30000
  ),

  # Maximum NULL percentage allowed
  max_null_pct = list(
    ffa_player_ids_nfl_id = 35,  # Up to 35% can be NULL
    nfl_players_esbId = 80       # esbId has high NULL rate
  )
)

# Export configuration ----------------------------------------------------

list(
  config = ETL_CONFIG,
  patterns = FILE_PATTERNS,
  phases = SIMULATION_PHASES,
  tag_rules = TAG_INFERENCE_RULES,
  id_mapping = ID_MAPPING_CONFIG,
  validation = VALIDATION_THRESHOLDS
)
