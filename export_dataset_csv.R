#!/usr/bin/env Rscript
# Export the canonical dataset/ dm databases to CSV, one file per table.
# Usage: Rscript export_dataset_csv.R
suppressWarnings(suppressMessages({
  library(dm); library(dplyr); library(purrr); library(readr); library(jsonlite)
}))

if (!file.exists("DudesData.Rproj")) stop("run this from the DudesData repo root")

out_dir <- "dataset/export"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# same shape-detection used by catalog_rds.R: dm -> named tables, single
# data.frame -> itself, list of data.frames -> itself
read_tables <- function(f) {
  obj <- readRDS(f)
  if (inherits(obj, "dm")) return(dm_get_tables(obj))
  if (is.data.frame(obj)) return(setNames(list(obj), tools::file_path_sans_ext(basename(f))))
  if (is.list(obj) && all(map_lgl(obj, is.data.frame))) return(obj)
  NULL
}

# list-columns (e.g. simulation seeds, quantiles) can't go straight to CSV;
# serialize each cell to JSON so no data is dropped
flatten_list_cols <- function(t) {
  mutate(t, across(where(is.list), ~ map_chr(.x, ~ toJSON(.x, auto_unbox = TRUE))))
}

rds <- list.files("dataset", pattern = "\\.rds$", full.names = TRUE)

for (f in rds) {
  db_name <- tools::file_path_sans_ext(basename(f))
  tables <- read_tables(f)
  if (is.null(tables)) { message("skip (not tabular): ", f); next }
  for (tn in names(tables)) {
    csv_path <- file.path(out_dir, sprintf("%s__%s.csv", db_name, tn))
    write_csv(flatten_list_cols(tables[[tn]]), csv_path)
    message("wrote ", csv_path)
  }
}
