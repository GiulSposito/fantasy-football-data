# DudesData Unified Historical Dataset (2020-2025)

This directory contains the complete consolidated DudesData fantasy football dataset spanning 6 seasons (2020-2025), merging data from individual year files into unified databases.

## Quick Access

- **New to this dataset?** Start with [`QUICK_START.md`](QUICK_START.md)
- **Need full details?** Read [`MERGE_COMPLETE_REPORT.md`](MERGE_COMPLETE_REPORT.md)
- **Want a summary?** See [`MERGE_SUMMARY.txt`](MERGE_SUMMARY.txt)

## Dataset Files (29.49 MB total)

### 7 Unified Databases

| File | Tables | Rows | Size | Coverage |
|------|--------|------|------|----------|
| [`ffa_db.rds`](ffa_db.rds) | 5 | 134,500 | 9.67 MB | 2020-2025 |
| [`nfl_stats_db.rds`](nfl_stats_db.rds) | 4 | 374,977 | 1.01 MB | 2019-2025 |
| [`nfl_players_db.rds`](nfl_players_db.rds) | 2 | 122,361 | 0.26 MB | 2019-2025 |
| [`nfl_round_db.rds`](nfl_round_db.rds) | 5 | 37,294 | 0.08 MB | 2020-2025 |
| [`dudes_simulation_db.rds`](dudes_simulation_db.rds) | 2 | 32,944 | 17.17 MB | 2020-2024 |
| [`nfl_recap_db.rds`](nfl_recap_db.rds) | 1 | 311 | 1.30 MB | 2023-2025 |
| [`nfl_teams_db.rds`](nfl_teams_db.rds) | 2 | 60 | 1.50 KB | 2020-2025 |

**Total:** 702,447 records across 21 tables

## CSV Export

`export/` holds a zipped CSV per table (~32MB total, versioned) — one
`<db>__<table>.zip` per `<db>__<table>.csv`, e.g.
`export/ffa_db__ffa_projtable.zip`. The raw (unzipped) CSVs are regenerated
locally via `Rscript export_dataset_csv.R` from the repo root and aren't
committed.

## Documentation Files

### Essential Reading

1. **[QUICK_START.md](QUICK_START.md)** (4 KB)
   - Code examples for loading and using data
   - Common queries and patterns
   - Quick reference tables

2. **[MERGE_COMPLETE_REPORT.md](MERGE_COMPLETE_REPORT.md)** (19 KB)
   - Complete merge operation documentation
   - Table-by-table analysis
   - Schema harmonization details
   - Data quality metrics
   - Known issues and gaps

3. **[MERGE_SUMMARY.txt](MERGE_SUMMARY.txt)** (3 KB)
   - High-level overview in text format
   - Key statistics at a glance
   - Quick reference for metrics

### Technical Files

4. **[merge_validation.csv](merge_validation.csv)** (5.3 KB)
   - 106 rows of validation data
   - Source and merged row counts
   - Status tracking (LOADED, PASS, WARNINGS)
   - Use for auditing merge results

5. **[merge_execution_v2.log](merge_execution_v2.log)** (22 KB)
   - Complete execution trace (403 lines)
   - Timestamped progress messages
   - Deduplication statistics
   - Validation results

6. **[merge_historical_data_v2.R](merge_historical_data_v2.R)** (12 KB)
   - Final merge script with type harmonization
   - Can be re-run to add new seasons
   - Fully documented and commented

### Legacy Files

- `merge_execution.log` - First merge attempt log (before type harmonization)
- `merge_historical_data.R` - Initial script version
- `MERGE_LOG.md` - Early merge documentation

## Key Features

### ✅ Comprehensive Coverage
- **6 seasons** of data (2020-2025)
- **2.4M source records** consolidated
- **1.69M duplicates** removed
- **28 tables** merged across 7 databases

### ✅ Data Quality
- All critical data preserved
- Type mismatches resolved
- Temporal integrity maintained
- Validation performed on all tables

### ✅ Schema Harmonization
- Player IDs standardized to character type
- Team IDs normalized
- Playoff seeding unified
- All type conversions lossless

### ✅ Efficient Storage
- 82.9% size reduction (172.5 MB → 29.49 MB)
- Intelligent deduplication
- Compressed RDS format
- dm relational structure

## Data Lineage

```
Source Data (2.4M rows)
├── etl/2020/     → 636,490 rows
├── etl/2021/     → 103,500 rows
├── etl/2022/     → 721,588 rows
└── app/2023-24-25/ → 930,183 rows
                     ↓
            Merge + Deduplication
              (-1.69M duplicates)
                     ↓
        Unified Dataset (702K rows)
```

