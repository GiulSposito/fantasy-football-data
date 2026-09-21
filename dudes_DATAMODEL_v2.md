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
    ├── Simulations               # ~90 arquivos (múltiplas fases por semana)
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
| **9. Simulations** | `simulation_v5_week{X}_{phase}.rds` (~90) | Snapshots de simulações Monte Carlo |
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

**Estrutura:** Lista de 11 elementos contendo snapshot completo do estado da simulação Monte Carlo

**Metodologia:** Simulação Monte Carlo com 1.000 iterações por matchup, usando distribuições de probabilidade baseadas em múltiplas fontes de projeção e erros históricos.

---

## 📊 Resumo Visual da Estrutura de Simulação

### Hierarquia de Dados

```
simulation_v5_week17_final.rds (Lista com 11 elementos)
│
├─ [1] week: 17 (numeric)
├─ [2] season: 2025 (numeric)
│
├─ [3] ptsproj (90,202 × 6)
│   └─ Todas as projeções de todas as fontes
│      (CBS, ESPN, FantasyPros, FleaFlicker, NFL)
│
├─ [4] matchups (8 × 13)
│   └─ Metadados dos 8 jogos da semana
│      (IDs, outcomes, bracket info)
│
├─ [5] teams (16 × 14)
│   ├─ Dados escalares dos times
│   └─ Nested:
│       ├─ rosters: roster completo
│       ├─ stats: estatísticas hierárquicas
│       ├─ matchups: schedule
│       ├─ week.stats: stats da semana
│       └─ season.stats: stats da temporada
│
├─ [6] proj_table (491 × 22)
│   └─ Projeções processadas com ranks e tiers
│
├─ [7] players_stats (1,126 × 28)
│   └─ Estatísticas reais dos jogadores
│
├─ [8] players_id (5,395 × 13)
│   └─ Mapeamento de IDs entre plataformas
│
├─ [9] players_sim (219 × 18) ⚡ SIMULAÇÃO
│   ├─ Dados escalares (teamId, playerId, position, etc.)
│   └─ Arrays de simulação:
│       ├─ pts.proj [43]: projeções das fontes
│       ├─ weekPts.sim [1000]: pontos reais × 1000
│       ├─ simulation.org [1000]: distribuição probabilística
│       └─ simulation [1000]: final (real ou projetado)
│
├─ [10] teams_sim (16 × 3) ⚡ SIMULAÇÃO
│   ├─ teamId
│   ├─ simulation [1000]: soma dos titulares
│   └─ simulation.org [1000]: apenas projeções
│
└─ [11] matchup_sim (8 × 22) ⚡ SIMULAÇÃO
    ├─ Dados escalares:
    │   ├─ matchupId, week
    │   ├─ homeTeam.winProb, awayTeam.winProb
    │   └─ homeTeam.totalPts, awayTeam.totalPts
    └─ Arrays [1000]:
        ├─ awayTeam.simulation, homeTeam.simulation
        ├─ homeTeam.win (logical), awayTeam.win (logical)
        └─ homeTeam.ptsdiff (numeric)
```

### Fluxo de Simulação Monte Carlo

