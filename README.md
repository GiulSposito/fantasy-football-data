# DudesData

Canonical fantasy football dataset for **"It's Football, Dudes!"** — a small
private NFL league — built by reshaping ffanalytics scrape projections and
league results into one harmonized schema for analysis.

- Start with **`CLAUDE.md`** for the full architecture, data lineage, and commands.
- Schema references: `app_DATAMODEL.md`, `dudes_DATAMODEL.md`,
  `app_DATA_DICTIONARY.md`, `dudes_DATA_DICTIONARY.md`.
- Generated inventory of every dataset file: `DATA_CATALOG.md`
  (regenerate with `Rscript catalog_rds.R`).

## What's in this repo

Only the canonical, converted dataset (`dataset/`) plus the ETL code and docs
are version controlled. Raw scrapes, per-season league exports, and
intermediate build products (`dudes/`, `app/`, `etl/`) are **not** committed —
they're either regenerated locally via `R/etl/` or obtained from their
original sources. See the "Repository scope" note in `CLAUDE.md` for details.

Superseded code and one-time migration scripts/reports are kept under
`archive/` for provenance.
