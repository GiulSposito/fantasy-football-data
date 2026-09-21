# 📊 Modelo de Dados - Dudes Fantasy Football

Documentação do modelo de dados do sistema de análise de Fantasy Football.

**Última Atualização:** 2026-03-06
**Temporada:** 2025 NFL
**Total de Arquivos RDS:** ~245 arquivos

---

## 📋 Índice

1. [Visão Geral](#-visão-geral)
2. [Organização de Arquivos](#-organização-de-arquivos)
3. [Modelo Conceitual de Dados](#-modelo-conceitual-de-dados)
4. [Entidades Principais](#-entidades-principais)
5. [Padrões de Nomenclatura](#-padrões-de-nomenclatura)
6. [Dicionário de Dados Resumido](#-dicionário-de-dados-resumido)
7. [Relacionamentos Entre Entidades](#-relacionamentos-entre-entidades)
8. [Fluxo de Dados](#-fluxo-de-dados)
9. [Guia de Manipulação](#-guia-de-manipulação)
10. [Referência Cruzada](#-referência-cruzada)

---

## 🎯 Visão Geral

O sistema armazena dados em arquivos `.rds` (formato binário R) organizados por:
- **Tipo de dado**: Scrapes, projeções, simulações, estatísticas reais
- **Granularidade temporal**: Semanal, sazonal, histórico
- **Fase de processamento**: Raw → Processado → Agregado → Simulado

### Estrutura de Diretórios

```
data/
├── 2019/                          # Dados históricos (temporadas anteriores)
├── 2020/
├── 2021/
├── 2022/
├── 2023/
├── 2024/
└── (root)                         # Temporada atual (2025)
    ├── Draft Files               # 5 arquivos
    ├── Player Stats              # 1 arquivo central
    ├── Projections               # 2 arquivos centrais + 17 semanais
    ├── Weekly Scrapes            # 17 arquivos por padrão
    ├── Weekly Projections        # 51 arquivos (3 padrões x 17 semanas)
    ├── Simulations               # ~140 arquivos (múltiplas fases por semana, varia por calendário NFL)
    ├── Rankings                  # 34 arquivos (2 padrões x 17 semanas)
    ├── Season Aggregates         # 8 arquivos
    └── References                # 1 arquivo
```

---

## 🗂️ Organização de Arquivos

### Categorias de Dados

| Categoria | Arquivos | Propósito |
|-----------|----------|-----------|
| **1. Player Statistics** | `players_points.rds` | Estatísticas reais dos jogadores |
| **2. Projections Core** | `points_projection*.rds` (2) | Projeções agregadas com/sem correção de erros |
| **3. Weekly Scrapes** | `week{X}_scrap.rds` (17) | Dados brutos de web scraping por semana |
| **4. Weekly Webscrapes** | `weekly_webscrapes_{X}.rds` (17) | Versão processada dos scrapes |
| **5. Weekly Projections** | `week{X}_players_projections.rds` (17) | Projeções completas por semana |
| **6. Projection Tables** | `weekly_proj_table_{X}.rds` (17) | Tabelas de projeção rankadas/tiered |
| **7. Site Projections** | `weekly_proj_player_site_{X}.rds` (17) | Projeções individuais por site |
| **8. Custom Projections** | `dudesffa_projpoints_week{X}.rds` (17) | Projeções customizadas (ML) |
| **9. Simulations** | `simulation_v5_week{X}_{phase}.rds` (~140) | Snapshots de simulações Monte Carlo (fases variam por semana) |
| **10. Team Rankings** | `rank_week{X}.rds` (17) | Rankings e estatísticas de times |
| **11. Position Rankings** | `rankAgainstPosition_week{X}.rds` (17) | Rankings por posição |
| **12. Draft** | `draft_*.rds` (5) | Dados do draft e análises |
| **13. Season Aggregates** | `season_*.rds` (8) | Dados agregados da temporada (equivalente a week0) |
| **14. Historical Errors** | `season_2024_projections_errors.rds` | Erros históricos para ML |
| **15. Accumulated** | `weeklies_scraps.rds` | Todos os scrapes da temporada |
| **16. Reference** | `injuryGameStatusAbbr.rds` | Lookup de status de lesão |

### Padrão de Repetição Semanal

**Arquivos que repetem por semana (0-17):**
- `week{X}_scrap.rds` - Scrapes brutos da semana X
- `week{X}_players_projections.rds` - Projeções completas da semana X
- `weekly_webscrapes_{X}.rds` - Webscrapes processados da semana X
- `weekly_proj_table_{X}.rds` - Tabela de projeções da semana X
- `weekly_proj_player_site_{X}.rds` - Projeções por site da semana X
- `dudesffa_projpoints_week{X}.rds` - Projeções customizadas da semana X
- `rank_week{X}.rds` - Rankings de times da semana X
- `rankAgainstPosition_week{X}.rds` - Rankings por posição da semana X

> **Nota:** Onde `{X}` pode ser:
> - `0` = **Temporada completa** (soma/agregação de todas as 17 semanas da temporada regular)
> - `1` a `17` = Semanas individuais da temporada regular NFL

---

## 🧱 Modelo Conceitual de Dados

```
┌─────────────────────────────────────────────────────────────────┐
│                     DUDES FANTASY FOOTBALL                       │
│                      DATA MODEL OVERVIEW                         │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   PLAYER DATA   │      │  PROJECTION DATA │      │  SIMULATION DATA │
│                 │      │                  │      │                  │
│ • Player IDs    │◄─────┤ • Raw Scrapes    │─────►│ • Game States   │
│ • Metadata      │      │ • Aggregated     │      │ • Probabilities │
│ • Stats (Real)  │      │ • Error-Corrected│      │ • Outcomes      │
│ • Weekly Perf   │      │ • ML Enhanced    │      │                 │
└────────┬────────┘      └────────┬─────────┘      └────────┬────────┘
         │                        │                         │
         │                        │                         │
         └────────────────────────┼─────────────────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────┐
                    │    FANTASY LEAGUE       │
                    │                         │
                    │  • Teams & Rosters      │
                    │  • Matchups             │
                    │  • Standings            │
                    │  • Draft Results        │
                    └─────────────────────────┘

                    ┌─────────────────────────┐
                    │   EXTERNAL SOURCES      │
                    │                         │
                    │  • ESPN API             │
                    │  • CBS Sports           │
                    │  • FantasyPros          │
                    │  • NFL.com              │
                    │  • Yahoo Fantasy        │
                    │  • + 5 more sources     │
                    └─────────────────────────┘
```

---

## 📦 Entidades Principais

### 1. **PLAYER** (Entidade Central)

**Arquivo Principal:** `players_points.rds`

**Identificadores:**
- `id` (integer) - ID interno do sistema (CHAVE PRIMÁRIA)
- `playerId` (integer) - ID NFL.com (estatísticas reais)
- `nfl_id` (integer) - Mesmo que playerId
- `cbs_id`, `espn_id`, `fantasypro_id`, etc. - IDs por plataforma

**Atributos:**
- Nome, posição, time NFL
- Idade, experiência, bye week
- Status de lesão
- URLs de imagens
- Estatísticas semanais (nested)
- Estatísticas agregadas (nested)

**Cardinalidade:** ~1,400 jogadores ativos por semana

---

### 2. **PROJECTION** (Dados Preditivos)

**Arquivos:**
- `points_projection.rds` - Projeções brutas
- `points_projection_and_errors.rds` - Projeções corrigidas

**Estrutura:**
```
week + data_src + id + pos → pts.proj
```

**Atributos:**
- `week` - Semana (1-17)
- `data_src` - Fonte (CBS, ESPN, FantasyPros, FleaFlicker, NFL)
- `id` - Player ID
- `pos` - Posição
- `pts.proj` - Pontos projetados
- `season` - Ano da temporada

**Granularidade:** Uma linha por jogador, por fonte, por semana

**Correções Aplicadas:**
- Erros históricos (lag-weighted)
- Erros da temporada anterior
- ML ensemble models

---

### 3. **WEEKLY_PROJECTION** (Visão Completa Semanal)

**Arquivo:** `week{X}_players_projections.rds`

**Estrutura:** União de PLAYER + PROJECTION + RANKINGS + TIERS + ROSTER_STATUS

**Atributos Principais:**
- **Projeções:** `points`, `floor`, `ceiling`, `sd_pts`
- **VOR:** `points_vor`, `floor_vor`, `ceiling_vor`
- **Rankings:** `rank`, `pos_rank`, `tier`
- **Roster:** `teamId`, `fantasy.team` (NULL = Free Agent)
- **Metadata:** Todos os campos de PLAYER

**Cardinalidade:** ~1,400 jogadores por semana

---

### 4. **WEEKLY_SCRAPE** (Dados Brutos)

**Arquivo:** `week{X}_scrap.rds`

**Estrutura:** Lista de 6 data.frames (por posição)

**Posições:**
- `QB` - Quarterbacks (~80 jogadores)
- `RB` - Running Backs (~120 jogadores)
- `WR` - Wide Receivers (~160 jogadores)
- `TE` - Tight Ends (~80 jogadores)
- `K` - Kickers (~35 jogadores)
- `DST` - Defense/Special Teams (~32 times)

**Atributos por Posição:**
- **QB:** Pass attempts, completions, yards, TDs, INTs, rush stats
- **RB:** Rush attempts, yards, TDs, receptions, receiving yards
- **WR/TE:** Targets, receptions, yards, TDs
- **K:** FG attempted/made, XP attempted/made
- **DST:** Sacks, INTs, fumble recoveries, TDs, points allowed

**Fontes:** CBS, ESPN, FantasyPros, FleaFlicker, NFL, FFToday, RTSports, WalterFootball

---

### 5. **SIMULATION** (Estado Completo de Simulação)

**Arquivo:** `simulation_v5_week{X}_{phase}.rds`

**Estrutura:** Lista de 11 elementos

**Elementos:**

| Elemento | Tipo | Descrição |
|----------|------|-----------|
| `week` | numeric | Semana atual |
| `season` | numeric | Temporada |
| `ptsproj` | data.frame | Todas as projeções (com erros) |
| `matchups` | data.frame | Matchups da semana |
| `teams` | data.frame | Dados de todos os times |
| `proj_table` | data.frame | Tabela de projeções |
| `players_stats` | data.frame | Estatísticas de jogadores |
| `players_id` | data.frame | Mapeamento de IDs |
| `players_sim` | data.frame | Jogadores no roster para simulação |
| `teams_sim` | data.frame | Resultados da simulação por time |
| `matchup_sim` | data.frame | Resultados da simulação por matchup |

**Fases da Semana:**

As fases disponíveis variam conforme o calendário NFL de cada semana:

**Fases padrão (maioria das semanas):**
- `preTNF` - Antes Thursday Night Football
- `posTNF` - Depois TNF
- `preSundayGames` - Antes dos jogos de domingo
- `preSNF` - Antes Sunday Night Football (semanas específicas)
- `preMNF` - Antes Monday Night Football
- `preWaivers` - Antes do processamento de waivers
- `posWaivers` - Depois dos waivers
- `final` - Semana completa (sempre presente)

**Fases de eventos especiais:**
- `preBR` / `posBrasilGame` - Jogos no Brasil
- `preLondon` / `preLondonGame` - Jogos em Londres
- `preDublinGame` - Jogos em Dublin
- `posThanksgiving` - Após Thanksgiving
- `preXMAS` - Antes de Natal

**Nota:** Fases de eventos especiais aparecem apenas nas semanas com jogos internacionais ou feriados.

**Cardinalidade:** ~140 arquivos total (varia: 7-9 fases por semana × 17 semanas, dependendo do calendário NFL)

---

### 6. **TEAM** (Times Fantasy)

**Arquivo Primário:** Dentro de `simulation_v5_*.rds$teams`

**Também em:** `rank_week{X}.rds`

**Atributos:**
- `teamId` - ID único do time
- `name` - Nome do time
- `ownerUserId` - ID do proprietário
- `imageUrl` - Logo do time
- `rank` - Posição atual
- `record` - Vitórias-Derrotas-Empates
- `rosters` (nested) - Roster completo
- `stats` (nested) - Estatísticas do time

**Cardinalidade:** 16 times na liga

---

### 7. **MATCHUP** (Partidas Semanais)

**Arquivo:** Dentro de `simulation_v5_*.rds$matchups`

**Atributos:**
- `matchupId` - ID único da partida
- `week` - Semana
- `awayTeam.teamId` - Time visitante
- `homeTeam.teamId` - Time mandante
- `awayTeam.simulation` - Resultados da simulação (visitante)
- `homeTeam.simulation` - Resultados da simulação (mandante)
- Probabilidades de vitória

**Cardinalidade:** 8 matchups por semana (16 times / 2)

---

### 8. **DRAFT** (Draft da Temporada)

**Arquivo Principal:** `draft_picks.rds`

**Estrutura:**
```
round + pick → player.id + team.id
```

**Atributos:**
- `round` - Rodada (1-15)
- `pick` - Pick geral (1-240)
- `player.id` - Jogador selecionado
- `player.name` - Nome do jogador
- `team.id` - Time que selecionou
- `team.name` - Nome do time

**Relacionado:**
- `draft_pick_projections.rds` - Picks com projeções pré-draft
- `draft_teams_projections.rds` - Análise por time
- `draft_recap_data.rds` - Recaps da NFL.com
- `draft_recap_rank.rds` - Rankings e grades dos drafts

**Cardinalidade:** 240 picks (16 times × 15 rodadas)

---

### 9. **SEASON_AGGREGATE** (Dados Sazonais)

**Arquivos:**
- `season_scrap.rds` - Scrapes sazonais (soma de todas as semanas)
- `season_projtable.rds` - Projeções da temporada completa
- `season_player_proj_sites.rds` - Projeções por site (temporada completa)
- `season_2024_projections_errors.rds` - Erros históricos para ML
- `week0_scrap.rds` - **Equivalente semanal** dos dados de temporada (formato week{X})

**Equivalência:**
- Arquivos `season_*` contêm dados agregados da temporada completa (17 semanas somadas)
- `week0_scrap.rds` contém os **mesmos dados** de temporada, mas no formato `week{X}` para compatibilidade com pipelines semanais
- **`week0` = `season`** - apenas convenções de nomenclatura diferentes para dados idênticos

**Uso:** Análise de temporada completa, treinamento de modelos, projeções pré-temporada

---

### 10. **AUXILIARY** (Arquivos Auxiliares)

Arquivos suplementares criados ad-hoc conforme necessidade.

#### `missing_player_ids.rds`

**Descrição:** Mapeamentos manuais de IDs de jogadores não detectados automaticamente pelo scraping

**Arquivo:** Presente em temporadas específicas quando necessário (e.g., `dudes/2024/missing_player_ids.rds`)

**Estrutura:** Tibble com schema idêntico aos campos de ID em outros arquivos

**Colunas:**
- `id`, `nfl_id`, `stats_id`, `cbs_id`, `espn_id`, `fleaflicker_id`, `fantasypro_id`, etc.

**Uso:** Suplementar IDs quando scraping automático falha (jogadores novatos, practice squad)

**Cardinalidade:** Varia (0-100 jogadores), criado apenas quando necessário

#### `draft_picks.html`

**Descrição:** Export HTML visual dos resultados do draft

**Arquivo:** Presente em temporadas com draft realizado (e.g., `dudes/2025/draft_picks.html`)

**Uso:** Visualização rápida em navegador; não usado em pipelines de dados

**Relacionamento:** Representação visual de `draft_picks.rds`

---

### 11. **RANKING** (Rankings e Posições)

**Arquivos:**
- `rank_week{X}.rds` - Rankings de times
- `rankAgainstPosition_week{X}.rds` - Rankings por posição

**Uso:** Standings, análise de performance, comparações

---

## 🏷️ Padrões de Nomenclatura

### Convenções de Nomes de Arquivos

| Padrão | Exemplo | Descrição |
|--------|---------|-----------|
| `week{X}_*.rds` | `week3_scrap.rds` | Dados da semana X (X=0 para temporada completa) |
| `weekly_*_{X}.rds` | `weekly_webscrapes_3.rds` | Dados semanais processados (semana X) |
| `*_week{X}.rds` | `rank_week3.rds` | Dados relacionados à semana X |
| `simulation_v{V}_week{X}_{phase}.rds` | `simulation_v5_week3_preTNF.rds` | Simulação versão V, semana X, fase específica |
| `season_*.rds` | `season_scrap.rds` | Dados agregados da temporada (equivalente a week0) |
| `draft_*.rds` | `draft_picks.rds` | Dados relacionados ao draft |

### Convenções de Colunas

| Coluna | Tipo | Significado |
|--------|------|-------------|
| `id` | integer | ID interno do jogador (CHAVE PRIMÁRIA) |
| `playerId` | integer | ID NFL.com do jogador |
| `nfl_id` | integer | Mesmo que playerId |
| `teamId` | integer | ID do time fantasy |
| `nflTeamId` | integer | ID do time NFL |
| `data_src` | character | Fonte de dados (CBS, ESPN, etc.) |
| `pos` / `position` | character | Posição (QB, RB, WR, TE, K, DST) |
| `week` | integer | Semana (1-17) |
| `season` | integer | Ano da temporada |
| `points` / `pts.proj` | numeric | Pontos (reais ou projetados) |
| `weekPts` | numeric | Pontos da semana específica |
| `floor` | numeric | Projeção conservadora (percentil 25) |
| `ceiling` | numeric | Projeção otimista (percentil 75) |
| `sd_pts` | numeric | Desvio padrão da projeção |
| `rank` | integer | Rank geral |
| `pos_rank` | integer | Rank dentro da posição |
| `tier` | integer | Agrupamento por tier |
| `*_vor` | numeric | Value Over Replacement |

---

## 📚 Dicionário de Dados Resumido

### Campos Chave por Tipo de Arquivo

#### **players_points.rds** (14,042 rows × 42 cols)
- Identificadores: `playerId`, `id`, `nfl_id`, `{platform}_id` (9 plataformas)
- Metadata: `name`, `firstName`, `lastName`, `position`, `nflTeamAbbr`, `byeWeek`
- Status: `injuryGameStatus`, `isReserveStatus`
- Imagens: `imageUrl`, `smallImageUrl`, `largeImageUrl`
- Estatísticas: `weekPts`, `weekSeasonPts`, `weekStats` (nested), `stats` (nested)
- Rankings: `rankAgainstPosition`

#### **points_projection_and_errors.rds** (90,202 rows × 6 cols)
- `week` - Semana (1-17)
- `data_src` - Fonte + variante de erro (ex: "ESPN_s2024_w3_error")
- `id` - Player ID
- `pos` - Posição
- `pts.proj` - Pontos projetados (com correção de erro aplicada)
- `season` - Temporada

#### **week{X}_players_projections.rds** (1,400 rows × 65 cols)
- **Projeções:** `points`, `floor`, `ceiling`, `sd_pts`
- **VOR:** `points_vor`, `floor_vor`, `ceiling_vor`
- **Rankings:** `rank`, `floor_rank`, `ceiling_rank`, `pos_rank`, `tier`
- **Roster:** `teamId`, `fantasy.team`
- **Dropoff:** `dropoff` (diferença para próximo jogador)
- **Plus:** Todos os campos de `players_points.rds`

#### **simulation_v5_week{X}_{phase}.rds** (Lista com 11 elementos)
- `week`, `season` - Contexto temporal
- `ptsproj` (~45k rows) - Todas as projeções
- `matchups` (8 rows) - Partidas da semana
- `teams` (16 rows) - Times com rosters nested
- `players_sim` (~230 rows) - Jogadores ativos na simulação
- `teams_sim` (16 rows) - Resultados simulados por time
- `matchup_sim` (8 rows) - Resultados simulados por partida

#### **dudesffa_projpoints_week{X}.rds** (470 rows × 5 cols)
- `id` - Player ID
- `estimate` - Projeção (média)
- `conf.low` - Intervalo de confiança inferior (95%)
- `conf.high` - Intervalo de confiança superior (95%)
- `data` (nested) - Dados de treinamento incluindo:
  - Projeções de cada fonte
  - Erros históricos (LAG_1, LAG_2 por fonte)

#### **rank_week{X}.rds** (16 rows × 22 cols)
- `teamId`, `name`, `imageUrl`
- `week.pts` - Pontos da semana
- `rank`, `rankChange`, `divisionRank`
- `record`, `wins`, `losses`, `ties`, `streak`
- `season.pts`, `season.ptsAgainst`
- `waiverPriority`, `playoffSeed`
- `transactionAddCount`, `transactionTradeCount`

---

## 🔗 Relacionamentos Entre Entidades

### Diagrama de Relacionamentos

```
┌────────────────────┐
│  players_points    │
│  ──────────────    │
│  PK: id            │
│      playerId      │
│      nfl_id        │
└─────────┬──────────┘
          │ 1
          │
          │ *
          ├──────────────────────────────────────┐
          │                                      │
          ▼ *                                    ▼ *
┌────────────────────┐              ┌────────────────────────┐
│  points_projection │              │ week{X}_players_       │
│  _and_errors       │              │ projections            │
│  ──────────────    │              │ ──────────────────     │
│  FK: id            │              │ FK: id                 │
│      week          │              │     playerId           │
│      data_src      │              │     teamId             │
└────────────────────┘              └───────────┬────────────┘
                                                │ *
                                                │
                                                │ 1
                                      ┌─────────▼────────┐
                                      │  teams           │
                                      │  ────────        │
                                      │  PK: teamId      │
                                      │      rosters(*)  │
                                      └─────────┬────────┘
                                                │ 1
                                                │
                                                │ *
                                      ┌─────────▼────────┐
                                      │  matchups        │
                                      │  ────────        │
                                      │  PK: matchupId   │
                                      │  FK: awayTeam.   │
                                      │      teamId      │
                                      │  FK: homeTeam.   │
                                      │      teamId      │
                                      └──────────────────┘

┌────────────────────┐              ┌────────────────────┐
│  draft_picks       │              │ rank_week{X}       │
│  ──────────────    │              │ ──────────────     │
│  FK: player.id ────┼──────────────┤ PK: teamId         │
│  FK: team.id       │              │     week           │
└────────────────────┘              └────────────────────┘

┌────────────────────────────────┐
│  simulation_v5_week{X}_{phase} │
│  ──────────────────────────    │
│  Contains:                     │
│    • ptsproj (FK: id)          │
│    • teams (PK: teamId)        │
│    • matchups (PK: matchupId)  │
│    • players_sim (FK: id)      │
│    • teams_sim (FK: teamId)    │
│    • matchup_sim (FK: matchup  │
│                        Id)     │
└────────────────────────────────┘
```

### Chaves de Relacionamento

| Arquivo Origem | Chave | Arquivo Destino | Chave | Tipo |
|----------------|-------|-----------------|-------|------|
| `players_points` | `id` | `points_projection_and_errors` | `id` | 1:N |
| `players_points` | `id` | `week{X}_players_projections` | `id` | 1:N |
| `players_points` | `id` | `weekly_proj_player_site_{X}` | `id` | 1:N |
| `players_points` | `id` | `dudesffa_projpoints_week{X}` | `id` | 1:N |
| `players_points` | `playerId` | `rankAgainstPosition_week{X}` | `playerId` | 1:N |
| `players_points` | `playerId` | `draft_picks` | `player.id` | 1:1 |
| `teams` | `teamId` | `rank_week{X}` | `teamId` | 1:N |
| `teams` | `teamId` | `draft_picks` | `team.id` | 1:N |
| `teams` | `teamId` | `matchups` | `awayTeam.teamId` | 1:N |
| `teams` | `teamId` | `matchups` | `homeTeam.teamId` | 1:N |

---

## 🔄 Fluxo de Dados

### Pipeline Completo

```
┌──────────────────────────────────────────────────────────────────┐
│                        DATA FLOW PIPELINE                         │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────┐
│  EXTERNAL APIs  │ (ESPN, CBS, FantasyPros, FleaFlicker, NFL, etc.)
└────────┬────────┘
         │
         ▼ SCRAPING
┌─────────────────┐
│ week{X}_scrap   │ ──┐
│ .rds            │   │
└─────────────────┘   │ ACCUMULATE
         │            │
         ▼            ▼
┌─────────────────┐  ┌──────────────────┐
│ weekly_web      │  │ weeklies_scraps  │
│ scrapes_{X}.rds │  │ .rds             │
└────────┬────────┘  └──────────────────┘
         │
         ▼ PROCESSING + AGGREGATION
┌─────────────────┐
│ weekly_proj_    │ (Individual site projections)
│ player_site_{X} │
└────────┬────────┘
         │
         ├──────────────────────────┐
         │                          │
         ▼ AGGREGATE                ▼ PROCESS RANKINGS/TIERS
┌─────────────────┐        ┌──────────────────┐
│ points_         │        │ weekly_proj_     │
│ projection.rds  │        │ table_{X}.rds    │
└────────┬────────┘        └──────────────────┘
         │
         ▼ ERROR CORRECTION
┌─────────────────┐
│ points_         │ ◄─── season_2024_projections_errors.rds
│ projection_and_ │      (Historical errors for ML)
│ errors.rds      │
└────────┬────────┘
         │
         ├──────────────────────┬────────────────┐
         │                      │                │
         ▼ ML MODELING          ▼ INTEGRATION    ▼ ESPN API
┌─────────────────┐    ┌──────────────────┐   ┌──────────────┐
│ dudesffa_proj   │    │ week{X}_players_ │   │ players_     │
│ points_week{X}  │    │ projections.rds  │   │ points.rds   │
│ .rds            │    └──────────┬───────┘   └──────┬───────┘
└─────────────────┘               │                   │
                                  │                   │
                                  └─────────┬─────────┘
                                            │
                                            ▼ ROSTER ALLOCATION
                                  ┌──────────────────┐
                                  │ teams + rosters  │
                                  └─────────┬────────┘
                                            │
                                            ▼ MONTE CARLO SIMULATION
                                  ┌──────────────────────────┐
                                  │ simulation_v5_week{X}_   │
                                  │ {phase}.rds              │
                                  └─────────┬────────────────┘
                                            │
                     ┌──────────────────────┼────────────────────┐
                     │                      │                    │
                     ▼ OUTCOMES             ▼ RANKINGS           ▼ ANALYSIS
            ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐
            │ matchup_sim      │  │ rank_week{X}.rds │  │ draft_recap_ │
            │ teams_sim        │  │ rankAgainst      │  │ rank.rds     │
            │                  │  │ Position_week{X} │  │              │
            └──────────────────┘  └──────────────────┘  └──────────────┘
                     │
                     ▼ ACCUMULATE ERRORS
            ┌──────────────────────────┐
            │ season_2025_projections_ │
            │ errors.rds               │ (Para próxima temporada)
            └──────────────────────────┘
```

### Sequência Temporal de Geração

**Ordem de Criação dos Arquivos:**

1. **Scraping** (Segunda/Quarta-feira antes da semana)
   - `week{X}_scrap.rds`
   - `weekly_webscrapes_{X}.rds`

2. **Processamento Básico** (Imediato)
   - `weekly_proj_player_site_{X}.rds`
   - `points_projection.rds` (atualizado)

3. **Correção de Erros** (Após processamento)
   - `points_projection_and_errors.rds` (inclui erros históricos)

4. **ML e Rankings** (Após correção)
   - `dudesffa_projpoints_week{X}.rds`
   - `weekly_proj_table_{X}.rds`

5. **Integração com API** (Durante a semana)
   - `players_points.rds` (atualizado em tempo real)
   - `rankAgainstPosition_week{X}.rds`

6. **Projeções Completas** (Antes dos jogos)
   - `week{X}_players_projections.rds`

7. **Simulação - Múltiplas Fases** (Durante a semana)
   - `simulation_v5_week{X}_preTNF.rds` (Quinta antes TNF)
   - `simulation_v5_week{X}_posTNF.rds` (Quinta depois TNF)
   - `simulation_v5_week{X}_preSundayGames.rds` (Domingo manhã)
   - `simulation_v5_week{X}_preMNF.rds` (Segunda antes MNF)
   - `simulation_v5_week{X}_final.rds` (Terça após MNF)

8. **Rankings Finais** (Após semana completa)
   - `rank_week{X}.rds`

9. **Acumulação** (Contínuo)
   - `weeklies_scraps.rds` (acumula todos os scrapes)

---

## 🛠️ Guia de Manipulação

### Como Ler Arquivos RDS

```r
# Ler um arquivo RDS
data <- readRDS("data/week3_players_projections.rds")

# Verificar estrutura
str(data)        # Estrutura completa
class(data)      # Tipo do objeto (data.frame, list, tibble)
names(data)      # Nomes das colunas/elementos
head(data, 10)   # Primeiras 10 linhas
dim(data)        # Dimensões (linhas x colunas)
```

### Operações Comuns

#### 1. Buscar Projeção de um Jogador

```r
# Carregar projeções da semana
proj <- readRDS("data/week3_players_projections.rds")

# Buscar por nome
cmc <- proj[proj$name == "Christian McCaffrey", ]

# Ver projeção
print(cmc[, c("name", "pos", "points", "floor", "ceiling", "tier")])
```

#### 2. Comparar Múltiplas Fontes

```r
# Carregar projeções individuais por site
site_proj <- readRDS("data/weekly_proj_player_site_3.rds")

# Filtrar por jogador (ex: id = 13130 é CMC)
cmc_sites <- site_proj[site_proj$id == 13130, ]

# Ver diferenças entre fontes
print(cmc_sites[, c("data_src", "pts.proj")])

# Calcular spread
spread <- max(cmc_sites$pts.proj) - min(cmc_sites$pts.proj)
print(paste("Spread:", spread))
```

#### 3. Analisar Acurácia de Projeções

```r
library(dplyr)

# Carregar erros históricos
errors <- readRDS("data/season_2024_projections_errors.rds")

# MAE por fonte
mae_by_source <- errors %>%
  group_by(data_src) %>%
  summarize(
    mae = mean(abs(proj.error), na.rm = TRUE),
    rmse = sqrt(mean(proj.error^2, na.rm = TRUE)),
    count = n()
  ) %>%
  arrange(mae)

print(mae_by_source)
```

#### 4. Explorar Simulação

```r
# Carregar snapshot da simulação
sim <- readRDS("data/simulation_v5_week3_preTNF.rds")

# Ver estrutura
names(sim)  # 11 elementos

# Acessar teams
teams <- sim$teams
print(teams[, c("teamId", "name", "rank")])

# Acessar matchup predictions
matchup_sim <- sim$matchup_sim
print(matchup_sim[, c("awayTeam.teamId", "homeTeam.teamId",
                      "homeTeam.win")])  # Prob. de vitória do mandante
```

#### 5. Análise de Draft

```r
# Carregar draft com projeções
draft <- readRDS("data/draft_pick_projections.rds")

# Identificar steals (valor > ADP)
library(dplyr)
steals <- draft %>%
  filter(!is.na(adp), !is.na(rank)) %>%
  mutate(value = adp - rank) %>%  # Positivo = steal
  filter(value > 10) %>%
  arrange(desc(value)) %>%
  select(round, pick, player.name, pos, rank, adp, value)

print(steals)
```

#### 6. Rankings de Time

```r
# Carregar rankings de uma semana
rankings <- readRDS("data/rank_week3.rds")

# Top 5 times
top5 <- rankings %>%
  arrange(rank) %>%
  head(5) %>%
  select(rank, name, record, week.pts, season.pts)

print(top5)

# Movimentações (maiores subidas/descidas)
movers <- rankings %>%
  arrange(desc(abs(rankChange))) %>%
  select(name, rank, rankChange, week.pts)

print(movers)
```

#### 7. Free Agents Disponíveis

```r
# Carregar projeções da semana
proj <- readRDS("data/week3_players_projections.rds")

# Filtrar free agents (sem fantasy.team)
library(dplyr)
free_agents <- proj %>%
  filter(fantasy.team == "*FreeAgent") %>%
  arrange(desc(points)) %>%
  select(name, pos, points, floor, ceiling, tier, rank) %>%
  head(20)

print(free_agents)
```

#### 8. Análise de Variance (Floor vs Ceiling)

```r
proj <- readRDS("data/week3_players_projections.rds")

library(dplyr)
variance_analysis <- proj %>%
  mutate(
    range = ceiling - floor,
    safe_score = range / points  # Quanto menor, mais seguro
  ) %>%
  filter(points > 5) %>%  # Apenas jogadores relevantes
  arrange(safe_score) %>%
  select(name, pos, points, floor, ceiling, range, safe_score) %>%
  head(20)

print(variance_analysis)  # Jogadores mais "seguros"
```

### Juntando Dados de Múltiplos Arquivos

```r
library(dplyr)

# 1. Projeções + Estatísticas Reais
proj <- readRDS("data/week3_players_projections.rds")
stats <- readRDS("data/players_points.rds") %>%
  filter(week == 3)

comparison <- proj %>%
  inner_join(stats, by = "id") %>%
  select(name.x, pos.x, points.x, weekPts) %>%
  rename(name = name.x, pos = pos.x, projected = points.x, actual = weekPts) %>%
  mutate(error = actual - projected) %>%
  arrange(desc(abs(error)))

print(comparison)

# 2. Draft Picks + Projeções Sazonais
draft <- readRDS("data/draft_picks.rds")
season_proj <- readRDS("data/season_projtable.rds")
player_stats <- readRDS("data/players_points.rds")

draft_analysis <- draft %>%
  left_join(player_stats %>% select(playerId, id), by = c("player.id" = "playerId")) %>%
  left_join(season_proj, by = "id") %>%
  select(round, pick, player.name, team.name, points, rank, pos_rank)

print(draft_analysis)
```

### Manipulando Listas (Scrapes e Simulações)

```r
# Scrapes são listas de data.frames por posição
scrape <- readRDS("data/week3_scrap.rds")

# Ver posições disponíveis
names(scrape)  # QB, RB, WR, TE, K, DST

# Acessar uma posição
qbs <- scrape$QB

# Combinar todas as posições em um único data.frame
library(purrr)
all_players <- map_df(scrape, ~.x, .id = "position")

# Filtrar por fonte
cbs_only <- all_players %>%
  filter(data_src == "CBS")
```

---

## 🔍 Referência Cruzada

### Por Caso de Uso

#### **Start/Sit Decisions**
Arquivos necessários:
- `week{X}_players_projections.rds` - Projeções completas
- `dudesffa_projpoints_week{X}.rds` - Intervalos de confiança
- `players_points.rds` - Histórico recente
- `rankAgainstPosition_week{X}.rds` - Matchup favorability

#### **Waiver Wire**
Arquivos necessários:
- `week{X}_players_projections.rds` - Identificar free agents
- `weekly_proj_table_{X}.rds` - Rankings e tiers
- `rank_week{X}.rds` - Prioridade de waivers
- `season_projtable.rds` - Projeções ROS (rest of season)

#### **Trade Analysis**
Arquivos necessários:
- `week{X}_players_projections.rds` - Valor atual
- `season_projtable.rds` - Valor de temporada
- `players_points.rds` - Tendências recentes
- `simulation_v5_week{X}_*.rds` - Impacto no time

#### **Draft Preparation**
Arquivos necessários:
- `season_projtable.rds` - Rankings pré-temporada
- `season_scrap.rds` - Múltiplas fontes
- Histórico: `data/2024/season_projtable.rds` - Comparação YoY

#### **Season-Long Strategy**
Arquivos necessários:
- `simulation_v5_week{X}_final.rds` - Probabilidades de playoff
- `rank_week{X}.rds` - Standings
- `draft_recap_data.rds` - Análise de roster

#### **Projection Accuracy Research**
Arquivos necessários:
- `season_2024_projections_errors.rds` - Erros históricos
- `points_projection_and_errors.rds` - Projeções atuais
- `players_points.rds` - Resultados reais

---

### Por Campo de Interesse

#### **Player Identification**
- `id` (integer) - CHAVE PRIMÁRIA universal
  - Usado em: Todos os arquivos de projeção
- `playerId` / `nfl_id` (integer) - ID NFL.com
  - Usado em: `players_points.rds`, `draft_picks.rds`, `rankAgainstPosition_*.rds`
- `{platform}_id` (character) - IDs específicos de plataforma
  - Usado em: `players_points.rds` (mapeamento)

#### **Scoring**
- `weekPts` - Pontos reais da semana
  - Fonte: `players_points.rds`
- `points` / `pts.proj` - Pontos projetados
  - Fonte: Arquivos de projeção
- `floor` / `ceiling` - Range de projeção
  - Fonte: Arquivos de projeção processados

#### **Rankings**
- `rank` - Rank geral (todos os jogadores)
- `pos_rank` - Rank dentro da posição
- `rankAgainstPosition` - Rank dentro da posição (alternativo)
- `tier` - Agrupamento por tier
- `overall_ecr` / `pos_ecr` - Expert consensus rankings

#### **Value**
- `points_vor` - Value Over Replacement
- `dropoff` - Diferença para próximo jogador
- `adp` - Average Draft Position
- `aav` - Average Auction Value

#### **Uncertainty**
- `sd_pts` - Desvio padrão
- `conf.low` / `conf.high` - Intervalos de confiança
- `uncertainty` - Métrica composta
- `proj.error` - Erro histórico

---

## 📊 Estatísticas do Sistema

### Volume de Dados

| Categoria | Arquivos | Tamanho Aproximado | Notas |
|-----------|----------|--------------------|-----------------------|
| Weekly Scrapes | 17 × 2 = 34 | ~50 MB | Includes week0 |
| Weekly Projections | 17 × 4 = 68 | ~80 MB | 4 patterns per week |
| Simulations | ~140 | ~70 MB | Varia por calendário NFL (fases de eventos) |
| Rankings | 17 × 2 = 34 | ~2 MB | Team + position rankings |
| Core Files | 5 | ~15 MB | Players, projections, errors |
| Draft Files | 6 | ~2 MB | Includes HTML export |
| Season Aggregates | 9 | ~10 MB | Includes timestamped versions (2025+) |
| Auxiliary Files | 2-3 | <1 MB | missing_player_ids (ad-hoc) |
| **TOTAL (2025)** | **~280** | **~230 MB** | Varia conforme completude da temporada |

### Granularidade Temporal

| Tipo de Dado | Frequência | Quantidade |
|--------------|------------|------------|
| Player Stats | Real-time (durante jogos) | 1 arquivo central |
| Projections | Semanal | 17 semanas |
| Simulations | 7-9 por semana | ~140 arquivos (varia por eventos NFL) |
| Rankings | Semanal | 17 semanas |
| Season Data | 1 por temporada | Acumulado |

---

## 🧰 Utilitários Recomendados

### Pacotes R Úteis

```r
# Manipulação de dados
library(tidyverse)  # dplyr, tidyr, ggplot2
library(purrr)      # Programação funcional

# Leitura/escrita
saveRDS(data, "path/to/file.rds")
data <- readRDS("path/to/file.rds")

# Análise
library(broom)      # Tidy statistical output
library(glue)       # String interpolation

# Visualização
library(plotly)     # Gráficos interativos
library(ggrepel)    # Labels inteligentes
```

### Scripts Helper Sugeridos

**1. `load_week_data.R`** - Carregar todos os dados de uma semana
```r
load_week_data <- function(week) {
  list(
    scrape = readRDS(glue("data/week{week}_scrap.rds")),
    projections = readRDS(glue("data/week{week}_players_projections.rds")),
    proj_table = readRDS(glue("data/weekly_proj_table_{week}.rds")),
    custom_proj = readRDS(glue("data/dudesffa_projpoints_week{week}.rds")),
    rankings = readRDS(glue("data/rank_week{week}.rds")),
    sim = readRDS(glue("data/simulation_v5_week{week}_final.rds"))
  )
}
```

**2. `compare_projections.R`** - Comparar projeção vs real
```r
compare_projections <- function(week) {
  proj <- readRDS(glue("data/week{week}_players_projections.rds"))
  stats <- readRDS("data/players_points.rds") %>% filter(week == !!week)

  inner_join(proj, stats, by = "id") %>%
    mutate(error = weekPts - points) %>%
    select(name.x, pos.x, points, weekPts, error)
}
```

**3. `get_player_history.R`** - Histórico de um jogador
```r
get_player_history <- function(player_name, max_week) {
  stats <- readRDS("data/players_points.rds")

  stats %>%
    filter(name == player_name, week <= max_week) %>%
    arrange(week) %>%
    select(week, weekPts, weekSeasonPts)
}
```

---

## 📝 Notas de Manutenção

### Backup e Versionamento

- **Git:** Não commitar arquivos `.rds` (são binários grandes)
- **Histórico:** Mover dados de temporadas anteriores para subdiretórios
  - Exemplo: `data/2024/` contém todos os arquivos de 2024
- **Backup Externo:** Fazer backup regular dos arquivos de simulação

### Limpeza de Dados

**Arquivos a remover ao fim da temporada:**
- `week{X}_scrap.rds` - Consolidado em `weeklies_scraps.rds`
- `weekly_webscrapes_{X}.rds` - Redundante
- Simulações intermediárias (manter apenas `_final.rds`)

**Arquivos a manter permanentemente:**
- `season_*.rds` - Dados agregados da temporada
- `draft_*.rds` - Histórico de draft
- `season_2025_projections_errors.rds` - Para ML futuro
- `weeklies_scraps.rds` - Histórico completo de scrapes

### Migração entre Temporadas

1. Mover dados da temporada anterior: `data/` → `data/2025/`
2. Gerar `season_2025_projections_errors.rds` para uso futuro
3. Limpar `data/` para nova temporada
4. Atualizar configurações: `config/config.yml`
5. Re-scrap `season_*.rds` com dados pré-temporada da nova temporada

---

## 📖 Referências

- **DATA_DICTIONARY.md** - Dicionário detalhado de cada arquivo
- **README.md** - Documentação geral do projeto
- **R/pipeline/update_pipe.R** - Pipeline completo de geração
- **R/simulation/players_projections.R** - Lógica de projeções
- **R/simulation/points_simulation_v6.R** - Lógica de simulação

---

## 🆘 Troubleshooting

### Erros Comuns

**1. "File not found"**
```r
# Verificar se arquivo existe
file.exists("data/week3_scrap.rds")

# Listar arquivos disponíveis
list.files("data/", pattern = "week3")
```

**2. "Object is not a data.frame"**
```r
# Scrapes e simulações são listas
data <- readRDS("data/week3_scrap.rds")
class(data)  # "list"

# Acessar elementos
data$QB      # Data.frame de QBs
```

**3. "Column not found"**
```r
# Verificar colunas disponíveis
names(data)

# Alguns arquivos usam nomes diferentes
# "pos" vs "position"
# "points" vs "pts.proj" vs "weekPts"
```

**4. "NA values"**
```r
# Jogadores lesionados podem ter NA
# Free agents não têm teamId/fantasy.team
# Jogadores novos podem não ter IDs históricos

# Tratamento
data %>% filter(!is.na(points))
data %>% replace_na(list(teamId = 0))
```

---

**Documento mantido por:** Projeto DudesFantasyFootball_claude
**Para dúvidas:** Consulte DATA_DICTIONARY.md ou README.md
**Versão:** 1.0
