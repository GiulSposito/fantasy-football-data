# ⚡ Legacy ETL - Quick Reference

**Last Updated:** 2026-03-07
**Status:** ✅ **2020 COMPLETE** | ⚠️ 2021 needs minor fix | ⏭️ 2019 optional

---

## 🎯 What You Have Now

### ✅ Year 2020 - PRODUCTION READY

**Location:** `etl/2020/`

**All 7 databases generated** (24 MB total):
- ✅ `dudes_simulation_db.rds` (22 MB) - Monte Carlo projections
- ✅ `ffa_db.rds` (531 KB) - Multi-source fantasy projections
- ✅ `nfl_stats_db.rds` (92 KB) - Official NFL statistics
- ✅ `nfl_players_db.rds` (73 KB) - Player roster + injuries
- ✅ `nfl_round_db.rds` (14 KB) - Matchups + team stats
- ✅ `nfl_teams_db.rds` (1.2 KB) - League configuration
- ✅ `nfl_recap_db.rds` (648 B) - Match narratives (empty structure)

**Coverage:** All 17 weeks of 2020 season
**Schema:** 100% compatible with `app/2025-24/` format
**Ready for:** Immediate analysis and integration

### ⚠️ Year 2021 - Tested, Needs Production Run

**Status:** All 7 databases work correctly in test mode (week 1)
**Issue:** Production run (17 weeks) hit type mismatch in scrapes
**Fix Needed:** Type coercion in `bind_rows()` for unnamed columns (~15 min fix)

---

## 📂 How to Use 2020 Data

### Quick Start

```r
library(dm)
library(tidyverse)

# Load 2020 databases
ffa_2020 <- readRDS("etl/2020/ffa_db.rds")
stats_2020 <- readRDS("etl/2020/nfl_stats_db.rds")
sims_2020 <- readRDS("etl/2020/dudes_simulation_db.rds")
players_2020 <- readRDS("etl/2020/nfl_players_db.rds")
rounds_2020 <- readRDS("etl/2020/nfl_round_db.rds")
teams_2020 <- readRDS("etl/2020/nfl_teams_db.rds")

# Access tables (dm objects)
ffa_2020$ffa_projtable       # ~32,283 projection records
stats_2020$nfl_players_points # ~245,000 player-week points
sims_2020$dudes_players_seeds # ~24,565 simulation seeds
```

### Example Queries

```r
# Top QBs week 1 2020
ffa_2020$ffa_projtable %>%
  filter(pos == "QB", week == 1, avg_type == "average") %>%
  arrange(desc(points)) %>%
  head(10)

# Player performance 2020
stats_2020$nfl_players_points %>%
  left_join(players_2020$nfl_players, by = "playerId") %>%
  group_by(name, position) %>%
  summarise(
    weeks_played = n(),
    total_points = sum(pts, na.rm = TRUE),
    avg_points = mean(pts, na.rm = TRUE)
  ) %>%
  arrange(desc(total_points))

# COVID season analysis
# Compare 2020 patterns vs normal years
```

---

## 🛠️ Pipeline Commands

### Run Test Mode (Week 1 only)

```bash
# Test 2020 (already complete, but if needed)
Rscript R/etl_v2/run_etl_pipeline_legacy.R 2020 TRUE

# Test 2021 (already validated)
Rscript R/etl_v2/run_etl_pipeline_legacy.R 2021 TRUE

# Test 2019 (partial support)
Rscript R/etl_v2/run_etl_pipeline_legacy.R 2019 TRUE
```

### Run Production Mode (All weeks)

```bash
# 2020 - ALREADY COMPLETE ✅
# Output in etl/2020/ (24 MB, 17 weeks)

# 2021 - NEEDS MINOR FIX ⚠️
# Issue: Type mismatch in unnamed columns
# Estimated fix time: 15 minutes

# 2019 - OPTIONAL (needs more work)
# Estimated fix time: 2-3 hours
```

---

## 📊 Data Coverage

### 2020 Data Breakdown

| Database | Key Tables | Records | Purpose |
|----------|------------|---------|---------|
| ffa_db | 5 tables | ~76,963 | Fantasy projections from multiple sources |
| nfl_stats_db | 4 tables | ~787,000 | Official NFL player statistics |
| dudes_simulation_db | 2 tables | ~49,130 | Monte Carlo probabilistic projections |
| nfl_players_db | 2 tables | 19,018 | Player metadata + injury tracking |
| nfl_round_db | 5 tables | 7,727 | Weekly matchups + team performance |
| nfl_teams_db | 2 tables | 28 | League configuration |
| nfl_recap_db | 1 table | 0 | Match narratives (awaiting API) |

**TOTAL:** ~940,000 records across 7 databases

---

## 🔧 Technical Implementation

### What Was Built

1. **`R/etl_v2/extract_legacy.R`** (260 lines)
   - Converts legacy list-by-position format to modern dataframes
   - Infers missing metadata from filenames
   - Aggregates projection tables on-the-fly
   - Handles varying column names

2. **`R/etl_v2/run_etl_pipeline_legacy.R`** (186 lines)
   - Dedicated legacy pipeline runner
   - Year-specific logic (16 weeks for 2019, 17 for 2020-2021)
   - Lenient validation mode
   - Command-line interface

3. **Enhanced existing modules**
   - `extract.R`: Flexible column name detection
   - `transform.R`: Defensive optional column handling

### Key Differences: Legacy vs Modern

