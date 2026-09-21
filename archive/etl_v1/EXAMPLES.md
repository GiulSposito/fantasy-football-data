# 📘 Exemplos de Uso - Dados Transformados

Exemplos práticos de como usar os databases gerados pelo pipeline ETL.

## 🎯 Setup Inicial

```r
library(tidyverse)
library(dm)

# Carregar databases
ffa_db <- readRDS("app/2025-24/ffa_db.rds")
nfl_stats_db <- readRDS("app/2025-24/nfl_stats_db.rds")
nfl_players_db <- readRDS("app/2025-24/nfl_players_db.rds")
dudes_simulation_db <- readRDS("app/2025-24/dudes_simulation_db.rds")
```

---

## 📊 Exemplos de Análises

### 1. Top 10 Jogadores por Pontos (Semana 3)

```r
# Buscar pontos da semana
top_players <- nfl_stats_db$nfl_players_points %>%
  filter(season == 2025, week == 3) %>%
  arrange(desc(pts)) %>%
  head(10)

# Adicionar nomes dos jogadores
top_players_named <- top_players %>%
  left_join(
    nfl_players_db$nfl_players %>% select(playerId, name, position),
    by = "playerId"
  )

print(top_players_named)
```

**Output esperado:**
```
   playerId  season week   pts name              position
1  2552374    2025    3  28.5 Patrick Mahomes   QB
2  4241389    2025    3  26.8 Christian McCaffrey RB
...
```

---

### 2. Comparar Projeções vs Performance Real

```r
# Projeções da semana 3 (tipo weighted)
projections <- ffa_db$ffa_projtable %>%
  filter(
    season == 2025,
    week == 3,
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  select(id, pos, proj = points, rank)

# Performance real
actual <- nfl_stats_db$nfl_players_points %>%
  filter(season == 2025, week == 3) %>%
  select(playerId, pts)

# ID mapping
id_map <- ffa_db$ffa_player_ids %>%
  transmute(id, playerId = as.integer(nfl_id))

# Juntar tudo
comparison <- projections %>%
  inner_join(id_map, by = "id") %>%
  inner_join(actual, by = "playerId") %>%
  mutate(
    diff = pts - proj,
    pct_error = (diff / proj) * 100
  ) %>%
  arrange(desc(abs(diff)))

# Top 10 maiores erros
print(head(comparison, 10))
```

---

### 3. Acurácia por Fonte de Projeção

```r
# Comparar todas as fontes
source_accuracy <- ffa_db$ffa_proj_source_points %>%
  filter(season == 2025, week == 3, timestamp == max(timestamp)) %>%
  select(id, data_src, proj = points) %>%
  inner_join(
    ffa_db$ffa_player_ids %>%
      transmute(id, playerId = as.integer(nfl_id)),
    by = "id"
  ) %>%
  inner_join(
    nfl_stats_db$nfl_players_points %>%
      filter(season == 2025, week == 3),
    by = "playerId"
  ) %>%
  mutate(error = pts - proj) %>%
  group_by(data_src) %>%
  summarise(
    n = n(),
    mae = mean(abs(error), na.rm = TRUE),
    rmse = sqrt(mean(error^2, na.rm = TRUE)),
    bias = mean(error, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(mae)

print(source_accuracy)
```

**Output esperado:**
```
   data_src       n   mae  rmse   bias
1  FantasyPros  450  4.2   5.8   0.3
2  ESPN         448  4.5   6.1  -0.2
3  CBS          445  4.7   6.3   0.5
...
```

---

### 4. Análise de Simulações - Ranges de Projeção

```r
# Pegar simulações da semana 3
sims <- dudes_simulation_db$dudes_players_simulations %>%
  filter(season == 2025, week == 3, simType == "proj_src_w_errors")

# Extrair quantis
sim_ranges <- sims %>%
  mutate(
    q05 = map_dbl(simQuantiles, ~.x["5%"]),
    q50 = map_dbl(simQuantiles, ~.x["50%"]),
    q95 = map_dbl(simQuantiles, ~.x["95%"]),
    range = q95 - q05
  ) %>%
  select(id, playerId, pos, q05, q50, q95, range) %>%
  arrange(desc(range))

# Jogadores com maior variância
print(head(sim_ranges, 10))
```

---

### 5. Melhores Escalações da Semana

