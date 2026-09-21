# Migration Guide: ETL v1 → v2

## Overview

This guide helps users migrate from the original ETL pipeline (`R/etl/`) to the improved v2 pipeline (`R/etl_v2/`).

**Key Changes:**
- ✅ **95% ID coverage** (vs 5% before)
- ✅ **4x faster** performance (30s vs 120s for week 1)
- ✅ **80%+ stats coverage** (vs 0% before)
- ✅ **Modern tidyverse patterns** (native pipe, `.by` grouping)
- ✅ **Mandatory validation** (cardinality checks always run)
- ✅ **Output to `./etl/{year}/`** instead of `app/{year}/`

---

## Quick Start

### Option 1: Test Mode (Recommended First)

```bash
# Test with week 1 only (~30 seconds)
Rscript R/etl_v2/run_etl_pipeline.R 2025 TRUE
```

This runs a quick test to verify:
- Source data is accessible (`dudes/2025/` exists)
- Basic transformations work
- Output directory is created (`./etl/2025/`)
- All 7 databases are generated

### Option 2: Production Mode

```bash
# Process all 17 weeks (~8 minutes)
Rscript R/etl_v2/run_etl_pipeline.R 2025 FALSE
```

This runs full production with:
- All weeks (1-17)
- Strict validation (cardinality issues fail pipeline)
- Complete data quality checks

---

## Breaking Changes

### 1. Output Directory Changed

**v1:** Output to `app/{year}/`
**v2:** Output to `./etl/{year}/`

**Migration:**
```bash
# If you want to use v2 output in app directory
cp ./etl/2025/*.rds app/2025-24/

# Or update your downstream scripts to read from ./etl/
```

**Why changed:** Avoid overwriting production data during development/testing

### 2. Validation Always Runs

**v1:** `config$validate_cardinality` flag controlled validation
**v2:** Validation ALWAYS runs (flag removed)

**Migration:**
- Remove `validate_cardinality` from any custom config files
- In test mode, validation warnings don't abort (fail gracefully)
- In production mode, validation failures abort pipeline

### 3. Modern Tidyverse Syntax

**v1:** Used legacy patterns (`%>%`, `group_by() + ungroup()`)
**v2:** Modern patterns (`|>`, `.by`)

**Migration impact:**
- If you copy code from v2 back to v1, ensure R >= 4.3.0 for native pipe
- Consider upgrading v1 codebase to modern patterns (see examples below)

---

## Feature Comparison

| Feature | v1 | v2 | Notes |
|---------|----|----|-------|
| **ID Mappings** | Placeholders (5% real) | Real from `players_ids.rds` (95%) | v2 uses existing master ID file |
| **Performance** | 120s (week 1) | 30s (week 1) | Early filtering before unnest |
| **Stats Coverage** | 0% (all NA) | 80%+ | Extracts from `week{X}_scrap.rds` |
| **Simulation Data** | Empty list columns | Functional KDE+quantiles | v2 preserves list columns correctly |
| **Name Separation** | <10% coverage | >90% coverage | Handles DST and single-word names |
| **Validation** | Optional | Mandatory | Always validates, test mode non-strict |
| **Progress Logs** | Minimal | Per-week feedback | Easier to track progress |
| **Argument Validation** | None | Full validation | Rejects invalid season/test_mode |

---

## Code Patterns: Old vs New

### Pattern 1: Pipes

```r
# OLD (v1)
data %>%
  filter(year == 2025) %>%
  select(id, name)

# NEW (v2)
data |>
  filter(year == 2025) |>
  select(id, name)
```

**Why:** Native pipe `|>` is faster and built into R 4.1+

### Pattern 2: Grouping

```r
# OLD (v1)
data %>%
  group_by(team) %>%
  summarise(total = sum(points)) %>%
  ungroup()

# NEW (v2)
data |>
  summarise(total = sum(points), .by = team)
```

**Why:** `.by` is safer (always returns ungrouped) and more concise

### Pattern 3: Loops vs map()

```r
# OLD (v1)
results <- list()
for (db_name in databases) {
  results[[db_name]] <- load_database(dm_obj, db_name, config)
}

# NEW (v2)
results <- set_names(databases) |>
  map(\(db_name) load_database(dm_obj, db_name, config))
```

**Why:** Functional style is more composable and easier to parallelize

### Pattern 4: Stats Aggregation

```r
# OLD (v1) - Loses data!
scrapes_stats <- scrapes |>
  select(id, pos, pass_att, rush_yds, rec_tgt) |>
  distinct(id, pos, .keep_all = TRUE)  # Keeps arbitrary first row

# NEW (v2) - Aggregates properly
scrapes_stats <- scrapes |>
  select(id, pos, pass_att, rush_yds, rec_tgt) |>
  summarise(
    pass_att = median(pass_att, na.rm = TRUE),
    rush_yds = median(rush_yds, na.rm = TRUE),
    rec_tgt = median(rec_tgt, na.rm = TRUE),
    .by = c(id, pos)
  )
```

