#!/usr/bin/env Rscript
# Build DATA_CATALOG.md for the DudesData repo.
suppressWarnings(suppressMessages({
  library(dm); library(dplyr); library(purrr); library(stringr)
  library(tibble); library(tidyr)
}))

# run from the repo root (where DudesData.Rproj lives)
if (!file.exists("DudesData.Rproj")) stop("run this from the DudesData repo root")
out <- character(); w <- function(...) out <<- c(out, sprintf(...))

rds <- list.files(".", pattern = "\\.[rR][dD][sS]$", recursive = TRUE,
                  full.names = TRUE, all.files = TRUE)
rds <- rds[!str_detect(rds, "\\.Rproj\\.user")]
info <- file.info(rds)
inv <- tibble(path = str_replace(rds, "^\\./", ""), size = info$size, mtime = as.Date(info$mtime)) |>
  mutate(top = str_split_fixed(path, "/", 2)[, 1])

fmt_mb <- function(b) sprintf("%.1f MB", b / 1024^2)
cm <- function(x) ifelse(is.na(x), "-", formatC(as.numeric(x), big.mark = ",", format = "d"))
rng <- function(x) { x <- suppressWarnings(as.numeric(x)); x <- x[!is.na(x)]
  if (!length(x)) return("-"); a <- min(x); b <- max(x)
  if (a == b) as.character(a) else paste0(a, "-", b) }
pick <- function(t, cands) { h <- cands[cands %in% names(t)]; if (length(h)) h[1] else NA_character_ }

read_tables <- function(f) {
  obj <- tryCatch(readRDS(f), error = function(e) NULL)
  if (is.null(obj)) return(NULL)
  if (inherits(obj, "dm")) return(dm_get_tables(obj))
  if (is.data.frame(obj)) return(setNames(list(obj), basename(f)))
  if (is.list(obj) && all(map_lgl(obj, is.data.frame))) return(obj)
  NULL
}

summ_table <- function(t, tn, f) {
  t <- as_tibble(t)
  sc <- pick(t, c("season", "seasonId", "year"))
  wc <- pick(t, c("week", "scoringPeriodId", "weekId"))
  pc <- pick(t, c("playerId", "id", "nfl_id", "player_id"))
  dc <- pick(t, c("data_src", "data_source", "src"))
  tibble(
    file = str_replace(f, "^\\./", ""), table = tn,
    rows = nrow(t), cols = ncol(t),
    season = if (!is.na(sc)) rng(t[[sc]]) else "-",
    week = if (!is.na(wc)) rng(t[[wc]]) else "-",
    players = if (!is.na(pc)) dplyr::n_distinct(t[[pc]]) else NA_real_,
    data_src = if (!is.na(dc)) dplyr::n_distinct(t[[dc]]) else NA_real_,
    src_list = if (!is.na(dc)) paste(sort(unique(as.character(t[[dc]]))), collapse = ", ") else NA_character_
  )
}

db_files <- sort(inv$path[str_detect(basename(inv$path), "_db\\.rds$")])
message("Reading ", length(db_files), " dm databases ...")
db_summ <- map_dfr(db_files, function(f) {
  ts <- read_tables(f); if (is.null(ts)) return(tibble(file = f, table = NA))
  map_dfr(names(ts), ~ summ_table(ts[[.x]], .x, f))
})

# ---------------------------------------------------------------- markdown
w("# DATA_CATALOG.md\n")
w("Inventory of every `.rds` in the DudesData repo: what each database holds, the season/week range it covers, and headline counts. Regenerate with `Rscript catalog_rds.R`.\n")
w("_Generated %s. %d rds files, %s on disk._\n", Sys.Date(), nrow(inv), fmt_mb(sum(inv$size)))

w("## 1. Top-level layout\n")
w("| Dir | Files | Size | What it is |")
w("|---|---|---|---|")
desc <- c(
  dudes = "DudesFFA (ESPN league). File-per-week, seasons 2019-2025. Raw + derived.",
  app   = "DudesApp (NFL Fantasy API). dm databases per season-set + `temp/` scrape cache.",
  etl   = "Legacy-year conversions: `dudes/` reshaped into `app/` dm schema, one folder per season 2020-2025.",
  dataset = "Unified historical dm dataset 2020-2025 (merge of app/2023-24-25 + etl/*).",
  ".claude" = "ETL checkpoint rds (pipeline resume state)."
)
tt <- inv |> group_by(top) |> summarise(n = n(), sz = sum(size), .groups = "drop") |> arrange(desc(sz))
for (i in seq_len(nrow(tt)))
  w("| `%s/` | %d | %s | %s |", tt$top[i], tt$n[i], fmt_mb(tt$sz[i]),
    ifelse(is.na(desc[tt$top[i]]), "", desc[tt$top[i]]))