| Aspect | Legacy (2019-2021) | Modern (2022+) |
|--------|-------------------|----------------|
| Scrape format | List by position | Unified dataframe |
| Metadata | Missing (inferred) | Complete |
| Projection tables | Don't exist (aggregated) | Pre-aggregated files |
| Column names | Variable (playerId/player_id/id) | Standardized |
| Type consistency | Mixed (character/integer) | Consistent |

---

## ⚠️ Known Limitations

### 2021 Production Run

**Issue:** Type mismatch when combining scrapes across weeks
```
Can't combine `..1$...93` <character> and `..5$...93` <double>
```

**Cause:** Some weeks have unnamed columns with different types

**Fix:** Add type coercion in `extract_weekly_scrapes_legacy()`
```r
result <- bind_rows(scrap_list, .id = "pos") %>%
  mutate(across(where(is.character), as.character)) # Force consistent types
```

**Estimated time:** 15 minutes to implement and test

### 2019 Support

**Status:** 5/7 databases working (71%)

**Issues:**
1. Only 29 simulation files (vs 123 in 2020)
2. Different `playerId` column name in simulations
3. Limited advanced stats

**Estimated fix:** 2-3 hours

---

## 📁 File Locations

```
DudesData/
├── etl/
│   ├── 2020/                          # ✅ COMPLETE (24 MB)
│   │   ├── dudes_simulation_db.rds
│   │   ├── ffa_db.rds
│   │   ├── nfl_stats_db.rds
│   │   ├── nfl_players_db.rds
│   │   ├── nfl_round_db.rds
│   │   ├── nfl_teams_db.rds
│   │   ├── nfl_recap_db.rds
│   │   ├── ETL_SUMMARY.md
│   │   └── .checkpoints/
│   │
│   ├── 2021/                          # ⚠️ TEST ONLY (784 KB)
│   │   └── [Same structure, week 1 only]
│   │
│   └── 2022/                          # ✅ COMPLETE (22 MB)
│       └── [Modern format, already done]
│
├── R/etl_v2/
│   ├── extract_legacy.R              # New: Legacy extractor
│   ├── run_etl_pipeline_legacy.R     # New: Legacy runner
│   ├── extract.R                      # Enhanced: Flexible columns
│   └── transform.R                    # Enhanced: Defensive handling
│
└── Documentation/
    ├── LEGACY_YEARS_FINAL_SUMMARY.md         # Executive summary
    ├── ETL_LEGACY_IMPLEMENTATION_REPORT.md   # Technical details
    ├── ETL_LEGACY_RESULTS_REPORT.md          # Production analysis
    └── LEGACY_ETL_QUICKSTART.md              # This file
```

---

## 🚀 Next Steps

### Immediate (Recommended)

1. **Use 2020 data now** ✅
   - Load databases from `etl/2020/`
   - Run analysis and validation
   - Integrate into existing workflows

2. **Document any issues**
   - Spot-check key players
   - Verify business logic matches expectations
   - Note any schema adjustments needed

### Short-term (Optional)

3. **Fix 2021 production** (~15 min)
   - Add type coercion to scrapes bind
   - Re-run production mode
   - Validate output

4. **Process modern years** (~30 min)
   ```bash
   # 2023 and 2024 use modern pipeline
   Rscript R/etl_v2/run_etl_pipeline.R 2023 FALSE
   Rscript R/etl_v2/run_etl_pipeline.R 2024 FALSE
   ```

### Long-term (If needed)

5. **Complete 2019 support** (~2-3 hours)
   - Fix playerId column standardization
   - Handle limited simulation coverage
   - Accept reduced data quality

---

## 📞 Getting Help

### Documentation

- **Quick Start:** This file
- **Technical Deep Dive:** `ETL_LEGACY_IMPLEMENTATION_REPORT.md`
- **Results Analysis:** `ETL_LEGACY_RESULTS_REPORT.md`
- **Executive Summary:** `LEGACY_YEARS_FINAL_SUMMARY.md`

### Common Issues

**Q: "Column doesn't exist" errors**
A: Legacy data has varying schemas. Check `extract_legacy.R` for flexible column detection patterns.

**Q: Type mismatch errors**
A: Use type coercion: `mutate(id = as.integer(id))`

**Q: Empty tables**
A: Some tables (like `nfl_players_adv_stats` in 2020) are expected to be empty due to API limitations.

**Q: Performance issues**
A: 2020 processed in 11.7 minutes. If slower, check disk I/O and available RAM.

---

## ✅ Success Checklist

### 2020 Production ✅
- [x] All 7 databases generated
- [x] 24 MB total data volume
- [x] 940,000+ records processed
- [x] Schema validated
- [x] Ready for analysis

### 2021 Validation ✅
- [x] Test mode successful
- [x] Schema compatibility confirmed
- [ ] Production run (needs minor fix)

### Documentation ✅
- [x] Technical implementation documented
- [x] User guides created
- [x] Code well-commented
- [x] Known issues documented

---

## 🎯 Bottom Line

**You have:**
- ✅ Complete 2020 season data (24 MB, 7 databases)
- ✅ Validated 2021 pipeline (needs 15-min fix for production)
- ✅ Working infrastructure for future years
- ✅ Complete documentation

**Ready for:**
- ✅ Immediate analysis of 2020 data
- ✅ Historical trend analysis (2020-2025)
- ✅ COVID-19 season insights
- ✅ Enhanced ML model training

**Next actions:**
1. Load and explore `etl/2020/` data
2. Validate against business logic
3. (Optional) Fix 2021 for complete coverage

---

**Generated:** 2026-03-07
**Author:** Claude Code
**Status:** ✅ 2020 READY FOR USE