```
┌─────────────────────────────────────────────────────────┐
│  1. FONTES DE PROJEÇÃO (ptsproj)                        │
│  ─────────────────────────────────────────────────      │
│  CBS: 24.5 pts                                          │
│  ESPN: 23.6 pts          ┌──────────────┐               │
│  FantasyPros: 25.1 pts  ─┤ KDE + Sample  │              │
│  FleaFlicker: 24.0 pts   └──────┬───────┘               │
│  NFL: 24.8 pts                  │                        │
│  + error corrections            ▼                        │
└─────────────────────────────────┼───────────────────────┘
                                  │
                ┌─────────────────┴──────────────────┐
                │                                    │
        ┌───────▼────────┐                 ┌────────▼────────┐
        │ PLAYER DIST.   │                 │  PLAYER DIST.   │
        │ [1000 samples] │                 │  [1000 samples] │
        │ QB: [24.1,     │       ...       │  WR: [16.8,     │
        │      25.3,     │                 │       15.2,     │
        │      23.7,     │                 │       17.9,     │
        │      ...]      │                 │       ...]      │
        └───────┬────────┘                 └────────┬────────┘
                │                                    │
                └────────┬───────────────────────────┘
                         │ SUM STARTERS (rosterSlotId < 20)
                         ▼
                ┌──────────────────┐
                │  TEAM TOTALS     │
                │  [1000 samples]  │
                │  Team A: [102.3, │
                │           105.8, │
                │           98.5,  │
                │           ...]   │
                └────────┬─────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
  ┌─────▼─────┐                   ┌──────▼──────┐
  │  Team A   │  COMPARE (1000x)  │   Team B    │
  │  [102.3]  │ ─────────────────▶│   [98.7]    │
  │  [105.8]  │  Team A > Team B? │   [103.2]   │
  │  [98.5]   │      ✓ or ✗       │   [95.1]    │
  │  [...]    │                   │   [...]     │
  └───────────┘                   └─────────────┘
        │                                 │
        └────────┬────────────────────────┘
                 ▼
        ┌────────────────────┐
        │  WIN PROBABILITIES │
        │  ────────────────  │
        │  Team A wins: 652  │
        │  Team B wins: 348  │
        │                    │
        │  → Team A: 65.2%   │
        │  → Team B: 34.8%   │
        └────────────────────┘
```

### Progressão Temporal Durante a Semana

```
QUINTA      │  DOMINGO              │  SEGUNDA   │  TERÇA/QUARTA
────────────┼───────────────────────┼────────────┼──────────────
            │                       │            │
preTNF      │  preSundayGames       │  preMNF    │  preWaivers
   │        │      │                │     │      │      │
   │ TNF    │      │ Early games    │     │ MNF  │      │ Waivers
   ▼        │      ▼                │     ▼      │      ▼
posTNF      │  preSNF               │  final     │  posWaivers
   │        │      │                │            │
   │        │      │ SNF            │            │
   │        │      ▼                │            │
   │        │  posSNF               │            │
   │        │                       │            │
   └────────┴───────────────────────┴────────────┴──────────────▶
                                                              TEMPO

Legend:
  • preTNF: 100% projeções
  • posTNF: TNF = real, resto = projeções
  • preSundayGames: TNF = real, resto = projeções
  • preMNF: ~80% real, MNF = projeções
  • final: 100% real
  • posWaivers: 100% real + rosters atualizados
```

### Diferença: simulation vs simulation.org

```
┌──────────────────────────────────────────────────────────┐
│  simulation.org (Original - Apenas Projeções)            │
│  ──────────────────────────────────────────────────      │
│  Todos os jogadores: SEMPRE usa distribuição KDE        │
│  Útil para: Análise "what-if", comparação pré-game      │
└──────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────┐
│  simulation (Final - Híbrido)                            │
│  ──────────────────────────────────────────────────      │
│  IF jogador.isEditable = FALSE (jogo já aconteceu):     │
│     → Usa weekPts (pontos reais) × 1000                  │
│  ELSE (jogo ainda vai acontecer):                        │
│     → Usa distribuição KDE                               │
│  Útil para: Projeção realista, ajuste em tempo real     │
└──────────────────────────────────────────────────────────┘

EXEMPLO - Domingo 6pm (antes SNF):

Player          │ isEditable │ simulation usa:
────────────────┼────────────┼─────────────────────────
RB (jogou 1pm)  │   FALSE    │ [24.8, 24.8, ...] real
WR (jogou 1pm)  │   FALSE    │ [16.2, 16.2, ...] real
QB (joga SNF)   │   TRUE     │ [23.1, 25.8, ...] KDE
TE (joga SNF)   │   TRUE     │ [12.5, 9.8, ...]  KDE
```

---

**Elementos Principais:**

#### 5.1. `week` (numeric)
- Semana da NFL (1-17)
- Valor único

#### 5.2. `season` (numeric)
- Ano da temporada (ex: 2025)
- Valor único

