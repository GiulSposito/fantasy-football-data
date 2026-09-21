# Dudes Football Analytics App

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![tidyverse](https://img.shields.io/badge/tidyverse-2.0-blue)](https://www.tidyverse.org/)
[![dm](https://img.shields.io/badge/dm-data_modeling-green)](https://cynkra.github.io/dm/)

> **Sistema avançado de análise e otimização para Fantasy Football da NFL**, com simulações Monte Carlo, machine learning e otimização matemática de escalações.

---

## 📋 Sumário

- [Sobre o Projeto](#-sobre-o-projeto)
- [Funcionalidades Principais](#-funcionalidades-principais)
- [Arquitetura](#️-arquitetura)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pipeline de Dados](#-pipeline-de-dados)
- [Sistema de Simulação](#-sistema-de-simulação)
- [Otimização de Times](#-otimização-de-times)
- [Instalação](#-instalação)
- [Configuração](#️-configuração)
- [Uso Básico](#-uso-básico)
- [Modelos de Dados](#-modelos-de-dados)
- [Análises Disponíveis](#-análises-disponíveis)
- [Workflow Semanal](#-workflow-semanal)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)

---

## 🎯 Sobre o Projeto

O **Dudes Football Analytics App** é uma plataforma completa desenvolvida em R para análise avançada e otimização de decisões em Fantasy Football da NFL. O sistema combina:

- **Agregação Inteligente de Dados**: Coleta de 11+ fontes de projeções especializadas
- **Simulações Estatísticas**: 15 estratégias diferentes de Monte Carlo
- **Otimização Matemática**: Seleção automática da melhor escalação
- **Machine Learning**: Modelos preditivos usando `tidymodels`
- **Análise Histórica**: Comparação de performance vs. potencial

### 🎯 Objetivo Principal

Fornecer **vantagem competitiva baseada em dados** através de:
- Análise de múltiplas fontes de projeções
- Simulações probabilísticas de cenários de jogo
- Otimização de escalações considerando upside e consistência
- Análise de erros históricos de projeções
- Predição de performance usando ML

### 📊 Estatísticas do Projeto

- **~3.500 linhas de código** em R
- **7 databases relacionais** (dm package)
- **15 estratégias de simulação** diferentes
- **11+ fontes de dados** de projeções
- **1000 simulações** por jogador por semana

---

## ✨ Funcionalidades Principais

### 🔄 Pipeline Automatizado de Dados

✅ Coleta semanal automática de projeções
✅ Integração com API oficial da NFL Fantasy
✅ Atualização de estatísticas, rosters e matchups
✅ Sistema de cache para reprocessamento e auditoria
✅ Versionamento por tags (`preview` e `final`)

**Fontes de Projeções:**
- CBS Sports
- ESPN
- FantasyPros
- FantasySharks
- FFToday
- FleaFlicker
- NumberFire
- FantasyFootballNerd
- NFL (oficial)
- RTSports
- Walterfootball

### 📊 Motor de Simulação Avançado

O sistema implementa **15 estratégias diferentes** de simulação:

#### 📌 Projeções Simples (valor único)
1. **NFL**: Projeção oficial da NFL
2. **proj_table_average**: Média simples de todas as fontes
3. **proj_table_robust**: Média robusta (resistente a outliers)
4. **proj_table_weighted**: Média ponderada por acurácia histórica

#### 🎲 Monte Carlo (múltiplos valores)
5. **proj_src**: Todas as projeções das fontes disponíveis
6. **proj_src_errors**: Projeções com erros históricos aplicados
7. **proj_src_w_errors**: Combinação de projeções originais + com erros
8. **hist_data**: Dados históricos completos do jogador
9. **current_season_his**: Performance apenas da temporada atual
10. **proj_src_w_errors_balanced**: Balanceamento de representatividade entre fontes

#### 📈 Sampling por Densidade (distribuição completa)
11. **proj_src_density**: Sampling da densidade das projeções
12. **proj_src_errors_density**: Sampling da densidade com erros
13. **proj_src_w_errors_density**: Sampling da densidade combinada
14. **hist_data_density**: Sampling da densidade de dados históricos
15. **current_season_his_density**: Sampling da densidade da temporada atual

**Outputs de Simulação:**
- 1000+ cenários por jogador
- Quantis de distribuição: 5%, 15%, 30%, 50%, 70%, 85%, 95%
- Análise de upside (potencial de alta performance)
- Análise de floor (pior cenário esperado)

### 🎯 Otimizador de Escalação

- ✅ Seleção automática dos melhores jogadores por posição
- ✅ Consideração de slots fixos (QB, RB, WR, TE, K, DEF)
- ✅ Otimização de slot FLEX (WR/RB)
- ✅ Análise de performance realizada vs. potencial máximo
- ✅ Comparação de cenários alternativos
- ✅ Simulação de 1000 cenários para cada combinação de jogadores

**Métricas Calculadas:**
- `totalPts`: Pontuação real obtida pelos starters
- `potencialPts`: Pontuação máxima possível com o roster
- `Eficiência`: % do potencial alcançado

### 🤖 Machine Learning

- 📊 Modelos preditivos usando `tidymodels`
- 🔧 Feature engineering com variáveis históricas
- 📈 Análise de importância de variáveis
- ✅ Cross-validation e métricas de performance
- 🎯 Predição de pontuação baseada em múltiplos fatores

### 📈 Análises e Insights

- 🏆 **Weekly Trophies**: Melhores performances da semana
- 📊 **Distribution Analysis**: Análise de distribuição de pontos
- 🔍 **Rank Analysis**: Comparação de rankings e consensos
- 🏥 **Injury Impact**: Status de lesões e impacto no desempenho
- 📉 **Projection Errors**: Análise de acurácia de projeções
- 🎲 **Simulation Analysis**: Comparação de estratégias de simulação

---

## 🏗️ Arquitetura

O sistema segue uma **arquitetura em camadas** com separação clara de responsabilidades:

```
┌─────────────────────────────────────────────────────────────┐
│                   CAMADA DE ANÁLISE                         │
│  - Weekly Trophies                                          │
│  - ML Predictions                                           │
│  - Team Optimization                                        │
│  - Distribution Analysis                                    │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│              CAMADA DE TRANSFORMAÇÃO                        │
│  - 15 Simulation Strategies                                 │
│  - Error Calculation & Application                          │
│  - Density Sampling                                         │
│  - Historical Data Processing                               │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                  PIPELINE DE DADOS (ETL)                    │
│  - Data Collection                                          │
│  - Data Aggregation                                         │
│  - Storage as DM (relational models)                        │
│  - Cache Management                                         │
└─────────────────────────────────────────────────────────────┘
                              ▲
┌─────────────────────────────────────────────────────────────┐
│                    CAMADA DE API                            │
│  - NFL Fantasy API                                          │
│  - FFAnalytics Scraping                                     │
│  - 11+ Data Sources                                         │
└─────────────────────────────────────────────────────────────┘
```

### 🎯 Princípios de Design

1. **Modularidade**: Cada camada é independente e reutilizável
2. **Data Models (DM)**: Uso extensivo do pacote `dm` para relacionamentos entre tabelas
3. **Reproducibilidade**: Sistema de cache com timestamps para auditoria
4. **Versionamento**: Suporte a tags (`preview`, `final`) para diferentes momentos da semana
5. **Type Safety**: Validação de integridade referencial entre tabelas

---

## 📁 Estrutura do Projeto

```
DudesApp_claude/
│
├── R/                                  # Código-fonte principal (~3.500 linhas)
│   │
│   ├── api/                            # Integrações com APIs externas
│   │   ├── nfl_api.R                  # Core da API da NFL (httr + jsonlite)
│   │   ├── nfl_league.R               # Endpoints de liga (teams, matchups, standings)
│   │   ├── nfl_players.R              # Endpoints de jogadores
│   │   ├── nfl_game.R                 # Endpoints de estatísticas de jogos
│   │   └── ffa_projection.R           # Web scraping com FFAnalytics
│   │
│   ├── transformation/                 # Transformação e processamento
│   │   ├── simulation.R               # Cálculo de erros e aplicação em projeções
│   │   └── missing_player_ids.R       # Mapeamento de IDs entre sistemas
│   │
│   ├── pipeline/                       # Pipelines de ETL
│   │   ├── data_pipeline.R            # ⭐ Pipeline principal (MASTER)
│   │   ├── data_pipeline_old.R        # Versão legacy
│   │   └── data_pipeline_*_playground.R  # Ambientes de teste
│   │
│   ├── analysis/                       # Análises avançadas
│   │   ├── team_optimizer.R           # Otimização de escalação de times
│   │   └── projection_ml.R            # Modelos de Machine Learning
│   │
│   └── snippets/                       # Scripts de análise ad-hoc
│       ├── simulation_machine.R       # ⭐ Gerador de 15 estratégias de simulação
│       ├── weekly_trophies.R          # Análise de melhores performances
│       ├── distribution_analysis.R    # Análise de distribuições de pontos
│       ├── player_simulation_analysis.R  # Análise de resultados de simulação
│       ├── team_sim.R                 # Simulação de matchups
│       ├── analysis_tier_rank_ecr.R   # Análise de rankings e tiers
│       └── analysis_injuryGameStatus.R   # Impacto de lesões
│
├── data/                               # Banco de dados (arquivos RDS) - 34MB total
│   ├── ffa_db.rds                     # 7.4MB - Projeções do FFAnalytics
│   ├── nfl_players_db.rds             # 164KB - Informações de jogadores
│   ├── nfl_teams_db.rds               # 1.4KB - Times e owners da liga
│   ├── nfl_stats_db.rds               # 453KB - Estatísticas por semana
│   ├── nfl_round_db.rds               # 39KB - Matchups e rosters
│   ├── nfl_recap_db.rds               # 934KB - Recaps semanais
│   ├── dudes_simulation_db.rds        # 25MB - Resultados de simulações
│   ├── 2023/                          # Dados históricos
│   └── temp/                          # Cache de respostas API
│
├── config/                             # Configurações
│   ├── config.yml                     # Auth token, league ID
│   ├── score_settings.yml             # Regras de pontuação da liga
│   └── leagues.json                   # Informações de ligas disponíveis
│
├── export/                             # Outputs e relatórios
│
├── .claude/                            # Claude Code Skills
│   └── skills/                        # 9 R skills instalados
│       ├── r-oop/                     # Programação orientada a objetos
│       ├── r-bayes/                   # Inferência Bayesiana
│       ├── tidyverse-patterns/        # Padrões tidyverse
│       ├── rlang-patterns/            # Metaprogramação
│       ├── r-style-guide/             # Guia de estilo
│       ├── r-performance/             # Otimização
│       ├── r-package-development/     # Desenvolvimento de pacotes
│       ├── dm-relational/             # Modelagem relacional
│       └── tdd-workflow/              # Test-driven development
│
├── _bmad/                              # BMAD workflows e agents
│
└── DudesApp.Rproj                     # Projeto RStudio

```

---

## 🔄 Pipeline de Dados

O pipeline principal (`R/pipeline/data_pipeline.R`) executa **6 etapas sequenciais**:

### Parâmetros Master

```r
# MASTER PARAMETERS
.season <- 2025L      # Temporada atual
.week <- 17L          # Semana atual
.tag <- "final"       # "preview" ou "final"
```

### 1️⃣ Coleta de Projeções (FFAnalytics)

**Função**: `getFFAScrapeData()` → `getFFAProjections()`

```r
# Scraping de 11+ fontes de projeções
Sources: CBS, ESPN, FantasyPros, FantasySharks, FFToday,
         FleaFlicker, NumberFire, FantasyFootballNerd, NFL,
         RTSports, Walterfootball
Posições: QB, RB, WR, TE, K, DST
```

**Output**: `ffa_db.rds` (7.4MB)
- `ffa_scrape`: Raw data do scraping com timestamp
- `ffa_player_ids`: Mapeamento de IDs entre sistemas
- `ffa_projtable`: Projeções agregadas (average, robust, weighted)
- `ffa_proj_source_points`: Projeções individuais por fonte

**Cache**: Salvo em `data/temp/ffa_scrape_db_s{season}w{week}_{tag}_{timestamp}.rds`

### 2️⃣ Atualização de Times

**Função**: `getFantasyTeams()`
**Endpoint**: `GET /v2/league/teams`

**Output**: `nfl_teams_db.rds` (1.4KB)
- `nfl_teams`: Informações dos times da liga
- `nfl_owners`: Proprietários dos times (com relacionamento FK)

### 3️⃣ Atualização de Jogadores

**Função**: `getFantasyPlayers()`
**Endpoint**: `GET /v2/league/players`

**Output**: `nfl_players_db.rds` (164KB)
- `nfl_players`: Dados cadastrais dos jogadores
- `nfl_player_injury_status`: Status de lesões com histórico temporal

**Features**:
- Histórico de status de lesões com timestamps
- Útil para análise de impacto de lesões na performance

### 4️⃣ Estatísticas de Jogos

**Função**: `getFantasyStatistics()`
**Endpoint**: `GET /v2/league/stats`

```r
# Coleta estatísticas de todas as semanas até a atual
# weeks 1:current_week
```

**Output**: `nfl_stats_db.rds` (453KB)
- `nfl_players_points`: Pontuação total por jogador/semana
- `nfl_players_stats`: Estatísticas detalhadas por categoria (statId)

### 5️⃣ Matchups e Rosters

**Função**: `getFantasyRound()`
**Endpoint**: `GET /v2/league/matchups`

**Output**: `nfl_round_db.rds` (39KB)
- `matchups_games`: Confrontos da semana
- `nfl_teams_rosters`: Escalações dos times (starters + bench)
- `nfl_teams_week_stats`: Estatísticas semanais dos times
- `nfl_teams_season_stats`: Estatísticas acumuladas da temporada

### 6️⃣ Recaps (Apenas para tag="final")

**Função**: Não especificada
**Endpoint**: `GET /v2/league/team/matchuprecap`

```r
# Coleta narrativas e highlights dos confrontos
# Apenas executado quando tag == "final"
```

**Output**: `nfl_recap_db.rds` (934KB)

### 🔄 Sistema de Cache

Todas as respostas de API são automaticamente salvas:

```r
saveTempResp(obj, name, season, week, tag, timestamp)
# Localização: data/temp/
# Permite reprocessamento sem novas chamadas à API
```

**Benefícios**:
- Auditoria de dados coletados
- Reprocessamento sem depender da API
- Desenvolvimento e testes sem rate limits

---

## 🎲 Sistema de Simulação

O arquivo `R/snippets/simulation_machine.R` é o **coração do sistema de simulação**, implementando 15 estratégias diferentes.

### 📊 Conceito: Seeds vs. Simulations

```r
# 1. SEEDS: Valores base para simulação
dudes_players_seeds
├── season, week, id, playerId, pos
├── simType: tipo de estratégia (15 tipos)
└── seeds: vetor de valores possíveis (1 a N valores)

# 2. SIMULATIONS: Resampling dos seeds
dudes_players_simulations
├── season, week, id, playerId, pos, simType
├── simulation: 1000 valores amostrados dos seeds
└── simQuantiles: quantis (5%, 15%, 30%, 50%, 70%, 85%, 95%)
```

### 🎯 Estratégias de Simulação

#### 📌 Tipo 1: Projeções Simples (1 seed)

Retornam um **único valor** de projeção:

```r
# 1. NFL - Projeção oficial da NFL
simType = "NFL"
seeds = [valor_unico_nfl]

# 2. proj_table_average - Média simples de todas as fontes
simType = "proj_table_average"
seeds = [mean(todas_fontes)]

# 3. proj_table_robust - Média robusta (resistente a outliers)
simType = "proj_table_robust"
seeds = [robust_mean(todas_fontes)]

# 4. proj_table_weighted - Média ponderada por acurácia histórica
simType = "proj_table_weighted"
seeds = [weighted_mean(todas_fontes)]
```

**Uso**: Baseline para comparação, representam o "consenso"

#### 🎲 Tipo 2: Monte Carlo (N seeds)

Retornam **múltiplos valores** para sampling:

```r
# 5. proj_src - Todas as projeções das fontes disponíveis
simType = "proj_src"
seeds = [ESPN, CBS, FantasyPros, ..., NFL]  # ~11 valores

# 6. proj_src_errors - Projeções com erros históricos aplicados
simType = "proj_src_errors"
seeds = [fonte1 + error_distribution, fonte2 + error_distribution, ...]

# 7. proj_src_w_errors - Combinação de originais + com erros
simType = "proj_src_w_errors"
seeds = [proj_src + proj_src_errors]  # ~22 valores

# 8. hist_data - Dados históricos completos do jogador
simType = "hist_data"
seeds = [todas_performances_historicas]  # N histórico

# 9. current_season_his - Performance apenas da temporada atual
simType = "current_season_his"
seeds = [performances_2024]  # ~17 valores (semanas jogadas)

# 10. proj_src_w_errors_balanced - Balanceamento de representatividade
simType = "proj_src_w_errors_balanced"
seeds = [balanced_sample(proj_src_w_errors)]
```

**Uso**: Captura variabilidade entre fontes e histórico

#### 📈 Tipo 3: Sampling por Densidade (distribuição completa)

Usa **kernel density estimation** para gerar distribuição:

```r
# 11-15. *_density - Sampling da densidade de probabilidade
simType = "proj_src_density"
seeds = sample(density(proj_src), n=1000)  # Amostragem da densidade
```

Estratégias com densidade:
- `proj_src_density`
- `proj_src_errors_density`
- `proj_src_w_errors_density`
- `hist_data_density`
- `current_season_his_density`

**Uso**: Captura a distribuição completa de probabilidade, não apenas valores discretos

### 🔧 Tratamento de Erros Históricos

Arquivo: `R/transformation/simulation.R`

#### Cálculo de Erros

```r
calcProjectionErrors(season, weeks)
  # Para cada jogador, semana e fonte:
  # erro = pontos_reais - pontos_projetados

  # Output:
  # - Distribuição de erros por fonte
  # - Distribuição de erros por posição
  # - Distribuição de erros por jogador
```

#### Aplicação de Erros

```r
applyErrorToProjection(projections, errors)
  # Para cada projeção atual:
  # 1. Identifica distribuição de erros históricos
  # 2. Amostra da distribuição de erros
  # 3. Aplica: projecao_com_erro = projecao + erro_sample

  # Resultado: Projeções "corrigidas" com erros históricos
```

**Conceito**: Projeções tendem a ter viés sistemático. Ao aplicar a distribuição de erros históricos, corrigimos esse viés.

### 📊 Output Final

```r
# dudes_simulation_db.rds (25MB)
dudes_simulation_db <- dm(
  dudes_players_seeds,        # Seeds base
  dudes_players_simulations   # 1000 simulações por jogador
) |>
  dm_add_pk(dudes_players_seeds, c(season, week, id, playerId, pos, simType)) |>
  dm_add_pk(dudes_players_simulations, c(season, week, id, playerId, pos, simType))
```

**Para cada jogador e cada estratégia:**
- 1000 valores simulados
- Quantis: 5%, 15%, 30%, 50% (mediana), 70%, 85%, 95%
- Permite análise de:
  - **Floor**: Quantil 15% (pior cenário esperado)
  - **Median**: Quantil 50% (cenário mais provável)
  - **Ceiling**: Quantil 85% (melhor cenário esperado)

---

## 🎯 Otimização de Times

O arquivo `R/analysis/team_optimizer.R` implementa otimização de escalação baseada em simulações.

### 📋 Configuração de Slots

```r
SLOTS <- tibble(
  pos = c("QB", "WR", "RB", "TE", "K", "DEF"),
  n   = c(  1,    2,    2,    1,   1,     1)
)

# Total: 8 slots fixos + 1 FLEX (WR/RB) = 9 starters
```

### 🔧 Algoritmos de Seleção

#### 1. Seleção por Projeção

```r
selectPlayers(playerSet, slots)
  # Para cada posição fixa:
  #   - Ordena por rank e projScore
  #   - Seleciona top N jogadores
  #
  # Para FLEX:
  #   - Dos restantes elegíveis (WR/RB)
  #   - Seleciona o melhor disponível
  #
  # Retorna: escalação otimizada por projeção
```

#### 2. Seleção por Performance Real

```r
selectBestPlayers(playerSet, slots)
  # Mesmo algoritmo, mas usa:
  #   - pts (pontuação real) ao invés de projScore
  #
  # Retorna: melhor escalação possível com hindsight
```

### 📊 Análise de Performance

```r
# Pontuação dos starters
team_perf <- rosters_perf |>
  filter(rosterSlotId < 20) |>  # Apenas starters
  summarise(totalPts = sum(pts), .by = c(season, week, teamId))

# Melhor escalação possível
team_potencial <- bestRoster |>
  summarise(potencialPts = sum(pts), .by = c(season, week, teamId))

# Eficiência
eficiencia <- totalPts / potencialPts * 100
```

**Métricas**:
- `totalPts`: Pontuação real obtida pelos starters escolhidos
- `potencialPts`: Pontuação máxima possível com o roster disponível
- `Eficiência`: % do potencial alcançado

**Insights**:
- Identifica decisões ruins de start/sit
- Quantifica "pontos deixados no banco"
- Compara managers: quem otimiza melhor?

### 🎲 Análise Probabilística de Cenários

```r
# Para cada par de jogadores da mesma posição:
# 1. Gera 1000 simulações para cada jogador
# 2. Compara os 1000 pares de valores
# 3. Calcula: P(jogador_A > jogador_B)
# 4. Identifica a melhor escolha probabilística
```

**Exemplo**:
```r
# Comparar dois WRs para o último slot:
WR_A: median = 12.5, ceiling = 22.0
WR_B: median = 11.8, ceiling = 18.5

# Simulação:
# - WR_A vence em 58% dos cenários
# - WR_B vence em 42% dos cenários
#
# Decisão: WR_A é a escolha mais segura
```

---

## 📦 Instalação

### Requisitos

- **R >= 4.0** (Recomendado: R 4.3+)
- **RStudio** (opcional, mas recomendado)
- **Conexão com internet** para scraping e API calls

### Pacotes Necessários

```r
# Manipulação de dados
install.packages(c("tidyverse", "dm", "lubridate", "glue"))

# APIs e Web Scraping
install.packages(c("httr", "jsonlite"))
devtools::install_github("FantasyFootballAnalytics/ffanalytics")

# Machine Learning
install.packages(c("tidymodels", "vip", "broom"))

# Visualização
install.packages(c("skimr", "ggplot2"))

# Utilities
install.packages(c("purrr", "yaml", "cli"))
```

### Clone do Repositório

```bash
git clone https://github.com/seu-usuario/DudesApp_claude.git
cd DudesApp_claude
```

---

## ⚙️ Configuração

### 1. Configuração da Liga

Edite `config/config.yml`:

```yaml
leagueId: 'SEU_LEAGUE_ID'
teamId: 'SEU_TEAM_ID'
season: 2025
authToken: Bearer SEU_AUTH_TOKEN_NFL
```

**Como obter o Auth Token:**

1. Acesse [NFL Fantasy](https://fantasy.nfl.com) no navegador
2. Faça login na sua conta
3. Abra as **DevTools** (F12) > Aba **Network**
4. Procure por requests para `api.fantasy.nfl.com`
5. Na aba **Headers**, procure por `Authorization`
6. Copie o token completo (incluindo `Bearer`)

### 2. Regras de Pontuação

Edite `config/score_settings.yml` conforme as regras da sua liga:

```yaml
pass:
  pass_yds: 0.04      # 1 ponto a cada 25 jardas (25 * 0.04 = 1)
  pass_tds: 4.0       # 4 pontos por TD de passe
  pass_int: -2.0      # -2 pontos por interceptação

rush:
  rush_yds: 0.1       # 1 ponto a cada 10 jardas (10 * 0.1 = 1)
  rush_tds: 6.0       # 6 pontos por TD de corrida

rec:
  rec: 1.0            # PPR (Point Per Reception) - 1 ponto por recepção
  rec_yds: 0.1        # 1 ponto a cada 10 jardas
  rec_tds: 6.0        # 6 pontos por TD de recepção

# ... (ver arquivo completo para todas as regras)
```

**Regras Comuns**:
- **PPR** (Point Per Reception): `rec: 1.0`
- **Half-PPR**: `rec: 0.5`
- **Standard** (Non-PPR): `rec: 0.0`

### 3. Parâmetros do Pipeline

Edite `R/pipeline/data_pipeline.R`:

```r
# MASTER PARAMETERS
.season <- 2025L      # Temporada atual
.week <- 17L          # Semana atual
.tag <- "final"       # "preview" ou "final"
```

**Tags**:
- `"preview"`: Projeções iniciais da semana (segunda/terça)
- `"final"`: Dados finais após todos os jogos (segunda seguinte)

---

## 🚀 Uso Básico

### 1. Executar Pipeline Completo

```r
# Abra o projeto no RStudio
# Carregue o script principal:
source("R/pipeline/data_pipeline.R")
```

**O que acontece:**
1. ✅ Scraping de todas as fontes de projeções
2. ✅ Atualização de dados da NFL via API
3. ✅ Merge inteligente com databases existentes (upsert)
4. ✅ Salvamento de cache em `data/temp/`
5. ✅ Atualização de todos os `.rds` em `data/`

**Tempo estimado**: 3-5 minutos

### 2. Gerar Simulações

```r
source("R/snippets/simulation_machine.R")
```

**O que acontece:**
1. ✅ Carrega databases existentes
2. ✅ Calcula erros históricos de projeções
3. ✅ Gera seeds para 15 estratégias
4. ✅ Executa 1000 simulações por jogador
5. ✅ Salva em `data/dudes_simulation_db.rds` (25MB)

**Tempo estimado**: 2-3 minutos

### 3. Otimizar Escalação

```r
source("R/analysis/team_optimizer.R")
```

**O que acontece:**
1. ✅ Analisa melhor escalação possível por time
2. ✅ Calcula performance vs. potencial
3. ✅ Identifica decisões sub-ótimas de start/sit
4. ✅ Compara cenários alternativos probabilísticos

### 4. Análises Ad-hoc

```r
# Melhores performances da semana
source("R/snippets/weekly_trophies.R")

# Análise de distribuição de pontos por posição
source("R/snippets/distribution_analysis.R")

# Machine Learning para predição de pontuação
source("R/analysis/projection_ml.R")

# Análise de rankings e tiers
source("R/snippets/analysis_tier_rank_ecr.R")

# Impacto de lesões na performance
source("R/snippets/analysis_injuryGameStatus.R")

# Comparação de estratégias de simulação
source("R/snippets/player_simulation_analysis.R")
```

---

## 📊 Modelos de Dados

O projeto usa o pacote `dm` (data models) para criar **relacionamentos type-safe** entre tabelas.

### 🗂️ Diagrama de Relacionamentos

```
┌─────────────────────────────────────────────────────────────┐
│                        ffa_db.rds                           │
├─────────────────────────────────────────────────────────────┤
│ ffa_scrape                                                  │
│   PK: season, week, tag, timestamp                          │
│                                                              │
│ ffa_player_ids                                              │
│   PK: id                                                    │
│                                                              │
│ ffa_projtable                                               │
│   PK: season, week, id, pos, avg_type, tag, timestamp       │
│   FK: id → ffa_player_ids                                   │
│                                                              │
│ ffa_proj_source_points                                      │
│   PK: season, week, id, pos, data_src, tag, timestamp       │
│   FK: id → ffa_player_ids                                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     nfl_teams_db.rds                        │
├─────────────────────────────────────────────────────────────┤
│ nfl_teams                                                   │
│   PK: teamId                                                │
│   FK: ownerUserId → nfl_owners                              │
│                                                              │
│ nfl_owners                                                  │
│   PK: ownerUserId                                           │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                   nfl_players_db.rds                        │
├─────────────────────────────────────────────────────────────┤
│ nfl_players                                                 │
│   PK: playerId                                              │
│                                                              │
│ nfl_player_injury_status                                    │
│   PK: playerId, timestamp                                   │
│   FK: playerId → nfl_players                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    nfl_stats_db.rds                         │
├─────────────────────────────────────────────────────────────┤
│ nfl_players_points                                          │
│   PK: season, week, playerId                                │
│                                                              │
│ nfl_players_stats                                           │
│   PK: season, week, playerId, statId                        │
│   FK: (season, week, playerId) → nfl_players_points         │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    nfl_round_db.rds                         │
├─────────────────────────────────────────────────────────────┤
│ matchups_games                                              │
│   PK: season, week, matchupId                               │
│                                                              │
│ nfl_teams_rosters                                           │
│   PK: season, week, teamId, playerId, tag, timestamp        │
│                                                              │
│ nfl_teams_week_stats                                        │
│   PK: season, week, teamId, tag, timestamp                  │
│                                                              │
│ nfl_teams_season_stats                                      │
│   PK: season, week, teamId, tag, timestamp                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 dudes_simulation_db.rds                     │
├─────────────────────────────────────────────────────────────┤
│ dudes_players_seeds                                         │
│   PK: season, week, id, playerId, pos, simType              │
│   Columns: seeds (list column)                              │
│                                                              │
│ dudes_players_simulations                                   │
│   PK: season, week, id, playerId, pos, simType              │
│   Columns: simulation (list column), simQuantiles (list)    │
└─────────────────────────────────────────────────────────────┘
```

### 🔗 Relacionamentos-Chave

1. **ffa_player_ids** é a ponte entre:
   - Sistema de IDs do FFAnalytics (`id`)
   - Sistema de IDs da NFL (`nfl_id` / `playerId`)

2. **Versionamento por timestamp**:
   - Permite múltiplas coletas por semana
   - Análise de evolução de projeções ao longo da semana

3. **Tags para momentos diferentes**:
   - `preview`: Antes dos jogos
   - `final`: Após os jogos

---

## 📈 Análises Disponíveis

### 1. 🏆 Weekly Trophies

**Arquivo**: `R/snippets/weekly_trophies.R`

Identifica os melhores desempenhos da semana:

- 🥇 **Best Player**: Jogador com maior pontuação absoluta
- 🎯 **Best by Position**: Melhor QB, RB, WR, TE, K, DEF
- 📈 **Biggest Overachiever**: Jogador que mais superou projeções
- 📉 **Biggest Disappointment**: Jogador que mais decepcionou vs. projeção
- 💎 **Hidden Gem**: Jogador sem projeção que pontuou bem
- 🎰 **Biggest Bust**: Projetado alto mas performou mal

### 2. 📊 Distribution Analysis

**Arquivo**: `R/snippets/distribution_analysis.R`

Análise estatística de distribuições:

- **Modelos testados**: Normal, Log-Normal, Gamma, Weibull
- **Ajuste de parâmetros**: Maximum Likelihood Estimation (MLE)
- **Comparação por posição**: QB, RB, WR, TE
- **Análise de outliers**: Identificação de performances extremas
- **Visualizações**: Histogramas, Q-Q plots, density plots

**Insights**:
- Qual distribuição melhor modela cada posição?
- QBs têm distribuição mais estável (menor variância)
- RBs e WRs têm maior variabilidade (cauda longa)

### 3. 🤖 Projection ML

**Arquivo**: `R/analysis/projection_ml.R`

Machine Learning para predição de pontuação:

**Features**:
- Projeções de múltiplas fontes
- Estatísticas históricas (média últimas 3 semanas, 5 semanas)
- Variância de performance
- Status de lesão
- Dificuldade de matchup

**Modelos testados**:
- Linear Regression
- Ridge/Lasso
- Random Forest (planejado)
- XGBoost (planejado)

**Pipeline tidymodels**:
```r
recipe() |>
  step_impute_median(all_numeric()) |>
  step_normalize(all_numeric()) |>
  step_pca(all_numeric(), threshold = 0.95)
```

### 4. 🎲 Team Simulation

**Arquivo**: `R/snippets/team_sim.R`

Simulação de matchups:

- **1000 simulações** de cada confronto
- **Probabilidade de vitória** por time
- **Distribuição de pontuação** por time
- **Análise de spread**: margin of victory
- **Risk vs. Upside**: Comparação de variância

**Output**:
```r
# Para cada matchup:
Team A: 65% de chance de vitória
  - Mediana: 112.5 pontos
  - Range 80%: 95.0 - 130.0 pontos

Team B: 35% de chance de vitória
  - Mediana: 98.3 pontos
  - Range 80%: 82.0 - 115.0 pontos
```

### 5. 🔍 Player Simulation Analysis

**Arquivo**: `R/snippets/player_simulation_analysis.R`

Compara acurácia das 15 estratégias:

**Métricas**:
- **RMSE** (Root Mean Square Error): Erro médio
- **MAE** (Mean Absolute Error): Erro absoluto médio
- **Bias**: Viés sistemático (over/under projection)
- **Coverage**: % de vezes que o real ficou no intervalo previsto

**Análise**:
- Qual estratégia é mais acurada?
- Estratégias baseadas em densidade são melhores?
- Erros históricos melhoram as previsões?

**Por posição**:
- QB: Estratégia X é melhor
- RB: Estratégia Y é melhor
- WR/TE: Estratégia Z é melhor

### 6. 📊 Rank Analysis

**Arquivo**: `R/snippets/analysis_tier_rank_ecr.R`

Análise de rankings e consenso:

- **ECR** (Expert Consensus Ranking): Média de rankings
- **Tier Breaks**: Identificação de grupos de jogadores similares
- **Divergências**: Fontes que discordam do consenso
- **Value Picks**: Jogadores subvalorizados vs. projeção

**Uso**:
- Identificar jogadores "sleepers"
- Encontrar value em drafts
- Comparar sua avaliação vs. consenso

### 7. 🏥 Injury Impact Analysis

**Arquivo**: `R/snippets/analysis_injuryGameStatus.R`

Estudo de impacto de lesões:

**Status analisados**:
- `QUESTIONABLE`: 70-75% de chance de jogar
- `DOUBTFUL`: 15-25% de chance de jogar
- `OUT`: Não joga
- `HEALTHY`: Sem restrições

**Análise**:
- Performance de jogadores `QUESTIONABLE` vs. `HEALTHY`
- % de snaps jogados por status
- Correlação entre status e pontuação
- Histórico: jogadores que sempre jogam mesmo "questionable"

---

## 🔧 Workflow Semanal Típico

### Segunda/Terça (Preview) - Projeções Iniciais

```r
# Configurar parâmetros
.week <- 18L
.tag <- "preview"

# Executar pipeline
source("R/pipeline/data_pipeline.R")

# Gerar simulações
source("R/snippets/simulation_machine.R")

# Otimizar escalação
source("R/analysis/team_optimizer.R")

# Analisar rankings
source("R/snippets/analysis_tier_rank_ecr.R")

# Verificar lesões
# Abrir nfl_players_db$nfl_player_injury_status

# 🎯 DECISÃO: Definir escalação inicial
```

### Quinta/Sexta - Ajustes Finais

```r
# Re-executar pipeline (projeções atualizadas)
.tag <- "preview"
source("R/pipeline/data_pipeline.R")

# Verificar mudanças em projeções
# Comparar com simulações anteriores

# Re-otimizar se necessário
source("R/analysis/team_optimizer.R")
```

### Domingo - Durante os Jogos

```r
# Monitorar performance em tempo real
# (Não requer execução de scripts)

# Opcional: Análise rápida de trophies
source("R/snippets/weekly_trophies.R")
```

### Segunda Seguinte (Final) - Análise Pós-Jogo

```r
# Configurar para dados finais
.week <- 18L
.tag <- "final"

# Coletar estatísticas finais
source("R/pipeline/data_pipeline.R")

# Avaliar acurácia das projeções
source("R/snippets/player_simulation_analysis.R")

# Atualizar erros históricos
source("R/transformation/simulation.R")

# Análise de performance
source("R/analysis/team_optimizer.R")

# Weekly trophies
source("R/snippets/weekly_trophies.R")

# 📊 RETROSPECTIVA: O que funcionou? O que não funcionou?
```

---

## 🛠️ Tecnologias Utilizadas

### Core R Packages

| Pacote | Uso | Versão |
|--------|-----|--------|
| `tidyverse` | Manipulação de dados | 2.0+ |
| `dm` | Data modeling relacional | Latest |
| `lubridate` | Manipulação de datas | Latest |
| `glue` | String interpolation | Latest |

### APIs e Scraping

| Pacote | Uso |
|--------|-----|
| `httr` | HTTP requests para NFL API |
| `jsonlite` | Parse de JSON responses |
| `ffanalytics` | Scraping de projeções |

### Machine Learning

| Pacote | Uso |
|--------|-----|
| `tidymodels` | Framework de ML |
| `vip` | Variable importance plots |
| `broom` | Tidy model outputs |

### Visualização

| Pacote | Uso |
|--------|-----|
| `ggplot2` | Gráficos |
| `skimr` | Data summaries |

### Utilities

| Pacote | Uso |
|--------|-----|
| `purrr` | Functional programming |
| `yaml` | Config files |
| `cli` | Progress bars |

---

## 🤝 Contribuindo

Sugestões de melhorias são bem-vindas! Áreas de interesse:

### 🎯 Novos Modelos de Simulação

- [ ] Adicionar estratégia baseada em Bayesian inference
- [ ] Implementar bootstrap para intervalos de confiança
- [ ] Testar Monte Carlo com correção de viés

### 🤖 Machine Learning

- [ ] Implementar Random Forest e XGBoost
- [ ] Feature engineering com estatísticas avançadas
- [ ] Ensemble de múltiplos modelos
- [ ] Predição de variance (não apenas média)

### 📊 Visualizações

- [ ] Dashboard interativo com Shiny
- [ ] Gráficos de evolução temporal de projeções
- [ ] Heatmaps de matchups favoráveis
- [ ] Network graphs de correlações entre jogadores

### 🔄 Automação

- [ ] GitHub Actions para pipeline automático semanal
- [ ] Notificações via Telegram/Slack
- [ ] API REST para consumo externo
- [ ] Docker container para deployment

### 📈 Novas Análises

- [ ] Análise de correlação entre jogadores (stacks)
- [ ] Otimização considerando ownership (DFS)
- [ ] Trade analyzer (value comparison)
- [ ] Playoff probability simulator

---

## 📚 Documentação Adicional

### Claude Code Skills Instalados

Este projeto usa **Claude Code** com 9 skills especializados em R:

1. **r-oop**: Programação orientada a objetos (S7, S3, S4)
2. **r-bayes**: Inferência Bayesiana com brms
3. **tidyverse-patterns**: Padrões modernos do tidyverse
4. **rlang-patterns**: Metaprogramação e tidy evaluation
5. **r-style-guide**: Guia de estilo para código R
6. **r-performance**: Otimização e profiling
7. **r-package-development**: Desenvolvimento de pacotes
8. **dm-relational**: Modelagem de dados relacionais
9. **tdd-workflow**: Test-driven development

### BMAD Workflows

O projeto também tem acesso aos **BMAD workflows** para:
- Gerenciamento de projetos
- Documentação automática
- Code review
- Criação de épicos e histórias

---

## 🐛 Troubleshooting

### Problema: API retorna 401 Unauthorized

**Solução**: Token expirado. Obtenha um novo token seguindo as instruções em [Configuração](#️-configuração).

### Problema: Scraping falha para algumas fontes

**Solução**: Algumas fontes podem estar temporariamente indisponíveis. O sistema continua com as fontes disponíveis.

### Problema: Simulações muito lentas

**Soluções**:
- Reduza o número de simulações (padrão: 1000)
- Use menos estratégias de densidade (mais custosas)
- Execute em paralelo com `future` package

### Problema: Database muito grande

**Soluções**:
- Arquive dados de temporadas antigas em `data/2023/`
- Limpe cache em `data/temp/` periodicamente
- Use `saveRDS(..., compress = "xz")` para maior compressão

---

## 📄 Licença

Este projeto é de uso pessoal para fins educacionais e de pesquisa.

**Disclaimer**: Este projeto não é afiliado à NFL ou a qualquer fonte de dados mencionada. Use por sua própria conta e risco.

---

## 🙏 Agradecimentos

- **[ffanalytics](https://github.com/FantasyFootballAnalytics/ffanalytics)**: Package R para scraping de projeções
- **NFL Fantasy API**: Dados oficiais da NFL
- **[tidyverse](https://www.tidyverse.org/)**: Ecossistema de pacotes R
- **[dm](https://cynkra.github.io/dm/)**: Package para data modeling
- **Comunidade Fantasy Football**: Pela paixão e análises compartilhadas

---

## 📧 Contato

Para dúvidas ou sugestões sobre este projeto:
- Abra uma **issue** no repositório
- Entre em contato via **e-mail**: [seu-email]

---

## 🏈 Let's Go!

**"In data we trust"** - Boa sorte na sua liga de Fantasy Football! 🏆

---

**Última atualização**: Temporada 2025 - Semana 17
**Status**: ✅ Produção - Sistema operacional

---

<div align="center">

Made with ❤️ and R

**[⬆ Voltar ao topo](#dudes-football-analytics-app)**

</div>
