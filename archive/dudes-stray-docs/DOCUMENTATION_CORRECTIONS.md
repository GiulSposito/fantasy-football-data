# Correções Necessárias para Documentação - DudesFFA

**Data:** 2026-03-07
**Arquivos Afetados:** `dudes_DATAMODEL.md`, `dudes_DATA_DICTIONARY.md`
**Baseado em:** Análise completa de dudes/2025/ e dudes/2024/

---

## 📋 Índice

1. [Correções Críticas](#correções-críticas)
2. [Correções Menores](#correções-menores)
3. [Adições à Documentação](#adições-à-documentação)
4. [Exemplos de Código Atualizados](#exemplos-de-código-atualizados)

---

## 🔴 Correções Críticas

### 1. Arquivos de Temporada com Timestamp (2025)

**Arquivo:** `dudes_DATAMODEL.md` - Seção "Season Aggregated Files"

**Problema:** A partir de 2025, os arquivos de temporada usam sufixo com timestamp `_YYYYMMDD`, mas a documentação só menciona nomes canônicos.

**Correção necessária:**

#### dudes_DATAMODEL.md (linha ~337-350)

**ANTES:**
```markdown
### 9. **SEASON_AGGREGATE** (Dados Sazonais)

**Arquivos:**
- `season_scrap.rds` - Scrapes sazonais (soma de todas as semanas)
- `season_projtable.rds` - Projeções da temporada completa
- `season_player_proj_sites.rds` - Projeções por site (temporada completa)
- `season_2024_projections_errors.rds` - Erros históricos para ML
- `week0_scrap.rds` - **Equivalente semanal** dos dados de temporada (formato week{X})
```

**DEPOIS:**
```markdown
### 9. **SEASON_AGGREGATE** (Dados Sazonais)

**Arquivos:**
- `season_scrap.rds` - Scrapes sazonais (soma de todas as semanas)
  - **2025+:** `season_scrap_YYYYMMDD.rds` (versão timestampada)
- `season_projtable.rds` - Projeções da temporada completa
  - **2025+:** `season_projtable_YYYYMMDD.rds` (versão timestampada)
- `season_player_proj_sites.rds` - Projeções por site (temporada completa)
  - **2025+:** `season_player_proj_sites_YYYYMMDD.rds` (versão timestampada)
- `season_2024_projections_errors.rds` - Erros históricos para ML
- `week0_scrap.rds` - **Equivalente semanal** dos dados de temporada (formato week{X})

**Estratégia de Versionamento (2025+):**

A partir da temporada 2025, os arquivos de agregação sazonal incluem um sufixo de timestamp
no formato `_YYYYMMDD` para versionamento automático. Exemplo: `season_scrap_20250826.rds`.

**Convenção:**
- **Nome canônico** (`season_*.rds`): Usado em pipelines legacy e código anterior a 2025
- **Nome timestampado** (`season_*_YYYYMMDD.rds`): Versão atual usada em 2025+
- **Quando usar cada um:**
  - Use a versão timestampada para garantir snapshot consistente
  - Múltiplas versões timestampadas podem coexistir (backups/histórico)
  - Pipelines novos devem buscar a versão mais recente via `list.files()` + `max()`

**Exemplo de código:**
```r
# Buscar versão mais recente (2025+)
season_files <- list.files("dudes/2025/",
                          pattern = "^season_scrap_\\d{8}\\.rds$",
                          full.names = TRUE)
latest_season <- readRDS(max(season_files))

# Fallback para nome canônico (compatibilidade com 2024 e anteriores)
if (length(season_files) == 0) {
  latest_season <- readRDS("dudes/2025/season_scrap.rds")
}
```

**Cardinalidade:**
- 2024 e anteriores: 3 arquivos principais + 1 histórico + 1 week0
- 2025+: 3+ arquivos timestampados + 1 histórico + 1 week0 (múltiplas versões podem existir)
```

#### dudes_DATA_DICTIONARY.md (linha ~520-560)

**Adicionar nova subseção:**

```markdown
### Estratégia de Versionamento de Arquivos de Temporada

**Evolução 2024 → 2025:**

| Arquivo | Formato 2024 | Formato 2025 |
|---------|-------------|-------------|
| Season scrapes | `season_scrap.rds` | `season_scrap_YYYYMMDD.rds` |
| Season projections | `season_projtable.rds` | `season_projtable_YYYYMMDD.rds` |
| Season site projections | `season_player_proj_sites.rds` | `season_player_proj_sites_YYYYMMDD.rds` |

**Padrão de timestamp:**
- Formato: `_YYYYMMDD` (8 dígitos)
- Exemplo: `_20250826` = 26 de agosto de 2025
- Múltiplas versões podem coexistir no mesmo diretório

**Uso em pipelines:**

```r
# Função auxiliar para carregar versão mais recente
load_latest_season_file <- function(base_name, season_dir = "dudes/2025/") {
  # Padrão: base_name_YYYYMMDD.rds
  pattern <- paste0("^", base_name, "_\\d{8}\\.rds$")

  # Buscar todos os arquivos timestampados
  files <- list.files(season_dir, pattern = pattern, full.names = TRUE)

  if (length(files) > 0) {
    # Retornar versão mais recente
    return(readRDS(max(files)))
  } else {
    # Fallback para nome canônico (compatibilidade com 2024)
    canonical <- file.path(season_dir, paste0(base_name, ".rds"))
    if (file.exists(canonical)) {
      return(readRDS(canonical))
    } else {
      stop("Nenhuma versão encontrada para ", base_name)
    }
  }
}

# Uso
season_scrap <- load_latest_season_file("season_scrap")
season_proj <- load_latest_season_file("season_projtable")
```

**Motivação:** O versionamento com timestamp permite:
1. Backup automático de diferentes snapshots
2. Comparação entre versões de projeções pré-temporada
3. Rollback para versões anteriores se necessário
4. Auditoria de quando os dados foram gerados
```

---

### 2. Fases de Simulação Não Documentadas

**Arquivo:** `dudes_DATA_DICTIONARY.md` - Seção "Simulation Files"

**Problema:** Documentação lista 10 fases padrão, mas existem 16 fases reais (6+ fases de eventos especiais não documentadas).

**Correção necessária:**

#### dudes_DATA_DICTIONARY.md (linha ~362-373)

**ANTES:**
```markdown
**Phase Suffixes:**
- `preTNF` - Before Thursday Night Football
- `posTNF` - After Thursday Night Football
- `preSundayGames` - Before Sunday games
- `preSNF` - Before Sunday Night Football
- `posSNF` - After Sunday Night Football
- `preMNF` - Before Monday Night Football
- `posMNF` - After Monday Night Football
- `preWaivers` - Before waiver processing
- `posWaivers` - After waiver processing
- `final` - Week completed
```

**DEPOIS:**
```markdown
**Phase Suffixes:**

#### Fases Padrão (presentes em todas as semanas aplicáveis)
- `preTNF` - Before Thursday Night Football
- `posTNF` - After Thursday Night Football
- `preSundayGames` - Before Sunday games
- `preSNF` - Before Sunday Night Football (semanas específicas)
- `posSNF` - After Sunday Night Football (não usado em 2025)
- `preMNF` - Before Monday Night Football
- `posMNF` - After Monday Night Football (não usado em 2025)
- `preWaivers` - Before waiver processing
- `posWaivers` - After waiver processing
- `final` - Week completed (sempre presente)

#### Fases de Eventos Especiais (semanas específicas)

**Jogos Internacionais:**
- `preBR` - Before Brazil Game (Week 1, 2025)
- `posBrasilGame` - After Brazil Game (Week 1, 2024)
- `preLondon` - Before London Game (Week 7, 2025)
- `preLondonGame` - Before London Game (Week 5-7, 2024)
- `preDublinGame` - Before Dublin Game (Week 4, 2025)

**Feriados:**
- `posThanksgiving` - After Thanksgiving (Week 13, 2025)
- `preXMAS` - Before Christmas (Week 17, 2024)

**Notas:**
- Fases de eventos especiais variam conforme calendário NFL de cada temporada
- Jogos internacionais (Londres, Dublin, Brasil) geram fases específicas
- Feriados (Thanksgiving, Christmas) podem adicionar fases extras
- A presença de fases específicas depende da semana e ano
- **Total esperado de arquivos de simulação: ~140-145** (não ~90 como estimado anteriormente)

**Exemplo de distribuição por semana (2025):**
```
Week 1:  preBR, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 fases)
Week 4:  preDublinGame, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 fases)
Week 7:  preLondon, preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (8 fases)
Week 13: preTNF, posTNF, posThanksgiving, preSundayGames, preMNF, preWaivers, posWaivers, final (8 fases)
Outras:  preTNF, posTNF, preSundayGames, preMNF, preWaivers, posWaivers, final (7 fases típicas)
```

**Código para listar fases disponíveis:**
```r
# Listar todas as fases disponíveis para uma semana
list_simulation_phases <- function(week, season_dir = "dudes/2025/") {
  pattern <- paste0("^simulation_v\\d+_week", week, "_(.+)\\.rds$")
  files <- list.files(season_dir, pattern = pattern)

  phases <- gsub(pattern, "\\1", files)
  phases <- gsub("\\.rds$", "", phases)

  return(sort(phases))
}

# Exemplo: Week 13 (Thanksgiving)
phases_week13 <- list_simulation_phases(13)
# [1] "final" "posThanksgiving" "posTNF" "preMNF" "preSundayGames"
# [6] "preTNF" "preWaivers" "posWaivers"
```
```

---

### 3. Contagem Total de Arquivos

**Arquivo:** `dudes_DATAMODEL.md` - Linha 7 e Seção "Estatísticas do Sistema"

**Problema:** Documentação indica ~245 arquivos, mas análise encontrou ~280 arquivos.

**Correção necessária:**

#### dudes_DATAMODEL.md (linha 7)

**ANTES:**
```markdown
**Total de Arquivos RDS:** ~245 arquivos
```

**DEPOIS:**
```markdown
**Total de Arquivos RDS:** ~280 arquivos (245 base + 35 simulações adicionais/backups)
```

#### dudes_DATAMODEL.md (linha ~972-986)

**ANTES:**
```markdown
### Volume de Dados

| Categoria | Arquivos | Tamanho Aproximado |
|-----------|----------|----------------------|
| Weekly Scrapes | 17 × 2 = 34 | ~50 MB |
| Weekly Projections | 17 × 4 = 68 | ~80 MB |
| Simulations | ~90 | ~45 MB |
| Rankings | 17 × 2 = 34 | ~2 MB |
| Core Files | 5 | ~15 MB |
| Draft Files | 5 | ~2 MB |
| Season Aggregates | 8 | ~8 MB |
| **TOTAL (2025)** | **~245** | **~200 MB** |
```

**DEPOIS:**
```markdown
### Volume de Dados

| Categoria | Arquivos | Tamanho Aproximado | Notas |
|-----------|----------|--------------------|-----------------------|
| Weekly Scrapes | 17 × 2 = 34 | ~50 MB | Includes week0 |
| Weekly Projections | 17 × 4 = 68 | ~80 MB | 4 patterns per week |
| Simulations | ~140 | ~70 MB | Includes event-specific phases |
| Rankings | 17 × 2 = 34 | ~2 MB | Team + position rankings |
| Core Files | 5 | ~15 MB | Players, projections, errors |
| Draft Files | 6 | ~2 MB | Includes HTML export |
| Season Aggregates | 9 | ~10 MB | Includes timestamped versions |
| Auxiliary Files | 3 | <1 MB | missing_player_ids, etc. |
| **TOTAL (2025)** | **~280** | **~230 MB** | Varies by season completeness |

**Nota sobre Simulações:**
- Fases padrão: ~119 arquivos (7 fases × 17 semanas)
- Fases de eventos especiais: +20-25 arquivos (variável por temporada)
- Total real: ~140-145 arquivos de simulação
```

---

## 🟡 Correções Menores

### 4. Documentar Arquivos Auxiliares

**Arquivo:** `dudes_DATA_DICTIONARY.md` - Seção "Lookup/Reference Files"

**Adicionar nova subseção:**

```markdown
### Auxiliary Files (Not in Standard Categories)

#### `missing_player_ids.rds` (2024)

**Description:** Manual player ID mappings for players not automatically detected by ffanalytics scraping.

**Location:** Root of season directory (e.g., `dudes/2024/missing_player_ids.rds`)

**Structure:** Tibble (same schema as `ffa_player_ids` from app/ project)

**Columns:**
- `id` - Internal player ID
- `nfl_id` - NFL.com ID
- `stats_id`, `cbs_id`, `espn_id`, etc. - Platform-specific IDs

**Usage:**
```r
# Consolidate automatic + manual IDs
proj_data <- readRDS("dudes/2024/points_projection.rds")
manual_ids <- readRDS("dudes/2024/missing_player_ids.rds")

# Merge if needed (usually pre-merged in pipeline)
# all_ids <- bind_rows(auto_ids, manual_ids)
```

**Status:** Present in 2024, may not exist in all seasons. Created ad-hoc when scraping fails to identify players.

---

#### `draft_picks.html` (2025, 2024)

**Description:** HTML export of draft picks for human-readable viewing.

**Location:** Root of season directory

**Content:** Rendered table of `draft_picks.rds` data with formatting

**Usage:** Open in browser for quick draft review. Not used in data pipelines.

---

#### `draft_simultaions.rds` (2024 only) - **DEPRECATED**

**Description:** Appears to be a typo variant of "simulations". Contains draft-related simulation data.

**Status:** Present in 2024 but not 2025. Likely consolidated into standard simulation files in 2025.

**Action:** Ignore this file in new analysis. Use `simulation_v5_week0_*.rds` for pre-season/draft simulations instead.
```

---

### 5. Clarificar Week 0 vs Season Files

**Arquivo:** `dudes_DATA_DICTIONARY.md` - Seção "Understanding Week 0 vs Season Files"

**Adicionar callout visual:**

#### dudes_DATA_DICTIONARY.md (linha ~663-685)

**ADICIONAR no início da seção:**

```markdown
### Understanding Week 0 vs Season Files

> **⚠️ IMPORTANTE:** `week0` e `season` são **formatos diferentes para os mesmos dados**!
>
> - `week0_*.rds` = Formato semanal para dados de temporada completa (17 semanas somadas)
> - `season_*.rds` = Formato especializado para dados de temporada completa
> - **Ambos contêm estatísticas idênticas** - escolha baseado no pipeline

**Quando usar cada formato:**

| Use `week0_*.rds` se... | Use `season_*.rds` se... |
|------------------------|--------------------------|
| Seu código loop por `week{X}` | Análise específica de temporada completa |
| Pipeline processa weeks 0-17 | Preparação de draft |
| Compatibilidade com código existente | Comparação multi-temporada |
| Estrutura week{X} é mandatória | Clareza semântica é prioridade |

[restante da seção continua...]
```

---

### 6. Corrigir Typo de Data

**Arquivo:** `dudes/2025/season_player_proj_sites_20280826.rds`

**Problema:** Arquivo tem data `20280826` (2028) em vez de `20250826` (2025).

**Ação:** Renomear arquivo:

```bash
# Comando para renomear
cd dudes/2025/
mv season_player_proj_sites_20280826.rds season_player_proj_sites_20250826.rds
```

**Documentação:** Nenhuma mudança de documentação necessária após correção.

---

## ➕ Adições à Documentação

### 7. Seção sobre Evolução de Schema entre Temporadas

**Arquivo:** `dudes_DATAMODEL.md`

**Adicionar nova seção principal (após "Referência Cruzada"):**

```markdown
---

## 🔄 Evolução de Schema Entre Temporadas

### Mudanças de Nomenclatura e Estrutura

#### 2024 → 2025

**Arquivos de Temporada - Versionamento com Timestamp:**

| Mudança | 2024 | 2025 |
|---------|------|------|
| Season scrapes | `season_scrap.rds` | `season_scrap_20250826.rds` |
| Season projections | `season_projtable.rds` | `season_projtable_20250826.rds` |
| Season site projections | `season_player_proj_sites.rds` | `season_player_proj_sites_20250826.rds` |

**Fases de Simulação - Eventos Especiais:**

| Adicionado em 2025 | Removido de 2024 |
|-------------------|------------------|
| `preBR` (Brasil) | `posBrasilGame` |
| `preDublinGame` | `preXMAS` |
| `posThanksgiving` | `posMNF` |
| `preLondon` (simplificado) | `preLondonGame` |

**Arquivos Auxiliares:**

| Arquivo | Status 2024 | Status 2025 |
|---------|------------|-------------|
| `missing_player_id.rds` (singular) | ✓ | ✗ Removido |
| `missing_player_ids.rds` (plural) | ✓ | ✓ Mantido |
| `draft_simultaions.rds` (typo) | ✓ | ✗ Removido |
| `draft_picks.html` | ✓ | ✓ Mantido |

### Guidelines para Análise Cross-Temporal

**1. Verificar disponibilidade de arquivos por temporada:**

```r
# Função para verificar se arquivo existe com fallback
read_season_file_safe <- function(filename, season_year) {
  season_dir <- paste0("dudes/", season_year, "/")

  # Tentar versões timestampadas (2025+)
  if (season_year >= 2025) {
    pattern <- gsub("\\.rds$", "_\\d{8}\\.rds$", filename)
    timestamped <- list.files(season_dir, pattern = pattern, full.names = TRUE)

    if (length(timestamped) > 0) {
      return(readRDS(max(timestamped)))
    }
  }

  # Fallback para nome canônico
  canonical_path <- file.path(season_dir, filename)
  if (file.exists(canonical_path)) {
    return(readRDS(canonical_path))
  }

  stop("Arquivo não encontrado: ", filename, " em temporada ", season_year)
}

# Uso
season_2024 <- read_season_file_safe("season_scrap.rds", 2024)
season_2025 <- read_season_file_safe("season_scrap.rds", 2025)
```

**2. Fases de simulação podem variar:**

```r
# Carregar todas as fases disponíveis para uma semana/ano
load_all_simulation_phases <- function(week, year) {
  season_dir <- paste0("dudes/", year, "/")
  pattern <- paste0("simulation_v\\d+_week", week, "_.*\\.rds$")

  files <- list.files(season_dir, pattern = pattern, full.names = TRUE)

  # Extrair nomes de fases
  phases <- basename(files) %>%
    gsub("simulation_v\\d+_week\\d+_", "", .) %>%
    gsub("\\.rds$", "", .)

  return(setNames(files, phases))
}

# Comparar fases disponíveis
phases_2024_w13 <- load_all_simulation_phases(13, 2024)
phases_2025_w13 <- load_all_simulation_phases(13, 2025)

# Fases presentes em 2025 mas não em 2024
setdiff(names(phases_2025_w13), names(phases_2024_w13))
# [1] "posThanksgiving"
```

**3. Usar arquivos comuns para análise longitudinal:**

```r
# Arquivos seguros para comparação cross-temporal (2019-2025)
safe_for_comparison <- c(
  "week{1-17}_scrap.rds",
  "week{1-17}_players_projections.rds",
  "weekly_proj_table_{1-17}.rds",
  "rank_week{1-17}.rds",
  "players_points.rds",
  "points_projection.rds",
  "draft_picks.rds"
)

# Carregar múltiplos anos com segurança
load_multi_year <- function(pattern, weeks = 1:17, years = 2024:2025) {
  results <- list()

  for (year in years) {
    year_data <- list()
    for (week in weeks) {
      filename <- glue::glue(pattern)  # pattern usa {week}
      filepath <- file.path("dudes", year, filename)

      if (file.exists(filepath)) {
        year_data[[paste0("week", week)]] <- readRDS(filepath) %>%
          mutate(season = year, week = week)
      }
    }
    results[[as.character(year)]] <- bind_rows(year_data)
  }

  return(bind_rows(results, .id = "season"))
}

# Exemplo: Comparar projeções de todos os weeks 1-17 em 2024-2025
all_projections <- load_multi_year("week{week}_players_projections.rds")
```

### Arquivos Estáveis Cross-Temporal

Estes arquivos **mantêm estrutura consistente** entre todas as temporadas (2019-2025):

#### Arquivos Semanais (100% compatíveis)
- ✅ `week{1-17}_scrap.rds`
- ✅ `week{1-17}_players_projections.rds`
- ✅ `weekly_proj_table_{1-17}.rds`
- ✅ `weekly_proj_player_site_{1-17}.rds`
- ✅ `rank_week{1-17}.rds`
- ✅ `rankAgainstPosition_week{1-17}.rds`

#### Arquivos Core (100% compatíveis)
- ✅ `players_points.rds`
- ✅ `points_projection.rds`
- ✅ `points_projection_and_errors.rds`

#### Arquivos de Draft (100% compatíveis)
- ✅ `draft_picks.rds`
- ✅ `draft_pick_projections.rds`

### Arquivos com Variação entre Temporadas

#### Variação de Nomenclatura
- ⚠️ `season_*.rds` → 2024: nome canônico | 2025: timestampado
- ⚠️ Arquivos auxiliares (presença varia por temporada)

#### Variação de Conteúdo
- ⚠️ `simulation_v5_week{X}_{phase}.rds` → Fases variam por calendário NFL
- ⚠️ `season_20XX_projections_errors.rds` → Referência rola anualmente (2023→2024→2025)

**Recomendação:** Sempre verificar existência de arquivo antes de assumir presença em análises multi-temporada.
```

---

### 8. Função Auxiliar para Detecção de Versão

**Arquivo:** `dudes_DATAMODEL.md` - Seção "Guia de Manipulação"

**Adicionar nova subseção:**

```markdown
### Funções Auxiliares para Compatibilidade Multi-Temporada

#### Detector de Formato de Arquivo

```r
#' Detecta formato de arquivo de temporada (canônico vs timestampado)
#'
#' @param base_name Nome base do arquivo (ex: "season_scrap")
#' @param season_dir Diretório da temporada (ex: "dudes/2025/")
#' @return Lista com $path (caminho completo) e $type ("canonical" ou "timestamped")
detect_season_file_format <- function(base_name, season_dir = "dudes/2025/") {
  # Tentar canônico primeiro
  canonical <- file.path(season_dir, paste0(base_name, ".rds"))

  if (file.exists(canonical)) {
    return(list(path = canonical, type = "canonical"))
  }

  # Buscar timestampado
  pattern <- paste0("^", base_name, "_\\d{8}\\.rds$")
  timestamped <- list.files(season_dir, pattern = pattern, full.names = TRUE)

  if (length(timestamped) > 0) {
    latest <- max(timestamped)  # Versão mais recente
    timestamp <- gsub(".*_(\\d{8})\\.rds$", "\\1", basename(latest))
    return(list(
      path = latest,
      type = "timestamped",
      timestamp = timestamp
    ))
  }

  stop("Arquivo não encontrado: ", base_name, " em ", season_dir)
}

# Uso
file_info <- detect_season_file_format("season_scrap", "dudes/2025/")
season_data <- readRDS(file_info$path)

cat("Formato:", file_info$type, "\n")
if (!is.null(file_info$timestamp)) {
  cat("Gerado em:", file_info$timestamp, "\n")
}
```

#### Carregador Universal de Arquivos de Temporada

```r
#' Carrega arquivo de temporada com fallback automático entre formatos
#'
#' @param base_name Nome base do arquivo
#' @param season_year Ano da temporada (2019-2025)
#' @param prefer_latest Se TRUE, usa versão timestampada mais recente quando disponível
#' @return Data frame/list do arquivo RDS
load_season_file <- function(base_name, season_year, prefer_latest = TRUE) {
  season_dir <- file.path("dudes", season_year)

  # Detectar formato
  file_info <- tryCatch(
    detect_season_file_format(base_name, season_dir),
    error = function(e) NULL
  )

  if (is.null(file_info)) {
    stop("Arquivo ", base_name, " não encontrado em temporada ", season_year)
  }

  # Carregar
  data <- readRDS(file_info$path)

  # Adicionar metadata
  attr(data, "file_format") <- file_info$type
  attr(data, "season") <- season_year
  if (!is.null(file_info$timestamp)) {
    attr(data, "timestamp") <- file_info$timestamp
  }

  return(data)
}

# Exemplos
season_2024 <- load_season_file("season_scrap", 2024)
season_2025 <- load_season_file("season_scrap", 2025)

# Verificar metadata
attributes(season_2025)[c("file_format", "season", "timestamp")]
# $file_format
# [1] "timestamped"
# $season
# [1] 2025
# $timestamp
# [1] "20250826"
```

#### Comparador de Disponibilidade de Fases de Simulação

```r
#' Compara fases de simulação disponíveis entre temporadas
#'
#' @param week Semana (1-17)
#' @param years Vetor de anos a comparar
#' @return Data frame com disponibilidade de cada fase por ano
compare_simulation_phases <- function(week, years = c(2024, 2025)) {
  results <- list()

  for (year in years) {
    season_dir <- file.path("dudes", year)
    pattern <- paste0("simulation_v\\d+_week", week, "_.*\\.rds$")

    files <- list.files(season_dir, pattern = pattern)
    phases <- gsub(paste0("simulation_v\\d+_week", week, "_"), "", files)
    phases <- gsub("\\.rds$", "", phases)

    results[[as.character(year)]] <- data.frame(
      phase = phases,
      available = TRUE,
      stringsAsFactors = FALSE
    )
  }

  # Combinar em formato wide
  all_phases <- unique(unlist(lapply(results, function(x) x$phase)))

  comparison <- data.frame(phase = all_phases)
  for (year in names(results)) {
    comparison[[year]] <- comparison$phase %in% results[[year]]$phase
  }

  return(comparison)
}

# Uso
phases_comparison <- compare_simulation_phases(13, years = c(2024, 2025))
print(phases_comparison)
#              phase  2024  2025
# 1            final  TRUE  TRUE
# 2       preWaivers  TRUE  TRUE
# 3       posWaivers  TRUE  TRUE
# 4           preMNF  TRUE  TRUE
# 5           preTNF  TRUE  TRUE
# 6          posTNF  TRUE  TRUE
# 7  preSundayGames  TRUE  TRUE
# 8  posThanksgiving FALSE  TRUE  # Novo em 2025
# 9          preXMAS  TRUE FALSE  # Removido em 2025
```
```

---

## 💻 Exemplos de Código Atualizados

### 9. Carregar Dados de Temporada (2025+)

**Arquivo:** `dudes_DATAMODEL.md` - Seção "Como Ler Arquivos RDS"

**Atualizar exemplo:**

#### dudes_DATAMODEL.md (linha ~673-683)

**ANTES:**
```r
# Ler um arquivo RDS
data <- readRDS("data/week3_players_projections.rds")
```

**DEPOIS:**
```r
# Ler um arquivo RDS semanal (funcionamento idêntico em todas as temporadas)
data <- readRDS("dudes/2025/week3_players_projections.rds")

# Ler arquivo de temporada (2025+: usar função auxiliar para lidar com timestamps)
season_data <- load_season_file("season_scrap", season_year = 2025)

# Ou manualmente buscar versão timestampada
season_files <- list.files("dudes/2025/",
                          pattern = "^season_scrap_\\d{8}\\.rds$",
                          full.names = TRUE)
if (length(season_files) > 0) {
  season_data <- readRDS(max(season_files))  # Versão mais recente
} else {
  season_data <- readRDS("dudes/2025/season_scrap.rds")  # Fallback
}
```

---

### 10. Explorar Simulação com Fases Variáveis

**Arquivo:** `dudes_DATAMODEL.md` - Seção "Explorar Simulação"

**Atualizar exemplo:**

#### dudes_DATAMODEL.md (linha ~740-756)

**ADICIONAR antes do exemplo existente:**

```r
# IMPORTANTE: Sempre verificar quais fases existem antes de carregar
available_phases <- list.files("dudes/2025/",
                              pattern = "simulation_v\\d+_week13_.*\\.rds$")
available_phases <- gsub("simulation_v\\d+_week13_", "", available_phases)
available_phases <- gsub("\\.rds$", "", available_phases)

cat("Fases disponíveis para Week 13:\n")
print(sort(available_phases))
# [1] "final" "posThanksgiving" "posTNF" "preMNF" "preSundayGames"
# [6] "preTNF" "preWaivers" "posWaivers"

# Verificar se fase específica existe
if ("posThanksgiving" %in% available_phases) {
  sim_thanksgiving <- readRDS("dudes/2025/simulation_v5_week13_posThanksgiving.rds")
  cat("Simulação Thanksgiving carregada.\n")
} else {
  cat("Fase Thanksgiving não disponível nesta temporada.\n")
}

# [restante do exemplo original continua...]
```

---

## 📊 Resumo de Prioridades

### Crítico (implementar imediatamente)
1. ✅ Documentar estratégia de versionamento com timestamp
2. ✅ Adicionar todas as fases de simulação (16 fases totais)
3. ✅ Corrigir contagens totais de arquivos (~280, não ~245)

### Importante (implementar em próxima revisão)
4. ✅ Documentar arquivos auxiliares
5. ✅ Adicionar seção de evolução de schema
6. ✅ Funções auxiliares para compatibilidade

### Opcional (melhoria incremental)
7. ✅ Clarificar week0 vs season com callout visual
8. ✅ Corrigir typo de data no arquivo (20280826 → 20250826)

---

## 🔧 Checklist de Implementação

- [ ] Atualizar `dudes_DATAMODEL.md` linha 7 (contagem total)
- [ ] Atualizar `dudes_DATAMODEL.md` linha ~337-350 (season files com timestamp)
- [ ] Atualizar `dudes_DATAMODEL.md` linha ~972-986 (tabela de volume)
- [ ] Adicionar nova seção "Evolução de Schema" ao `dudes_DATAMODEL.md`
- [ ] Atualizar `dudes_DATA_DICTIONARY.md` linha ~362-373 (fases de simulação)
- [ ] Adicionar subseção "Estratégia de Versionamento" ao `dudes_DATA_DICTIONARY.md` linha ~520
- [ ] Adicionar subseção "Auxiliary Files" ao `dudes_DATA_DICTIONARY.md` linha ~747
- [ ] Adicionar callout visual à seção "Week 0 vs Season" linha ~663
- [ ] Adicionar subseção "Funções Auxiliares" ao `dudes_DATAMODEL.md` linha ~669
- [ ] Atualizar exemplos de código linha ~673-683 e ~740-756 do `dudes_DATAMODEL.md`
- [ ] Renomear arquivo `dudes/2025/season_player_proj_sites_20280826.rds` → `*_20250826.rds`

---

**Documento gerado em:** 2026-03-07
**Próxima revisão sugerida:** Após implementação das correções críticas