## Usage Example

```r
library(tidyverse)
library(dm)

# Load database
ffa_db <- readRDS("dataset/ffa_db.rds")

# Extract table
projections <- ffa_db$ffa_projtable

# Filter for latest week 17 data
week17 <- projections |>
  filter(season == 2025, week == 17) |>
  group_by(id) |>
  filter(timestamp == max(timestamp)) |>
  ungroup()
```

See [QUICK_START.md](QUICK_START.md) for more examples.

## Known Data Gaps

- **2021 projections:** Only week 1 available
- **2020 advanced stats:** Not available from NFL API
- **2022 teams data:** Missing from source
- **2020-2022 recaps:** Feature introduced in 2023
- **2025 simulations:** Not yet generated
- **2024 simulations:** Limited to weeks 2-4

See [MERGE_COMPLETE_REPORT.md](MERGE_COMPLETE_REPORT.md) section "Known Data Gaps" for details.

## Schema Compatibility Notes

### Type Changes Applied

All databases use **character type** for player/team IDs (converted from integer in 2020-2022):

```r
# ✅ Correct
filter(playerId == "4241479")

# ❌ Will fail
filter(playerId == 4241479)
```

### Breaking Changes

**nfl_players_adv_stats** schema completely changed between 2022 and 2023:
- 2020-2022: roster percentages, targets, touches
- 2023-2025: transaction data, auction data, league availability

Cannot compare advanced stats across this boundary.

See `/Users/gsposito/Projects/DudesData/CLAUDE.md` for complete schema documentation.

## File Organization

```
dataset/
├── README.md                          ← You are here
├── QUICK_START.md                     ← Start here for usage
├── MERGE_COMPLETE_REPORT.md           ← Full documentation
├── MERGE_SUMMARY.txt                  ← Quick overview
│
├── ffa_db.rds                         ← Database files (7 total)
├── nfl_stats_db.rds
├── nfl_players_db.rds
├── nfl_round_db.rds
├── dudes_simulation_db.rds
├── nfl_recap_db.rds
├── nfl_teams_db.rds
│
├── merge_validation.csv               ← Validation data
├── merge_execution_v2.log             ← Execution log
├── merge_historical_data_v2.R         ← Merge script
│
└── [legacy files]                     ← Historical artifacts
```

## Performance Metrics

- **Execution Time:** ~22 seconds
- **Peak Memory:** ~500 MB
- **Processing Rate:** 108,716 rows/second
- **Databases Processed:** 7
- **Tables Merged:** 28
- **Deduplication Rate:** 70.6%

## Future Maintenance

### Adding New Seasons

1. Place new season RDS files in `etl/YYYY/`
2. Run `merge_historical_data_v2.R`
3. Review validation results
4. Update documentation

### Refreshing Data

1. Replace source files in `etl/` or `app/`
2. Re-run merge script (idempotent)
3. Existing unified files will be overwritten
4. Check logs for new warnings

### Troubleshooting

- **Missing columns?** Check schema compatibility in CLAUDE.md
- **Type errors?** All IDs are now character type
- **Missing data?** Check known gaps in MERGE_COMPLETE_REPORT.md
- **Validation warnings?** See merge_validation.csv for details

## Credits

**Merge Operation:** 2026-03-08
**Script Version:** v2 (with type harmonization)
**Author:** Claude Code
**Dataset Version:** 1.0

## Related Documentation

- **Project Overview:** `/Users/gsposito/Projects/DudesData/CLAUDE.md`
- **Data Model (app):** `/Users/gsposito/Projects/DudesData/app_DATAMODEL.md`
- **Data Dictionary:** `/Users/gsposito/Projects/DudesData/data_DATA_DICTIONARY.md`

## Questions?

1. **For usage questions:** See [QUICK_START.md](QUICK_START.md)
2. **For schema questions:** See `/Users/gsposito/Projects/DudesData/CLAUDE.md`
3. **For data quality questions:** See [MERGE_COMPLETE_REPORT.md](MERGE_COMPLETE_REPORT.md)
4. **For technical issues:** Check [merge_execution_v2.log](merge_execution_v2.log)

---

**Last Updated:** 2026-03-08
**Dataset Status:** ✅ Production Ready
**Total Records:** 702,447 rows
**Total Size:** 29.49 MB
**Temporal Coverage:** 2019-2025
