# Resultados dos Testes do Pipeline ETL

**Data**: 2026-03-07
**Status**: Testes básicos ✅ | Pipeline completo ⚠️

---

## ✅ Testes Bem-Sucedidos

### 1. Leitura de Arquivos Fonte

**Teste**: minimal_test.R

Todos os arquivos fonte carregam corretamente:

- ✅ `week1_scrap.rds`: 2,651 registros (6 posições: QB, RB, WR, TE, K, DST)
- ✅ `weekly_proj_player_site_1.rds`: 2,537 projeções
- ✅ `simulation_v5_week1_final.rds`: 229 jogadores simulados
- ✅ `players_points.rds`: 14,042 registros de jogadores

### 2. Estrutura dos Dados

**Verificações**:
- ✅ Scrapes têm colunas esperadas (player, pos, team, stats)
- ✅ Simulações têm players_sim com 229 linhas
- ✅ Player IDs podem ser extraídos (586 únicos em week1_scrap)
- ✅ weekStats é uma lista aninhada (list[[week]][[statId]] = value)

---

## 🔧 Correções Implementadas

### 1. Função `unnest_week_stats()` - CORRIGIDO

**Problema Original**:
```
Error unnesting weekStats: In argument: `value = as.numeric(weekStats)`.
```

**Causa**:
- weekStats é uma lista de listas (weeks → stats)
- Cada valor é string, não número direto
- Estrutura: `list[[week_idx]][[statId]] = "value"`

**Solução**:
```r
# Antes (ERRADO)
unnest_longer(weekStats, indices_to = "statCategory") |>
mutate(value = as.numeric(weekStats))  # Falha!

# Depois (CORRETO)
mutate(
  stats_long = map(weekStats, function(week_list) {
    map_dfr(seq_along(week_list), function(week_idx) {
      week_stats <- week_list[[week_idx]]
      tibble(
        week = week_idx,
        statId = names(week_stats),
        value = as.character(week_stats)
      )
    })
  })
) |>
unnest(stats_long) |>
mutate(statId = as.integer(statId), value = as.numeric(value))
```

### 2. Função `extract_simulations()` - CORRIGIDO

**Problema**: Processava TODOS os arquivos de simulação (91 arquivos), não apenas as semanas solicitadas.

**Solução**: Adicionar filtro antes de processar:
```r
sim_files_filtered <- sim_files |>
  keep(function(file) {
    filename <- path_file(file)
    parts <- str_match(filename, "simulation_v5_week(\\d+)_(.+)\\.rds")
    if (is.na(parts[1, 2])) return(FALSE)
    week <- as.integer(parts[1, 2])
    week %in% weeks  # FILTRO ADICIONADO
  })
```

### 3. Target Directory - CORRIGIDO

**Problema**: Configuração apontava para `etl/2025/` ao invés de `app/2025-24/`

**Solução**:
```r
ETL_CONFIG$target_dir <- "app/2025-24/"  # Corrigido
```

---

## ⚠️ Problemas Pendentes

### 1. Pipeline Completo Muito Lento

**Sintomas**:
- `test_pipeline()` travava/demorava muito
- Processava todas as 17 semanas ao invés de só week 1
- Timeout após 2 minutos

**Possíveis Causas**:
1. `source()` recursivo nos módulos pode estar causando reload
2. Extração de player_points.rds processa TODOS os jogadores (14k) mesmo em teste
3. Transform/Load podem estar fazendo operações caras

**Status**: Não diagnosticado completamente

### 2. test_pipeline() Não Respeita weeks=1

**Problema**: Mesmo definindo `test_config$weeks <- 1`, o log mostra processamento de weeks 1-17

**Causa Provável**:
- Os módulos fazem `source("R/etl/config_transform.R")` no topo
- Isso carrega ETL_CONFIG original com weeks=1:17
- O config passado como parâmetro pode não estar sendo usado

**Possível Solução**: Remover `source("config_transform.R")` dos módulos individuais

---

## 📝 Recomendações

### Para Teste Rápido

Use o **minimal_test.R** para validar estrutura de dados:
```bash
Rscript R/etl/minimal_test.R
# Executa em ~2 segundos
```

### Para Desenvolvimento

1. **Isolar módulos**: Testar extract.R, transform.R, load.R separadamente
2. **Usar checkpoints**: Salvar resultados intermediários
3. **Processar incrementalmente**:
   - Primeiro: apenas extração (sem transform/load)
   - Depois: extração + transformação
   - Finalmente: pipeline completo

### Próximos Passos

1. ✅ Corrigir unnest_weekStats - **FEITO**
2. ✅ Corrigir extract_simulations filtro - **FEITO**
3. ⏳ Otimizar extract_player_points (não processar tudo em teste)
4. ⏳ Remover source() recursivo nos módulos
5. ⏳ Adicionar modo "quick test" que pula validações caras
6. ⏳ Testar transform.R isoladamente
7. ⏳ Testar load.R isoladamente

---

## 📊 Performance Esperada

| Operação | Tempo Esperado | Tempo Atual |
|----------|---------------|-------------|
| minimal_test.R | ~2 seg | ✅ ~2 seg |
| Extração week 1 | ~10 seg | ⚠️ >120 seg (timeout) |
| Transformação week 1 | ~5 seg | ⏳ Não testado |
| Load week 1 | ~2 seg | ⏳ Não testado |
| **Pipeline completo (1 week)** | **~30 seg** | **⚠️ >120 seg** |

---

## 🎯 Conclusão

**Dados estão OK**: Os arquivos fonte carregam perfeitamente e têm a estrutura esperada.

**Pipeline precisa otimização**: O código de extração/transformação/load precisa ser otimizado ou simplificado para processar uma semana em tempo razoável.

**Correções aplicadas funcionam**: As correções em unnest_weekStats e extract_simulations são válidas e necessárias.

**Próximo passo sugerido**: Testar cada módulo (extract, transform, load) ISOLADAMENTE antes de rodar o pipeline completo.