w("")

canon <- c("dataset", "app/2025-24")
w("## 2. Canonical dm databases (detail)\n")
w("`players` = distinct player-id values in the table; `data_src` = distinct projection sources.\n")
for (d in canon) {
  sub <- db_summ |> filter(dirname(file) == d, !is.na(table))
  w("### `%s/`\n", d)
  w("| DB / table | Rows | Cols | Season | Week | Players | data_src |")
  w("|---|---|---|---|---|---|---|")
  cur <- ""
  for (i in seq_len(nrow(sub))) {
    b <- basename(sub$file[i]); if (b != cur) { w("| **%s** | | | | | | |", b); cur <- b }
    w("| &nbsp;&nbsp;`%s` | %s | %d | %s | %s | %s | %s |",
      sub$table[i], cm(sub$rows[i]), sub$cols[i], sub$season[i], sub$week[i],
      cm(sub$players[i]), ifelse(is.na(sub$data_src[i]), "-", as.character(sub$data_src[i])))
  }
  w("")
}

w("## 3. Other dm database folders (per-file rollup)\n")
w("Same 7-database schema. Rows = summed across tables in the file.\n")
roll <- db_summ |> filter(!is.na(table), !dirname(file) %in% canon) |>
  group_by(file) |>
  summarise(dir = dirname(file[1]), db = basename(file[1]),
            tables = n(), rows = sum(rows),
            season = rng(unlist(str_split(season[season != "-"], "-"))),
            week = rng(unlist(str_split(week[week != "-"], "-"))),
            .groups = "drop") |>
  arrange(dir, db)
w("| Folder | DB file | Tables | Rows | Season | Week |")
w("|---|---|---|---|---|---|")
for (i in seq_len(nrow(roll)))
  w("| `%s/` | %s | %d | %s | %s | %s |", roll$dir[i], roll$db[i], roll$tables[i],
    cm(roll$rows[i]), roll$season[i], roll$week[i])
w("")

w("## 4. Projection sources (`data_src`)\n")
srcs <- db_summ |> filter(!is.na(src_list), src_list != "", nchar(src_list) < 400) |>
  distinct(table, src_list) |> group_by(table) |>
  summarise(src_list = src_list[which.max(nchar(src_list))], .groups = "drop")
for (i in seq_len(nrow(srcs))) w("- **`%s`**: %s", srcs$table[i], srcs$src_list[i])
w("")

# ---------------------------------------------------------------- dudes/
dud <- inv |> filter(top == "dudes", str_detect(path, "/\\d{4}/")) |>
  mutate(season = str_match(path, "dudes/(\\d{4})/")[, 2],
         fname = basename(path),
         week = as.integer(str_match(fname, "[wW]eek[_]?(\\d{1,2})")[, 2]),
         phase = str_match(fname, "week\\d{1,2}_([A-Za-z0-9]+)\\.rds$")[, 2],
         group = case_when(
           str_detect(fname, "^simulation_v") ~ "simulation_v3-6 (weekly, per phase)",
           str_detect(fname, "_scrap\\.rds$|weekly_webscrap|weeklies_scraps") ~ "raw web scrape",
           str_detect(fname, "projpoints|_players_projections|weekly_proj|points_projection|season_proj|drafted_season") ~ "projections / proj tables",
           str_detect(fname, "^rank") ~ "rank / rankAgainstPosition",
           str_detect(fname, "players_points|player_game_status|players\\.rds|post_matchups|weekly_results|weekly_matchups|matchups_json") ~ "actuals / matchups",
           str_detect(fname, "draft") ~ "draft",
           str_detect(fname, "simulation_(winner|points)_evaluation|simulations_history|prediction") ~ "sim evaluation",
           str_detect(fname, "id|espn_stat|injury|stats_id|not_mapped|not_imported") ~ "id maps / lookups",
           TRUE ~ "other"))
d_season <- dud |> group_by(season) |>
  summarise(files = n(), size = fmt_mb(sum(size)), weeks = rng(week),
            n_phases = n_distinct(na.omit(phase)), .groups = "drop")
w("## 5. `dudes/` (ESPN league) - file-per-week\n")
w("| Season | RDS files | Size | Week range | Distinct in-week phases |")
w("|---|---|---|---|---|")
for (i in seq_len(nrow(d_season)))
  w("| %s | %d | %s | %s | %d |", d_season$season[i], d_season$files[i],
    d_season$size[i], d_season$weeks[i], d_season$n_phases[i])
w("")
w("Phase tags (`week{N}_{phase}.rds`) evolve each year around the real NFL schedule - e.g. 2023: %s\n",
  paste(sort(unique(na.omit(dud$phase[dud$season == "2023"]))), collapse = ", "))
