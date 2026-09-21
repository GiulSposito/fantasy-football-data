library(dm)
library(tidyverse)

## normalize FFA Predictions ####

# load
ffa_db <- readRDS("./dataset/ffa_db.rds")

# season/weeks/sources
ffa_db$ffa_proj_source_points |>
  distinct(season, week, data_src) |> 
  count(season, week) |> 
  pivot_wider(id_cols = season, names_from=week, values_from = n)

nfl_stats <- readRDS("./dataset/nfl_stats_db.rds")

# season/weeks/players
nfl_stats$nfl_players_points |>
  filter(!is.na(pts)) |> 
  distinct() |> 
  count(season, week) |> 
  pivot_wider(id_cols=season, names_from = week, values_from = n)


# 2021
ffa_db_21 <- readRDS("./etl/2021/ffa_db.rds")
ffa_db_21$ffa_proj_source_points |>
  distinct(season, week, data_src) |> 
  count(season, week) |> 
  pivot_wider(id_cols = season, names_from=week, values_from = n)

nfl_stats_21 <- readRDS("./etl/2021/nfl_stats_db.rds")
# season/weeks/players
nfl_stats_21$nfl_players_points |>
  filter(!is.na(pts)) |> 
  distinct() |> 
  count(season, week) |> 
  pivot_wider(id_cols=season, names_from = week, values_from = n)



