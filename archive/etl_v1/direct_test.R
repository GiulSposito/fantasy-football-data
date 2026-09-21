#!/usr/bin/env Rscript
# Direct test without sourcing - Week 1 only

cat("\n=== DIRECT ETL TEST - Week 1 Only ===\n\n")

# Load libraries
library(tidyverse, warn.conflicts = FALSE)
library(dm, warn.conflicts = FALSE)
library(fs)
library(cli)

cat("✓ Libraries loaded\n")

# Simple config for week 1 only
config <- list(
  source_dir = "dudes/2025/",
  target_dir = "app/test_week1/",
  season = 2025,
  weeks = 1,  # ONLY WEEK 1
  strict_mode = FALSE
)

dir_create(config$target_dir)
cat("✓ Target directory created:", config$target_dir, "\n\n")

# Test 1: Read week 1 scrape
cat("Test 1: Reading week1_scrap.rds...\n")
scrape_file <- path(config$source_dir, "week1_scrap.rds")
scrape <- readRDS(scrape_file)
scrape_df <- map_dfr(scrape, bind_rows, .id = "position")
cat("  ✓ Loaded", nrow(scrape_df), "rows\n")

# Test 2: Read week 1 projections
cat("\nTest 2: Reading weekly_proj_player_site_1.rds...\n")
proj_file <- path(config$source_dir, "weekly_proj_player_site_1.rds")
proj <- readRDS(proj_file)
cat("  ✓ Loaded", nrow(proj), "projections\n")

# Test 3: Basic transformation - create player IDs table
cat("\nTest 3: Creating player IDs table...\n")
if ("id" %in% names(scrape_df)) {
  player_ids <- scrape_df %>%
    distinct(id, player, pos, team) %>%
    mutate(
      season = config$season,
      source = "scrape"
    )
  cat("  ✓ Created", nrow(player_ids), "player ID records\n")
} else {
  cat("  ! No 'id' column found\n")
  player_ids <- tibble()
}

# Test 4: Create simple projection table
cat("\nTest 4: Creating projection table...\n")
if (nrow(proj) > 0 && "id" %in% names(proj)) {
  proj_table <- proj %>%
    mutate(
      points = pts.proj,
      season = config$season,
      week = 1
    ) %>%
    select(id, pos, points, data_src, season, week)
  cat("  ✓ Created", nrow(proj_table), "projection records\n")
} else {
  cat("  ! Projection data incomplete\n")
  proj_table <- tibble()
}

# Test 5: Save results
cat("\nTest 5: Saving results...\n")
if (nrow(player_ids) > 0) {
  saveRDS(player_ids, path(config$target_dir, "player_ids.rds"))
  cat("  ✓ Saved player_ids.rds\n")
}
if (nrow(proj_table) > 0) {
  saveRDS(proj_table, path(config$target_dir, "proj_table.rds"))
  cat("  ✓ Saved proj_table.rds\n")
}

cat("\n=== TEST COMPLETE ===\n")
cat("Output directory:", config$target_dir, "\n")
cat("Files created:", length(dir_ls(config$target_dir)), "\n\n")