#### 5.3. `ptsproj` (data.frame: ~90,202 × 6)
**Descrição:** Todas as projeções de todos os jogadores de todas as fontes, incluindo correções de erro
**Colunas:**
- `week` (integer) - Semana
- `data_src` (character/glue) - Fonte de dados (CBS, ESPN, FantasyPros, FleaFlicker, NFL) + variantes de erro
- `id` (integer) - Player ID interno
- `pos` (character) - Posição (QB, RB, WR, TE, K, DST)
- `pts.proj` (numeric) - Pontos projetados (com correção de erro aplicada)
- `season` (numeric) - Temporada

**Uso:** Base de dados para geração das distribuições de probabilidade na simulação

#### 5.4. `matchups` (data.frame: 8 × 13)
**Descrição:** Matchups da semana com metadados da NFL.com
**Colunas:**
- `matchupId` (character) - ID único do matchup (formato: "w{X}_a{away}_h{home}")
- `week` (integer) - Semana
- `previewUrl` (character) - URL da prévia NFL.com
- `recapUrl` (character) - URL do recap NFL.com
- `bracketType` (character) - Tipo de bracket ("championship", "consolation")
- `bracketTitle` (character) - Título do jogo (ex: "9th Place Game", "Championship")
- `hasMatchupTeams` (logical) - Se tem times definidos
- `awayTeam.teamId` (integer) - ID do time visitante
- `awayTeam.outcome` (character) - Resultado ("W", "L", NULL se não jogado)
- `awayTeam.playoffSeeding` (character) - Seed de playoff
- `homeTeam.teamId` (integer) - ID do time mandante
- `homeTeam.outcome` (character) - Resultado ("W", "L", NULL se não jogado)
- `homeTeam.playoffSeeding` (character) - Seed de playoff

**Cardinalidade:** 8 matchups por semana (16 times / 2)

#### 5.5. `teams` (data.frame: 16 × 14)
**Descrição:** Dados completos de todos os times da liga incluindo rosters e estatísticas
**Colunas Escalares:**
- `teamId` (integer) - ID único do time
- `name` (character) - Nome do time
- `ownerUserId` (integer) - ID do proprietário na NFL.com
- `coManagerUserId` (character) - ID do co-manager (NULL se não houver)
- `imageUrl` (character) - URL do logo (standard)
- `imageUrlLarge` (character) - URL do logo (grande)
- `isActive` (logical) - Se o time está ativo
- `rank` (character) - Ranking atual (string)
- `imageId` (character) - ID da imagem

**Colunas Nested (list):**

**`stats` (list):** Estatísticas do time, estruturado como:
  - `week` (list): Estatísticas por semana
    - `[season]` (list): Por temporada
      - `[week]` (list): Por semana
        - `pts` (character): Pontos da semana
  - `season` (list): Estatísticas sazonais
    - `[season]` (list): Por temporada
      - `rank` (character): Rank
      - `rankChange` (character): Mudança de rank
      - `divisionRank` (character): Rank na divisão
      - `record` (character): Record (formato "W-L-T")
      - `wins` (character): Vitórias
      - `losses` (character): Derrotas
      - `ties` (character): Empates
      - `streak` (character): Sequência (ex: "W2", "L1")
      - `waiverPriority` (character): Prioridade no waiver
      - `pts` (character): Pontos totais da temporada
      - `ptsAgainst` (character): Pontos contra
      - `playoffSeed` (character): Seed de playoff
      - `playoffBracketType` (character): Tipo de bracket
      - `place` (character): Colocação final
      - `transactionAddCount` (integer): Número de adds
      - `transactionTradeCount` (integer): Número de trades
      - `trophyImageUrl` (NULL/character): URL do troféu

**`matchups` (list):** IDs dos matchups por semana
  - `[week]` (character): matchupId da semana

