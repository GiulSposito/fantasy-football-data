# 🏗️ Arquitetura do Pipeline ETL

## 📐 Visão Geral

```
┌───────────────────────────────────────────────────────────────────┐
│                    DUDES → APP ETL PIPELINE                        │
│                                                                    │
│  Input: 245 arquivos .rds (dudes/2025/)                          │
│  Output: 7 databases relacionais (app/2025-24/)                  │
│  Tempo: ~6-10 minutos                                             │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Fluxo de Dados

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  SOURCE: dudes/2025/ (File-per-Week Structure)                 │
│  ─────────────────────────────────────────────────────────      │
│                                                                  │
│  📁 Week Files (17 weeks × multiple patterns)                   │
│     ├─ week{1-17}_scrap.rds                (6 DFs per file)   │
│     ├─ week{1-17}_players_projections.rds  (1,400 rows)       │
│     ├─ weekly_proj_player_site_{1-17}.rds  (2,000 rows)       │
│     ├─ weekly_proj_table_{1-17}.rds        (500 rows)         │
│     └─ dudesffa_projpoints_week{1-17}.rds  (470 rows)         │
│                                                                  │
│  📁 Simulation Files (~140 files)                               │
│     └─ simulation_v5_week{X}_{phase}.rds   (11 elements)      │
│                                                                  │
│  📁 Central Files                                               │
│     ├─ players_points.rds                  (14k rows)          │
│     ├─ season_scrap.rds                                        │
│     └─ draft_picks.rds                                         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │
         │ PHASE 1: EXTRACTION
         │ ├─ extract.R
         │ ├─ Read all source files
         │ ├─ Parse nested structures
         │ └─ Checkpoint: extraction.rds
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  INTERMEDIATE: Consolidated DataFrames                          │
│  ─────────────────────────────────────────                      │
│                                                                  │
│  • scrapes (all weeks combined)                                 │
│  • projections (all sources/weeks)                              │
│  • player_data (unnested stats)                                 │
│  • simulations (all phases)                                     │
│  • matchups, rosters                                            │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │
         │ PHASE 2: TRANSFORMATION
         │ ├─ transform.R
         │ ├─ Normalize data (3NF)
         │ ├─ Create PKs/FKs
         │ ├─ Aggregate projections
         │ └─ Checkpoint: transformation.rds
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  OUTPUT: dm Objects (Relational Databases)                      │
│  ─────────────────────────────────────────────                  │
│                                                                  │
│  1️⃣ ffa_db (5 tables)                                          │
│     ├─ ffa_scrape          (PK: season, week, tag, timestamp) │
│     ├─ ffa_player_ids      (PK: id)                            │
│     ├─ ffa_players         (PK: id, pos)                       │
│     ├─ ffa_projtable       (PK: season, week, ..., id, pos)   │
│     └─ ffa_proj_source_pts (PK: season, week, ..., src, id)   │
│                                                                  │
│  2️⃣ nfl_stats_db (4 tables)                                    │
│     ├─ nfl_stat_dictionary (PK: statId)                        │
│     ├─ nfl_players_points  (PK: playerId, season, week)       │
│     ├─ nfl_players_stats   (PK: playerId, season, week, stat) │
│     └─ nfl_players_adv     (PK: playerId, season, week)       │
│                                                                  │
│  3️⃣ dudes_simulation_db (2 tables)                             │
│     ├─ dudes_players_seeds (PK: season, week, id, ..., type)  │
│     └─ dudes_players_sims  (PK: season, week, id, ..., type)  │
│                                                                  │
│  4️⃣ nfl_teams_db (2 tables)                                    │
│     ├─ nfl_teams           (PK: teamId)                        │
│     └─ nfl_owners          (PK: ownerUserId)                   │
│                                                                  │
│  5️⃣ nfl_players_db (2 tables)                                  │
│     ├─ nfl_players         (PK: playerId)                      │
│     └─ nfl_player_injury   (PK: playerId, timestamp)           │
│                                                                  │
│  6️⃣ nfl_round_db (5 tables)                                    │
│     ├─ nfl_teams_round     (PK: season, week, teamId)         │
│     ├─ nfl_teams_rosters   (PK: season, week, ..., player)    │
│     ├─ nfl_teams_week_stats                                    │
│     ├─ nfl_teams_season_stats                                  │
│     └─ matchups_games      (PK: season, week, matchupId)      │
│                                                                  │
│  7️⃣ nfl_recap_db (1 table)                                     │
│     └─ nfl_recap           (PK: leagueId, season, week, match) │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         │
         │ PHASE 3: LOADING & VALIDATION
         │ ├─ load.R
         │ ├─ Validate PKs/FKs
         │ ├─ Check cardinalities
         │ └─ Generate ETL_SUMMARY.md
         │
         ▼
┌─────────────────────────────────────────────────────────────────┐
│                                                                  │
│  TARGET: app/2025-24/                                           │
│  ─────────────────────────                                      │
│                                                                  │
│  ✅ ffa_db.rds                     (7.4 MB)                    │
│  ✅ nfl_stats_db.rds               (453 KB)                    │
│  ✅ dudes_simulation_db.rds        (25 MB)                     │
│  ✅ nfl_teams_db.rds               (1.4 KB)                    │
│  ✅ nfl_players_db.rds             (164 KB)                    │
│  ✅ nfl_round_db.rds               (39 KB)                     │
│  ✅ nfl_recap_db.rds               (934 KB)                    │
│  📄 ETL_SUMMARY.md                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🧩 Módulos do Sistema

### 1. config_transform.R
```
┌──────────────────────────────────┐
│  CONFIGURATION MODULE            │
├──────────────────────────────────┤
│  • ETL_CONFIG                    │
│    - Paths, weeks, options      │
│  • FILE_PATTERNS                 │
│    - Naming conventions         │
│  • SIMULATION_PHASES             │
│    - Phase detection rules      │
│  • TAG_INFERENCE_RULES           │
│    - Tag mapping logic          │
│  • VALIDATION_THRESHOLDS         │
│    - Quality checks             │
└──────────────────────────────────┘
```

### 2. utils_transform.R
```
┌──────────────────────────────────┐
│  UTILITIES MODULE                │
├──────────────────────────────────┤
│  Logging                          │
│  ├─ log_message()                │
│  ├─ log_section()                │
│  └─ log_progress()               │
│                                   │
│  File I/O                         │
│  ├─ safe_read_rds()              │
│  └─ safe_write_rds()             │
│                                   │
│  Checkpoints                      │
│  ├─ create_checkpoint()          │
│  ├─ load_checkpoint()            │
│  └─ clear_checkpoints()          │
│                                   │
│  Validation                       │
│  ├─ validate_required_columns()  │
│  ├─ validate_no_duplicates()     │
│  └─ validate_count_threshold()   │
│                                   │
│  Data Processing                  │
│  ├─ unnest_week_stats()          │
│  ├─ aggregate_projections()      │
│  └─ calculate_ranks_and_tiers()  │
└──────────────────────────────────┘
```

### 3. extract.R
```
┌──────────────────────────────────┐
│  EXTRACTION MODULE               │
├──────────────────────────────────┤
│  extract_all()                   │
│    ├─ extract_weekly_scrapes()  │
│    ├─ extract_projections()     │
│    ├─ extract_player_points()   │
│    ├─ extract_simulations()     │
│    ├─ extract_matchups()        │
│    ├─ extract_rosters()         │
│    ├─ extract_season_data()     │
│    └─ extract_draft_data()      │
│                                   │
│  Output: Consolidated DataFrames │
└──────────────────────────────────┘
```

### 4. transform.R
```
┌──────────────────────────────────┐
│  TRANSFORMATION MODULE           │
├──────────────────────────────────┤
│  transform_all()                 │
│    ├─ transform_to_ffa_db()     │
│    │   ├─ Create ffa_scrape     │
│    │   ├─ Create ffa_player_ids │
│    │   ├─ Create ffa_players    │
│    │   ├─ Create ffa_projtable  │
│    │   └─ Define PKs/FKs        │
│    │                             │
│    ├─ transform_to_nfl_stats()  │
│    │   ├─ Unnest stats          │
│    │   ├─ Create dictionary     │
│    │   └─ Define PKs/FKs        │
│    │                             │
│    ├─ transform_to_simulation() │
│    │   ├─ Extract seeds         │
│    │   ├─ Extract simulations   │
│    │   └─ Define PKs            │
│    │                             │
│    └─ transform_to_teams_db()   │
│        └─ Extract from sims     │
│                                   │
│  Output: dm Objects              │
└──────────────────────────────────┘
```

### 5. load.R
```
┌──────────────────────────────────┐
│  LOADING MODULE                  │
├──────────────────────────────────┤
│  load_all()                      │
│    ├─ load_database()           │
│    │   ├─ validate_dm_object()  │
│    │   │   ├─ Check constraints │
│    │   │   ├─ Check counts      │
│    │   │   └─ Check cardinality │
│    │   └─ safe_write_rds()      │
│    │                             │
│    └─ generate_summary_report() │
│        └─ ETL_SUMMARY.md        │
│                                   │
│  Output: Validated .rds files    │
└──────────────────────────────────┘
```

### 6. transform_dudes_to_app.R
```
┌──────────────────────────────────┐
│  ORCHESTRATOR (Main Script)      │
├──────────────────────────────────┤
│  main()                          │
│    ├─ Setup & Config            │
│    ├─ Check Checkpoints         │
│    ├─ Phase 1: extract_all()    │
│    ├─ Phase 2: transform_all()  │
│    ├─ Phase 3: load_all()       │
│    └─ generate_report()         │
│                                   │
│  run_batch()                     │
│    └─ Process in batches        │
│                                   │
│  test_pipeline()                 │
│    └─ Quick test (week 1)       │
└──────────────────────────────────┘
```

---

## 🔗 Relacionamentos entre Databases

```
┌────────────────────────────────────────────────────────────┐
│                    CROSS-DATABASE LINKS                     │
└────────────────────────────────────────────────────────────┘

