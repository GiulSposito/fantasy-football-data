#!/usr/bin/env Rscript
# Visual Report Generation
# Creates charts and detailed statistics from investigation results

library(tidyverse)
library(scales)

# Load summary data
summary_df <- read_csv("dataset/investigation_summary.csv", show_col_types = FALSE)

# Parse database source and type
summary_df <- summary_df %>%
  mutate(
    source = case_when(
      str_starts(database, "app_") ~ "app",
      str_starts(database, "etl_") ~ "TRUE",
      TRUE ~ "unknown"
    ),
    db_type = str_extract(database, "(?<=_)[^_]+$"),
    year = case_when(
      str_detect(database, "2023-24-25") ~ "2023-2025",
      str_detect(database, "2023") ~ "2023",
      TRUE ~ "unknown"
    )
  )

cat("\n=== VISUAL REPORT GENERATION ===\n\n")

# 1. Data Volume Analysis
cat("1. DATA VOLUME ANALYSIS\n")
cat("------------------------\n")

volume_summary <- summary_df %>%
  group_by(source, db_type) %>%
  summarise(
    total_rows = sum(rows, na.rm = TRUE),
    total_tables = n(),
    avg_completeness = mean(avg_completeness, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(total_rows))

print(volume_summary)

# 2. Completeness by Database Type
cat("\n2. COMPLETENESS BY DATABASE TYPE\n")
cat("---------------------------------\n")

completeness_summary <- summary_df %>%
  group_by(db_type) %>%
  summarise(
    tables = n(),
    avg_completeness = mean(avg_completeness, na.rm = TRUE),
    min_completeness = min(avg_completeness, na.rm = TRUE),
    max_completeness = max(avg_completeness, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_completeness))

print(completeness_summary)

# 3. Tables with Quality Issues
cat("\n3. TABLES WITH QUALITY ISSUES (<80% complete)\n")
cat("----------------------------------------------\n")

quality_issues <- summary_df %>%
  filter(avg_completeness < 80 | is.na(avg_completeness)) %>%
  select(database, table, rows, avg_completeness) %>%
  arrange(avg_completeness)

print(quality_issues)

# 4. Large Tables (>100K rows)
cat("\n4. LARGE TABLES (>100K rows)\n")
cat("-----------------------------\n")

large_tables <- summary_df %>%
  filter(rows > 100000) %>%
  select(database, table, rows, cols) %>%
  arrange(desc(rows))

print(large_tables)

# 5. Temporal Coverage Analysis
cat("\n5. TEMPORAL COVERAGE ANALYSIS\n")
cat("------------------------------\n")

temporal_coverage <- summary_df %>%
  filter(season_range != "N/A") %>%
  mutate(
    seasons_span = str_extract_all(season_range, "\\d{4}") %>%
      map_dbl(~{
        years <- as.numeric(.x)
        if(length(years) == 2) years[2] - years[1] + 1 else 1
      })
  ) %>%
  select(database, table, season_range, week_range, seasons_span) %>%
  arrange(desc(seasons_span))

print(temporal_coverage)

# 6. Database Size Estimates
cat("\n6. DATABASE SIZE ESTIMATES\n")
cat("---------------------------\n")

size_estimates <- summary_df %>%
  group_by(database) %>%
  summarise(
    total_rows = sum(rows, na.rm = TRUE),
    total_cols = sum(cols, na.rm = TRUE),
    tables = n(),
    est_size_mb = (total_rows * total_cols * 8) / (1024^2),  # Rough estimate
    .groups = "drop"
  ) %>%
  arrange(desc(total_rows))

print(size_estimates)

# 7. Schema Comparison (app vs etl)
cat("\n7. SCHEMA COMPARISON (app vs etl for same database type)\n")
cat("---------------------------------------------------------\n")

schema_comparison <- summary_df %>%
  group_by(db_type, table) %>%
  summarise(
    sources = n(),
    cols_app = max(ifelse(source == "app", cols, NA), na.rm = TRUE),
    cols_etl = max(ifelse(source == "etl", cols, NA), na.rm = TRUE),
    rows_app = max(ifelse(source == "app", rows, NA), na.rm = TRUE),
    rows_etl = max(ifelse(source == "etl", rows, NA), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(sources == 2) %>%  # Only tables present in both
  mutate(
    col_diff = cols_app - cols_etl,
    row_ratio = round(rows_app / rows_etl, 2)
  ) %>%
  filter(col_diff != 0 | row_ratio > 2 | row_ratio < 0.5) %>%
  arrange(desc(abs(col_diff)))

cat("Tables with schema or data volume differences:\n")
print(schema_comparison)

# 8. Quality Tiers
cat("\n8. QUALITY TIER CLASSIFICATION\n")
cat("-------------------------------\n")

quality_tiers <- summary_df %>%
  mutate(
    quality_tier = case_when(
      is.na(avg_completeness) ~ "Empty/Error",
      avg_completeness >= 95 ~ "Excellent (95-100%)",
      avg_completeness >= 80 ~ "Good (80-95%)",
      avg_completeness >= 60 ~ "Fair (60-80%)",
      TRUE ~ "Poor (<60%)"
    )
  ) %>%
  count(quality_tier) %>%
  arrange(desc(n))

print(quality_tiers)

# 9. Data Freshness (based on season coverage)
cat("\n9. DATA FRESHNESS ASSESSMENT\n")
cat("-----------------------------\n")

freshness <- summary_df %>%
  mutate(
    has_2025 = str_detect(season_range, "2025"),
    has_2024 = str_detect(season_range, "2024"),
    has_2023 = str_detect(season_range, "2023"),
    freshness_score = case_when(
      has_2025 ~ "Current (2025)",
      has_2024 ~ "Recent (2024)",
      has_2023 ~ "Historical (2023)",
      season_range == "N/A" ~ "Static/Metadata",
      TRUE ~ "Unknown"
    )
  ) %>%
  count(source, db_type, freshness_score) %>%
  arrange(source, db_type)

print(freshness)

# 10. Summary Statistics
cat("\n10. OVERALL SUMMARY STATISTICS\n")
cat("-------------------------------\n")

overall_stats <- list(
  total_databases = length(unique(summary_df$database)),
  total_tables = nrow(summary_df),
  total_records = sum(summary_df$rows, na.rm = TRUE),
  total_columns = sum(summary_df$cols, na.rm = TRUE),
  avg_completeness_all = mean(summary_df$avg_completeness, na.rm = TRUE),
  tables_with_issues = sum(summary_df$avg_completeness < 80, na.rm = TRUE),
  empty_tables = sum(summary_df$rows == 0, na.rm = TRUE),
  largest_table = summary_df %>%
    filter(rows == max(rows, na.rm = TRUE)) %>%
    pull(table) %>%
    first(),
  smallest_table = summary_df %>%
    filter(rows > 0, rows == min(rows[rows > 0], na.rm = TRUE)) %>%
    pull(table) %>%
    first()
)

cat("\nOverall Statistics:\n")
cat(sprintf("  Total Databases: %d\n", overall_stats$total_databases))
cat(sprintf("  Total Tables: %d\n", overall_stats$total_tables))
cat(sprintf("  Total Records: %s\n", comma(overall_stats$total_records)))
cat(sprintf("  Total Columns: %s\n", comma(overall_stats$total_columns)))
cat(sprintf("  Average Completeness: %.2f%%\n", overall_stats$avg_completeness_all))
cat(sprintf("  Tables with Issues (<80%%): %d\n", overall_stats$tables_with_issues))
cat(sprintf("  Empty Tables: %d\n", overall_stats$empty_tables))
cat(sprintf("  Largest Table: %s\n", overall_stats$largest_table))
cat(sprintf("  Smallest Table: %s\n", overall_stats$smallest_table))

# Save enhanced summary
saveRDS(
  list(
    summary = summary_df,
    volume = volume_summary,
    completeness = completeness_summary,
    quality_issues = quality_issues,
    temporal = temporal_coverage,
    sizes = size_estimates,
    schema_diff = schema_comparison,
    quality_tiers = quality_tiers,
    freshness = freshness,
    overall = overall_stats
  ),
  "dataset/visual_report_data.rds"
)

cat("\n\n✅ Visual report data saved to: dataset/visual_report_data.rds\n")

# Generate CSV exports
write_csv(volume_summary, "dataset/report_volume.csv")
write_csv(completeness_summary, "dataset/report_completeness.csv")
write_csv(quality_issues, "dataset/report_quality_issues.csv")
write_csv(temporal_coverage, "dataset/report_temporal_coverage.csv")
write_csv(size_estimates, "dataset/report_size_estimates.csv")

cat("✅ Individual CSV reports exported to dataset/report_*.csv\n")
cat("\n=== REPORT GENERATION COMPLETE ===\n")
