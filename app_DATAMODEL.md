# 📊 DudesApp - Data Model Documentation

> **Comprehensive data dictionary and schema documentation for all databases**
>
> Generated: 2026-03-06 | Total Databases: 7 | Total Tables: 21

---

## 📑 Table of Contents

- [Overview](#overview)
- [Database Summary](#database-summary)
- [Detailed Schema Documentation](#detailed-schema-documentation)
  - [1. ffa_db.rds - Fantasy Football Analytics](#1-ffa_dbrds---fantasy-football-analytics)
  - [2. nfl_teams_db.rds - League Teams & Owners](#2-nfl_teams_dbrds---league-teams--owners)
  - [3. nfl_players_db.rds - NFL Players](#3-nfl_players_dbrds---nfl-players)
  - [4. nfl_stats_db.rds - Player Statistics](#4-nfl_stats_dbrds---player-statistics)
  - [5. nfl_round_db.rds - Matchups & Rosters](#5-nfl_round_dbrds---matchups--rosters)
  - [6. nfl_recap_db.rds - Game Recaps](#6-nfl_recap_dbrds---game-recaps)
  - [7. dudes_simulation_db.rds - Simulation Data](#7-dudes_simulation_dbrds---simulation-data)
- [Cross-Database Relationships](#cross-database-relationships)
- [Data Quality Notes](#data-quality-notes)
- [Usage Examples](#usage-examples)

---

## Overview

O DudesApp utiliza o pacote `dm` (data models) do R para criar relacionamentos estruturados entre tabelas. Cada arquivo `.rds` contém um objeto `dm` com múltiplas tabelas relacionadas através de Primary Keys (PK) e Foreign Keys (FK).

### Key Concepts

- **Primary Key (PK)**: Identifica unicamente cada registro em uma tabela
- **Foreign Key (FK)**: Referência a um PK em outra tabela, estabelecendo relacionamento
- **dm object**: Container que mantém múltiplas tabelas com relacionamentos type-safe
- **Temporal data**: Muitas tabelas incluem `timestamp` para versionamento histórico

---

## Data Freshness & Coverage

Esta seção documenta a cobertura temporal dos dados em cada database.

| Database | Temporadas | Semanas | Timestamps Únicos |
|----------|-----------|---------|-------------------|
| `ffa_db.rds` | 2024, 2025 | W0-W18 | 39 scrapes |
| `nfl_stats_db.rds` | 2024, 2025 | W0-W18 | - |
| `nfl_players_db.rds` | - | - | 39 snapshots |
| `nfl_round_db.rds` | 2024, 2025 | W1-W17 | 39 snapshots |
| `nfl_recap_db.rds` | 2024, 2025 | W1-W17 | - |
| `dudes_simulation_db.rds` | 2024 | W2, W3, W4 | - |

**⚠️ Importante**: Para análises temporais, sempre use `timestamp == max(timestamp)` ou `tag == "final"` para garantir que está usando os dados mais recentes de cada semana.

---

## Database Summary

| Database | Size | Tables | Purpose |
|----------|------|--------|---------|
| `ffa_db.rds` | 7.4 MB | 5 | Projeções de 11+ fontes externas |
| `nfl_teams_db.rds` | 1.4 KB | 2 | Times e proprietários da liga |
| `nfl_players_db.rds` | 164 KB | 2 | Jogadores e status de lesões |
| `nfl_stats_db.rds` | 453 KB | 4 | Estatísticas detalhadas de jogos |
| `nfl_round_db.rds` | 39 KB | 5 | Matchups, rosters e rankings |
| `nfl_recap_db.rds` | 934 KB | 1 | Narrativas de confrontos |
| `dudes_simulation_db.rds` | 25 MB | 2 | Simulações e projeções customizadas |

**Total Data**: ~34 MB | **Total Records**: ~190K rows

---

## Detailed Schema Documentation

---

## 1. ffa_db.rds - Fantasy Football Analytics

**Purpose**: Armazena projeções de múltiplas fontes (CBS, ESPN, FantasyPros, etc.) agregadas pelo pacote `ffanalytics`.

**Size**: 7.4 MB | **Tables**: 5

### 📋 Entity Relationship Diagram

```
┌──────────────────┐
│ ffa_player_ids   │
│ PK: id           │
└──────────────────┘
         ▲
         │ FK: id
         │
┌────────┴──────────┐
│ ffa_players       │
│ PK: id, pos       │
└───────────────────┘
         ▲
         │ FK: id, pos
    ┌────┴────┐
    │         │
┌───┴────────────────┐  ┌──────────────────────┐
│ ffa_projtable      │  │ ffa_proj_source_points│
│ PK: season, week,  │  │ PK: season, week,     │
│     tag, timestamp,│  │     tag, timestamp,   │
│     avg_type,      │  │     data_src,         │
│     id, pos        │  │     id, pos           │
│ FK: id, pos        │  │ FK: id, pos           │
│ FK: season, week,  │  │ FK: season, week,     │
│     tag, timestamp │  │     tag, timestamp    │
└────────────────────┘  └───────────────────────┘
         ▲                       ▲
         │                       │
         └───────────┬───────────┘
                     │ FK
         ┌───────────┴────────┐
         │ ffa_scrape         │
         │ PK: season, week,  │
         │     tag, timestamp │
         └────────────────────┘
```

**Note**: As tabelas `ffa_projtable` e `ffa_proj_source_points` têm FK para `ffa_players` (não diretamente para `ffa_player_ids`), e ambas também têm FK composta para `ffa_scrape` que rastreia o momento da coleta dos dados.

---

### Table: `ffa_player_ids`

**Purpose**: Mapeamento de IDs entre diferentes sistemas de fantasy football.

**Dimensions**: 5,395 rows × 15 cols

**Primary Key**: `id`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `id` | character | 5395 | 0% | **ID universal interno do ffanalytics** |
| `stats_id` | character | 5238 | 2.9% | ID do sistema Stats |
| `cbs_id` | character | 4986 | 7.5% | ID do CBS Sports |
| `fleaflicker_id` | character | 3757 | 30.3% | ID do FleaFlicker |
| `nfl_id` | character | 3702 | 31.4% | **ID oficial da NFL** (importante!) |
| `espn_id` | character | 4370 | 18.9% | ID do ESPN |
| `fftoday_id` | character | 4212 | 21.9% | ID do FFToday |
| `numfire_id` | character | 3673 | 31.9% | ID do NumberFire |
| `fantasypro_id` | character | 4399 | 18.4% | ID do FantasyPros (texto) |
| `fantasydata_id` | character | 2171 | 59.7% | ID do FantasyData |
| `fantasynerd_id` | character | 1300 | 75.9% | ID do FantasyNerd |
| `rts_id` | character | 1493 | 72.3% | ID do RTSports |
| `fantasypro_num_id` | character | 3243 | 39.9% | ID numérico do FantasyPros |
| `gsis_id` | character | 4261 | 21% | ID do Game Statistics and Information System |
| `sleeper_id` | character | 5152 | 4.5% | ID do Sleeper App |

**Key Insights**:
- Esta tabela é **crucial** para join entre sistemas FFA e NFL
- O campo `nfl_id` deve ser convertido para `integer` e usado como `playerId`
- Algumas fontes têm baixa cobertura (fantasynerd: 76% NA, rts: 72% NA)

**Usage Example**:
```r
# Mapeamento FFA → NFL
id_map <- ffa_db$ffa_player_ids %>%
  transmute(
    id,
    playerId = as.integer(nfl_id)
  )
```

---

### Table: `ffa_players`

**Purpose**: Informações básicas dos jogadores projetados.

**Dimensions**: 858 rows × 8 cols

**Primary Key**: `id, pos`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `id` | character | 849 | 0% | ID do jogador (FK para ffa_player_ids) |
| `pos` | character | 6 | 0% | Posição: QB, RB, WR, TE, K, DST |
| `first_name` | character | 539 | 0.5% | Primeiro nome do jogador |
| `last_name` | character | 671 | 0.5% | Sobrenome do jogador |
| `team` | character | 34 | 0.5% | Abreviação do time (BUF, PHI, WAS, etc.) |
| `position` | character | 8 | 0.5% | Posição detalhada (pode incluir FB, RBWR) |
| `age` | integer | 24 | 4.5% | Idade do jogador |
| `exp` | integer | 24 | 0.5% | Anos de experiência (-4 = rookie futuro) |

**Note**: PK composto `(id, pos)` permite um jogador ter múltiplas posições listadas.

---

### Table: `ffa_projtable`

**Purpose**: **Projeções agregadas** usando diferentes métodos de média.

**Dimensions**: 61,332 rows × 26 cols

**Primary Key**: `season, week, tag, timestamp, avg_type, id, pos`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `season` | integer | 2 | 0% | Temporada (2024, 2025) |
| `week` | integer | 18 | 0% | Semana da NFL (0-18) |
| `tag` | character | 6 | 0% | Momento: preWaivers, final, posWaivers, etc. |
| `timestamp` | POSIXct | 39 | 0% | Momento da coleta |
| `avg_type` | character | 3 | 0% | **Tipo de agregação**: average, robust, weighted |
| `id` | character | 849 | 0% | ID do jogador (FK) |
| `pos` | character | 6 | 0% | Posição |
| `points` | numeric | 49536 | 0% | **Projeção de pontos** |
| `sd_pts` | numeric | 47570 | 8.4% | Desvio padrão das projeções |
| `dropoff` | numeric | 48080 | 0% | Diferença para o próximo jogador ranqueado |
| `rank` | integer | - | - | Ranking na posição |
| `tier` | integer | - | - | Tier do jogador (agrupamento) |
| `ceiling` | numeric | - | - | Projeção otimista (quantil alto) |
| `floor` | numeric | - | - | Projeção pessimista (quantil baixo) |
| ... | ... | ... | ... | (22 outras colunas de estatísticas) |

**avg_type Explained**:
- **average**: Média aritmética simples de todas as fontes
- **robust**: Média robusta (resistente a outliers)
- **weighted**: Média ponderada por acurácia histórica de cada fonte

**Usage**:
```r
# Pegar projeção mais recente da semana
proj_latest <- ffa_db$ffa_projtable %>%
  filter(
    season == 2024,
    week == 4,
    timestamp == max(timestamp)
  ) %>%
  select(id, pos, avg_type, points, rank, tier)
```

---

### Table: `ffa_proj_source_points`

**Purpose**: **Projeções individuais de cada fonte**, antes da agregação.

**Dimensions**: 103,266 rows × 8 cols

**Primary Key**: `season, week, tag, timestamp, data_src, id, pos`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `season` | integer | 2 | 0% | Temporada |
| `week` | integer | 18 | 0% | Semana |
| `tag` | character | 6 | 0% | Momento da coleta |
| `timestamp` | POSIXct | 39 | 0% | Timestamp |
| `data_src` | character | 11 | 0% | **Fonte**: CBS, ESPN, FantasyPros, etc. |
| `id` | character | 849 | 0% | ID do jogador |
| `pos` | character | 6 | 0% | Posição |
| `points` | numeric | 18506 | 0% | **Projeção da fonte específica** |

**data_src values**: CBS, ESPN, FantasyPros, FantasySharks, FFToday, FleaFlicker, NumberFire, FantasyFootballNerd, NFL, RTSports, Walterfootball

**Usage**:
```r
# Comparar variância entre fontes
source_comparison <- ffa_db$ffa_proj_source_points %>%
  filter(season == 2024, week == 4, id == "13589") %>%
  select(data_src, points) %>%
  arrange(desc(points))
```

---

### Table: `ffa_scrape`

**Purpose**: Metadados sobre cada operação de scraping.

**Dimensions**: 39 rows × 5 cols

**Primary Key**: `season, week, tag, timestamp`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `tag` | character | Tag da coleta |
| `timestamp` | POSIXct | Momento do scraping |
| `scrapeData` | list | **Lista com raw data do scraping** (formato ffanalytics) |

**Note**: `scrapeData` é uma list-column contendo objetos complexos do pacote ffanalytics. Normalmente não é acessada diretamente.

---

## 2. nfl_teams_db.rds - League Teams & Owners

**Purpose**: Informações dos times da liga de fantasy e seus proprietários.

**Size**: 1.4 KB | **Tables**: 2

### 📋 Entity Relationship Diagram

```
┌──────────────────┐        ┌──────────────────┐
│ nfl_owners       │        │ nfl_teams        │
│ PK: ownerUserId  │ ◄──────│ PK: teamId       │
└──────────────────┘   FK   │ FK: ownerUserId  │
                             └──────────────────┘
```

---

### Table: `nfl_teams`

**Purpose**: Times participantes da liga de fantasy.

**Dimensions**: 16 rows × 4 cols

**Primary Key**: `teamId`

**Foreign Key**: `ownerUserId` → `nfl_owners.ownerUserId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `teamId` | integer | **ID único do time na liga** |
| `name` | character | Nome do time (ex: "Paulinia Robots", "Sorocaba Wild Cats") |
| `ownerUserId` | integer | ID do proprietário (FK) |
| `imageUrl` | character | URL da logo do time |

**Usage**:
```r
# Listar todos os times com seus owners
nfl_teams_db %>%
  dm_flatten_to_tbl(nfl_teams)
```

---

### Table: `nfl_owners`

**Purpose**: Proprietários dos times da liga.

**Dimensions**: 16 rows × 2 cols

**Primary Key**: `ownerUserId`

#### Columns

| Column | Type | Distinct | Description |
|--------|------|----------|-------------|
| `ownerUserId` | integer | 16 | **ID único do usuário** |
| `name` | character | 15 | Nome do proprietário (1 duplicata) |

---

## 3. nfl_players_db.rds - NFL Players

**Purpose**: Informações completas dos jogadores da NFL e histórico de lesões.

**Size**: 164 KB | **Tables**: 2

### 📋 Entity Relationship Diagram

```
┌────────────────────────┐
│ nfl_players            │
│ PK: playerId           │
└────────────────────────┘
           ▲
           │ FK
           │
┌──────────┴──────────────┐
│ nfl_player_injury_status│
│ PK: playerId, timestamp │
│ FK: playerId            │
└─────────────────────────┘
```

---

### Table: `nfl_players`

**Purpose**: Dados cadastrais dos jogadores disponíveis na liga.

**Dimensions**: 1,398 rows × 19 cols

**Primary Key**: `playerId`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `playerId` | integer | 1398 | 0% | **ID único do jogador (NFL oficial)** |
| `nflGlobalEntityId` | character | 1398 | 0% | ID global da NFL |
| `esbId` | character | 324 | 76.9% | Elias Sports Bureau ID |
| `name` | character | 1398 | 0% | Nome completo |
| `firstName` | character | 789 | 0% | Primeiro nome |
| `lastName` | character | 1017 | 0% | Sobrenome |
| `position` | character | 6 | 0% | **Posição**: DEF, RB, WR, TE, QB, K |
| `nflTeamAbbr` | character | 33 | 0% | Abreviação do time NFL (SF, DAL, etc.) |
| `nflTeamId` | integer | 33 | 33.5% | ID do time NFL |
| `imageUrl` | character | 1304 | 0% | URL da foto (padrão) |
| `smallImageUrl` | character | 1304 | 0% | URL da foto (pequena) |
| `largeImageUrl` | character | 1304 | 0% | URL da foto (grande) |
| `byeWeek` | integer | 9 | 33.5% | **Semana de bye week** |
| `cancelledWeeks` | logical | 1 | 100% | Semanas canceladas (sempre NA) |
| `archetypes` | logical | 1 | 100% | Arquétipos (sempre NA) |
| `isUndroppable` | logical | 2 | 20.9% | Se não pode ser dropado |
| `isReserveStatus` | logical | 2 | 0% | **Se está em lista de reserva/IR** |
| `lastNoteTimestamp` | character | 1207 | 13.7% | Última nota de notícias |
| `lastVideoTimestamp` | logical | 1 | 100% | Último vídeo (sempre NA) |

**Key Insights**:
- `playerId` é a chave para join com outras tabelas
- `byeWeek` é importante para otimização de escalação
- `isReserveStatus = TRUE` indica jogador na IR (injured reserve)

---

### Table: `nfl_player_injury_status`

**Purpose**: **Histórico temporal de status de lesões** dos jogadores.

**Dimensions**: 43,430 rows × 3 cols

**Primary Key**: `playerId, timestamp`

**Foreign Key**: `playerId` → `nfl_players.playerId`

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `playerId` | integer | 1398 | 0% | ID do jogador (FK) |
| `timestamp` | POSIXct | 39 | 0% | Momento da captura do status |
| `injuryGameStatus` | character | 10 | 83.5% | **Status**: Questionable, Out, Injured Reserve, etc. |

**injuryGameStatus values**:
- `NA`: Saudável
- `Questionable`: 70-75% de chance de jogar
- `Doubtful`: 15-25% de chance de jogar
- `Out`: Não joga
- `Injured Reserve`: Fora por tempo indeterminado
- `PUP` (Physically Unable to Perform)
- `Non-Football Injury`

**Usage**:
```r
# Status de lesão mais recente por jogador
current_injuries <- nfl_players_db$nfl_player_injury_status %>%
  filter(timestamp == max(timestamp)) %>%
  filter(!is.na(injuryGameStatus))
```

---

## 4. nfl_stats_db.rds - Player Statistics

**Purpose**: Estatísticas detalhadas de performance dos jogadores.

**Size**: 453 KB | **Tables**: 4

### 📋 Entity Relationship Diagram

```
┌──────────────────────┐
│ nfl_stat_dictionary  │
│ PK: statId           │
└──────────────────────┘
           ▲
           │ FK: statId
           │
┌──────────┴────────────┐
│ nfl_players_stats     │
│ PK: playerId, season, │
│     week, statId      │
└───────────────────────┘

┌──────────────────────┐
│ nfl_players_points    │ ← Relacionamento lógico
│ PK: playerId, season, │   (não é FK formal)
│     week              │
└───────────────────────┘

┌──────────────────────┐
│ nfl_players_adv_stats│
│ PK: playerId, season,│
│     week             │
└──────────────────────┘
```

**Note sobre relacionamentos**: Embora `nfl_players_stats` e `nfl_players_points` compartilhem a chave composta `(playerId, season, week)`, **não existe uma Foreign Key formal** entre elas no dm object. Elas são relacionadas logicamente - `nfl_players_points` contém os pontos totais, enquanto `nfl_players_stats` contém as estatísticas detalhadas que geraram aquela pontuação. O join deve ser feito manualmente via `left_join()` ou `inner_join()`.

---

### Table: `nfl_stat_dictionary`

**Purpose**: Dicionário de códigos de estatísticas da NFL.

**Dimensions**: 95 rows × 10 cols

**Primary Key**: `statId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `statId` | integer | **ID da estatística** (1-95) |
| `abbr` | character | Abreviação (GP, Att, Comp, etc.) |
| `name` | character | Nome completo da estatística |
| `shortName` | character | Nome curto |
| `scoringType` | character | Tipo: '', 'points', 'yards_per_point' |
| `isBonus` | logical | Se é uma estatística de bônus |
| `groupName` | character | Grupo: Passing, Rushing, Receiving, etc. |
| `positionCategory` | character | Categoria: O (offense), K (kicker), D (defense) |
| `n` | integer | Ordem de exibição |
| `colName` | character | Nome da coluna no sistema |

**Usage**:
```r
# Ver todas as estatísticas de passing
nfl_stats_db$nfl_stat_dictionary %>%
  filter(groupName == "Passing")
```

---

### Table: `nfl_players_points`

**Purpose**: **Pontuação total** de cada jogador por semana.

**Dimensions**: 12,593 rows × 4 cols

**Primary Key**: `playerId, season, week`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `playerId` | integer | ID do jogador |
| `season` | integer | Temporada |
| `week` | integer | Semana (0 = preseason) |
| `pts` | numeric | **Pontuação total fantasy** |

**Usage**:
```r
# Top 10 performances de uma semana
nfl_stats_db$nfl_players_points %>%
  filter(season == 2024, week == 4) %>%
  arrange(desc(pts)) %>%
  head(10)
```

---

### Table: `nfl_players_stats`

**Purpose**: **Estatísticas detalhadas** por categoria (passing, rushing, receiving, etc.).

**Dimensions**: 75,596 rows × 5 cols

**Primary Key**: `playerId, season, week, statId`

**Foreign Key**: `(playerId, season, week)` → `nfl_players_points`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `playerId` | integer | ID do jogador |
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `statId` | integer | ID da estatística (FK para nfl_stat_dictionary) |
| `value` | numeric | **Valor da estatística** |

**Usage**:
```r
# Estatísticas de passing de um QB específico
nfl_stats_db %>%
  dm_flatten_to_tbl(nfl_players_stats) %>%
  filter(
    playerId == 2552374,
    season == 2024,
    week == 4,
    groupName == "Passing"
  ) %>%
  select(shortName, value)
```

---

### Table: `nfl_players_adv_stats`

**Purpose**: Estatísticas avançadas (ADP, ownership, etc.).

**Dimensions**: 19,816 rows × 21 cols

**Primary Key**: `playerId, season, week`

#### Key Columns

| Column | Type | NA % | Description |
|--------|------|------|-------------|
| `playerId` | integer | 0% | ID do jogador |
| `season` | integer | 0% | Temporada |
| `week` | integer | 0% | Semana |
| `averageDraftPosition` | numeric | 88.9% | ADP (Average Draft Position) |
| `averageDraftAuctionCost` | numeric | 96.3% | Custo médio em draft auction |
| `transactionNumAdds` | numeric | 88.7% | Número de vezes adicionado |
| `transactionNumDrops` | numeric | 88.7% | Número de vezes dropado |
| `percentStarted` | numeric | 47% | **% de ligas onde foi starter** |
| `percentStartedChange` | numeric | 50.6% | Mudança no % started |
| `percentOwned` | numeric | 20.1% | **% de ligas onde está em roster** |
| `percentOwnedChange` | numeric | 38.8% | Mudança no % owned |

**Note**: Muitos NAs porque dados avançados não estão disponíveis para todos os jogadores/semanas.

---

## 5. nfl_round_db.rds - Matchups & Rosters

**Purpose**: Matchups semanais, escalações dos times e estatísticas.

**Size**: 39 KB | **Tables**: 5

### 📋 Entity Relationship Diagram

```
┌─────────────────────┐
│ nfl_teams_round     │
│ PK: season, week,   │
│     teamId          │
└─────────────────────┘

┌─────────────────────┐
│ nfl_teams_rosters   │
│ PK: season, week,   │
│     tag, timestamp, │
│     teamId,         │
│     rosterSlotId,   │
│     playerId        │
└─────────────────────┘

┌─────────────────────┐
│ nfl_teams_week_stats│
│ PK: season, week,   │
│     tag, timestamp, │
│     teamId, statId  │
└─────────────────────┘

┌─────────────────────┐
│nfl_teams_season_stats│
│ PK: season, week,   │
│     tag, timestamp, │
│     teamId, name    │
└─────────────────────┘

┌─────────────────────┐
│ matchups_games      │
│ PK: season, week,   │
│     matchupId       │
└─────────────────────┘
```

---

### Table: `nfl_teams_round`

**Purpose**: Informações dos times em cada rodada.

**Dimensions**: 510 rows × 6 cols

**Primary Key**: `season, week, teamId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `teamId` | integer | ID do time |
| `rank` | integer | **Ranking atual do time na liga** |
| `imageUrl` | character | URL da logo |
| `imageUrlLarge` | character | URL da logo (grande) |

---

### Table: `nfl_teams_rosters`

**Purpose**: **Escalações completas** dos times (starters + bench).

**Dimensions**: 8,744 rows × 10 cols

**Primary Key**: `season, week, tag, timestamp, teamId, rosterSlotId, playerId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `tag` | character | Tag: preWaivers, final, posWaivers |
| `timestamp` | POSIXct | Momento da captura |
| `teamId` | integer | ID do time |
| `slotPosition` | character | **Categoria**: O (offense), K (kicker), DT (defense/team) |
| `rosterSlotId` | integer | **Slot**: 1-8 = starters, 20+ = bench |
| `playerId` | integer | ID do jogador (0 = slot vazio) |
| `isEditable` | logical | Se o slot pode ser editado |
| `isReserveStatus` | logical | Se está na IR |

**rosterSlotId mapping**:
- `1`: QB
- `2-3`: RB
- `4-5`: WR
- `6`: TE
- `7`: FLEX (WR/RB/TE)
- `8`: K
- `16`: DEF
- `20+`: Bench slots

**Usage**:
```r
# Ver starters de um time em uma semana
nfl_round_db$nfl_teams_rosters %>%
  filter(
    season == 2024,
    week == 4,
    teamId == 1,
    rosterSlotId < 20  # Apenas starters
  )
```

---

### Table: `nfl_teams_week_stats`

**Purpose**: Pontuação do time em cada semana.

**Dimensions**: 540 rows × 7 cols

**Primary Key**: `season, week, tag, timestamp, teamId, statId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `tag` | character | Tag (final, posTNF, preMNF) |
| `timestamp` | POSIXct | Momento da captura |
| `teamId` | integer | ID do time |
| `statId` | character | Sempre 'pts' |
| `value` | numeric | **Pontuação total do time na semana** |

---

### Table: `nfl_teams_season_stats`

**Purpose**: Estatísticas acumuladas da temporada.

**Dimensions**: 8,760 rows × 7 cols

**Primary Key**: `season, week, tag, timestamp, teamId, name`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana (acumulado até esta semana) |
| `tag` | character | Tag |
| `timestamp` | POSIXct | Momento |
| `teamId` | integer | ID do time |
| `name` | character | Nome da estatística: rank, rankChange, divisionRank, etc. |
| `value` | character | **Valor da estatística** (texto) |

**name values**:
- `rank`: Ranking geral
- `rankChange`: Mudança de ranking
- `divisionRank`: Ranking na divisão
- `gamesPlayed`: Jogos disputados
- `wins`, `losses`, `ties`: Resultados
- `pointsFor`, `pointsAgainst`: Pontos

---

### Table: `matchups_games`

**Purpose**: **Confrontos semanais** entre times.

**Dimensions**: 257 rows × 14 cols

**Primary Key**: `season, week, matchupId`

#### Columns

| Column | Type | NA % | Description |
|--------|------|------|-------------|
| `season` | integer | 0% | Temporada |
| `week` | integer | 0% | Semana |
| `matchupId` | character | 0% | ID do confronto (ex: w4_a14_h11) |
| `previewUrl` | character | 1.6% | URL do preview |
| `recapUrl` | character | 1.6% | URL do recap |
| `bracketType` | character | 81.7% | Tipo (playoffs): consolation, championship |
| `bracketTitle` | character | 89.5% | Fase: Quarterfinal, Semifinal, Final |
| `hasMatchupTeams` | logical | 0% | Sempre TRUE |
| `awayTeamTeamId` | integer | 0% | ID do time visitante |
| `awayTeamOutcome` | character | 0% | Resultado: win/loss |
| `awayTeamPlayoffSeeding` | integer | 81.7% | Seed no playoff |
| `homeTeamTeamId` | integer | 1.6% | ID do time mandante |
| `homeTeamOutcome` | character | 0% | Resultado: win/loss |
| `homeTeamPlayoffSeeding` | integer | 83.3% | Seed no playoff |

**matchupId format**: `w{week}_a{awayTeamId}_h{homeTeamId}`

---

## 6. nfl_recap_db.rds - Game Recaps

**Purpose**: Narrativas geradas pela NFL sobre os confrontos.

**Size**: 934 KB | **Tables**: 1

---

### Table: `nfl_recap`

**Purpose**: Recaps com narrativas, destaques e análises dos matchups.

**Dimensions**: 220 rows × 15 cols

**Primary Key**: `leagueId, season, week, matchupId`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `leagueId` | integer | ID da liga (sempre 3940933) |
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `matchupId` | character | ID do matchup |
| `title` | character | Título do recap |
| `paragraphs` | list | **Lista de parágrafos narrativos** |
| `type` | character | Sempre "Recap" |
| `written_at` | character | Data de escrita |
| `weekday` | character | Sempre "Tuesday" |
| `playoff` | logical | Se é jogo de playoff |
| `standard_scheduling` | logical | Se usa scheduling padrão |
| `standard_scoring` | logical | Sempre FALSE (liga usa scoring custom) |
| `teams` | list | **Lista com dados dos dois times** |
| `free_agent_target_touch_leaders` | list | Destaques de free agents |
| `league_notes` | list | Notas da liga |

**paragraphs structure**:
```r
# Exemplo de acesso
recap <- nfl_recap_db$nfl_recap[1,]
recap$paragraphs[[1]]  # Lista de textos narrativos
```

**teams structure**:
```r
# Contém para cada time:
# - nome, pontuação
# - best_player (melhor jogador)
# - clutch_player (jogador decisivo)
# - unsung_hero (herói improvável)
```

---

## 7. dudes_simulation_db.rds - Simulation Data

**Purpose**: Resultados das simulações Monte Carlo customizadas.

**Size**: 25 MB | **Tables**: 2

### 📋 Entity Relationship Diagram

```
┌─────────────────────┐
│ dudes_players_seeds │
│ PK: season, week,   │
│     id, playerId,   │
│     pos, simType    │
└─────────────────────┘
           ║
           ║ 1:1
           ║
┌─────────────────────┐
│dudes_players_sim    │
│ PK: season, week,   │
│     id, playerId,   │
│     pos, simType    │
└─────────────────────┘
```

---

### Table: `dudes_players_seeds`

**Purpose**: **Valores base (seeds)** para cada estratégia de simulação.

**Dimensions**: 21,809 rows × 7 cols

**Primary Key**: `season, week, id, playerId, pos, simType`

**⚠️ Importante**: Esta tabela contém **17 valores distintos** de `simType`, mas a tabela `dudes_players_simulations` contém apenas **13 valores distintos**. Isso ocorre porque algumas estratégias definidas em seeds podem falhar na geração de simulações ou serem descartadas durante o processo. Sempre use os simTypes presentes em `dudes_players_simulations` para análises de resultados.

#### Columns

| Column | Type | Distinct | NA % | Description |
|--------|------|----------|------|-------------|
| `season` | integer | 1 | 0% | Temporada (2024) |
| `week` | integer | 3 | 0% | Semana (2, 3, 4) |
| `id` | character | 572 | 0% | ID do FFA |
| `playerId` | integer | 570 | 0.2% | ID da NFL |
| `pos` | character | 6 | 0% | Posição |
| `simType` | character | 17 | 0% | **Tipo de estratégia de simulação** |
| `seeds` | list | 16665 | 0% | **Vetor de valores base para sampling** |

**simType values** (17 estratégias):
1. `NFL` - Projeção oficial NFL
2. `proj_table_average` - Média simples
3. `proj_table_robust` - Média robusta
4. `proj_table_weighted` - Média ponderada
5. `proj_src` - Todas as projeções das fontes
6. `proj_src_errors` - Com erros históricos
7. `proj_src_w_errors` - Projeções + erros
8. `hist_data` - Dados históricos completos
9. `current_season_his` - Performance temporada atual
10. `proj_src_w_errors_balanced` - Balanceado
11. `proj_src_density` - Density sampling
12. `proj_src_errors_density` - Density com erros
13. `proj_src_w_errors_density` - Density combinado
14. `hist_data_density` - Density histórico
15. `current_season_his_density` - Density temporada
16. `proj_src_w_error_current_season_density` - Mix densidades
17. Outras variações...

**seeds structure**:
- Para estratégias simples (NFL, average): `seeds` = vetor com 1 valor
- Para Monte Carlo (proj_src, hist_data): `seeds` = vetor com N valores
- Para density: `seeds` = vetor com 1000+ valores amostrados

---

### Table: `dudes_players_simulations`

**Purpose**: **Resultados finais das simulações** (1000 valores por jogador).

**Dimensions**: 15,799 rows × 8 cols

**Primary Key**: `season, week, id, playerId, pos, simType`

#### Columns

| Column | Type | Description |
|--------|------|-------------|
| `season` | integer | Temporada |
| `week` | integer | Semana |
| `id` | character | ID do FFA |
| `playerId` | integer | ID da NFL |
| `pos` | character | Posição |
| `simType` | character | Tipo de estratégia |
| `simulation` | list | **Vetor com 1000 valores simulados** |
| `simQuantiles` | list | **Named vector com quantis**: 5%, 15%, 30%, 50%, 70%, 85%, 95% |

**Usage**:
```r
# Pegar projeção mediana e ceiling de um jogador
sim_data <- dudes_simulation_db$dudes_players_simulations %>%
  filter(
    season == 2024,
    week == 4,
    playerId == 2552374,
    simType == "proj_src_w_errors"
  )

# Mediana (50th percentile)
median_proj <- sim_data$simQuantiles[[1]]["50%"]

# Ceiling (85th percentile)
ceiling_proj <- sim_data$simQuantiles[[1]]["85%"]

# Floor (15th percentile)
floor_proj <- sim_data$simQuantiles[[1]]["15%"]
```

---

## Cross-Database Relationships

### Primary Join Keys

#### 1. **Player Identification**

```r
# FFA → NFL
ffa_db$ffa_player_ids$nfl_id (character)
  → as.integer() →
    nfl_players_db$nfl_players$playerId (integer)

# FFA → Simulation
ffa_db$ffa_player_ids$id (character)
  → dudes_simulation_db$dudes_players_seeds$id (character)
```

#### 2. **Team Relationships**

```r
# Teams → Owners
nfl_teams_db$nfl_teams$ownerUserId
  → nfl_teams_db$nfl_owners$ownerUserId

# Teams → Rosters
nfl_teams_db$nfl_teams$teamId
  → nfl_round_db$nfl_teams_rosters$teamId

# Teams → Matchups
nfl_teams_db$nfl_teams$teamId
  → nfl_round_db$matchups_games$awayTeamTeamId
  → nfl_round_db$matchups_games$homeTeamTeamId
```

#### 3. **Statistics Relationships**

```r
# Players → Stats
nfl_players_db$nfl_players$playerId
  → nfl_stats_db$nfl_players_points$playerId
  → nfl_stats_db$nfl_players_stats$playerId

# Stats → Dictionary
nfl_stats_db$nfl_players_stats$statId
  → nfl_stats_db$nfl_stat_dictionary$statId
```

### Complete Join Example

```r
# Juntar projeções FFA com performance real NFL
library(tidyverse)
library(dm)

# 1. Carregar databases
ffa_db <- readRDS("data/ffa_db.rds")
stats_db <- readRDS("data/nfl_stats_db.rds")

# 2. ID mapping
id_map <- ffa_db$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))

# 3. Join projeções com performance
analysis <- ffa_db$ffa_projtable %>%
  filter(
    season == 2024,
    week == 4,
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  inner_join(id_map, by = "id") %>%
  inner_join(
    stats_db$nfl_players_points,
    by = c("playerId", "season", "week")
  ) %>%
  mutate(
    error = pts - points,
    pct_error = error / points * 100
  ) %>%
  select(id, playerId, pos, points, pts, error, pct_error)

# 4. Análise de acurácia
analysis %>%
  group_by(pos) %>%
  summarise(
    n = n(),
    mae = mean(abs(error)),
    rmse = sqrt(mean(error^2)),
    bias = mean(error)
  )
```

---

## Data Quality Notes

### Missing Data Patterns

#### 1. **ffa_db** - Incomplete Player IDs
- **Problem**: Nem todos os jogadores têm IDs em todos os sistemas
- **Impact**: ~31% dos jogadores sem `nfl_id`
- **Solution**: Usar `ffa_players` para informações básicas quando ID não disponível

#### 2. **nfl_players_db** - ESB IDs
- **Problem**: 76.9% dos jogadores sem `esbId`
- **Impact**: Baixo - `esbId` raramente usado
- **Solution**: Usar `playerId` como identificador principal

#### 3. **nfl_player_injury_status** - Sparse Data
- **Problem**: 83.5% dos registros com NA em `injuryGameStatus`
- **Impact**: Normal - NA significa jogador saudável
- **Solution**: `filter(!is.na(injuryGameStatus))` para ver apenas lesionados

#### 4. **nfl_stats_db** - Advanced Stats
- **Problem**: Alta % de NA em estatísticas avançadas (>80%)
- **Impact**: Dados avançados não disponíveis para todos
- **Solution**: Usar apenas quando disponível; não confiar para análises gerais

#### 5. **matchups_games** - Playoff Data
- **Problem**: ~82% NA em campos de playoff
- **Impact**: Normal - maioria dos jogos é temporada regular
- **Solution**: Filtrar `!is.na(bracketType)` para jogos de playoff apenas

### Temporal Data Considerations

#### Timestamp Best Practices

```r
# SEMPRE pegar o timestamp mais recente por grupo
latest_data <- table %>%
  filter(timestamp == max(timestamp), .by = c(season, week))
```

#### Tag Best Practices

- **preWaivers**: Projeções iniciais (segunda/terça)
- **preMNF**: Antes do Monday Night Football
- **postTNF**: Após Thursday Night Football
- **posWaivers**: Após waivers (quarta)
- **final**: Dados finais após todos os jogos

**Recomendação**: Para análises, usar `tag == "final"` quando possível.

---

## Usage Examples

### Example 1: Top Projections vs. Performance

```r
library(tidyverse)
library(dm)

# Carregar dados
ffa <- readRDS("data/ffa_db.rds")
stats <- readRDS("data/nfl_stats_db.rds")
players <- readRDS("data/nfl_players_db.rds")

# ID map
id_map <- ffa$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))

# Join everything
week_analysis <- ffa$ffa_projtable %>%
  filter(
    season == 2024,
    week == 4,
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  select(id, pos, proj = points, rank) %>%
  inner_join(id_map) %>%
  inner_join(
    stats$nfl_players_points %>%
      filter(season == 2024, week == 4),
    by = "playerId"
  ) %>%
  inner_join(
    players$nfl_players %>%
      select(playerId, name, nflTeamAbbr),
    by = "playerId"
  ) %>%
  mutate(
    diff = pts - proj,
    pct_diff = diff / proj * 100
  )

# Top overachievers
week_analysis %>%
  arrange(desc(diff)) %>%
  head(10) %>%
  select(name, nflTeamAbbr, pos, proj, pts, diff, pct_diff)

# Top underperformers
week_analysis %>%
  arrange(diff) %>%
  head(10) %>%
  select(name, nflTeamAbbr, pos, proj, pts, diff, pct_diff)
```

### Example 2: Roster Optimization Analysis

```r
# Qual foi a melhor escalação possível para cada time?

library(tidyverse)
library(dm)

# Carregar
round <- readRDS("data/nfl_round_db.rds")
stats <- readRDS("data/nfl_stats_db.rds")
players <- readRDS("data/nfl_players_db.rds")

# Função para selecionar melhores jogadores
selectBestRoster <- function(roster_players) {
  # Definir slots
  slots <- tribble(
    ~pos,   ~n,
    "QB",   1,
    "RB",   2,
    "WR",   2,
    "TE",   1,
    "K",    1,
    "DEF",  1
  )

  # Fixos
  fixed <- slots %>%
    pmap_df(function(pos, n) {
      roster_players %>%
        filter(position == pos) %>%
        slice_max(pts, n = n)
    })

  # FLEX (melhor WR/RB restante)
  flex <- roster_players %>%
    anti_join(fixed, by = "playerId") %>%
    filter(position %in% c("WR", "RB")) %>%
    slice_max(pts, n = 1)

  bind_rows(fixed, flex)
}

# Análise
team_efficiency <- round$nfl_teams_rosters %>%
  filter(
    season == 2024,
    week == 4,
    timestamp == max(timestamp)
  ) %>%
  left_join(
    players$nfl_players %>%
      select(playerId, position),
    by = "playerId"
  ) %>%
  left_join(
    stats$nfl_players_points %>%
      filter(season == 2024, week == 4),
    by = "playerId"
  ) %>%
  mutate(pts = replace_na(pts, 0)) %>%
  group_by(teamId) %>%
  summarise(
    # Pontuação real (starters)
    actual_pts = sum(
      pts[rosterSlotId < 20],
      na.rm = TRUE
    ),
    # Melhor possível
    optimal_roster = list(selectBestRoster(cur_data())),
    optimal_pts = sum(optimal_roster[[1]]$pts)
  ) %>%
  mutate(
    efficiency = actual_pts / optimal_pts * 100,
    pts_left = optimal_pts - actual_pts
  )

# Ver resultados
team_efficiency %>%
  arrange(desc(pts_left)) %>%
  select(teamId, actual_pts, optimal_pts, efficiency, pts_left)
```

### Example 3: Injury Impact Analysis

```r
# Jogadores que jogam mesmo "Questionable" performam bem?

library(tidyverse)
library(dm)

players_db <- readRDS("data/nfl_players_db.rds")
stats_db <- readRDS("data/nfl_stats_db.rds")

# Join injury status com performance
injury_impact <- players_db$nfl_player_injury_status %>%
  mutate(date = as.Date(timestamp)) %>%
  inner_join(
    stats_db$nfl_players_points,
    by = "playerId"
  ) %>%
  inner_join(
    players_db$nfl_players %>%
      select(playerId, name, position),
    by = "playerId"
  ) %>%
  # Assumir que injury status do dia antes do jogo é relevante
  # (simplificação - idealmente usar data do jogo)
  group_by(playerId, season, week) %>%
  slice_max(timestamp, n = 1) %>%
  ungroup()

# Comparar performance por status
injury_impact %>%
  mutate(
    status = case_when(
      is.na(injuryGameStatus) ~ "Healthy",
      injuryGameStatus == "Questionable" ~ "Questionable",
      TRUE ~ "Other"
    )
  ) %>%
  filter(status %in% c("Healthy", "Questionable")) %>%
  group_by(position, status) %>%
  summarise(
    n = n(),
    avg_pts = mean(pts, na.rm = TRUE),
    median_pts = median(pts, na.rm = TRUE),
    sd_pts = sd(pts, na.rm = TRUE),
    .groups = "drop"
  )
```

### Example 4: Simulation Analysis

```r
# Comparar estratégias de simulação

library(tidyverse)
library(dm)

sim_db <- readRDS("data/dudes_simulation_db.rds")
stats_db <- readRDS("data/nfl_stats_db.rds")
ffa_db <- readRDS("data/ffa_db.rds")

# ID map
id_map <- ffa_db$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))

# Comparar mediana de cada estratégia com performance real
sim_accuracy <- sim_db$dudes_players_simulations %>%
  filter(season == 2024, week == 4) %>%
  mutate(
    median_proj = map_dbl(simQuantiles, ~.x["50%"])
  ) %>%
  select(id, playerId, pos, simType, median_proj) %>%
  inner_join(
    stats_db$nfl_players_points %>%
      filter(season == 2024, week == 4),
    by = "playerId"
  ) %>%
  mutate(
    error = pts - median_proj,
    abs_error = abs(error),
    sq_error = error^2
  )

# Métricas por estratégia e posição
sim_accuracy %>%
  group_by(simType, pos) %>%
  summarise(
    n = n(),
    mae = mean(abs_error, na.rm = TRUE),
    rmse = sqrt(mean(sq_error, na.rm = TRUE)),
    bias = mean(error, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(pos, mae)

# Melhor estratégia por posição
sim_accuracy %>%
  group_by(simType, pos) %>%
  summarise(rmse = sqrt(mean(sq_error, na.rm = TRUE)), .groups = "drop") %>%
  group_by(pos) %>%
  slice_min(rmse, n = 3)
```

---

## 🔧 Maintenance Notes

### Adding New Data

#### Weekly Pipeline Update

```r
# data_pipeline.R will automatically:
# 1. Fetch new data
# 2. Upsert into existing databases
# 3. Maintain PKs and FKs
# 4. Preserve historical data with timestamps
```

#### Manual Database Inspection

```r
library(dm)

# Visualizar estrutura
db <- readRDS("data/ffa_db.rds")
dm_examine_constraints(db)
dm_draw(db)

# Verificar integridade
dm_examine_cardinalities(db)
```

### Data Validation Queries

```r
# Verificar duplicatas em PK
check_duplicates <- function(db, table_name, pk_cols) {
  db[[table_name]] %>%
    group_by(across(all_of(pk_cols))) %>%
    filter(n() > 1) %>%
    ungroup()
}

# Verificar FKs órfãos
check_orphans <- function(db, child_table, child_fk, parent_table, parent_pk) {
  db[[child_table]] %>%
    anti_join(
      db[[parent_table]],
      by = set_names(parent_pk, child_fk)
    )
}
```

---

## ⚠️ Armadilhas Comuns (Common Pitfalls)

Esta seção documenta erros frequentes ao trabalhar com os databases do DudesApp.

### 1. Conversão de ID FFA → NFL

**❌ ERRADO** - `nfl_id` é character, não integer:
```r
id_map <- ffa_db$ffa_player_ids %>%
  select(id, playerId = nfl_id)
# Vai causar problemas nos joins!
```

**✅ CORRETO** - Sempre converter para integer:
```r
id_map <- ffa_db$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))
```

---

### 2. Múltiplos timestamps por semana

**❌ ERRADO** - Pega todos os scrapes, incluindo versões antigas:
```r
proj <- ffa_db$ffa_projtable %>%
  filter(season == 2024, week == 4)
# Vai retornar múltiplas linhas por jogador!
```

**✅ CORRETO** - Filtrar timestamp mais recente:
```r
proj <- ffa_db$ffa_projtable %>%
  filter(
    season == 2024,
    week == 4,
    timestamp == max(timestamp)
  )
```

**Melhor ainda** - Usar `.by` para agrupar:
```r
proj <- ffa_db$ffa_projtable %>%
  filter(timestamp == max(timestamp), .by = c(season, week))
```

---

### 3. NA em injuryGameStatus significa saudável

**❌ ERRADO** - Remove jogadores saudáveis:
```r
injuries <- nfl_player_injury_status %>%
  drop_na(injuryGameStatus)
# Só mostra lesionados, perde informação dos saudáveis!
```

**✅ CORRETO** - Entender que NA = saudável:
```r
injury_status <- nfl_player_injury_status %>%
  mutate(
    status = if_else(
      is.na(injuryGameStatus),
      "Healthy",
      injuryGameStatus
    )
  )
```

---

### 4. Starters vs Bench - rosterSlotId

**❌ ERRADO** - Inclui jogadores do bench na análise:
```r
team_pts <- nfl_teams_rosters %>%
  left_join(nfl_players_points) %>%
  summarise(total = sum(pts))
# Soma TODOS os jogadores, não só starters!
```

**✅ CORRETO** - Filtrar apenas starters (slotId < 20):
```r
team_pts <- nfl_teams_rosters %>%
  filter(rosterSlotId < 20) %>%  # Apenas starters
  left_join(nfl_players_points) %>%
  summarise(total = sum(pts, na.rm = TRUE))
```

---

### 5. Join FFA → NFL sem tratamento de NAs

**❌ ERRADO** - Não trata NAs no nfl_id:
```r
analysis <- ffa_db$ffa_projtable %>%
  left_join(
    ffa_db$ffa_player_ids %>%
      transmute(id, playerId = as.integer(nfl_id))
  ) %>%
  left_join(nfl_players_db$nfl_players)
# ~31% dos jogadores terão playerId = NA!
```

**✅ CORRETO** - Filtrar NAs explicitamente:
```r
id_map <- ffa_db$ffa_player_ids %>%
  filter(!is.na(nfl_id)) %>%
  transmute(id, playerId = as.integer(nfl_id))

analysis <- ffa_db$ffa_projtable %>%
  inner_join(id_map) %>%  # inner_join remove NAs automaticamente
  left_join(nfl_players_db$nfl_players)
```

---

### 6. Usar tag errado para análises finais

**❌ ERRADO** - Usa projeções preliminares:
```r
proj <- ffa_db$ffa_projtable %>%
  filter(tag == "preWaivers")
# Dados de segunda/terça, antes de ajustes!
```

**✅ CORRETO** - Usar tag "final" para análises:
```r
proj <- ffa_db$ffa_projtable %>%
  filter(tag == "final")
# Dados após todos os jogos da semana
```

**Tags disponíveis** (em ordem cronológica):
1. `preWaivers` - Antes do waiver wire
2. `postTNF` - Após Thursday Night Football
3. `preMNF` - Antes do Monday Night Football
4. `posWaivers` - Após waiver wire
5. `final` - Dados finais após todos os jogos

---

### 7. Esquecer de tratar playerId = 0

**❌ ERRADO** - Conta slots vazios como jogadores:
```r
roster_size <- nfl_teams_rosters %>%
  count(teamId)
# Conta slots vazios (playerId = 0)!
```

**✅ CORRETO** - Filtrar playerId = 0:
```r
roster_size <- nfl_teams_rosters %>%
  filter(playerId != 0) %>%
  count(teamId)
```

---

### 8. Não verificar se simType existe em simulations

**❌ ERRADO** - Assume que todos os seeds têm simulações:
```r
sim_results <- dudes_simulation_db$dudes_players_seeds %>%
  left_join(dudes_simulation_db$dudes_players_simulations)
# Algumas combinações terão simulation = NA!
```

**✅ CORRETO** - Use inner_join ou verifique os simTypes disponíveis:
```r
# Opção 1: Inner join (só pega seeds com simulações)
sim_results <- dudes_simulation_db$dudes_players_seeds %>%
  inner_join(dudes_simulation_db$dudes_players_simulations)

# Opção 2: Verificar simTypes disponíveis primeiro
available_simTypes <- dudes_simulation_db$dudes_players_simulations %>%
  distinct(simType) %>%
  pull(simType)

sim_results <- dudes_simulation_db$dudes_players_seeds %>%
  filter(simType %in% available_simTypes)
```

---

## 📚 Additional Resources

### Related Documentation

- [README.md](README.md) - Project overview
- [R/pipeline/data_pipeline.R](R/pipeline/data_pipeline.R) - ETL pipeline code
- [R/snippets/simulation_machine.R](R/snippets/simulation_machine.R) - Simulation engine

### Package Documentation

- [dm package](https://cynkra.github.io/dm/) - Data modeling
- [ffanalytics package](https://github.com/FantasyFootballAnalytics/ffanalytics) - Projection scraping
- [tidyverse](https://www.tidyverse.org/) - Data manipulation

---

## 📊 Quick Reference Card

### Most Common Joins

```r
# FFA → NFL Player
ffa_db$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))

# Projection → Performance
ffa_db$ffa_projtable %>%
  inner_join(id_map) %>%
  inner_join(stats_db$nfl_players_points)

# Team → Roster → Player Stats
nfl_teams_db$nfl_teams %>%
  inner_join(nfl_round_db$nfl_teams_rosters) %>%
  inner_join(stats_db$nfl_players_points)

# Player → Injury Status
players_db$nfl_players %>%
  left_join(
    players_db$nfl_player_injury_status %>%
      filter(timestamp == max(timestamp))
  )
```

### Common Filters

```r
# Latest data only
filter(timestamp == max(timestamp), .by = c(season, week))

# Starters only
filter(rosterSlotId < 20)

# Healthy players only
filter(is.na(injuryGameStatus))

# Current season
filter(season == max(season))

# Regular season (no playoffs)
filter(is.na(bracketType))
```

---

**Document Version**: 1.1
**Last Updated**: 2026-03-06 (Atualizado após auditoria técnica)
**Maintainer**: DudesApp Team
**Changelog**:
- v1.1 (2026-03-06): Corrigido diagrama ERD de ffa_db e nfl_stats_db; Atualizado byeWeek (9 valores); Adicionado nota sobre simType em dudes_simulation_db; Adicionada seção "Armadilhas Comuns"
- v1.0 (2026-03-06): Versão inicial

<div align="center">

**[⬆ Back to Top](#-dudesapp---data-model-documentation)**

</div>