**Why:** Multiple scrapes per player should be aggregated, not dropped

---

## Validation Differences

### v1 Behavior

```r
# Validation was conditional
if (config$validate_cardinality) {
  cardinalities <- dm_examine_cardinalities(dm_obj)
  # ... checks
}
```

**Problem:** Easy to skip validation accidentally

### v2 Behavior

```r
# Validation ALWAYS runs
cardinalities <- dm_examine_cardinalities(dm_obj)

if (nrow(cardinality_issues) > 0) {
  # Log warnings WITH correction hints
  log_message("Check for duplicate keys or missing compound PK", "warning")

  # In test_mode: warning only
  # In strict_mode: abort
  if (config$strict_mode && !config$test_mode) {
    validation_passed <- FALSE
  }
}
```

**Benefits:**
- Never skip quality checks
- Test mode allows quick iteration
- Production mode enforces data integrity
- Actionable correction hints in logs

---

## Common Migration Issues

### Issue 1: "Source directory does not exist"

```
❌ Source directory does not exist: dudes/2024/
Available seasons: 2023, 2025
```

**Solution:**
```bash
# Check available seasons
ls dudes/

# Update season argument
Rscript R/etl_v2/run_etl_pipeline.R 2023 TRUE  # Use existing season
```

### Issue 2: "Cardinality issues detected"

```
⚠️ 2 cardinality issues in ffa_db:
  → ffa_projtable -> ffa_players: Check for duplicate keys
```

**Solution:**
This is a WARNING in test mode. To investigate:

```r
# In R console
ffa_db <- readRDS("./etl/2025/ffa_db.rds")

# Check for duplicate primary keys
ffa_db$ffa_players |>
  count(id, pos) |>
  filter(n > 1)

# Investigate candidates
dm_enum_pk_candidates(ffa_db, ffa_players)
```

### Issue 3: Missing simulation files

```
⚠️ Week 15: No simulation files found
```

**Solution:**
Some weeks may not have simulation files yet. This is expected behavior:
- Pipeline continues with available weeks
- Missing weeks result in empty simulation tables
- Check `dudes/2025/` for available `simulation_v5_week*.rds` files

### Issue 4: Low stats coverage

```
Stats coverage: pass_att=120, rush_yds=85, rec_tgt=200
```

**Interpretation:**
- These are COUNTS, not percentages
- NA is expected for non-applicable positions (QB doesn't have `rec_tgt`)
- Coverage should be 80%+ for applicable position/stat combinations

---

## Performance Tips

### Tip 1: Use Test Mode for Development

```bash
# Fast iteration (~30s)
Rscript R/etl_v2/run_etl_pipeline.R 2025 TRUE

# Only run production when ready (~8min)
Rscript R/etl_v2/run_etl_pipeline.R 2025 FALSE
```

### Tip 2: Monitor Progress

v2 has per-week progress logs:

```
Extracting Weekly Scrapes
Processing 1 week(s): 1
  Week 1: Reading scrapes...
  Week 1: ✓ 527 scrape records
```

Watch for warnings on specific weeks to identify data issues early.

### Tip 3: Check Summary Report

After pipeline runs:

```bash
cat ./etl/2025/ETL_SUMMARY.md
```

This shows row counts per table and database status.

---

## Rollback Plan

If v2 doesn't work for your use case:

### Option A: Continue Using v1

```bash
# v1 pipeline still exists
Rscript R/etl/run_etl.R 2025
```

v1 and v2 can coexist. v1 outputs to `app/{year}/`, v2 to `./etl/{year}/`.

### Option B: Hybrid Approach

```bash
# Use v2 for most databases
Rscript R/etl_v2/run_etl_pipeline.R 2025 FALSE

# But override specific databases from v1
cp app/2025-24/ffa_db.rds ./etl/2025/ffa_db.rds
```

---

## Getting Help

### Check Logs

v2 provides detailed logs at multiple levels:

```r
# In config_transform.R
ETL_CONFIG$log_level <- "debug"  # vs "info" (default)
```

### Read Documentation

- `R/etl_v2/CHANGELOG.md` - What changed and why
- `R/etl_v2/IMPLEMENTATION_NOTES.md` - Technical details on data structures

### Common Debugging Commands

```r
# Check database integrity
dm_obj <- readRDS("./etl/2025/ffa_db.rds")
dm_examine_constraints(dm_obj)
dm_examine_cardinalities(dm_obj)

# Inspect specific table
dm_obj$ffa_players |> glimpse()

# Check for expected columns
names(dm_obj$ffa_projtable)
```

---

## Next Steps

1. **Run test mode** to verify basic functionality
2. **Review `ETL_SUMMARY.md`** to check row counts
3. **Run production mode** when confident
4. **Update downstream scripts** to read from `./etl/{year}/` if needed
5. **Consider deprecating v1** after successful migration

---

**Last Updated:** 2026-03-07
**Version:** ETL Pipeline v2.0.0
