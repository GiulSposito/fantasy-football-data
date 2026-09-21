# DudesData

Canonical fantasy football dataset for **"It's Football, Dudes!"** — a small
private NFL league — built by reshaping ffanalytics scrape projections and
league results into one harmonized schema for analysis.

- Generated inventory of every dataset file: `DATA_CATALOG.md`
  (regenerate with `Rscript catalog_rds.R`).
- Dataset table reference: `dataset/README.md`.
- Analyses: 14 Quarto EDA reports on projection accuracy, calibration, and
  league outcomes in `reports/` (rendered `.md` + source `.qmd`).

## What's in this repo

This repo publishes only the consolidated, historical output of the DudesData
pipeline:

- **`dataset/`** — the canonical dm databases (2020–2025), the one dataset to
  use for analysis. `dataset/export/` carries a zipped CSV per table (~32MB,
  versioned); the raw CSVs themselves are regenerable locally via
  `Rscript export_dataset_csv.R` and aren't committed (~189MB).
- **`R/`** and **`catalog_rds.R`** — the ETL/merge scripts that produce
  `dataset/` and the catalog script that inventories it.
- **`reports/`** — the Quarto analyses built on top of `dataset/`.

Raw scrapes, per-season league exports, intermediate build products, and
superseded/one-time migration code and internal docs are **not** committed —
they live locally under `dudes/`, `app/`, `etl/`, and `archive/` for
provenance and regeneration, but aren't part of this published repo.