ffa_db.ffa_player_ids.nfl_id (character)
    │
    │ as.integer()
    ▼
nfl_players_db.nfl_players.playerId (integer)
    │
    ├──► nfl_stats_db.nfl_players_points.playerId
    ├──► nfl_stats_db.nfl_players_stats.playerId
    ├──► nfl_round_db.nfl_teams_rosters.playerId
    └──► dudes_simulation_db.dudes_players_*.playerId

ffa_db.ffa_player_ids.id (character)
    │
    └──► dudes_simulation_db.dudes_players_*.id

nfl_teams_db.nfl_teams.teamId (integer)
    │
    ├──► nfl_round_db.nfl_teams_round.teamId
    ├──► nfl_round_db.nfl_teams_rosters.teamId
    └──► nfl_round_db.matchups_games.awayTeamTeamId/homeTeamTeamId
```

---

## ⚙️ Configurações e Opções

```
┌──────────────────────────────────────────────────────────┐
│  PIPELINE OPTIONS                                         │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Processing Mode                                          │
│  ├─ Full:    All 17 weeks                                │
│  ├─ Batch:   Process in chunks (configurable)            │
│  └─ Test:    Week 1 only                                 │
│                                                            │
│  Validation Mode                                          │
│  ├─ Strict:  Abort on any constraint violation           │
│  └─ Lenient: Warning only, continue processing            │
│                                                            │
│  Performance                                              │
│  ├─ Parallel:     Use multiple cores                     │
│  ├─ Checkpoints:  Save intermediate results              │
│  └─ Batch Size:   Control memory usage                   │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 📊 Métricas de Transformação

