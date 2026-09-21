# ⚡ Quick Start Guide - ETL Pipeline

## 🎯 Objetivo

Transformar dados de `dudes/2025/` (245 arquivos) → `app/2025-24/` (7 databases relacionais)

## 🚀 Em 3 Passos

### 1. Verificar Ambiente

```r
# Instalar pacotes necessários (se ainda não tiver)
install.packages(c("tidyverse", "dm", "fs", "cli", "lubridate", "glue"))

# Verificar que os arquivos fonte existem
fs::dir_exists("dudes/2025/")  # TRUE
length(fs::dir_ls("dudes/2025/", regexp = "\\.rds$"))  # ~245 arquivos
```

### 2. Testar Pipeline (Semana 1 Apenas)

```r
# Carregar o script
source("R/etl/transform_dudes_to_app.R")

# Rodar teste com 1 semana apenas (~30 segundos)
test_pipeline()
```

### 3. Executar Pipeline Completo

```r
# Pipeline completo (6-10 minutos)
main()
```

## ✅ Resultado Esperado

Após executar, você terá:

```
app/2025-24/
├── ffa_db.rds                     ✅ (7.4 MB)
├── nfl_stats_db.rds               ✅ (453 KB)
├── dudes_simulation_db.rds        ✅ (25 MB)
├── nfl_teams_db.rds               ✅ (1.4 KB)
├── nfl_players_db.rds             ✅ (164 KB)
├── nfl_round_db.rds               ✅ (39 KB)
├── nfl_recap_db.rds               ✅ (934 KB)
└── ETL_SUMMARY.md                 ✅ (relatório)
```

## 🔍 Validar Resultado

```r
# Carregar database gerado
ffa_db <- readRDS("app/2025-24/ffa_db.rds")

# Verificar estrutura
library(dm)
ffa_db %>% dm_draw()

# Verificar constraints
ffa_db %>% dm_examine_constraints()

# Ver contagens
ffa_db$ffa_projtable %>% count(season, week)
```

## ⚙️ Configurações Comuns

### Processar Apenas Algumas Semanas

```r
# Editar config
source("R/etl/config_transform.R")
ETL_CONFIG$weeks <- 1:5  # Apenas semanas 1-5

# Executar
main(ETL_CONFIG)
```

### Processar em Lotes (Economizar Memória)

```r
# Processar 3 semanas por vez
source("R/etl/transform_dudes_to_app.R")
ETL_CONFIG$batch_size <- 3
run_batch(1:17, ETL_CONFIG)
```

### Modo Debug (Não Falhar em Erros)

```r
ETL_CONFIG$strict_mode <- FALSE  # Só warnings, não para
main(ETL_CONFIG)
```

## 🐛 Problemas Comuns

### "File not found: dudes/2025/week1_scrap.rds"

**Causa**: Diretório fonte incorreto ou arquivos não existem

**Solução**:
```r
# Verificar arquivos disponíveis
fs::dir_ls("dudes/2025/", regexp = "week\\d+_scrap")

# Ajustar path em config_transform.R se necessário
ETL_CONFIG$source_dir <- "path/correto/"
```

### "Constraint violation in ffa_db"

**Causa**: Dados origem têm problemas de integridade

**Solução**:
```r
# Ver detalhes do erro
ffa_db %>% dm_examine_constraints() %>% filter(!ok)

# Rodar em modo não-estrito para continuar
ETL_CONFIG$strict_mode <- FALSE
main(ETL_CONFIG)
```

### Pipeline muito lento

**Causa**: Muitos dados, processamento sequencial

**Solução**:
```r
# Habilitar paralelização
ETL_CONFIG$parallel <- TRUE

# Processar em lotes menores
run_batch(1:17, ETL_CONFIG)
```

## 📊 Verificação Rápida

```r
# Após executar pipeline, verificar:

# 1. Todos os databases foram criados?
fs::dir_ls("app/2025-24/", regexp = "\\.rds$")
# Deve mostrar 7 arquivos + ETL_SUMMARY.md

# 2. Tamanhos corretos?
fs::file_size(fs::dir_ls("app/2025-24/", regexp = "\\.rds$"))
# ffa_db.rds deve ter ~7 MB
# dudes_simulation_db.rds deve ter ~25 MB

# 3. Estrutura OK?
library(dm)
ffa_db <- readRDS("app/2025-24/ffa_db.rds")
names(ffa_db)  # Deve mostrar 5 tabelas

# 4. Dados corretos?
ffa_db$ffa_projtable %>%
  summarise(
    n_records = n(),
    n_weeks = n_distinct(week),
    n_players = n_distinct(id)
  )
# n_weeks deve ser ~17
```

## 🎓 Próximos Passos

1. **Ler o relatório**: `app/2025-24/ETL_SUMMARY.md`
2. **Ver documentação completa**: `R/etl/README.md`
3. **Explorar databases**: Use scripts em `app/` para análises

## 🆘 Ajuda

```r
# Ver funções disponíveis
source("R/etl/transform_dudes_to_app.R")

# Lista de funções:
# - main()           # Pipeline completo
# - test_pipeline()  # Teste rápido
# - run_batch()      # Processar em lotes

# Ver configuração atual
ETL_CONFIG

# Limpar checkpoints
clear_checkpoints(ETL_CONFIG$checkpoint_dir)
```

## ⏱️ Tempos Esperados

| Ação | Tempo |
|------|-------|
| `test_pipeline()` | ~30 seg |
| `main()` completo | ~6-10 min |
| `run_batch()` | ~8-12 min |

*MacBook Pro M1, 16GB RAM*

---

**Ready to start?**

```r
source("R/etl/transform_dudes_to_app.R")
test_pipeline()  # Começa aqui! 🚀
```
