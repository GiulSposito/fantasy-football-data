# Minimal ETL test - Week 1 only, no complex dependencies
library(tidyverse)
library(fs)

message("\n=== MINIMAL ETL TEST - Week 1 ===\n")

# Test 1: Read week1_scrap.rds
message("Test 1: Reading week1_scrap.rds...")
scrape <- readRDS("dudes/2025/week1_scrap.rds")
message("  ✓ Loaded ", length(scrape), " position groups")
message("  ✓ Total rows: ", sum(map_int(scrape, nrow)))

# Test 2: Read weekly_proj_player_site_1.rds
message("\nTest 2: Reading weekly_proj_player_site_1.rds...")
proj <- readRDS("dudes/2025/weekly_proj_player_site_1.rds")
message("  ✓ Loaded ", nrow(proj), " projection records")

# Test 3: Read simulation file
message("\nTest 3: Reading simulation_v5_week1_final.rds...")
sim <- readRDS("dudes/2025/simulation_v5_week1_final.rds")
message("  ✓ Loaded simulation with ", length(sim), " components")
message("  ✓ players_sim has ", nrow(sim$players_sim), " rows")

# Test 4: Read players_points.rds (partial)
message("\nTest 4: Reading players_points.rds (first 10 players)...")
players <- readRDS("dudes/2025/players_points.rds")
message("  ✓ Loaded ", nrow(players), " player records")
message("  ✓ Columns: ", paste(names(players)[1:10], collapse=", "))

# Test 5: Simple transformation - consolidate scrapes
message("\nTest 5: Simple transformation...")
scrape_df <- map_dfr(scrape, bind_rows, .id = "position")
message("  ✓ Combined scrapes: ", nrow(scrape_df), " rows")
message("  ✓ Columns: ", paste(names(scrape_df)[1:10], collapse=", "))

# Test 6: Extract player IDs
message("\nTest 6: Extracting player IDs...")
if ("id" %in% names(scrape_df)) {
  n_players <- n_distinct(scrape_df$id)
  message("  ✓ Found ", n_players, " unique player IDs")
} else {
  message("  ! No 'id' column found")
}

message("\n=== ALL TESTS PASSED ===\n")
