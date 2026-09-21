# 🔄 ETL Pipeline: dudes/ → app/

Sistema de transformação de dados do formato **dudes/** (arquivos semanais) para o formato **app/** (databases relacionais com dm).

## 📁 Arquivos

```
R/etl/
├── README.md                      # Este arquivo
├── transform_dudes_to_app.R       # Script principal (orquestrador)
├── config_transform.R             # Configurações do pipeline
├── utils_transform.R              # Funções utilitárias
├── extract.R                      # Fase 1: Extração
├── transform.R                    # Fase 2: Transformação
└── load.R                         # Fase 3: Loading e validação
```

## 🚀 Uso Rápido

### Modo Interativo (R)

```r
# Carregar o script
source("R/etl/transform_dudes_to_app.R")

# Executar pipeline completo
main()

# Modo teste (apenas semana 1)
test_pipeline()

# Processar em lotes
run_batch(weeks = 1:17)
```

### Linha de Comando

```bash
# Pipeline completo
Rscript R/etl/transform_dudes_to_app.R

# Modo teste
Rscript R/etl/transform_dudes_to_app.R --test

# Modo batch
Rscript R/etl/transform_dudes_to_app.R --batch
```

## ⚙️ Configuração

Editar `config_transform.R`:

```r
ETL_CONFIG <- list(
  # Diretórios
  source_dir = "dudes/2025/",      # Origem
  target_dir = "app/2025-24/",     # Destino

  # Parâmetros
  season = 2025,
  weeks = 1:17,

  # Opções
  parallel = TRUE,
  batch_size = 5,
  strict_mode = TRUE,              # Falha em violações de constraint
  save_intermediate = TRUE         # Salvar checkpoints
)
```

## 📊 Fluxo de Dados

```
┌─────────────────────────────────────────────────┐
│ FASE 1: EXTRACTION                              │
├─────────────────────────────────────────────────┤
│ • Ler week{X}_scrap.rds (17 semanas)           │
│ • Ler weekly_proj_player_site_{X}.rds          │
│ • Ler simulation_v5_week{X}_{phase}.rds        │
│ • Ler players_points.rds                       │
│ ✓ Checkpoint: extraction.rds                   │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ FASE 2: TRANSFORMATION                          │
├─────────────────────────────────────────────────┤
│ • Consolidar 245 arquivos → 7 databases        │
│ • Criar PKs e FKs                              │
│ • Agregar projeções (average, robust, weighted)│
│ • Calcular ranks e tiers                       │
│ • Desnormalizar nested lists                   │
│ ✓ Checkpoint: transformation.rds               │
└─────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ FASE 3: LOADING & VALIDATION                    │
├─────────────────────────────────────────────────┤
│ • Validar constraints (dm_examine_constraints) │
│ • Validar cardinalidades                       │
│ • Salvar 7 .rds com dm objects                 │
│ • Gerar ETL_SUMMARY.md                         │
│ ✓ Output: app/2025-24/*.rds                    │
└─────────────────────────────────────────────────┘
```

## 📦 Databases Gerados

| Database | Tabelas | Descrição |
|----------|---------|-----------|
| `ffa_db.rds` | 5 | Projeções de múltiplas fontes |
| `nfl_stats_db.rds` | 4 | Estatísticas de jogadores |
| `dudes_simulation_db.rds` | 2 | Simulações Monte Carlo |
| `nfl_teams_db.rds` | 2 | Times e proprietários |
| `nfl_players_db.rds` | 2 | Jogadores e lesões |
| `nfl_round_db.rds` | 5 | Matchups e rosters |
| `nfl_recap_db.rds` | 1 | Narrativas de jogos |

## 🔍 Validações

### Automáticas

✅ **Primary Keys**: Verifica unicidade
✅ **Foreign Keys**: Verifica integridade referencial
✅ **Cardinalidades**: Verifica relacionamentos 1:N, N:1
✅ **Counts**: Verifica número mínimo de registros
✅ **NULLs**: Verifica colunas obrigatórias

### Strict Mode

Com `strict_mode = TRUE`:
- Pipeline **aborta** se houver violações
- Use para produção

Com `strict_mode = FALSE`:
- Pipeline **continua** com warnings
- Use para desenvolvimento/testes

## 🛠️ Checkpoints

O sistema salva checkpoints após cada fase em `.claude/etl_checkpoints/`:

```r
# Listar checkpoints disponíveis
list_checkpoints(ETL_CONFIG$checkpoint_dir)

# Carregar checkpoint específico
data <- load_checkpoint("extraction", ETL_CONFIG$checkpoint_dir)

# Limpar todos os checkpoints
clear_checkpoints(ETL_CONFIG$checkpoint_dir)
```

**Uso:**
- Se o pipeline falhar, você pode resumir da última fase completa
- Economiza tempo durante desenvolvimento

## 📋 Outputs

### Databases (.rds)

Salvos em `app/2025-24/`:
- `ffa_db.rds`
- `nfl_stats_db.rds`
- `dudes_simulation_db.rds`
- `nfl_teams_db.rds`
- `nfl_players_db.rds`
- `nfl_round_db.rds`
- `nfl_recap_db.rds`

### Relatório (ETL_SUMMARY.md)

```markdown
# ETL Transformation Summary Report

**Generated:** 2026-03-07 14:32:15
**Source:** dudes/2025/
**Target:** app/2025-24/
**Season:** 2025

## Database Summary

### ✅ ffa_db

| Table | Rows |
|-------|------|
| `ffa_scrape` | 39 |
| `ffa_player_ids` | 849 |
| `ffa_players` | 858 |
| `ffa_projtable` | 61,332 |
| `ffa_proj_source_points` | 103,266 |
| **Total** | **165,344** |
```

## 🐛 Troubleshooting

### Erro: "File not found"

```r
# Verificar arquivos disponíveis
fs::dir_ls("dudes/2025/", regexp = "week\\d+_scrap.rds")

# Ajustar configuração
ETL_CONFIG$weeks <- 1:10  # Só processar semanas disponíveis
```

### Erro: "Constraint violation"

```r
# Desabilitar strict mode para ver todos os erros
ETL_CONFIG$strict_mode <- FALSE
main(ETL_CONFIG)

# Verificar relatório de constraints
dm_obj$ffa_db %>% dm_examine_constraints()
```

### Erro: "Memory exhausted"

```r
# Processar em lotes menores
ETL_CONFIG$batch_size <- 3  # Processar 3 semanas por vez
run_batch(1:17, ETL_CONFIG)

# Ou processar semanas individuais
ETL_CONFIG$weeks <- 1
main(ETL_CONFIG)
```

### Pipeline muito lento

```r
# Habilitar processamento paralelo
ETL_CONFIG$parallel <- TRUE
ETL_CONFIG$n_cores <- 4  # Ajustar para seu sistema
main(ETL_CONFIG)
```

## 🔧 Customização

### Adicionar novo database

1. Criar função de transformação em `transform.R`:

```r
transform_to_my_db <- function(extracted_data, config) {
  # Criar tabelas
  table1 <- ...
  table2 <- ...

  # Criar dm object
  dm(table1, table2) %>%
    dm_add_pk(table1, id) %>%
    dm_add_pk(table2, id) %>%
    dm_add_fk(table2, id, table1)
}
```

2. Adicionar ao `transform_all()`:

```r
transform_all <- function(extracted_data, config) {
  # ... código existente ...

  results$my_db <- transform_to_my_db(extracted_data, config)

  results
}
```

3. Database será automaticamente validado e salvo!

### Adicionar nova validação

Editar `load.R`:

```r
validate_dm_object <- function(dm_obj, db_name, config) {
  # ... validações existentes ...

  # Nova validação customizada
  if (db_name == "ffa_db") {
    # Verificar algo específico
    if (some_condition) {
      log_message("Custom validation failed", "warning")
      validation_passed <- FALSE
    }
  }

  # ... resto do código ...
}
```

## 📈 Performance

### Tempos Esperados

| Fase | Tempo (17 semanas) |
|------|--------------------|
| Extraction | ~2-3 min |
| Transformation | ~3-5 min |
| Loading | ~1-2 min |
| **Total** | **~6-10 min** |

*Testado em MacBook Pro M1, 16GB RAM*

### Otimizações

✅ **Já implementadas:**
- Checkpoints (evita reprocessamento)
- Batch processing (controla memória)
- Processamento paralelo (opcional)

🔄 **Possíveis melhorias:**
- Usar `data.table` para operações grandes
- Cachear IDs de jogadores
- Processar apenas arquivos novos (incremental)

## 📚 Referências

### Documentação

- [dudes_DATAMODEL.md](../../dudes_DATAMODEL.md) - Modelo origem
- [app_DATAMODEL.md](../../app_DATAMODEL.md) - Modelo destino
- [dudes_DATA_DICTIONARY.md](../../dudes_DATA_DICTIONARY.md) - Dicionário origem
- [app_DATA_DICTIONARY.md](../../app_DATA_DICTIONARY.md) - Dicionário destino

### Pacotes Utilizados

- **tidyverse**: Manipulação de dados
- **dm**: Data modeling e relacionamentos
- **fs**: Operações de arquivo
- **cli**: Interface de linha de comando
- **glue**: String interpolation

## 🤝 Contribuindo

### Adicionar funcionalidade

1. Editar módulo apropriado (`extract.R`, `transform.R`, `load.R`)
2. Adicionar função ao export no final do arquivo
3. Documentar no README
4. Testar com `test_pipeline()`

### Reportar bug

Incluir:
- Comando executado
- Erro completo
- Arquivo `ETL_SUMMARY.md` (se gerado)
- Checkpoints disponíveis

## 📝 Changelog

### v1.0.0 (2026-03-07)

- ✨ Pipeline completo de ETL
- ✅ Validações automáticas de PKs/FKs
- 💾 Sistema de checkpoints
- 📊 Relatório de sumário
- 🔄 Processamento em lotes
- 🧪 Modo teste

---

**Maintainer**: DudesData ETL Team
**Created**: 2026-03-07
**Last Updated**: 2026-03-07
