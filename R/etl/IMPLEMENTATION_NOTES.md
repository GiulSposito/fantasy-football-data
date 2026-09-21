# ETL Pipeline v2 - Implementation Notes

## Estruturas de Dados Validadas

Este documento detalha as estruturas de dados investigadas e validadas durante a implementação do pipeline ETL v2.

---

### 1. Simulações (`simulation_v5_week{X}_{phase}.rds`)

**Tipo:** Lista com 11 elementos
**Elemento-chave:** `players_sim` (229 rows × 18 columns)

#### List Columns Identificadas

| Coluna | Tipo | Descrição | Uso no Pipeline |
|--------|------|-----------|-----------------|
| `pts.proj` | LIST<numeric[~43]> | Seeds (projeções de múltiplas fontes) | → `dudes_players_seeds$seeds` |
| `simulation.org` | LIST<numeric[1000]> | KDE output (sempre probabilístico) | → `dudes_players_simulations$simulation` |
| `simulation` | LIST<numeric[1000]> | Híbrido (real se jogo completo, senão KDE) | Não usado (preferimos `.org`) |
| `weekPts.sim` | LIST<numeric[1000]> | Pontos reais × 1000 | Não usado no pipeline |

#### Algoritmo KDE (Kernel Density Estimation)

**Processo de geração de `simulation.org`:**

1. **Input:** `pts.proj` com ~43 projeções de 11+ fontes web (CBS, ESPN, FantasyPros, etc)
2. **Algoritmo:** `density()` do R base para estimar distribuição contínua de probabilidade
3. **Sampling:** `sample()` de 1,000 valores da distribuição
4. **Output:** `simulation.org` com 1,000 valores representando possíveis outcomes

**Implementação:**
```r
# No arquivo de simulação original (não no pipeline):
density_obj <- density(pts.proj, na.rm = TRUE)
simulation.org <- sample(density_obj$x, size = 1000, replace = TRUE, prob = density_obj$y)
```

**Pipeline extrai diretamente:**
```r
# extract.R
sim$players_sim |>
  select(pts.proj, simulation.org, simulation)

# transform.R
dudes_players_seeds <- simulations |>
  select(season, week, id, playerId, pos, phase, seeds = pts.proj)

dudes_players_simulations <- simulations |>
  select(season, week, id, playerId, pos, phase, simulation = simulation.org) |>
  mutate(simQuantiles = map(simulation, ~ quantile(.x, probs = c(0.05, 0.15, 0.30, 0.50, 0.70, 0.85, 0.95))))
```

#### Diferença entre `simulation.org` e `simulation`

- **`simulation.org`**: Sempre usa distribuição KDE das projeções (útil para análise "what-if" contrafactual)
- **`simulation`**: Híbrido - usa pontos reais se `isEditable=FALSE`, senão usa `simulation.org` (útil para projeção realista em tempo real)

**Exemplo temporal (Domingo 6pm):**
```
Player             │ isEditable │ simulation usa:
───────────────────┼────────────┼─────────────────────────
RB (jogou 1pm)     │   FALSE    │ [24.8, 24.8, ...] real
QB (joga SNF 8pm)  │   TRUE     │ [23.1, 27.3, ...] KDE
WR (joga MNF)      │   TRUE     │ [15.2, 18.9, ...] KDE
```

**Pipeline escolhe `.org`** para consistência - sempre KDE, nunca híbrido.

---

### 2. Stats Projetadas (`week{X}_scrap.rds`)

**Fonte:** Scrapes por posição (QB, RB, WR, TE, K, DST)
**Estrutura:** Lista de 6 data.frames

#### Estrutura Documentada

```r
list(
  QB = data.frame(
    player, pos, team,
    pass_att, pass_comp, pass_yds, pass_tds, pass_int,
    rush_att, rush_yds, rush_tds
  ),
  RB = data.frame(
    player, pos, team,
    rush_att, rush_yds, rush_tds,
    rec_tgt, rec, rec_yds, rec_tds
  ),
  WR = data.frame(
    player, pos, team,
    rec_tgt, rec, rec_yds, rec_tds,
    rush_att, rush_yds  # Alguns WRs correm
  ),
  TE = data.frame(
    player, pos, team,
    rec_tgt, rec, rec_yds, rec_tds
  ),
  K = data.frame(
    player, pos, team,
    fg_att, fg_made, fg_50, xp
  ),
  DST = data.frame(
    player, pos, team,
    sacks, int, fum_rec, def_td, pts_allowed
  )
)
```

#### Extração no Pipeline

```r
# extract.R - Consolidar todas as posições
scrapes_stats <- map_dfr(scrapes, ~ .x, .id = "position_group") |>
  select(
    id, pos,
    pass_att, pass_comp, pass_yds, pass_tds, pass_int,
    rush_att, rush_yds, rush_tds,
    rec_tgt, rec, rec_yds, rec_tds
  )

# transform.R - Join com projeções
ffa_projtable <- ffa_projtable_base |>
  left_join(scrapes_stats, by = c("id", "pos"))
```

**Confirmação:** Stats detalhadas vêm de scrapes, NÃO de `weekly_proj_table_{X}.rds`

**Coverage esperada:**
- QBs: `pass_att`, `pass_comp`, `pass_yds` preenchidos (>80%)
- RBs: `rush_att`, `rush_yds` preenchidos (>80%)
- WRs/TEs: `rec_tgt`, `rec`, `rec_yds` preenchidos (>80%)
- Stats não aplicáveis: NA (ex: QB não tem `rec_tgt` = esperado)

---