```
┌──────────────────────────────────────────────────────────┐
│  TRANSFORMATION METRICS                                   │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Reduction                                                │
│  ├─ Files:      245 → 7        (97% reduction)           │
│  └─ Structure:  Flat → Relational                        │
│                                                            │
│  Normalization                                            │
│  ├─ Player IDs: 14 sources consolidated                  │
│  ├─ Timestamps: Unified temporal tracking                │
│  └─ Nested data: Unnested to flat tables                 │
│                                                            │
│  Quality                                                  │
│  ├─ PKs:        21 primary keys defined                  │
│  ├─ FKs:        11 foreign keys enforced                 │
│  └─ Validation: Automated constraint checking            │
│                                                            │
│  Performance                                              │
│  ├─ Pipeline:   6-10 minutes (full season)               │
│  ├─ Test mode:  ~30 seconds (week 1)                     │
│  └─ Memory:     Peak ~2-3 GB                             │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 🔐 Data Integrity

```
┌──────────────────────────────────────────────────────────┐
│  DATA QUALITY CHECKS                                      │
├──────────────────────────────────────────────────────────┤
│                                                            │
│  Automated Validations                                    │
│  ├─ ✅ Primary key uniqueness                            │
│  ├─ ✅ Foreign key referential integrity                 │
│  ├─ ✅ Cardinality constraints (1:N, N:1)                │
│  ├─ ✅ Minimum record counts per table                   │
│  ├─ ✅ Required column presence                          │
│  └─ ✅ NULL checks for non-nullable fields               │
│                                                            │
│  Data Consistency                                         │
│  ├─ Player ID mapping (14 systems)                       │
│  ├─ Temporal alignment (timestamps/tags)                 │
│  └─ Position/team standardization                        │
│                                                            │
└──────────────────────────────────────────────────────────┘
```

---

## 🛠️ Extension Points

Para adicionar novos databases ou funcionalidades:

```
1. config_transform.R
   └─ Adicionar configuração

2. extract.R
   └─ Adicionar extract_my_data()

3. transform.R
   └─ Adicionar transform_to_my_db()
   └─ Registrar em transform_all()

4. load.R
   └─ Validação é automática!

5. Pipeline
   └─ Novo database aparece no output
```

---

**Arquitetura completa implementada e funcional! 🎉**

Para detalhes de uso, ver: `README.md` e `QUICK_START.md`