**`rosters` (data.frame):** Roster completo do time
  - `slotPosition` (character): Posição do slot ("O", "O/F", "D", etc.)
  - `rosterSlotId` (integer): ID do slot (1-20, onde 20 = banco)
  - `playerId` (integer): ID do jogador NFL.com
  - `isEditable` (logical): Se o jogador pode ser editado (TRUE antes do jogo, FALSE após)
  - `isReserveStatus` (logical): Se está em reserve (IR, suspensão, etc.)

**`week.stats` (list):** Estatísticas da semana atual (estrutura similar a stats$week)

**`season.stats` (list):** Estatísticas da temporada (estrutura similar a stats$season)

#### 5.6. `proj_table` (data.frame: ~491 × 22)
**Descrição:** Tabela de projeções processadas com rankings e tiers
**Colunas:**
- `avg_type` (character) - Método de agregação (ex: "robust")
- `id` (integer) - Player ID
- `pos` (character) - Posição
- `points` (numeric) - Projeção de pontos
- `sd_pts` (numeric) - Desvio padrão
- `dropoff` (numeric) - Diferença para próximo jogador
- `floor` (numeric) - Floor (percentil 25)
- `ceiling` (numeric) - Ceiling (percentil 75)
- `points_vor` (numeric) - Value Over Replacement
- `floor_vor` (numeric) - Floor VOR
- `ceiling_vor` (numeric) - Ceiling VOR
- `rank` (integer) - Rank geral
- `floor_rank` (integer) - Rank por floor
- `ceiling_rank` (integer) - Rank por ceiling
- `pos_rank` (integer) - Rank na posição
- `tier` (integer) - Tier
- `first_name` (character) - Primeiro nome
- `last_name` (character) - Sobrenome
- `team` (character) - Time NFL
- `position` (character) - Posição
- `age` (integer) - Idade
- `exp` (integer) - Anos de experiência

#### 5.7. `players_stats` (data.frame: ~1,126 × 28)
**Descrição:** Estatísticas reais de todos os jogadores (idêntico a `players_points.rds`)
**Colunas:** Ver documentação de `players_points.rds`
- 28 colunas incluindo IDs, metadata, estatísticas nested, rankings
- Campo adicional: `isUndroppable` (logical) - Se o jogador não pode ser dropado

#### 5.8. `players_id` (data.frame: ~5,395 × 13)
**Descrição:** Mapeamento de IDs entre diferentes plataformas
**Colunas:**
- `id` (integer) - ID interno (CHAVE PRIMÁRIA)
- `stats_id` (character) - ID do provedor de estatísticas
- `cbs_id` (character) - CBS Sports ID
- `fleaflicker_id` (character) - FleaFlicker ID
- `nfl_id` (integer) - NFL.com ID
- `espn_id` (character) - ESPN ID
- `fftoday_id` (character) - FFToday ID
- `numfire_id` (character) - NumberFire ID
- `fantasypro_id` (character) - FantasyPros ID
- `fantasydata_id` (character) - FantasyData ID
- `fantasynerd_id` (character) - FantasyNerds ID
- `rts_id` (character) - RotoSports ID
- `fantasypro_num_id` (character) - FantasyPros numeric ID

#### 5.9. `players_sim` (data.frame: ~219 × 18)
**Descrição:** Jogadores ativos em rosters com arrays de simulação (1.000 iterações cada)

**Colunas Escalares:**
- `teamId` (integer) - ID do time
- `teamName` (character) - Nome do time
- `slotPosition` (character) - Posição do slot
- `rosterSlotId` (integer) - ID do slot (< 20 = titular, 20 = banco)
- `playerId` (integer) - ID NFL.com do jogador
- `isEditable` (logical) - Se pode ser editado
- `isReserveStatus` (logical) - Se está em reserve
- `id` (integer) - ID interno
- `byeWeek` (integer) - Bye week
- `isUndroppable` (logical) - Se não pode ser dropado
- `injuryGameStatus` (character) - Status de lesão
- `week` (integer) - Semana
- `weekPts` (numeric) - Pontos reais da semana
- `seasonPts` (logical/numeric) - Pontos da temporada