```r
# Calcular melhor escalação possível para cada time

# 1. Carregar rosters
nfl_round_db <- readRDS("app/2025-24/nfl_round_db.rds")

rosters <- nfl_round_db$nfl_teams_rosters %>%
  filter(
    season == 2025,
    week == 3,
    timestamp == max(timestamp)
  )

# 2. Juntar com pontos reais
roster_points <- rosters %>%
  left_join(
    nfl_stats_db$nfl_players_points %>%
      filter(season == 2025, week == 3),
    by = "playerId"
  ) %>%
  left_join(
    nfl_players_db$nfl_players %>%
      select(playerId, name, position),
    by = "playerId"
  ) %>%
  mutate(pts = replace_na(pts, 0))

# 3. Calcular melhor escalação vs real
optimal_lineups <- roster_points %>%
  group_by(teamId) %>%
  summarise(
    # Pontos reais (starters apenas)
    actual_pts = sum(pts[rosterSlotId < 20]),

    # Melhor escalação possível
    best_qb = max(pts[position == "QB"]),
    best_rb1 = max(pts[position == "RB"]),
    best_rb2 = sort(pts[position == "RB"], decreasing = TRUE)[2],
    best_wr1 = max(pts[position == "WR"]),
    best_wr2 = sort(pts[position == "WR"], decreasing = TRUE)[2],
    best_te = max(pts[position == "TE"]),
    best_k = max(pts[position == "K"]),
    best_def = max(pts[position == "DEF"]),

    optimal_pts = best_qb + best_rb1 + best_rb2 +
                  best_wr1 + best_wr2 + best_te +
                  best_k + best_def,

    .groups = "drop"
  ) %>%
  mutate(
    pts_left = optimal_pts - actual_pts,
    efficiency = actual_pts / optimal_pts * 100
  ) %>%
  arrange(desc(pts_left))

print(optimal_lineups)
```

---

### 6. Análise de Projeções por Posição

```r
# Distribuição de projeções por posição
position_stats <- ffa_db$ffa_projtable %>%
  filter(
    season == 2025,
    week == 3,
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  group_by(pos) %>%
  summarise(
    n_players = n(),
    avg_points = mean(points, na.rm = TRUE),
    sd_points = sd(points, na.rm = TRUE),
    min_points = min(points, na.rm = TRUE),
    max_points = max(points, na.rm = TRUE),
    top10_avg = mean(head(sort(points, decreasing = TRUE), 10)),
    .groups = "drop"
  ) %>%
  arrange(desc(avg_points))

print(position_stats)
```

---

### 7. Histórico de um Jogador

```r
# Ver performance de Patrick Mahomes ao longo da temporada
mahomes_id <- 2552374

mahomes_history <- nfl_stats_db$nfl_players_points %>%
  filter(playerId == mahomes_id, season == 2025) %>%
  arrange(week) %>%
  select(week, pts)

# Adicionar projeções
mahomes_proj <- ffa_db$ffa_projtable %>%
  filter(
    season == 2025,
    avg_type == "weighted",
    timestamp == max(timestamp),
    id %in% (ffa_db$ffa_player_ids %>%
              filter(as.integer(nfl_id) == mahomes_id) %>%
              pull(id))
  ) %>%
  select(week, proj = points)

# Combinar
mahomes_comparison <- mahomes_history %>%
  left_join(mahomes_proj, by = "week") %>%
  mutate(
    diff = pts - proj,
    beat_projection = pts > proj
  )

print(mahomes_comparison)

# Sumário
mahomes_comparison %>%
  summarise(
    total_pts = sum(pts, na.rm = TRUE),
    avg_pts = mean(pts, na.rm = TRUE),
    weeks_beat_proj = sum(beat_projection, na.rm = TRUE),
    pct_beat_proj = mean(beat_projection, na.rm = TRUE) * 100
  )
```

---

### 8. Melhores Waiver Wire Pickups

```r
# Free agents com melhor performance
# (assumindo que rosters indicam quem está em time)

# 1. Jogadores em rosters
rostered_players <- nfl_round_db$nfl_teams_rosters %>%
  filter(season == 2025, week == 3) %>%
  distinct(playerId) %>%
  pull(playerId)

# 2. Top performers que NÃO estão em rosters
free_agent_stars <- nfl_stats_db$nfl_players_points %>%
  filter(season == 2025, week == 3) %>%
  filter(!(playerId %in% rostered_players)) %>%
  left_join(
    nfl_players_db$nfl_players %>%
      select(playerId, name, position, nflTeamAbbr),
    by = "playerId"
  ) %>%
  arrange(desc(pts)) %>%
  head(20)

print(free_agent_stars)
```

---

### 9. Análise de Consistency (Desvio Padrão)