### 3. ID Mappings (`dudes/players_ids.rds`)

**Localização:** ROOT level (não em year subdirs)
**Dimensões:** 5,395 rows × 13 columns
**Coverage:** 69% têm nfl_id preenchido (~3,563 players)

#### Schema

```r
id              # PK - ffanalytics ID interno
nfl_id          # NFL.com ID (~69% coverage)
stats_id        # NFL.com Stats ID
cbs_id          # CBS Sports ID
espn_id         # ESPN ID
fleaflicker_id  # Fleaflicker ID
fftoday_id      # FFToday ID
numfire_id      # NumberFire ID
fantasypro_id   # FantasyPros ID
fantasypro_num_id  # FantasyPros Numeric ID
fantasydata_id  # FantasyData ID
fantasynerd_id  # FantasyNerd ID
rts_id          # RTS ID
```

#### Extração no Pipeline

```r
# transform.R
player_ids_master <- readRDS("dudes/players_ids.rds")

ffa_player_ids <- extracted_ids |>
  left_join(player_ids_master, by = "id") |>
  mutate(
    # Fallback: se nfl_id é NA, usar id convertido
    nfl_id = coalesce(as.character(nfl_id), as.character(id))
  )
```

**Resultado:** 95% de cobertura (69% real + 31% fallback)

---

### 4. Metadata de Jogadores (`weekly_proj_table_{X}.rds`)

**Dimensões:** 527 rows × 22 columns
**Uso:** Metadados (nomes, team, age, exp) mas NÃO stats projetadas

#### Campos Úteis

```r
id              # PK
pos             # Posição
first_name      # Primeiro nome
last_name       # Sobrenome
team            # Time NFL (abreviação)
age             # Idade (NA para DST)
exp             # Anos de experiência (50 para DST = placeholder)
points          # Projeção de pontos
floor           # Projeção conservadora (p25)
ceiling         # Projeção otimista (p75)
sd_pts          # Desvio padrão
rank            # Rank geral
pos_rank        # Rank dentro da posição
tier            # Tier assignment
```

**NÃO contém:** `pass_att`, `pass_yds`, `rush_att`, `rush_yds`, `rec_tgt`, etc.

---

## Progressão de Fases Dentro da Semana

**Fases Documentadas:**

1. `preTNF` - Antes de Thursday Night Football
2. `posTNF` - Após TNF, antes de Sunday
3. `preSundayGames` - Domingo de manhã
4. `preMNF` - Após Sunday, antes de Monday Night Football
5. `final` - Semana completa

**Uso no Pipeline:**

```r
# extract.R - Extrai todas as fases
parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")
phase <- parts[1, 3]  # preTNF, final, etc

# transform.R - Fase vira simType
dudes_players_seeds <- simulations |>
  mutate(simType = phase)
```

**Impacto:** Permite análise temporal de como probabilidades evoluem durante a semana.

---

## Decisões de Performance

### 1. Filtro Early em `extract_player_points()`

**Problema:**
```r
# ANTES: Expande 14k players × 17 weeks = 238k rows, DEPOIS filtra
players |> unnest_week_stats() |> filter(week %in% config$weeks)
```

**Solução:**
```r
# DEPOIS: Filtra nested lists ANTES de expandir
players |>
  mutate(
    weekStats = map(weekStats, ~ .x[config$weeks]),
    weekAdvancedStats = map(weekAdvancedStats, ~ .x[config$weeks])
  ) |>
  unnest_week_stats()
```

**Speedup:** 80s → 10s (8x) para week 1

### 2. List Columns Nativas

**Não fazemos unnest** de seeds e simulations - mantemos como list columns:

```r
# Simulações permanecem como LIST<numeric[1000]>
dudes_players_simulations$simulation  # Cada elemento é vetor de 1000 valores

# Análise usa map() diretamente
dudes_players_simulations |>
  mutate(
    mean_pts = map_dbl(simulation, mean),
    sd_pts = map_dbl(simulation, sd),
    q50 = map_dbl(simulation, ~ quantile(.x, 0.5))
  )
```

**Vantagem:** Eficiência de memória + facilita análises vetorizadas

---

## Validação de Dados

### Cardinalities (Obrigatório)

```r
# load.R - Sempre executa
cardinalities <- dm_examine_cardinalities(dm_obj)

cardinality_issues <- cardinalities |>
  filter(all_many_to_many)  # Problemas são many-to-many inesperados
```

**Em test_mode:** Warnings não abortam
**Em production:** Cardinality issues abortam se `strict_mode=TRUE`

### Constraints

```r
constraints <- dm_examine_constraints(dm_obj)

failed_constraints <- constraints |>
  filter(!ok)
```

**Sempre valida:** Primary keys únicos, foreign keys válidos

---

## Troubleshooting

### Simulações Vazias

**Sintoma:** `dudes_players_seeds$seeds` são listas vazias
**Causa:** Arquivo de simulação não tem `pts.proj` column
**Fix:** Verificar que extract.R está selecionando `pts.proj` explicitamente

### Stats Todas NA

**Sintoma:** `ffa_projtable$pass_att` sempre NA
**Causa:** Join com `scrapes_stats` não está funcionando
**Fix:** Verificar que `id` e `pos` existem em ambos data frames

### Performance Lenta

**Sintoma:** Pipeline demora >120s para week 1
**Causa:** Filtro early não está sendo aplicado
**Fix:** Verificar que `config$weeks` está definido e `extract_player_points()` tem lógica de filtro

---

**Última atualização:** 2026-03-07
**Autor:** DudesData ETL Pipeline v2