**Colunas Array (list - cada uma contendo vetores numéricos):**
- `pts.proj` (list<numeric[43]>) - Array de projeções das múltiplas fontes
- `weekPts.sim` (list<numeric[1000]>) - Array de pontos reais replicado 1.000 vezes
- `simulation.org` (list<numeric[1000]>) - Array de 1.000 simulações (distribuição original)
- `simulation` (list<numeric[1000]>) - Array de 1.000 simulações (final)
  - Se `isEditable=FALSE`: usa `weekPts.sim` (pontos reais já conhecidos)
  - Se `isEditable=TRUE`: usa `simulation.org` (distribuição de probabilidade)

**Lógica de Simulação:**
```
Para cada jogador:
  - Se jogo já aconteceu (isEditable=FALSE): usa pontos reais
  - Se jogo ainda vai acontecer (isEditable=TRUE): usa distribuição de probabilidade
```

#### 5.10. `teams_sim` (data.frame: 16 × 3)
**Descrição:** Resultados agregados da simulação por time

**Colunas:**
- `teamId` (integer) - ID do time
- `simulation` (list<numeric[1000]>) - Array de 1.000 pontos totais simulados do time
  - Cada valor é a soma dos pontos dos titulares (rosterSlotId < 20) naquela iteração
- `simulation.org` (list<numeric[1000]>) - Array de 1.000 pontos usando apenas projeções originais

**Cálculo:**
Para cada iteração (1-1000):
  - Soma os pontos de todos os titulares do time naquela iteração
  - Resultado: distribuição de 1.000 possíveis pontos totais do time

**Estatísticas Derivadas:**
- Média: Pontos projetados do time
- Mediana: Pontos mais prováveis
- Desvio padrão: Variabilidade/risco
- Min/Max: Range de possibilidades

#### 5.11. `matchup_sim` (data.frame: 8 × 22)
**Descrição:** Resultados da simulação por matchup, incluindo probabilidades de vitória

**Colunas Escalares:**
- `matchupId` (character) - ID do matchup
- `week` (integer) - Semana
- `awayTeam.teamId` (integer) - ID do time visitante
- `homeTeam.teamId` (integer) - ID do time mandante
- `homeTeam.winProb` (numeric) - Probabilidade de vitória do mandante (0-1)
- `awayTeam.winProb` (numeric) - Probabilidade de vitória do visitante (0-1)
- `homeTeam.winProb.org` (numeric) - Prob. de vitória (projeções originais)
- `awayTeam.winProb.org` (numeric) - Prob. de vitória (projeções originais)
- `homeTeam.totalPts` (numeric) - Pontos projetados do mandante (mediana)
- `awayTeam.totalPts` (numeric) - Pontos projetados do visitante (mediana)
- `homeTeam.totalPts.org` (numeric) - Pontos projetados (projeções originais)
- `awayTeam.totalPts.org` (numeric) - Pontos projetados (projeções originais)

**Colunas Array (list):**
- `awayTeam.simulation` (list<numeric[1000]>) - 1.000 pontos simulados do visitante
- `homeTeam.simulation` (list<numeric[1000]>) - 1.000 pontos simulados do mandante
- `awayTeam.simulation.org` (list<numeric[1000]>) - Simulação com projeções originais
- `homeTeam.simulation.org` (list<numeric[1000]>) - Simulação com projeções originais
- `homeTeam.win` (list<logical[1000]>) - Array de vitórias do mandante (TRUE/FALSE)
- `homeTeam.win.org` (list<logical[1000]>) - Vitórias com projeções originais
- `awayTeam.win` (list<logical[1000]>) - Array de vitórias do visitante
- `awayTeam.win.org` (list<logical[1000]>) - Vitórias com projeções originais
- `homeTeam.ptsdiff` (list<numeric[1000]>) - Diferença de pontos (mandante - visitante)
- `homeTeam.ptsdiff.org` (list<numeric[1000]>) - Diferença com projeções originais

**Cálculo das Probabilidades:**
```r
# Para cada iteração (1-1000):
homeTeam.win[i] = homeTeam.simulation[i] > awayTeam.simulation[i]

# Probabilidade de vitória:
homeTeam.winProb = mean(homeTeam.win)  # % de vezes que mandante venceu
awayTeam.winProb = mean(awayTeam.win)  # % de vezes que visitante venceu
```

