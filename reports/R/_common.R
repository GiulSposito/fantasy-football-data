# Shared helpers for reports/*.qmd. Source with source("R/_common.R").
# All paths are relative to reports/ (quarto project root for this folder).

db_path <- function(name) file.path("..", "dataset", paste0(name, ".rds"))

# ffa_projtable / ffa_proj_source_points$id is a character ffanalytics id;
# nfl_players_points$playerId is integer. The bridge is ffa_player_ids$nfl_id,
# itself stored as character. season/week also differ in type across the two
# schemas (character in ffa_*, integer in nfl_*), so both sides get coerced
# here or every downstream join breaks or silently returns zero rows.
bridge_ffa_to_nfl <- function(ffa_tbl, player_ids_tbl) {
  ffa_tbl |>
    dplyr::mutate(season = as.integer(season), week = as.integer(week)) |>
    dplyr::left_join(
      dplyr::select(player_ids_tbl, id, nfl_id),
      by = "id"
    ) |>
    dplyr::mutate(playerId = suppressWarnings(as.integer(nfl_id))) |>
    dplyr::select(-nfl_id)
}

filter_final <- function(tbl) dplyr::filter(tbl, tag == "final")

# nfl_teams_rosters keeps multiple timestamps even within tag == "final"
# (temporal snapshots through the week: preTNF/posTNF/.../final-of-final).
# Collapse to the single latest timestamp per group before counting slots or
# summing points, or bench/starter counts get inflated by duplicate rows.
latest_snapshot <- function(tbl, group_cols) {
  tbl |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::filter(timestamp == max(timestamp)) |>
    dplyr::ungroup() |>
    dplyr::distinct()
}

# nfl_player_injury_status has no season/week, only a weekly-snapshot
# timestamp. Approximate season/week by mapping each injury timestamp to the
# nearest preceding week boundary in `calendar` (distinct season/week/timestamp
# from ffa_projtable, tag == "final"). This is a documented approximation, not
# the official NFL schedule, and is only used by 06-injury-economics.qmd.
assign_week <- function(timestamps, calendar) {
  cal <- calendar |>
    dplyr::distinct(season, week, timestamp) |>
    dplyr::arrange(timestamp)
  idx <- findInterval(timestamps, cal$timestamp)
  idx[idx == 0] <- NA
  dplyr::tibble(season = cal$season[idx], week = cal$week[idx])
}

POSITIONS <- c("QB", "RB", "WR", "TE", "K", "DST")

# Harmonizes nfl_players$position ("DEF") with ffa_*$pos ("DST"), and drops
# junk rows found in ffa_projtable$pos (a leaked player name, stray "FB").
clean_positions <- function(tbl, pos_col = pos) {
  tbl |>
    dplyr::mutate({{ pos_col }} := dplyr::case_match({{ pos_col }}, "DEF" ~ "DST", .default = {{ pos_col }})) |>
    dplyr::filter({{ pos_col }} %in% POSITIONS)
}

error_metrics <- function(actual, projected, na.rm = TRUE) {
  err <- actual - projected
  dplyr::tibble(
    n = sum(!is.na(err)),
    mae = mean(abs(err), na.rm = na.rm),
    rmse = sqrt(mean(err^2, na.rm = na.rm)),
    bias = mean(err, na.rm = na.rm)
  )
}

theme_reports <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      legend.position = "bottom",
      plot.title.position = "plot",
      panel.grid.minor = ggplot2::element_blank()
    )
}

position_colors <- c(
  QB = "#1b9e77", RB = "#d95f02", WR = "#7570b3",
  TE = "#e7298a", K = "#66a61e", DST = "#e6ab02"
)
scale_color_position <- function(...) ggplot2::scale_color_manual(values = position_colors, ...)
scale_fill_position <- function(...) ggplot2::scale_fill_manual(values = position_colors, ...)

# Fixed defaults from script_de_analise.md; K/DST extended by the same logic.
# Not derived from rosterSlotId demand -- nfl_teams_rosters$slotPosition only
# has 3 coarse buckets (O/DT/K), too coarse to reconstruct true per-position
# starter demand. Documented simplification, see 09-value-over-replacement.qmd.
REPLACEMENT_RANK <- c(QB = 14, RB = 35, WR = 40, TE = 14, K = 14, DST = 14)

# rosterSlotId 1,2,3,4,5,7,8 = starters (7 lineup slots/week); 20 = bench;
# 21 = IR. See 11-manager-effect.qmd.
STARTER_SLOTS <- c(1, 2, 3, 4, 5, 7, 8)
BENCH_SLOTS <- c(20, 21)

# Prints the join match rate as a sanity check every report should run once
# right after its core join (~75-85% expected; a value near 0% means the
# season/week/id coercion broke).
report_match_rate <- function(matched_n, total_n, label = "join match rate") {
  cat(sprintf("%s: %d / %d = %.1f%%\n", label, matched_n, total_n, 100 * matched_n / total_n))
}
