# 📖 DudesApp - Data Dictionary

> **Dicionário técnico de dados para todas as tabelas e colunas do sistema**
>
> Version: 1.0 | Generated: 2026-03-06 | Databases: 7 | Tables: 21 | Total Columns: 183

---

## 📑 Table of Contents

### Databases
1. [ffa_db.rds](#1-ffa_dbrds---fantasy-football-analytics) (5 tables, 71 columns)
2. [nfl_teams_db.rds](#2-nfl_teams_dbrds---league-teams--owners) (2 tables, 6 columns)
3. [nfl_players_db.rds](#3-nfl_players_dbrds---nfl-players) (2 tables, 22 columns)
4. [nfl_stats_db.rds](#4-nfl_stats_dbrds---player-statistics) (4 tables, 40 columns)
5. [nfl_round_db.rds](#5-nfl_round_dbrds---matchups--rosters) (5 tables, 37 columns)
6. [nfl_recap_db.rds](#6-nfl_recap_dbrds---game-recaps) (1 table, 15 columns)
7. [dudes_simulation_db.rds](#7-dudes_simulation_dbrds---simulation-data) (2 tables, 15 columns)

### Utilities
- [Column Index (Alphabetical)](#column-index-alphabetical)
- [Primary Keys Reference](#primary-keys-reference)
- [Foreign Keys Reference](#foreign-keys-reference)

---

## Notation Guide

| Symbol | Meaning |
|--------|---------|
| 🔑 | Primary Key |
| 🔗 | Foreign Key |
| ⚠️ | Nullable (pode ser NULL) |
| ✓ | Required (NOT NULL) |
| 📝 | List-column (contém objetos complexos) |
| 🕐 | Timestamp/Temporal data |

---

## 1. ffa_db.rds - Fantasy Football Analytics

**File Size**: 7.6 MB | **Tables**: 5 | **Purpose**: Projeções de múltiplas fontes

---

### Table: `ffa_player_ids`

**Purpose**: Mapeamento de IDs entre diferentes sistemas de fantasy football

**Rows**: 5,395 | **Columns**: 15

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `id` | character | 🔑 | ✓ | 5395 | ID universal interno do ffanalytics |
| `stats_id` | character | - | ⚠️ (2.9%) | 5237 | ID do sistema Stats |
| `cbs_id` | character | - | ⚠️ (7.5%) | 4985 | ID do CBS Sports |
| `fleaflicker_id` | character | - | ⚠️ (30.3%) | 3756 | ID do FleaFlicker |
| `nfl_id` | character | - | ⚠️ (31.4%) | 3701 | **ID oficial da NFL** (converter para integer para joins) |
| `espn_id` | character | - | ⚠️ (18.9%) | 4369 | ID do ESPN |
| `fftoday_id` | character | - | ⚠️ (21.9%) | 4211 | ID do FFToday |
| `numfire_id` | character | - | ⚠️ (31.9%) | 3672 | ID do NumberFire |
| `fantasypro_id` | character | - | ⚠️ (18.4%) | 4398 | ID do FantasyPros (formato texto) |
| `fantasydata_id` | character | - | ⚠️ (59.7%) | 2170 | ID do FantasyData |
| `fantasynerd_id` | character | - | ⚠️ (75.9%) | 1299 | ID do FantasyNerd |
| `rts_id` | character | - | ⚠️ (72.3%) | 1492 | ID do RTSports |
| `fantasypro_num_id` | character | - | ⚠️ (39.9%) | 3242 | ID numérico do FantasyPros |
| `gsis_id` | character | - | ⚠️ (21%) | 4260 | ID do Game Statistics and Information System |
| `sleeper_id` | character | - | ⚠️ (4.5%) | 5151 | ID do Sleeper App |

---

### Table: `ffa_players`

**Purpose**: Informações básicas dos jogadores projetados

**Rows**: 858 | **Columns**: 8

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `id` | character | 🔑🔗 | ✓ | 849 | ID do jogador (FK → ffa_player_ids.id) |
| `pos` | character | 🔑 | ✓ | 6 | Posição: QB, RB, WR, TE, K, DST |
| `first_name` | character | - | ⚠️ (0.5%) | 538 | Primeiro nome |
| `last_name` | character | - | ⚠️ (0.5%) | 670 | Sobrenome |
| `team` | character | - | ⚠️ (0.5%) | 33 | Abreviação do time NFL |
| `position` | character | - | ⚠️ (0.5%) | 7 | Posição detalhada (pode incluir FB, RBWR) |
| `age` | integer | - | ⚠️ (4.5%) | 23 | Idade do jogador |
| `exp` | integer | - | ⚠️ (0.5%) | 23 | Anos de experiência (-4 = rookie futuro) |

---

### Table: `ffa_projtable`

**Purpose**: Projeções agregadas usando diferentes métodos de média

**Rows**: 61,332 | **Columns**: 26

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada (2024, 2025) |
| `week` | integer | 🔑 | ✓ | 18 | Semana da NFL (0-18, onde 0 = preseason) |
| `tag` | character | 🔑 | ✓ | 6 | Momento: preWaivers, final, posWaivers, etc. |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Momento da coleta |
| `avg_type` | character | 🔑 | ✓ | 3 | Tipo: average, robust, weighted |
| `id` | character | 🔑🔗 | ✓ | 849 | ID do jogador (FK → ffa_players) |
| `pos` | character | 🔑🔗 | ✓ | 6 | Posição (FK → ffa_players) |
| `points` | numeric | - | ✓ | 49536 | **Projeção de pontos** |
| `sd_pts` | numeric | - | ⚠️ (8.4%) | 47569 | Desvio padrão das projeções |
| `dropoff` | numeric | - | ✓ | 48080 | Diferença para o próximo jogador ranqueado |
| `rank` | integer | - | ✓ | - | Ranking na posição |
| `tier` | integer | - | ✓ | - | Tier do jogador |
| `ceiling` | numeric | - | ✓ | - | Projeção otimista (quantil alto) |
| `floor` | numeric | - | ✓ | - | Projeção pessimista (quantil baixo) |
| `pass_att` | numeric | - | ⚠️ | - | Tentativas de passe (QB) |
| `pass_comp` | numeric | - | ⚠️ | - | Passes completos (QB) |
| `pass_yds` | numeric | - | ⚠️ | - | Jardas de passe (QB) |
| `pass_tds` | numeric | - | ⚠️ | - | TDs de passe (QB) |
| `pass_int` | numeric | - | ⚠️ | - | Interceptações (QB) |
| `rush_att` | numeric | - | ⚠️ | - | Tentativas de corrida |
| `rush_yds` | numeric | - | ⚠️ | - | Jardas de corrida |
| `rush_tds` | numeric | - | ⚠️ | - | TDs de corrida |
| `rec_tgt` | numeric | - | ⚠️ | - | Alvos (targets) |
| `rec` | numeric | - | ⚠️ | - | Recepções |
| `rec_yds` | numeric | - | ⚠️ | - | Jardas de recepção |
| `rec_tds` | numeric | - | ⚠️ | - | TDs de recepção |

**Note**: Colunas de estatísticas (pass_*, rush_*, rec_*) têm NAs para posições não aplicáveis.

---

### Table: `ffa_proj_source_points`

**Purpose**: Projeções individuais de cada fonte, antes da agregação

**Rows**: 103,266 | **Columns**: 8

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 18 | Semana |
| `tag` | character | 🔑 | ✓ | 6 | Momento da coleta |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Timestamp |
| `data_src` | character | 🔑 | ✓ | 11 | Fonte: CBS, ESPN, FantasyPros, etc. |
| `id` | character | 🔑🔗 | ✓ | 849 | ID do jogador (FK → ffa_players) |
| `pos` | character | 🔑🔗 | ✓ | 6 | Posição (FK → ffa_players) |
| `points` | numeric | - | ✓ | 18506 | **Projeção da fonte específica** |

**data_src values**: CBS, ESPN, FantasyPros, FantasySharks, FFToday, FleaFlicker, NumberFire, FantasyFootballNerd, NFL, RTSports, Walterfootball

---

### Table: `ffa_scrape`

**Purpose**: Metadados sobre cada operação de scraping

**Rows**: 39 | **Columns**: 5

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 18 | Semana |
| `tag` | character | 🔑 | ✓ | 6 | Tag da coleta |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Momento do scraping |
| `scrapeData` | list | - 📝 | ✓ | 39 | Raw data do scraping (formato ffanalytics) |

---

## 2. nfl_teams_db.rds - League Teams & Owners

**File Size**: 1.4 KB | **Tables**: 2 | **Purpose**: Times da liga de fantasy

---

### Table: `nfl_teams`

**Purpose**: Times participantes da liga de fantasy

**Rows**: 16 | **Columns**: 4

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `teamId` | integer | 🔑 | ✓ | 16 | ID único do time na liga |
| `name` | character | - | ✓ | 16 | Nome do time (ex: "Paulinia Robots") |
| `ownerUserId` | integer | - 🔗 | ✓ | 16 | ID do proprietário (FK → nfl_owners) |
| `imageUrl` | character | - | ✓ | 16 | URL da logo do time |

---

### Table: `nfl_owners`

**Purpose**: Proprietários dos times da liga

**Rows**: 16 | **Columns**: 2

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `ownerUserId` | integer | 🔑 | ✓ | 16 | ID único do usuário |
| `name` | character | - | ✓ | 15 | Nome do proprietário (1 duplicata) |

---

## 3. nfl_players_db.rds - NFL Players

**File Size**: 164 KB | **Tables**: 2 | **Purpose**: Jogadores da NFL e histórico de lesões

---

### Table: `nfl_players`

**Purpose**: Dados cadastrais dos jogadores disponíveis

**Rows**: 1,398 | **Columns**: 19

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `playerId` | integer | 🔑 | ✓ | 1398 | **ID único do jogador (NFL oficial)** |
| `nflGlobalEntityId` | character | - | ✓ | 1398 | ID global da NFL |
| `esbId` | character | - | ⚠️ (76.9%) | 323 | Elias Sports Bureau ID |
| `name` | character | - | ✓ | 1398 | Nome completo |
| `firstName` | character | - | ✓ | 789 | Primeiro nome |
| `lastName` | character | - | ✓ | 1017 | Sobrenome |
| `position` | character | - | ✓ | 6 | Posição: DEF, RB, WR, TE, QB, K |
| `nflTeamAbbr` | character | - | ✓ | 33 | Abreviação do time NFL (SF, DAL, etc.) |
| `nflTeamId` | integer | - | ⚠️ (33.5%) | 32 | ID do time NFL |
| `imageUrl` | character | - | ✓ | 1304 | URL da foto (padrão) |
| `smallImageUrl` | character | - | ✓ | 1304 | URL da foto (pequena) |
| `largeImageUrl` | character | - | ✓ | 1304 | URL da foto (grande) |
| `byeWeek` | integer | - | ⚠️ (33.5%) | 9 | Semana de bye week |
| `cancelledWeeks` | logical | - | ⚠️ (100%) | 0 | Semanas canceladas (sempre NA) |
| `archetypes` | logical | - | ⚠️ (100%) | 0 | Arquétipos (sempre NA) |
| `isUndroppable` | logical | - | ⚠️ (20.9%) | 1 | Se não pode ser dropado |
| `isReserveStatus` | logical | - | ✓ | 2 | Se está em lista de reserva/IR |
| `lastNoteTimestamp` | character | - | ⚠️ (13.7%) | 1206 | Última nota de notícias |
| `lastVideoTimestamp` | logical | - | ⚠️ (100%) | 0 | Último vídeo (sempre NA) |

---

### Table: `nfl_player_injury_status`

**Purpose**: Histórico temporal de status de lesões

**Rows**: 43,430 | **Columns**: 3

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `playerId` | integer | 🔑🔗 | ✓ | 1398 | ID do jogador (FK → nfl_players) |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Momento da captura do status |
| `injuryGameStatus` | character | - | ⚠️ (83.5%) | 9 | Status: Questionable, Out, IR, etc. (NA = saudável) |

**injuryGameStatus values**: NA (saudável), Questionable, Doubtful, Out, Injured Reserve, PUP, Non-Football Injury, Suspension, COVID-19

---

## 4. nfl_stats_db.rds - Player Statistics

**File Size**: 453 KB | **Tables**: 4 | **Purpose**: Estatísticas de performance

---

### Table: `nfl_stat_dictionary`

**Purpose**: Dicionário de códigos de estatísticas da NFL

**Rows**: 95 | **Columns**: 10

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `statId` | integer | 🔑 | ✓ | 95 | ID da estatística (1-95) |
| `abbr` | character | - | ✓ | 63 | Abreviação (GP, Att, Comp, etc.) |
| `name` | character | - | ✓ | 93 | Nome completo da estatística |
| `shortName` | character | - | ✓ | 88 | Nome curto |
| `scoringType` | character | - | ✓ | 3 | Tipo: '', 'points', 'yards_per_point' |
| `isBonus` | logical | - | ✓ | 2 | Se é estatística de bônus |
| `groupName` | character | - | ⚠️ (3.2%) | 17 | Grupo: Passing, Rushing, Receiving, etc. |
| `positionCategory` | character | - | ⚠️ (3.2%) | 4 | Categoria: O (offense), K (kicker), D (defense) |
| `n` | integer | - | ✓ | 2 | Ordem de exibição |
| `colName` | character | - | ✓ | 95 | Nome da coluna no sistema |

---

### Table: `nfl_players_points`

**Purpose**: Pontuação total de cada jogador por semana

**Rows**: 12,593 | **Columns**: 4

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `playerId` | integer | 🔑 | ✓ | 767 | ID do jogador |
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 18 | Semana (0 = preseason) |
| `pts` | numeric | - | ✓ | 1686 | **Pontuação total fantasy** |

---

### Table: `nfl_players_stats`

**Purpose**: Estatísticas detalhadas por categoria

**Rows**: 75,596 | **Columns**: 5

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `playerId` | integer | 🔑 | ✓ | 832 | ID do jogador |
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 18 | Semana |
| `statId` | integer | 🔑🔗 | ✓ | 83 | ID da estatística (FK → nfl_stat_dictionary) |
| `value` | numeric | - | ✓ | 980 | **Valor da estatística** |

---

### Table: `nfl_players_adv_stats`

**Purpose**: Estatísticas avançadas (ADP, ownership, etc.)

**Rows**: 19,816 | **Columns**: 21

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `playerId` | integer | 🔑 | ✓ | 1398 | ID do jogador |
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 18 | Semana |
| `averageDraftPosition` | numeric | - | ⚠️ (88.9%) | 490 | ADP (Average Draft Position) |
| `averageDraftAuctionCost` | numeric | - | ⚠️ (96.3%) | 58 | Custo médio em draft auction |
| `transactionNumAdds` | numeric | - | ⚠️ (88.7%) | 185 | Número de vezes adicionado |
| `transactionNumDrops` | numeric | - | ⚠️ (88.7%) | 216 | Número de vezes dropado |
| `percentStarted` | numeric | - | ⚠️ (47%) | 993 | % de ligas onde foi starter |
| `percentStartedChange` | numeric | - | ⚠️ (50.6%) | 1252 | Mudança no % started |
| `percentOwned` | numeric | - | ⚠️ (20.1%) | 986 | % de ligas onde está em roster |
| `percentOwnedChange` | numeric | - | ⚠️ (38.8%) | - | Mudança no % owned |
| `percentStartedBuysellChng` | numeric | - | ⚠️ | - | Mudança buy/sell % started |
| `transactionBuysellAdd` | numeric | - | ⚠️ | - | Adds em buy/sell |
| `transactionBuysellDrop` | numeric | - | ⚠️ | - | Drops em buy/sell |
| `transactionBuysellNet` | numeric | - | ⚠️ | - | Net buy/sell |
| `auctionTeamCount` | numeric | - | ⚠️ | - | Times em auction |
| `avgPointsAgainst` | numeric | - | ⚠️ | - | Média de pontos contra |
| `avgPointsAgainstRank` | numeric | - | ⚠️ | - | Rank pontos contra |
| `leaguesAvailable` | numeric | - | ⚠️ | - | Ligas disponível |
| `leaguesOwned` | numeric | - | ⚠️ | - | Ligas onde está owned |
| `leaguesStarted` | numeric | - | ⚠️ | - | Ligas onde foi started |

---

## 5. nfl_round_db.rds - Matchups & Rosters

**File Size**: 39 KB | **Tables**: 5 | **Purpose**: Matchups e escalações

---

### Table: `nfl_teams_round`

**Purpose**: Informações dos times em cada rodada

**Rows**: 510 | **Columns**: 6

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana |
| `teamId` | integer | 🔑 | ✓ | 16 | ID do time |
| `rank` | integer | - | ✓ | 16 | Ranking atual do time na liga |
| `imageUrl` | character | - | ✓ | 17 | URL da logo |
| `imageUrlLarge` | character | - | ✓ | 17 | URL da logo (grande) |

---

### Table: `nfl_teams_rosters`

**Purpose**: Escalações completas dos times (starters + bench)

**Rows**: 8,744 | **Columns**: 10

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana |
| `tag` | character | 🔑 | ✓ | 6 | Tag: preWaivers, final, posWaivers |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Momento da captura |
| `teamId` | integer | 🔑 | ✓ | 16 | ID do time |
| `slotPosition` | character | - | ✓ | 3 | Categoria: O (offense), K (kicker), DT (defense/team) |
| `rosterSlotId` | integer | 🔑 | ✓ | 8 | Slot: 1-8=starters, 20+=bench |
| `playerId` | integer | 🔑 | ⚠️ (0.2%) | 413 | ID do jogador (0 = slot vazio) |
| `isEditable` | logical | - | ✓ | 2 | Se o slot pode ser editado |
| `isReserveStatus` | logical | - | ✓ | 2 | Se está na IR |

**rosterSlotId mapping**: 1=QB, 2-3=RB, 4-5=WR, 6=TE, 7=FLEX, 8=K, 16=DEF, 20+=Bench

---

### Table: `nfl_teams_week_stats`

**Purpose**: Pontuação do time em cada semana

**Rows**: 540 | **Columns**: 7

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana |
| `tag` | character | 🔑 | ✓ | 3 | Tag (final, posTNF, preMNF) |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 36 | Momento da captura |
| `teamId` | integer | 🔑 | ✓ | 16 | ID do time |
| `statId` | character | 🔑 | ✓ | 1 | Sempre 'pts' |
| `value` | numeric | - | ✓ | 491 | **Pontuação total do time na semana** |

---

### Table: `nfl_teams_season_stats`

**Purpose**: Estatísticas acumuladas da temporada

**Rows**: 8,760 | **Columns**: 7

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana (acumulado até esta semana) |
| `tag` | character | 🔑 | ✓ | 6 | Tag |
| `timestamp` | POSIXct | 🔑🕐 | ✓ | 39 | Momento |
| `teamId` | integer | 🔑 | ✓ | 16 | ID do time |
| `name` | character | 🔑 | ✓ | 16 | Nome da estatística: rank, wins, losses, etc. |
| `value` | character | - | ✓ | 623 | Valor da estatística (texto) |

**name values**: rank, rankChange, divisionRank, gamesPlayed, wins, losses, ties, pointsFor, pointsAgainst, etc.

---

### Table: `matchups_games`

**Purpose**: Confrontos semanais entre times

**Rows**: 257 | **Columns**: 14

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana |
| `matchupId` | character | 🔑 | ✓ | 255 | ID: w{week}_a{awayId}_h{homeId} |
| `previewUrl` | character | - | ⚠️ (1.6%) | 253 | URL do preview |
| `recapUrl` | character | - | ⚠️ (1.6%) | 253 | URL do recap |
| `bracketType` | character | - | ⚠️ (81.7%) | 2 | Tipo playoff: consolation, championship |
| `bracketTitle` | character | - | ⚠️ (89.5%) | 10 | Fase: Quarterfinal, Semifinal, Final |
| `hasMatchupTeams` | logical | - | ✓ | 1 | Sempre TRUE |
| `awayTeamTeamId` | integer | - | ✓ | 16 | ID do time visitante |
| `awayTeamOutcome` | character | - | ✓ | 2 | Resultado: win/loss |
| `awayTeamPlayoffSeeding` | integer | - | ⚠️ (81.7%) | 7 | Seed no playoff |
| `homeTeamTeamId` | integer | - | ⚠️ (1.6%) | 16 | ID do time mandante |
| `homeTeamOutcome` | character | - | ✓ | 2 | Resultado: win/loss |
| `homeTeamPlayoffSeeding` | integer | - | ⚠️ (83.3%) | 7 | Seed no playoff |

---

## 6. nfl_recap_db.rds - Game Recaps

**File Size**: 934 KB | **Tables**: 1 | **Purpose**: Narrativas dos confrontos

---

### Table: `nfl_recap`

**Purpose**: Recaps com narrativas e análises dos matchups

**Rows**: 220 | **Columns**: 15

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `leagueId` | integer | 🔑 | ✓ | 1 | ID da liga (sempre 3940933) |
| `season` | integer | 🔑 | ✓ | 2 | Temporada |
| `week` | integer | 🔑 | ✓ | 17 | Semana |
| `matchupId` | character | 🔑 | ✓ | 218 | ID do matchup |
| `title` | character | - | ✓ | 220 | Título do recap |
| `paragraphs` | list | - 📝 | ✓ | 220 | Lista de parágrafos narrativos |
| `type` | character | - | ✓ | 1 | Sempre "Recap" |
| `written_at` | character | - | ✓ | 218 | Data de escrita |
| `weekday` | character | - | ✓ | 1 | Sempre "Tuesday" |
| `playoff` | logical | - | ✓ | 2 | Se é jogo de playoff |
| `standard_scheduling` | logical | - | ✓ | 2 | Se usa scheduling padrão |
| `standard_scoring` | logical | - | ✓ | 1 | Sempre FALSE (liga custom) |
| `teams` | list | - 📝 | ✓ | 220 | Dados dos dois times com destaques |
| `free_agent_target_touch_leaders` | list | - 📝 | ⚠️ | 28 | Destaques de free agents |
| `league_notes` | list | - 📝 | ⚠️ | 29 | Notas da liga |

---

## 7. dudes_simulation_db.rds - Simulation Data

**File Size**: 25.2 MB | **Tables**: 2 | **Purpose**: Simulações Monte Carlo

---

### Table: `dudes_players_seeds`

**Purpose**: Valores base (seeds) para cada estratégia de simulação

**Rows**: 21,809 | **Columns**: 7

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 1 | Temporada (2024) |
| `week` | integer | 🔑 | ✓ | 3 | Semana (2, 3, 4) |
| `id` | character | 🔑 | ✓ | 572 | ID do FFA |
| `playerId` | integer | 🔑 | ⚠️ (0.2%) | 569 | ID da NFL |
| `pos` | character | 🔑 | ✓ | 6 | Posição |
| `simType` | character | 🔑 | ✓ | 17 | Tipo de estratégia de simulação |
| `seeds` | list | - 📝 | ✓ | 16665 | Vetor de valores base para sampling |

**⚠️ Note**: 17 simTypes em seeds, mas apenas 13 em simulations.

**simType values**: NFL, proj_table_average, proj_table_robust, proj_table_weighted, proj_src, proj_src_errors, proj_src_w_errors, hist_data, current_season_his, proj_src_w_errors_balanced, proj_src_density, proj_src_errors_density, proj_src_w_errors_density, hist_data_density, current_season_his_density, proj_src_w_error_current_season_density, [+1 more]

---

### Table: `dudes_players_simulations`

**Purpose**: Resultados finais das simulações (1000 valores por jogador)

**Rows**: 15,799 | **Columns**: 8

| Column | Type | Key | Nullable | Distinct | Description |
|--------|------|-----|----------|----------|-------------|
| `season` | integer | 🔑 | ✓ | 1 | Temporada |
| `week` | integer | 🔑 | ✓ | 3 | Semana |
| `id` | character | 🔑 | ✓ | 572 | ID do FFA |
| `playerId` | integer | 🔑 | ⚠️ (0.2%) | 569 | ID da NFL |
| `pos` | character | 🔑 | ✓ | 6 | Posição |
| `simType` | character | 🔑 | ✓ | 13 | Tipo de estratégia (apenas 13 de 17) |
| `simulation` | list | - 📝 | ✓ | 14672 | Vetor com 1000 valores simulados |
| `simQuantiles` | list | - 📝 | ✓ | 10973 | Named vector: 5%, 15%, 30%, 50%, 70%, 85%, 95% |

---

## Column Index (Alphabetical)

Índice alfabético de todas as 183 colunas do sistema, com referência à tabela.

| Column Name | Table(s) | Database | Type | Description |
|-------------|----------|----------|------|-------------|
| `abbr` | nfl_stat_dictionary | nfl_stats_db | character | Abreviação da estatística |
| `age` | ffa_players | ffa_db | integer | Idade do jogador |
| `archetypes` | nfl_players | nfl_players_db | logical | Arquétipos (sempre NA) |
| `auctionTeamCount` | nfl_players_adv_stats | nfl_stats_db | numeric | Times em auction |
| `avgPointsAgainst` | nfl_players_adv_stats | nfl_stats_db | numeric | Média pontos contra |
| `avgPointsAgainstRank` | nfl_players_adv_stats | nfl_stats_db | numeric | Rank pontos contra |
| `averageDraftAuctionCost` | nfl_players_adv_stats | nfl_stats_db | numeric | Custo médio auction |
| `averageDraftPosition` | nfl_players_adv_stats | nfl_stats_db | numeric | ADP |
| `avg_type` | ffa_projtable | ffa_db | character | Tipo de agregação |
| `awayTeamOutcome` | matchups_games | nfl_round_db | character | Resultado away |
| `awayTeamPlayoffSeeding` | matchups_games | nfl_round_db | integer | Seed playoff away |
| `awayTeamTeamId` | matchups_games | nfl_round_db | integer | ID time away |
| `bracketTitle` | matchups_games | nfl_round_db | character | Fase playoff |
| `bracketType` | matchups_games | nfl_round_db | character | Tipo playoff |
| `byeWeek` | nfl_players | nfl_players_db | integer | Semana bye |
| `cancelledWeeks` | nfl_players | nfl_players_db | logical | Semanas canceladas |
| `cbs_id` | ffa_player_ids | ffa_db | character | ID CBS Sports |
| `ceiling` | ffa_projtable | ffa_db | numeric | Projeção otimista |
| `colName` | nfl_stat_dictionary | nfl_stats_db | character | Nome coluna sistema |
| `data_src` | ffa_proj_source_points | ffa_db | character | Fonte projeção |
| `dropoff` | ffa_projtable | ffa_db | numeric | Gap para próximo |
| `esbId` | nfl_players | nfl_players_db | character | Elias Sports ID |
| `espn_id` | ffa_player_ids | ffa_db | character | ID ESPN |
| `exp` | ffa_players | ffa_db | integer | Anos experiência |
| `fantasydata_id` | ffa_player_ids | ffa_db | character | ID FantasyData |
| `fantasynerd_id` | ffa_player_ids | ffa_db | character | ID FantasyNerd |
| `fantasypro_id` | ffa_player_ids | ffa_db | character | ID FantasyPros |
| `fantasypro_num_id` | ffa_player_ids | ffa_db | character | ID FantasyPros num |
| `fftoday_id` | ffa_player_ids | ffa_db | character | ID FFToday |
| `first_name` | ffa_players | ffa_db | character | Primeiro nome |
| `firstName` | nfl_players | nfl_players_db | character | Primeiro nome |
| `fleaflicker_id` | ffa_player_ids | ffa_db | character | ID FleaFlicker |
| `floor` | ffa_projtable | ffa_db | numeric | Projeção pessimista |
| `free_agent_target_touch_leaders` | nfl_recap | nfl_recap_db | list | Destaques FA |
| `groupName` | nfl_stat_dictionary | nfl_stats_db | character | Grupo estatística |
| `gsis_id` | ffa_player_ids | ffa_db | character | ID GSIS |
| `hasMatchupTeams` | matchups_games | nfl_round_db | logical | Tem matchup teams |
| `homeTeamOutcome` | matchups_games | nfl_round_db | character | Resultado home |
| `homeTeamPlayoffSeeding` | matchups_games | nfl_round_db | integer | Seed playoff home |
| `homeTeamTeamId` | matchups_games | nfl_round_db | integer | ID time home |
| `id` | ffa_player_ids, ffa_players, ffa_projtable, ffa_proj_source_points, dudes_players_seeds, dudes_players_simulations | Multiple | character | ID jogador FFA |
| `imageUrl` | nfl_teams, nfl_players, nfl_teams_round | Multiple | character | URL imagem |
| `imageUrlLarge` | nfl_teams_round | nfl_round_db | character | URL imagem grande |
| `injuryGameStatus` | nfl_player_injury_status | nfl_players_db | character | Status lesão |
| `isBonus` | nfl_stat_dictionary | nfl_stats_db | logical | É bônus |
| `isEditable` | nfl_teams_rosters | nfl_round_db | logical | Editável |
| `isReserveStatus` | nfl_players, nfl_teams_rosters | Multiple | logical | Está na IR |
| `isUndroppable` | nfl_players | nfl_players_db | logical | Não pode dropar |
| `largeImageUrl` | nfl_players | nfl_players_db | character | URL foto grande |
| `last_name` | ffa_players | ffa_db | character | Sobrenome |
| `lastName` | nfl_players | nfl_players_db | character | Sobrenome |
| `lastNoteTimestamp` | nfl_players | nfl_players_db | character | Última nota |
| `lastVideoTimestamp` | nfl_players | nfl_players_db | logical | Último vídeo |
| `leagueId` | nfl_recap | nfl_recap_db | integer | ID liga |
| `league_notes` | nfl_recap | nfl_recap_db | list | Notas liga |
| `leaguesAvailable` | nfl_players_adv_stats | nfl_stats_db | numeric | Ligas disponível |
| `leaguesOwned` | nfl_players_adv_stats | nfl_stats_db | numeric | Ligas owned |
| `leaguesStarted` | nfl_players_adv_stats | nfl_stats_db | numeric | Ligas started |
| `matchupId` | matchups_games, nfl_recap | Multiple | character | ID matchup |
| `n` | nfl_stat_dictionary | nfl_stats_db | integer | Ordem exibição |
| `name` | nfl_teams, nfl_owners, nfl_players, nfl_stat_dictionary, nfl_teams_season_stats | Multiple | character | Nome |
| `nfl_id` | ffa_player_ids | ffa_db | character | ID oficial NFL |
| `nflGlobalEntityId` | nfl_players | nfl_players_db | character | ID global NFL |
| `nflTeamAbbr` | nfl_players | nfl_players_db | character | Abrev time NFL |
| `nflTeamId` | nfl_players | nfl_players_db | integer | ID time NFL |
| `numfire_id` | ffa_player_ids | ffa_db | character | ID NumberFire |
| `ownerUserId` | nfl_teams, nfl_owners | nfl_teams_db | integer | ID owner |
| `paragraphs` | nfl_recap | nfl_recap_db | list | Parágrafos recap |
| `pass_att` | ffa_projtable | ffa_db | numeric | Tentativas passe |
| `pass_comp` | ffa_projtable | ffa_db | numeric | Passes completos |
| `pass_int` | ffa_projtable | ffa_db | numeric | Interceptações |
| `pass_tds` | ffa_projtable | ffa_db | numeric | TDs passe |
| `pass_yds` | ffa_projtable | ffa_db | numeric | Jardas passe |
| `percentOwned` | nfl_players_adv_stats | nfl_stats_db | numeric | % owned |
| `percentOwnedChange` | nfl_players_adv_stats | nfl_stats_db | numeric | Mudança % owned |
| `percentStarted` | nfl_players_adv_stats | nfl_stats_db | numeric | % started |
| `percentStartedBuysellChng` | nfl_players_adv_stats | nfl_stats_db | numeric | Mudança buysell |
| `percentStartedChange` | nfl_players_adv_stats | nfl_stats_db | numeric | Mudança % started |
| `playerId` | nfl_players, nfl_player_injury_status, nfl_players_points, nfl_players_stats, nfl_players_adv_stats, nfl_teams_rosters, dudes_players_seeds, dudes_players_simulations | Multiple | integer | ID jogador NFL |
| `playoff` | nfl_recap | nfl_recap_db | logical | É playoff |
| `points` | ffa_projtable, ffa_proj_source_points | ffa_db | numeric | Pontos projetados |
| `pos` | ffa_players, ffa_projtable, ffa_proj_source_points, dudes_players_seeds, dudes_players_simulations | Multiple | character | Posição |
| `position` | ffa_players, nfl_players | Multiple | character | Posição detalhada |
| `positionCategory` | nfl_stat_dictionary | nfl_stats_db | character | Categoria posição |
| `previewUrl` | matchups_games | nfl_round_db | character | URL preview |
| `pts` | nfl_players_points | nfl_stats_db | numeric | Pontos totais |
| `rank` | ffa_projtable, nfl_teams_round | Multiple | integer/numeric | Ranking |
| `rec` | ffa_projtable | ffa_db | numeric | Recepções |
| `rec_tds` | ffa_projtable | ffa_db | numeric | TDs recepção |
| `rec_tgt` | ffa_projtable | ffa_db | numeric | Targets |
| `rec_yds` | ffa_projtable | ffa_db | numeric | Jardas recepção |
| `recapUrl` | matchups_games | nfl_round_db | character | URL recap |
| `rosterSlotId` | nfl_teams_rosters | nfl_round_db | integer | Slot roster |
| `rts_id` | ffa_player_ids | ffa_db | character | ID RTSports |
| `rush_att` | ffa_projtable | ffa_db | numeric | Tentativas corrida |
| `rush_tds` | ffa_projtable | ffa_db | numeric | TDs corrida |
| `rush_yds` | ffa_projtable | ffa_db | numeric | Jardas corrida |
| `scoringType` | nfl_stat_dictionary | nfl_stats_db | character | Tipo scoring |
| `scrapeData` | ffa_scrape | ffa_db | list | Raw scrape data |
| `sd_pts` | ffa_projtable | ffa_db | numeric | Desvio padrão pts |
| `season` | ffa_projtable, ffa_proj_source_points, ffa_scrape, nfl_players_points, nfl_players_stats, nfl_players_adv_stats, nfl_teams_round, nfl_teams_rosters, nfl_teams_week_stats, nfl_teams_season_stats, matchups_games, nfl_recap, dudes_players_seeds, dudes_players_simulations | Multiple | integer | Temporada |
| `seeds` | dudes_players_seeds | dudes_simulation_db | list | Seeds simulação |
| `shortName` | nfl_stat_dictionary | nfl_stats_db | character | Nome curto |
| `simQuantiles` | dudes_players_simulations | dudes_simulation_db | list | Quantis simulação |
| `simType` | dudes_players_seeds, dudes_players_simulations | dudes_simulation_db | character | Tipo simulação |
| `simulation` | dudes_players_simulations | dudes_simulation_db | list | Valores simulados |
| `sleeper_id` | ffa_player_ids | ffa_db | character | ID Sleeper |
| `slotPosition` | nfl_teams_rosters | nfl_round_db | character | Posição slot |
| `smallImageUrl` | nfl_players | nfl_players_db | character | URL foto pequena |
| `standard_scheduling` | nfl_recap | nfl_recap_db | logical | Schedule padrão |
| `standard_scoring` | nfl_recap | nfl_recap_db | logical | Scoring padrão |
| `statId` | nfl_stat_dictionary, nfl_players_stats, nfl_teams_week_stats | Multiple | integer/character | ID estatística |
| `stats_id` | ffa_player_ids | ffa_db | character | ID Stats system |
| `tag` | ffa_projtable, ffa_proj_source_points, ffa_scrape, nfl_teams_rosters, nfl_teams_week_stats, nfl_teams_season_stats | Multiple | character | Tag momento |
| `team` | ffa_players | ffa_db | character | Time NFL |
| `teamId` | nfl_teams, nfl_teams_round, nfl_teams_rosters, nfl_teams_week_stats, nfl_teams_season_stats | Multiple | integer | ID time liga |
| `teams` | nfl_recap | nfl_recap_db | list | Dados times |
| `tier` | ffa_projtable | ffa_db | integer | Tier jogador |
| `timestamp` | ffa_projtable, ffa_proj_source_points, ffa_scrape, nfl_player_injury_status, nfl_teams_rosters, nfl_teams_week_stats, nfl_teams_season_stats | Multiple | POSIXct | Timestamp |
| `title` | nfl_recap | nfl_recap_db | character | Título recap |
| `transactionBuysellAdd` | nfl_players_adv_stats | nfl_stats_db | numeric | Adds buysell |
| `transactionBuysellDrop` | nfl_players_adv_stats | nfl_stats_db | numeric | Drops buysell |
| `transactionBuysellNet` | nfl_players_adv_stats | nfl_stats_db | numeric | Net buysell |
| `transactionNumAdds` | nfl_players_adv_stats | nfl_stats_db | numeric | Num adds |
| `transactionNumDrops` | nfl_players_adv_stats | nfl_stats_db | numeric | Num drops |
| `type` | nfl_recap | nfl_recap_db | character | Tipo (Recap) |
| `value` | nfl_players_stats, nfl_teams_week_stats, nfl_teams_season_stats | Multiple | numeric/character | Valor |
| `week` | ffa_projtable, ffa_proj_source_points, ffa_scrape, nfl_players_points, nfl_players_stats, nfl_players_adv_stats, nfl_teams_round, nfl_teams_rosters, nfl_teams_week_stats, nfl_teams_season_stats, matchups_games, nfl_recap, dudes_players_seeds, dudes_players_simulations | Multiple | integer | Semana |
| `weekday` | nfl_recap | nfl_recap_db | character | Dia semana |
| `written_at` | nfl_recap | nfl_recap_db | character | Data escrita |

---

## Primary Keys Reference

Lista completa de Primary Keys por tabela.

| Database | Table | Primary Key |
|----------|-------|-------------|
| ffa_db | ffa_player_ids | `id` |
| ffa_db | ffa_players | `id, pos` |
| ffa_db | ffa_projtable | `season, week, tag, timestamp, avg_type, id, pos` |
| ffa_db | ffa_proj_source_points | `season, week, tag, timestamp, data_src, id, pos` |
| ffa_db | ffa_scrape | `season, week, tag, timestamp` |
| nfl_teams_db | nfl_teams | `teamId` |
| nfl_teams_db | nfl_owners | `ownerUserId` |
| nfl_players_db | nfl_players | `playerId` |
| nfl_players_db | nfl_player_injury_status | `playerId, timestamp` |
| nfl_stats_db | nfl_stat_dictionary | `statId` |
| nfl_stats_db | nfl_players_points | `playerId, season, week` |
| nfl_stats_db | nfl_players_stats | `playerId, season, week, statId` |
| nfl_stats_db | nfl_players_adv_stats | `playerId, season, week` |
| nfl_round_db | nfl_teams_round | `season, week, teamId` |
| nfl_round_db | nfl_teams_rosters | `season, week, tag, timestamp, teamId, rosterSlotId, playerId` |
| nfl_round_db | nfl_teams_week_stats | `season, week, tag, timestamp, teamId, statId` |
| nfl_round_db | nfl_teams_season_stats | `season, week, tag, timestamp, teamId, name` |
| nfl_round_db | matchups_games | `season, week, matchupId` |
| nfl_recap_db | nfl_recap | `leagueId, season, week, matchupId` |
| dudes_simulation_db | dudes_players_seeds | `season, week, id, playerId, pos, simType` |
| dudes_simulation_db | dudes_players_simulations | `season, week, id, playerId, pos, simType` |

---

## Foreign Keys Reference

Lista completa de Foreign Keys (relacionamentos entre tabelas).

### Within ffa_db.rds

| Child Table | Child Column(s) | Parent Table | Parent Column(s) |
|-------------|----------------|--------------|------------------|
| ffa_players | id | ffa_player_ids | id |
| ffa_projtable | id, pos | ffa_players | id, pos |
| ffa_projtable | season, week, tag, timestamp | ffa_scrape | season, week, tag, timestamp |
| ffa_proj_source_points | id, pos | ffa_players | id, pos |
| ffa_proj_source_points | season, week, tag, timestamp | ffa_scrape | season, week, tag, timestamp |

### Within nfl_teams_db.rds

| Child Table | Child Column(s) | Parent Table | Parent Column(s) |
|-------------|----------------|--------------|------------------|
| nfl_teams | ownerUserId | nfl_owners | ownerUserId |

### Within nfl_players_db.rds

| Child Table | Child Column(s) | Parent Table | Parent Column(s) |
|-------------|----------------|--------------|------------------|
| nfl_player_injury_status | playerId | nfl_players | playerId |

### Within nfl_stats_db.rds

| Child Table | Child Column(s) | Parent Table | Parent Column(s) |
|-------------|----------------|--------------|------------------|
| nfl_players_stats | statId | nfl_stat_dictionary | statId |

### Within nfl_round_db.rds

| Child Table | Child Column(s) | Parent Table | Parent Column(s) |
|-------------|----------------|--------------|------------------|
| nfl_teams_rosters | season, week, teamId | nfl_teams_round | season, week, teamId |
| nfl_teams_week_stats | season, week, teamId | nfl_teams_round | season, week, teamId |
| nfl_teams_season_stats | season, week, teamId | nfl_teams_round | season, week, teamId |

### Cross-Database Relationships (Logical, not FK)

Estes relacionamentos existem logicamente mas não são Foreign Keys formais no dm object:

| From | To | Via Columns |
|------|----|----|
| ffa_player_ids.nfl_id | nfl_players.playerId | Convert: `as.integer(nfl_id)` |
| ffa_player_ids.id | dudes_players_seeds.id | Direct match (both character) |
| dudes_players_seeds | dudes_players_simulations | season, week, id, playerId, pos, simType |
| nfl_players_points | nfl_players_stats | playerId, season, week |
| nfl_teams.teamId | nfl_teams_round.teamId | Direct match |
| nfl_teams.teamId | matchups_games.awayTeamTeamId/homeTeamTeamId | Direct match |

---

## 📊 Summary Statistics

### Database Sizes

| Database | Size (MB) | Size (KB) | Tables | Total Rows | Total Columns |
|----------|-----------|-----------|--------|------------|---------------|
| dudes_simulation_db.rds | 24.6 | 25,234 | 2 | 37,608 | 15 |
| ffa_db.rds | 7.45 | 7,624 | 5 | 170,624 | 71 |
| nfl_players_db.rds | 0.16 | 164 | 2 | 44,828 | 22 |
| nfl_recap_db.rds | 0.91 | 934 | 1 | 220 | 15 |
| nfl_round_db.rds | 0.04 | 39 | 5 | 18,811 | 37 |
| nfl_stats_db.rds | 0.44 | 453 | 4 | 108,100 | 40 |
| nfl_teams_db.rds | 0.00 | 1.4 | 2 | 32 | 6 |
| **TOTAL** | **33.6 MB** | **34,450 KB** | **21** | **380,223** | **206** |

### Column Type Distribution

| Type | Count | % |
|------|-------|---|
| integer | 62 | 30.1% |
| character | 60 | 29.1% |
| numeric | 44 | 21.4% |
| list | 11 | 5.3% |
| logical | 18 | 8.7% |
| POSIXct | 11 | 5.3% |

### Key Statistics

- **Total Primary Keys**: 21 (uma por tabela)
- **Total Foreign Keys**: 11 (relacionamentos formais)
- **List-columns** (complex data): 11
- **Temporal columns** (timestamp/date): 11
- **Average columns per table**: 8.7
- **Largest table**: ffa_projtable (61,332 rows)
- **Smallest table**: nfl_teams (16 rows)

---

## 🔍 Quick Lookup Patterns

### Finding Players

```r
# By FFA ID
ffa_db$ffa_players %>% filter(id == "13589")

# By NFL ID
nfl_players_db$nfl_players %>% filter(playerId == 2552374)

# By Name
nfl_players_db$nfl_players %>% filter(str_detect(name, "Mahomes"))

# Convert FFA → NFL
ffa_db$ffa_player_ids %>%
  filter(id == "13589") %>%
  transmute(playerId = as.integer(nfl_id))
```

### Finding Statistics

```r
# Player points in a week
nfl_stats_db$nfl_players_points %>%
  filter(playerId == 2552374, season == 2024, week == 4)

# Detailed stats
nfl_stats_db$nfl_players_stats %>%
  inner_join(nfl_stats_db$nfl_stat_dictionary) %>%
  filter(playerId == 2552374, season == 2024, week == 4)

# Projections
ffa_db$ffa_projtable %>%
  filter(
    id == "13589",
    season == 2024,
    week == 4,
    avg_type == "weighted",
    timestamp == max(timestamp)
  )
```

### Finding Team/Roster Info

```r
# Team roster
nfl_round_db$nfl_teams_rosters %>%
  filter(
    teamId == 1,
    season == 2024,
    week == 4,
    timestamp == max(timestamp),
    rosterSlotId < 20  # Starters only
  )

# Matchups
nfl_round_db$matchups_games %>%
  filter(season == 2024, week == 4)

# Team points
nfl_round_db$nfl_teams_week_stats %>%
  filter(teamId == 1, season == 2024, week == 4)
```

---

**Document Version**: 1.0
**Last Updated**: 2026-03-06
**Source**: DudesApp Database Schema
**Format**: Data Dictionary (Technical Reference)

---

<div align="center">

**[⬆ Back to Top](#-dudesapp---data-dictionary)**

</div>