w("### Files by group x season\n")
gs <- dud |> count(group, season) |> pivot_wider(names_from = season, values_from = n, values_fill = 0)
sc <- sort(setdiff(names(gs), "group"))
w("| Group | %s |", paste(sc, collapse = " | "))
w("|%s", paste(rep("---|", length(sc) + 1), collapse = ""))
gs <- gs |> mutate(tot = rowSums(across(all_of(sc)))) |> arrange(desc(tot))
for (i in seq_len(nrow(gs)))
  w("| %s | %s |", gs$group[i], paste(map_chr(sc, ~ as.character(gs[[.x]][i])), collapse = " | "))
w("")

# dudes content stats
load1 <- function(p) tryCatch({ x <- readRDS(p)
  if (is.data.frame(x)) as_tibble(x)
  else if (is.list(x) && any(map_lgl(x, is.data.frame))) bind_rows(x[map_lgl(x, is.data.frame)])
  else NULL }, error = function(e) NULL)
d_stats <- map_dfr(sort(unique(na.omit(dud$season))), function(s) {
  tp <- load1(sprintf("dudes/%s/players_points.rds", s))
  wp <- load1(head(sort(Sys.glob(sprintf("dudes/%s/weekly_proj_table_*.rds", s))), 1))
  pj <- load1(head(sort(Sys.glob(sprintf("dudes/%s/dudesffa_projpoints_week*.rds", s))), 1))
  tibble(season = s,
    pts_rows = if (!is.null(tp)) nrow(tp) else NA,
    pts_players = if (!is.null(tp) && !is.na(pick(tp, c("playerId", "id")))) dplyr::n_distinct(tp[[pick(tp, c("playerId", "id"))]]) else NA,
    pts_weeks = if (!is.null(tp) && "week" %in% names(tp)) rng(tp$week) else "-",
    proj_rows = if (!is.null(wp)) nrow(wp) else NA,
    projpoints_rows = if (!is.null(pj)) nrow(pj) else NA)
})
w("### Content stats (representative file per season)\n")
w("| Season | players_points rows | distinct players | weeks | weekly_proj_table_1 rows | dudesffa_projpoints wk-file rows |")
w("|---|---|---|---|---|---|")
for (i in seq_len(nrow(d_stats))) { s <- d_stats[i, ]
  w("| %s | %s | %s | %s | %s | %s |", s$season, cm(s$pts_rows), cm(s$pts_players),
    s$pts_weeks, cm(s$proj_rows), cm(s$projpoints_rows)) }
w("")

# app/temp
tmp <- inv |> filter(str_detect(path, "app/temp/")) |>
  mutate(season = str_match(fname <- basename(path), "s(\\d{4})")[, 2],
         week = as.integer(str_match(path, "w(\\d{2})")[, 2]),
         kind = str_match(basename(path), "^(ffa_scrape_db|ffa_db|[A-Za-z]+)")[, 2])
w("## 6. `app/temp/` - scrape cache\n")
w("- %d files, %s. Seasons %s, weeks %s. Kinds: %s.",
  nrow(tmp), fmt_mb(sum(tmp$size)), rng(as.numeric(tmp$season)), rng(tmp$week),
  paste(sort(unique(na.omit(tmp$kind))), collapse = ", "))
w("- Filename pattern: `{kind}_s{season}w{week}_{phase}_{timestamp}.rds` - point-in-time snapshots of the weekly scrape/projection build.")
w("")
w("## 7. Notes\n")
w("- `app/2023/dudes_simulation.rds` (single table `dudes_simSeeds`, 21 MB) is the **obsolete** pre-dm simulation format - ignore it, use `dudes_simulation_db.rds` (two tables: seeds + 1000-sample simulations).")
w("- `etl/*/nfl_recap_db.rds` is empty (0 rows) for every legacy year; recaps only exist 2023+ (see `dataset/nfl_recap`, 311 rows). `etl/2022/nfl_teams_db.rds` is also empty.")
w("- `dudes_players_seeds` / `dudes_players_simulations` row counts differ slightly per file - seeds carry a few players that never made a simulated roster.")
w("- `missing_player_ids.rds` / `missing_player_id.rds` (app/2023*, dudes/2023-24): hand-maintained ID patches, plain tibbles matching `ffa_player_ids` schema - `bind_rows()` onto the main table.")
w("- `app/2023_compliance/` = `app/2023/` re-emitted to the current schema; `app/2023-24-25/` merges 2023-2025; `dataset/` adds legacy 2020-2022 on top.")

writeLines(out, "DATA_CATALOG.md")
message("wrote DATA_CATALOG.md (", length(out), " lines)")