**Diferença entre .org e sem sufixo:**
- **Sem sufixo:** Usa pontos reais para jogos já realizados + projeções para jogos futuros
- **Com .org:** Usa apenas projeções originais (ignora pontos reais, útil para análise contrafactual)

---

**Fases da Semana:**
- `preTNF` - Antes Thursday Night Football
- `posTNF` - Depois TNF (jogos de quinta atualizados com pontos reais)
- `preSundayGames` - Antes dos jogos de domingo
- `preSNF` - Antes Sunday Night Football
- `preMNF` - Antes Monday Night Football (maioria dos jogos já com pontos reais)
- `preWaivers` - Antes do processamento de waivers (após MNF)
- `posWaivers` - Depois dos waivers (rosters atualizados)
- `final` - Semana completa (todos os jogos finalizados)

**Cardinalidade:** ~5-7 arquivos por semana × 17 semanas = ~90 arquivos

**Tamanho Típico:** 100-500 KB por arquivo (dependendo da fase e dados nested)

---

### Exemplos Práticos de Uso

#### Exemplo 1: Analisar Probabilidade de Vitória
```r
# Carregar simulação
sim <- readRDS("data/simulation_v5_week17_final.rds")

# Ver probabilidades de todos os matchups
sim$matchup_sim %>%
  select(matchupId, homeTeam.teamId, awayTeam.teamId,
         homeTeam.winProb, awayTeam.winProb,
         homeTeam.totalPts, awayTeam.totalPts)

# Encontrar jogos mais próximos (toss-up)
close_games <- sim$matchup_sim %>%
  mutate(margin = abs(homeTeam.winProb - 0.5)) %>%
  filter(margin < 0.1) %>%  # Menos de 60-40
  arrange(margin)
```

#### Exemplo 2: Distribuição de Pontos de um Time
```r
# Pegar resultados de um time específico
team_5_sim <- sim$teams_sim %>%
  filter(teamId == 5) %>%
  pull(simulation) %>%
  .[[1]]

# Estatísticas descritivas
summary(team_5_sim)
quantile(team_5_sim, c(0.1, 0.25, 0.5, 0.75, 0.9))

# Visualizar distribuição
library(ggplot2)
data.frame(points = team_5_sim) %>%
  ggplot(aes(x = points)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  geom_vline(xintercept = median(team_5_sim),
             color = "red", linetype = "dashed", size = 1) +
  labs(title = "Distribuição de Pontos - Time 5",
       x = "Pontos", y = "Frequência")
```

#### Exemplo 3: Comparar Projeções vs Realidade
```r
# Comparar probabilidades antes vs depois dos jogos
matchup <- sim$matchup_sim[1, ]

cat("Antes dos jogos (apenas projeções):\n")
cat("  Home win prob:", matchup$homeTeam.winProb.org, "\n")
cat("  Pontos projetados: Home =", matchup$homeTeam.totalPts.org,
    "/ Away =", matchup$awayTeam.totalPts.org, "\n\n")

cat("Depois dos jogos (com resultados reais):\n")
cat("  Home win prob:", matchup$homeTeam.winProb, "\n")
cat("  Pontos projetados: Home =", matchup$homeTeam.totalPts,
    "/ Away =", matchup$awayTeam.totalPts, "\n\n")

# Mudança na probabilidade
prob_shift <- matchup$homeTeam.winProb - matchup$homeTeam.winProb.org
cat("Mudança na probabilidade:",
    sprintf("%+.1f%%", prob_shift * 100), "\n")
```

