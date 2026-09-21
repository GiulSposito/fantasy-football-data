# 🏈 Dudes Fantasy Football - Sistema de Análise e Simulação

Sistema completo de análise estatística, projeções e simulações para a liga de Fantasy Football "It's Football, Dudes".

**Website:** [dudesfootball.netlify.app](https://dudesfootball.netlify.app)

> 📘 **Documentação de Dados:** Consulte [DATAMODEL.md](DATAMODEL.md) para modelo conceitual e [DATA_DICTIONARY.md](DATA_DICTIONARY.md) para dicionário detalhado de todos os arquivos RDS.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Características Principais](#-características-principais)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Pipeline de Dados](#-pipeline-de-dados)
- [Configuração](#-configuração)
- [Uso](#-uso)
- [Dependências](#-dependências)
- [Fluxo de Trabalho](#-fluxo-de-trabalho)
- [Módulos Principais](#-módulos-principais)
- [Relatórios Gerados](#-relatórios-gerados)

## 🎯 Visão Geral

Este projeto é um sistema automatizado de análise de Fantasy Football desenvolvido em R que:

- 📊 **Coleta projeções** de múltiplas fontes (ESPN, Yahoo, FantasyPros, etc.)
- 🧮 **Calcula estatísticas agregadas** com ponderação de múltiplas fontes
- 🎲 **Executa simulações Monte Carlo** para prever resultados de partidas
- 📈 **Gera dashboards interativos** com análises visuais
- 🌐 **Publica automaticamente** em website estático

O sistema está ativo desde a temporada 2021 e atualmente processa dados da **temporada 2025 da NFL**.

## ⚡ Características Principais

### 1. Multi-Source Data Aggregation
Coleta e agrega projeções de 10+ fontes especializadas:
- CBS Sports
- ESPN
- FantasyPros
- FantasySharks
- FleaFlicker
- NumberFire
- NFL.com
- RTSports
- Walterfootball
- Yahoo Fantasy

### 2. Correção de Erros Históricos
- Calcula erros de projeção de semanas anteriores
- Aplica pesos decrescentes (lag-weighted) para correção
- Melhora precisão das previsões ao longo da temporada

### 3. Simulação Monte Carlo
- 1000 iterações por partida
- Usa distribuições ECDF (Empirical Cumulative Distribution Function)
- Combina estatísticas reais (jogadores que já jogaram) com projeções
- Calcula probabilidade de vitória para cada time

### 4. Análise de Incerteza
- Intervalo de confiança de 95% (t-test)
- Floor e Ceiling para cada jogador
- Identificação de riscos e oportunidades

### 5. Website Automatizado
- Geração via Blogdown/Hugo
- Deploy automático no Netlify
- Relatórios interativos em HTML
- Exportações em CSV

## 📁 Estrutura do Projeto

```
DudesFantasyFootball_claude/
│
├── R/                          # Código-fonte principal
│   ├── api/                    # Integração com ESPN Fantasy API v2
│   │   ├── ffa_api.R          # Wrapper HTTP base (JWT auth)
│   │   ├── ffa_league.R       # Endpoints de liga (matchups, standings)
│   │   ├── ffa_players.R      # Estatísticas de jogadores
│   │   └── ffa_user.R         # Autenticação de usuário
│   │
│   ├── import/                 # Web scraping e importação de dados
│   │   ├── ffa_player_projection.R    # Orquestrador principal de scraping
│   │   ├── espn_scraper.R             # Scraper customizado ESPN
│   │   ├── nfl_id_mapping.R           # Mapeamento de IDs entre sistemas
│   │   ├── checkFantasyAPI.R          # Validação de conectividade
│   │   └── ...
│   │
│   ├── simulation/             # Lógica de projeção e simulação
│   │   ├── players_projections.R      # Engine de projeções
│   │   ├── error_projection.R         # Análise de erros históricos
│   │   ├── points_simulation_v6.R     # Simulação Monte Carlo (versão atual)
│   │   └── ...
│   │
│   ├── reports/                # Geração de relatórios (Rmarkdown)
│   │   ├── ffa_players_projection.Rmd # Dashboard de projeções
│   │   ├── dudes_simulation_v5.Rmd    # Dashboard de simulações
│   │   └── ...
│   │
│   ├── pipeline/               # Scripts de orquestração
│   │   ├── update_pipe.R      # Pipeline principal (ATUAL)
│   │   ├── new_week.R         # Pipeline legado
│   │   ├── season_simulation.R # Análise de temporada completa
│   │   └── ...
│   │
│   ├── analysis/               # Análises pós-processamento
│   │   ├── player_performance.R       # Performance histórica
│   │   ├── draft_analysis.R           # Avaliação de draft
│   │   └── ...
│   │
│   └── tidy/                   # Utilitários de transformação de dados
│
├── config/                     # Arquivos de configuração
│   ├── config.yml             # Configurações da liga (IDs, tokens)
│   └── score_settings.yml     # Regras de pontuação PPR
│
├── data/                       # Dados persistentes (RDS)
│   ├── weeklies_scraps.rds    # Scrapes acumulados
│   ├── players_points.rds     # Pontuações reais
│   ├── points_projection_and_errors.rds
│   └── {season}/              # Dados por temporada
│
├── static/                     # Assets do website
│   ├── reports/{season}/      # Relatórios HTML por temporada
│   ├── exports/{season}/      # Exportações CSV
│   └── images/                # Imagens e logos
│
├── content/                    # Posts do blog (Hugo)
│   └── posts/                 # Artigos e análises
│
├── public/                     # Website gerado (Hugo)
│
├── layouts/                    # Templates Hugo customizados
│
└── index.Rmd                   # Landing page do site

```

## 🔄 Pipeline de Dados

O fluxo completo de processamento está implementado em `R/pipeline/update_pipe.R` e executa 7 fases:

### Fase 1: Web Scraping
```r
scrapPlayersPredictions(week, season)
```
- Coleta projeções de todas as fontes via `ffanalytics`
- Persiste em: `./data/week{X}_scrap.rds`
- Acumula historicamente em: `./data/weeklies_scraps.rds`

### Fase 2: Cálculo de Projeções Agregadas
```r
calcPlayersProjections(webScrape, score_settings)
```
- Agrega dados de múltiplas fontes (média robusta)
- Adiciona metadados (nome, posição, time, ECR)
- Output: `./data/weekly_proj_table_{week}.rds`

### Fase 3: Importação de Estatísticas da Fantasy API
```r
importPlayerStatistics(config, week)
```
- Busca pontuações reais da semana (ESPN API)
- Inclui rank contra posição (RAP)
- Output: `./data/players_points.rds`

### Fase 4: Matchups e Rosters
```r
importMatchups(config, week)
```
- Recupera cronograma de partidas da liga
- Busca rosters ativos por time
- Ajusta para status de lesão (zera projeções de jogadores lesionados)
- Cria mapeamento de alocação por time
- Output: `./data/week{X}_players_projections.rds`

### Fase 5: Projeção de Erros e Correção
```r
projectErrorPoints(players_stats, site_ptsproj, player_ids, week)
```
- Compara histórico: pontuação real vs. projetada
- Calcula distribuições de erro por fonte
- Aplica correções com peso decrescente (lag-weighted)
- **Aplica erros da temporada anterior** quando configurado
- Output: `./data/points_projection_and_errors.rds`

### Fase 6: Cálculo de Confiança Estatística
```r
t.test() aplicado em agregação de projeções
```
- Intervalos de confiança de 95% por jogador
- Output: `./data/dudesffa_projpoints_week{X}.rds`

### Fase 7: Simulação Monte Carlo
```r
simulateGames(week, season, ptsproj, matchups, rosters, stats, ids, proj)
```
- Gera 1000 iterações de cada partida
- Usa ECDF para criar distribuições realistas de pontos
- **Combina:**
  - Estatísticas reais para jogadores que já jogaram (fixas)
  - Projeções para jogadores que ainda vão jogar
- Calcula probabilidade de vitória por time
- Output: `./data/simulation_v6_week{X}_{phase}.rds`

### Fase 8: Geração de Relatórios
```r
rmarkdown::render(flexdashboard)
```
- **Players Projection Dashboard**: Rankings, floor/ceiling, alocação por time
- **Simulation Dashboard**: Previsões de partidas, probabilidades de vitória, intervalos de confiança
- **Exportações CSV**: Dados completos + dados brutos por posição

### Fase 9: Publicação no Website
```r
blogdown::build_site()
```
- Gera site estático via Hugo
- Relatórios em: `/static/reports/{season}/`
- Deploy automático no Netlify

## ⚙️ Configuração

### config/config.yml
```yaml
leagueId: '3940933'       # ID da Liga no ESPN Fantasy
teamId: '4'               # ID do seu time
week: '0'                 # Semana atual (0 = offseason)
season: 2025              # Temporada NFL
authToken: <JWT_TOKEN>    # Token de autenticação (não commitado)
```

### config/score_settings.yml
Sistema de pontuação PPR (Points Per Reception):

**Passing (QB):**
- 0.04 pts/jardas
- 4 pts/TD
- -2 pts/Interceptação

**Rushing (RB):**
- 0.1 pts/jardas
- 6 pts/TD

**Receiving (WR/TE):**
- 1 pt/recepção (PPR)
- 0.1 pts/jardas
- 6 pts/TD

**Defense:**
- 2-3 pts para turnovers/sacks
- 6 pts/TD
- 1.5 pts/kick bloqueado

**Kicking (K):**
- 1 pt/PAT
- 3-5 pts/Field Goal (baseado em distância)

**IDP (Individual Defensive Players):**
- 1 pt/tackle solo
- 0.5 pts/assistência
- 3 pts/interceptação
- 3 pts/fumble forçado
- 6 pts/TD

## 🚀 Uso

### Atualização Semanal Completa

```r
# Carregar pipeline principal
source("./R/pipeline/update_pipe.R")

# Configurar parâmetros
week <- 17
season <- 2025
prefix <- "preTNF"  # preTNF, posTNF, preSunday, final, etc.

# Executar pipeline completo
# (o script executa automaticamente todas as fases)
```

### Execução Modular (Fases Individuais)

```r
# Apenas scraping
source("./R/import/ffa_player_projection.R")
webScrape <- scrapPlayersPredictions(week, season)

# Apenas projeções
source("./R/simulation/players_projections.R")
proj_table <- calcPlayersProjections(webScrape, score_settings)

# Apenas simulação
source("./R/simulation/points_simulation_v6.R")
sim <- simulateGames(week, season, ptsproj, matchups, rosters, stats, ids, proj)
```

### Visualização Local do Website

```r
library(blogdown)

# Servir site localmente
blogdown::serve_site()

# Acesse: http://localhost:4321
```

### Análise de Temporada Completa

```r
source("./R/pipeline/season_simulation.R")
# Gera análises estatísticas da temporada inteira
```

## 📦 Dependências

### Core
```r
library(tidyverse)        # Manipulação de dados
library(ffanalytics)      # Scraping de projeções Fantasy Football
library(httr2)            # Requisições HTTP
library(jsonlite)         # Parsing JSON
```

### Análise e Simulação
```r
library(lubridate)        # Manipulação de datas
library(glue)             # Interpolação de strings
library(purrr)            # Programação funcional
library(dm)               # Modelagem relacional
```

### Relatórios e Visualização
```r
library(flexdashboard)    # Dashboards interativos
library(rmarkdown)        # Renderização de relatórios
library(plotly)           # Gráficos interativos
library(ggrepel)          # Posicionamento de labels
```

### Website
```r
library(blogdown)         # Geração de site Hugo
library(yaml)             # Parsing de configurações
```

### Instalação de Dependências

```r
# Instalar pacotes necessários
install.packages(c(
  "tidyverse", "ffanalytics", "httr2", "jsonlite",
  "lubridate", "glue", "flexdashboard", "blogdown",
  "plotly", "ggrepel", "dm", "yaml", "rmarkdown"
))
```

## 🔄 Fluxo de Trabalho Semanal

### Ciclo Típico de Atualização:

1. **Segunda/Quarta-feira (Pre-TNF)**
   ```r
   prefix <- "preTNF"
   ```
   - Executar scrapers antes do Thursday Night Football
   - Gerar projeções iniciais com correções de erro

2. **Quinta-feira (Post-TNF)**
   ```r
   prefix <- "posTNF"
   ```
   - Atualizar com estatísticas reais do jogo de quinta
   - Re-executar simulações

3. **Domingo (Pre-Sunday Games)**
   ```r
   prefix <- "preSunday"
   ```
   - Atualização final antes dos jogos de domingo

4. **Segunda-feira (Pre-MNF)**
   ```r
   prefix <- "preMNF"
   ```
   - Incorporar resultados de domingo

5. **Terça-feira (Final)**
   ```r
   prefix <- "final"
   ```
   - Resultados completos da semana
   - Calcular erros para próxima semana
   - Commit: `w{X} final`

### Padrão de Commits
```bash
git commit -m "w17 preTNF"
git commit -m "w17 posTNF"
git commit -m "w17 preSunday"
git commit -m "w17 preMNF"
git commit -m "w17 final"
```

## 🧩 Módulos Principais

### 1. API Integration (`R/api/`)

#### ffa_api.R
```r
# Wrapper base para requisições HTTP
ffa_get(url, token, league_id, ...)
```
- Autenticação JWT via Bearer token
- Tratamento de erros HTTP
- Retry logic

#### ffa_league.R
```r
ffa_league_matchups(token, league_id, week)
ffa_league_standings(token, league_id)
ffa_league_schedule(token, league_id)
```

#### ffa_players.R
```r
ffa_players_stats(token, league_id, season, weeks)
ffa_extractPlayersStats(api_response)
```
- Busca estatísticas semanais + agregadas
- Métricas avançadas
- Rank contra posição

### 2. Data Import (`R/import/`)

#### ffa_player_projection.R
```r
scrapPlayersPredictions(week, season)
  # Retorna: list(QB, RB, WR, TE, K, DST)

accumulateWeeklyScrape(week, webScrape)
  # Persiste em: ./data/weeklies_scraps.rds
```

#### nfl_id_mapping.R
```r
# Mapeia IDs entre sistemas:
# - ffanalytics ID
# - ESPN Fantasy ID
# - NFL Official ID
# - NFLVERSE ID
```

### 3. Simulation Engine (`R/simulation/`)

#### players_projections.R
```r
calcPointsProjection(season, score_settings)
  # Agrega projeções de todas as fontes
  # Retorna: tibble com id, pos, week, data_src, pts.proj

projectErrorPoints(actual_stats, projected_stats, player_ids, week)
  # Calcula erros históricos
  # Aplica pesos decrescentes
  # Retorna: tibble com correções de erro

projectFloorCeiling(projections, confidence=0.95)
  # Calcula intervalos de confiança
  # Retorna: floor, ceiling por jogador
```

#### points_simulation_v6.R
```r
simulateGames(week, season, ptsproj, matchups, rosters, stats, ids, proj_table)
  # Executa 1000 iterações Monte Carlo
  # Retorna: list(
  #   win_probabilities,
  #   score_distributions,
  #   confidence_intervals
  # )
```

**Algoritmo de Simulação:**
1. Para cada partida e cada iteração:
   - Identifica jogadores que já jogaram → pontos fixos
   - Para jogadores não-jogados:
     - Amostra de distribuição ECDF baseada em projeções + erros
   - Soma pontos do time
2. Compara pontos dos times
3. Calcula frequência de vitórias
4. Gera intervalos de confiança

### 4. Reporting (`R/reports/`)

#### ffa_players_projection.Rmd
```r
# Flexdashboard com:
# - Tabela de rankings por posição
# - Floor/Ceiling/Projeção
# - Alocação por time fantasy
# - ECR (Expert Consensus Ranking)
```

#### dudes_simulation_v5.Rmd
```r
# Flexdashboard com:
# - Previsões de partidas
# - Probabilidades de vitória
# - Distribuições de pontos (histogramas)
# - Confidence intervals
# - Análise de risco/oportunidade
```

## 📊 Relatórios Gerados

### 1. Player Projections Dashboard
**Arquivo:** `ffa_players_projection_week{X}.html`

**Conteúdo:**
- Rankings por posição (QB, RB, WR, TE, K, DST)
- Projeção de pontos (média + floor/ceiling)
- Team allocation (qual time fantasy possui o jogador)
- Status de lesão
- ECR (Expert Consensus Ranking)

### 2. Simulation Dashboard
**Arquivo:** `dudes_simulation_v6_week{X}_{phase}.html`

**Conteúdo:**
- Tabela de matchups
- Probabilidade de vitória para cada time
- Projeção de pontos (média ± desvio padrão)
- Distribuições de pontos (histogramas)
- Intervalos de confiança (95%)
- Análise de favoritos/underdogs

### 3. Exportações CSV
**Arquivos gerados em:** `./static/exports/{season}/`

- `week{X}_full_ppr.csv` - Dados completos agregados
- `week{X}_QB_rawdata.csv` - Dados brutos por posição
- `week{X}_RB_rawdata.csv`
- `week{X}_WR_rawdata.csv`
- `week{X}_TE_rawdata.csv`
- `week{X}_K_rawdata.csv`
- `week{X}_DST_rawdata.csv`

**Estrutura CSV:**
```csv
id, player_name, pos, team, week, data_src, points, floor, ceiling, sd_pts, ecr, ...
```

## 🔍 Análises Especializadas

### Draft Analysis
```r
source("./R/analysis/draft_analysis.R")
```
- Avaliação de performance de picks
- ROI por rodada de draft
- Comparação entre times

### Player Performance
```r
source("./R/analysis/player_performance.R")
```
- Histórico de pontos
- Tendências de performance
- Análise de consistência (desvio padrão)

### Victory Table
```r
source("./R/analysis/victory_table.R")
```
- Matriz de confrontos diretos
- Histórico de vitórias/derrotas

### Prediction Performance
```r
source("./R/analysis/predictionPerformance.R")
```
- Acurácia das simulações
- Calibração das probabilidades
- Análise de erros do modelo

## 🛠️ Manutenção e Troubleshooting

### Verificar Conectividade com API
```r
source("./R/import/checkFantasyAPI.R")
checkFantasyAPI(config$authToken, config$leagueId, week)
```

### Re-processar Semana Específica
```r
week <- 15
webScrape <- readRDS(glue("./data/week{week}_scrap.rds"))
# Re-executar fases seguintes...
```

### Atualizar IDs de Jogadores
```r
# Jogadores não mapeados ficam em:
mis_player_ids <- readRDS("./data/missing_player_ids.rds")

# Tabela consolidada:
my_player_ids <- ffanalytics:::player_ids %>%
  bind_rows(mis_player_ids)
```

### Aplicar Erros de Temporada Anterior
```r
# No update_pipe.R, configurar:
apply.previous.season.errors <- TRUE

# O sistema carrega automaticamente:
past_proj_errors <- readRDS("./data/season_2024_projections_errors.rds")
```

## 📈 Histórico de Versões

### Versões de Simulação
- **v6** (atual): ECDF com combinação de stats reais + projeções
- **v5**: Introdução de confidence intervals
- **v4-v1**: Versões anteriores (arquivadas)

### Versões de Relatórios
- **rep.version = 5** (atual)
- **sim.version = 6** (atual)

## 🤝 Contribuindo

Este é um projeto pessoal, mas sugestões são bem-vindas:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaAnalise`)
3. Commit suas mudanças (`git commit -m 'Add: Nova análise de consistência'`)
4. Push para a branch (`git push origin feature/NovaAnalise`)
5. Abra um Pull Request

## 📝 Licença

Este projeto é de uso pessoal para análise da liga "It's Football, Dudes".

## 🎓 Créditos

- **ffanalytics**: Package R para scraping de projeções Fantasy Football
- **ESPN Fantasy API**: Fonte de dados oficial da liga
- **Blogdown/Hugo**: Framework de geração de site estático
- **Netlify**: Hospedagem e deploy contínuo

## 📧 Contato

Para questões sobre o projeto, abra uma issue no repositório.

---

**Última atualização:** Semana 17, Temporada 2025 NFL
**Status:** ✅ Ativo e em produção