```r
# Jogadores mais consistentes ao longo da temporada
player_consistency <- nfl_stats_db$nfl_players_points %>%
  filter(season == 2025) %>%
  group_by(playerId) %>%
  summarise(
    games = n(),
    avg_pts = mean(pts, na.rm = TRUE),
    sd_pts = sd(pts, na.rm = TRUE),
    min_pts = min(pts, na.rm = TRUE),
    max_pts = max(pts, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(games >= 3) %>%  # Mínimo 3 jogos
  mutate(
    consistency = avg_pts / sd_pts  # Quanto maior, mais consistente
  ) %>%
  left_join(
    nfl_players_db$nfl_players %>%
      select(playerId, name, position),
    by = "playerId"
  ) %>%
  arrange(desc(consistency)) %>%
  head(20)

print(player_consistency)
```

---

### 10. Comparar Tiers de Projeção

```r
# Análise de tiers para RBs na semana 3
rb_tiers <- ffa_db$ffa_projtable %>%
  filter(
    season == 2025,
    week == 3,
    pos == "RB",
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  select(id, points, floor, ceiling, rank, tier, sd_pts) %>%
  arrange(rank)

# Sumário por tier
tier_summary <- rb_tiers %>%
  group_by(tier) %>%
  summarise(
    n_players = n(),
    avg_points = mean(points),
    avg_floor = mean(floor),
    avg_ceiling = mean(ceiling),
    avg_uncertainty = mean(sd_pts),
    .groups = "drop"
  )

print(tier_summary)
```

---

## 🔍 Análises Avançadas

### Join Múltiplos Databases

```r
# Análise completa: projeções + performance + simulações
complete_analysis <- ffa_db$ffa_projtable %>%
  filter(
    season == 2025,
    week == 3,
    avg_type == "weighted",
    timestamp == max(timestamp)
  ) %>%
  # ID mapping
  inner_join(
    ffa_db$ffa_player_ids %>%
      transmute(id, playerId = as.integer(nfl_id)),
    by = "id"
  ) %>%
  # Player info
  left_join(
    nfl_players_db$nfl_players %>%
      select(playerId, name, nflTeamAbbr),
    by = "playerId"
  ) %>%
  # Actual points
  left_join(
    nfl_stats_db$nfl_players_points %>%
      filter(season == 2025, week == 3),
    by = "playerId"
  ) %>%
  # Simulation ranges
  left_join(
    dudes_simulation_db$dudes_players_simulations %>%
      filter(season == 2025, week == 3, simType == "proj_src_w_errors") %>%
      mutate(
        sim_q50 = map_dbl(simQuantiles, ~.x["50%"]),
        sim_q05 = map_dbl(simQuantiles, ~.x["5%"]),
        sim_q95 = map_dbl(simQuantiles, ~.x["95%"])
      ) %>%
      select(id, sim_q05, sim_q50, sim_q95),
    by = "id"
  ) %>%
  # Calculate metrics
  mutate(
    proj_error = pts - points,
    within_range = pts >= sim_q05 & pts <= sim_q95
  )

# Análise de cobertura das simulações
complete_analysis %>%
  summarise(
    coverage = mean(within_range, na.rm = TRUE) * 100,
    avg_error = mean(abs(proj_error), na.rm = TRUE)
  )
```

---

## 📈 Visualizações

### Gráfico: Projeções vs Real

```r
library(ggplot2)

# Preparar dados
plot_data <- comparison %>%
  head(50)  # Top 50 jogadores

# Plot
ggplot(plot_data, aes(x = proj, y = pts)) +
  geom_point(aes(color = pos), size = 3, alpha = 0.7) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  geom_smooth(method = "lm", se = FALSE, color = "blue") +
  labs(
    title = "Projeções vs Performance Real - Semana 3",
    x = "Pontos Projetados",
    y = "Pontos Reais",
    color = "Posição"
  ) +
  theme_minimal()
```

---

## 🎓 Dicas de Performance

### 1. Filtrar Cedo
```r
# ❌ Ruim - carrega tudo depois filtra
all_data <- ffa_db$ffa_projtable
filtered <- all_data %>% filter(week == 3)

# ✅ Bom - filtra logo
filtered <- ffa_db$ffa_projtable %>% filter(week == 3)
```

### 2. Usar dm_flatten para Joins Automáticos
```r
# Ao invés de joins manuais, use dm_flatten
result <- ffa_db %>%
  dm_flatten_to_tbl(ffa_projtable) %>%
  filter(week == 3)
# Automaticamente inclui dados de tabelas relacionadas!
```

### 3. Cachear Resultados Intermediários
```r
# Ler database uma vez
ffa_db <- readRDS("app/2025-24/ffa_db.rds")

# Extrair tabela usada múltiplas vezes
projtable <- ffa_db$ffa_projtable

# Usar tabela extraída
result1 <- projtable %>% filter(week == 1)
result2 <- projtable %>% filter(week == 2)
```

---

**Mais exemplos?** Ver documentação completa em `app_DATAMODEL.md`