#### Exemplo 4: Identificar Jogadores Mais Impactantes
```r
# Jogadores com maior variância (risco/recompensa)
high_variance <- sim$players_sim %>%
  mutate(
    variance = map_dbl(simulation.org, var),
    mean_pts = map_dbl(simulation.org, mean)
  ) %>%
  filter(rosterSlotId < 20) %>%  # Apenas titulares
  arrange(desc(variance)) %>%
  select(teamName, playerId, slotPosition, mean_pts, variance) %>%
  head(10)

# Jogadores mais "seguros" (baixa variância)
low_variance <- sim$players_sim %>%
  mutate(
    variance = map_dbl(simulation.org, var),
    mean_pts = map_dbl(simulation.org, mean)
  ) %>%
  filter(rosterSlotId < 20, mean_pts > 10) %>%
  arrange(variance) %>%
  select(teamName, playerId, slotPosition, mean_pts, variance) %>%
  head(10)
```

#### Exemplo 5: Progressão Durante a Semana
```r
# Comparar probabilidades em diferentes fases
phases <- c("preTNF", "posTNF", "preSundayGames", "preMNF", "final")
matchup_id <- "w17_a5_h7"

results <- map_df(phases, function(phase) {
  file <- paste0("data/simulation_v5_week17_", phase, ".rds")
  if(!file.exists(file)) return(NULL)

  sim <- readRDS(file)
  sim$matchup_sim %>%
    filter(matchupId == matchup_id) %>%
    select(matchupId, homeTeam.winProb, awayTeam.winProb) %>%
    mutate(phase = phase)
})

# Visualizar mudança ao longo do tempo
results %>%
  ggplot(aes(x = factor(phase, levels = phases))) +
  geom_line(aes(y = homeTeam.winProb, group = 1),
            color = "blue", size = 1.5) +
  geom_line(aes(y = awayTeam.winProb, group = 1),
            color = "red", size = 1.5) +
  geom_point(aes(y = homeTeam.winProb), color = "blue", size = 3) +
  geom_point(aes(y = awayTeam.winProb), color = "red", size = 3) +
  labs(title = "Evolução das Probabilidades Durante a Semana",
       x = "Fase", y = "Probabilidade de Vitória") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
```

#### Exemplo 6: Análise de Risco por Posição
```r
# Análise de variabilidade por posição
position_variance <- sim$players_sim %>%
  filter(rosterSlotId < 20) %>%  # Apenas titulares
  mutate(
    mean_pts = map_dbl(simulation.org, mean),
    sd_pts = map_dbl(simulation.org, sd),
    cv = sd_pts / mean_pts  # Coeficiente de variação
  ) %>%
  left_join(sim$players_id %>% select(id, playerId=nfl_id)) %>%
  left_join(sim$players_stats %>% select(playerId, position)) %>%
  group_by(position) %>%
  summarize(
    n_players = n(),
    avg_points = mean(mean_pts, na.rm = TRUE),
    avg_sd = mean(sd_pts, na.rm = TRUE),
    avg_cv = mean(cv, na.rm = TRUE)
  ) %>%
  arrange(desc(avg_cv))

print(position_variance)
# Posições com maior CV = mais voláteis/arriscadas
```

---

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
- `week0_scrap.rds` contém os mesmos dados de temporada, mas no formato `week{X}` para compatibilidade com pipelines semanais

**Uso:** Análise de temporada completa, treinamento de modelos, projeções pré-temporada

---

### 10. **RANKING** (Rankings e Posições)

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

| Categoria | Arquivos | Tamanho Aproximado |
|-----------|----------|-------------------|
| Weekly Scrapes | 17 × 2 = 34 | ~50 MB |
| Weekly Projections | 17 × 4 = 68 | ~80 MB |
| Simulations | ~90 | ~45 MB |
| Rankings | 17 × 2 = 34 | ~2 MB |
| Core Files | 5 | ~15 MB |
| Draft Files | 5 | ~2 MB |
| Season Aggregates | 8 | ~8 MB |
| **TOTAL (2025)** | **~245** | **~200 MB** |

### Granularidade Temporal

| Tipo de Dado | Frequência | Quantidade |
|--------------|------------|------------|
| Player Stats | Real-time (durante jogos) | 1 arquivo central |
| Projections | Semanal | 17 semanas |
| Simulations | 5-7 por semana | ~100 arquivos |
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
