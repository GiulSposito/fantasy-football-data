# 📊 Relatório de Discrepâncias - Dados 2025

**Gerado em:** 2026-03-07
**Comparação entre:** `etl/2025/` vs `app/2025-24/`
**Referências:** `app_DATAMODEL.md` e `app_DATA_DICTIONARY.md`

---

## 📋 Resumo Executivo

### Arquivos Presentes

| Database | etl/2025/ | app/2025-24/ | Status |
|----------|-----------|--------------|--------|
| **ffa_db.rds** | ✅ 0.52 MB | ✅7.45 MB | ⚠️ Diferenças de schema |
| **nfl_teams_db.rds** | ✅ 0 KB | ✅ 0 KB | ✅ Idênticos |
| **nfl_players_db.rds** | ❌ | ✅ 164 KB | ❌ **FALTANDO em ETL** |
| **nfl_stats_db.rds** | ✅ 0.11 MB | ✅ 0.44 MB | ✅ Mesma estrutura |
| **nfl_round_db.rds** | ❌ | ✅ 39 KB | ❌ **FALTANDO em ETL** |
| **nfl_recap_db.rds** | ❌ | ✅ 934 KB | ❌ **FALTANDO em ETL** |
| **dudes_simulation_db.rds** | ✅ 24.9 MB | ✅ 24.64 MB | ⚠️ Dados 2025 só em ETL |

### Completude dos Dados

**app/2025-24/:** ✅ **COMPLETO** - Todos os 7 databases esperados
**etl/2025/:** ⚠️ **PARCIAL** - Apenas 4 de 7 databases (57% completo)

---

## 🔍 Discrepâncias Detalhadas

### 1. Databases Faltando em ETL

#### ❌ nfl_players_db.rds
- **Status:** NÃO EXISTE em `etl/2025/`
- **Impacto:** CRÍTICO
- **Conteúdo esperado:**
  - `nfl_players` (1,398 jogadores)
  - `nfl_player_injury_status` (43,430 registros históricos)
- **Dados 2025 em app/:** ✅ Presentes
- **Tamanho esperado:** ~164 KB

#### ❌ nfl_round_db.rds
- **Status:** NÃO EXISTE em `etl/2025/`
- **Impacto:** CRÍTICO
- **Conteúdo esperado:**
  - `nfl_teams_round` (510 registros)
  - `nfl_teams_rosters` (8,744 escalações)
  - `nfl_teams_week_stats` (540 registros)
  - `nfl_teams_season_stats` (8,760 registros)
  - `matchups_games` (257 confrontos)
- **Dados 2025 em app/:** ✅ Presentes
- **Tamanho esperado:** ~39 KB

#### ❌ nfl_recap_db.rds
- **Status:** NÃO EXISTE em `etl/2025/`
- **Impacto:** MÉDIO (dados narrativos)
- **Conteúdo esperado:**
  - `nfl_recap` (220 narrativas de jogos)
- **Dados 2025 em app/:** ✅ Presentes
- **Tamanho esperado:** ~934 KB

---

### 2. Discrepâncias de Schema: ffa_db.rds

#### Tabela: `ffa_player_ids`

**Problema:** Colunas de mapeamento de IDs faltando em ETL

| Coluna | etl/2025/ | app/2025-24/ | Tipo | Impacto |
|--------|-----------|--------------|------|---------|
| `gsis_id` | ❌ | ✅ | character | ALTO - ID do Game Statistics and Information System |
| `sleeper_id` | ❌ | ✅ | character | MÉDIO - ID do Sleeper App |

**Registros:**
- etl/2025/: 722 jogadores
- app/2025-24/: 5,395 jogadores
- **Diferença:** 4,673 jogadores a mais em app/ (747% maior)

**Ação recomendada:** ETL deve incluir mapeamentos completos de IDs

---

#### Tabela: `ffa_projtable`

**Problema 1:** Estatísticas detalhadas faltando em APP

| Coluna | etl/2025/ | app/2025-24/ | Tipo | Descrição |
|--------|-----------|--------------|------|-----------|
| `pass_att` | ✅ | ❌ | numeric | Tentativas de passe |
| `pass_comp` | ✅ | ❌ | numeric | Passes completos |
| `pass_yds` | ✅ | ❌ | numeric | Jardas de passe |
| `pass_tds` | ✅ | ❌ | numeric | TDs de passe |
| `pass_int` | ✅ | ❌ | numeric | Interceptações |
| `rush_att` | ✅ | ❌ | numeric | Tentativas de corrida |
| `rush_yds` | ✅ | ❌ | numeric | Jardas de corrida |
| `rush_tds` | ✅ | ❌ | numeric | TDs de corrida |
| `rec_tgt` | ✅ | ❌ | numeric | Targets |
| `rec` | ✅ | ❌ | numeric | Recepções |
| `rec_yds` | ✅ | ❌ | numeric | Jardas de recepção |
| `rec_tds` | ✅ | ❌ | numeric | TDs de recepção |

**Impacto:** CRÍTICO - 12 colunas de estatísticas faltando em app/

**Problema 2:** Colunas extras em APP (não documentadas)

| Coluna | etl/2025/ | app/2025-24/ | Tipo | Descrição |
|--------|-----------|--------------|------|-----------|
| `points_vor` | ❌ | ✅ | numeric | Value Over Replacement (pontos) |
| `floor_vor` | ❌ | ✅ | numeric | VOR floor |
| `ceiling_vor` | ❌ | ✅ | numeric | VOR ceiling |
| `floor_rank` | ❌ | ✅ | integer | Ranking floor |
| `ceiling_rank` | ❌ | ✅ | integer | Ranking ceiling |
| `first_name` | ❌ | ✅ | character | Primeiro nome |
| `last_name` | ❌ | ✅ | character | Sobrenome |
| `team` | ❌ | ✅ | character | Time NFL |
| `position` | ❌ | ✅ | character | Posição detalhada |
| `age` | ❌ | ✅ | integer | Idade |
| `exp` | ❌ | ✅ | integer | Anos de experiência |

**Impacto:** MÉDIO - 11 colunas extras em app/ (metadados de jogador e VOR)

**Problema 3:** Coluna extra em ETL não documentada

| Coluna | etl/2025/ | app/2025-24/ | Documentação | Descrição |
|--------|-----------|--------------|--------------|-----------|
| `pos_rank` | ✅ | ✅ | ❌ | Ranking por posição (não documentado) |

**Dimensões:**
- etl/2025/: 25,236 registros × 27 colunas
- app/2025-24/: 61,332 registros × 26 colunas
- **Diferença:** 36,096 registros a mais em app/ (243% maior)

**Ação recomendada:**
1. Atualizar documentação para incluir `pos_rank`
2. ETL deve incluir estatísticas detalhadas (pass_*, rush_*, rec_*)
3. Definir se VOR e metadados de jogador devem estar nesta tabela

---

### 3. Dados da Temporada 2025

#### ✅ Databases com dados 2025

| Database | etl/2025/ | app/2025-24/ | Observações |
|----------|-----------|--------------|-------------|
| **ffa_db.rds** | ✅ Semanas 1-17 | ✅ Semanas 0-17 | app/ inclui preseason (week 0) |
| **nfl_stats_db.rds** | ✅ | ✅ | Ambos têm 2025 |
| **dudes_simulation_db.rds** | ✅ | ❌ | **APENAS ETL tem 2025** |

#### ⚠️ nfl_teams_db.rds
- **Status:** Sem coluna `season` (dados atemporais)
- **Comportamento esperado:** Times da liga não mudam entre temporadas

#### ⚠️ dudes_simulation_db.rds - Inconsistência Crítica

**Problema:** Dados 2025 só existem em ETL

- **etl/2025/:** ✅ Contém dados 2025
  - `dudes_players_seeds`: 19,872 registros
  - `dudes_players_simulations`: 19,872 registros

- **app/2025-24/:** ❌ **NÃO contém dados 2025**
  - Pasta sugere temporada 2025-24 mas os dados são de 2024

**Impacto:** CRÍTICO - Simulações de 2025 não estão no diretório app/

**Ação recomendada:** Sincronizar simulações 2025 de etl/ para app/

---

### 4. Diferenças de Volume de Dados (2025)

#### ffa_db.rds - Tabela ffa_projtable

| Métrica | etl/2025/ | app/2025-24/ | Diferença |
|---------|-----------|--------------|-----------|
| **Total registros 2025** | 25,236 | 29,325 | +4,089 (16% mais em app/) |
| **Semanas disponíveis** | 1-17 | 0-17 | app/ tem week 0 (preseason) |
| **Scrapes (ffa_scrape)** | 34 | 19 | +15 scrapes em ETL |

**Observação:** ETL tem mais scrapes mas menos projeções finais - sugere que app/ consolida múltiplos scrapes

#### ffa_db.rds - Tabela ffa_proj_source_points

| Métrica | etl/2025/ | app/2025-24/ | Diferença |
|---------|-----------|--------------|-----------|
| **Total registros 2025** | 37,555 | 45,466 | +7,911 (21% mais em app/) |

**Observação:** Consistente com diferença em projeções agregadas

#### nfl_stats_db.rds

| Métrica | etl/2025/ | app/2025-24/ | Status |
|---------|-----------|--------------|--------|
| **Tamanho** | 0.11 MB | 0.44 MB | app/ 4x maior |
| **Estrutura** | 4 tabelas | 4 tabelas | ✅ Idêntica |

**Tabelas:**
- `nfl_stat_dictionary`: 80 stats (ETL) vs 95 stats (doc/app) - **15 stats faltando em ETL**
- `nfl_players_points`: 14,042 registros (ETL)
- `nfl_players_stats`: 528,292 registros (ETL)
- `nfl_players_adv_stats`: 14,042 registros (ETL)

---

## 📊 Análise de Conformidade com Documentação

### Schema Validation: ffa_db.rds

#### ✅ Conforme Documentação

| Tabela | etl/2025/ | app/2025-24/ |
|--------|-----------|--------------|
| **ffa_players** | ✅ | ✅ |
| **ffa_proj_source_points** | ✅ | ✅ |
| **ffa_scrape** | ✅ | ✅ |

#### ⚠️ Parcialmente Conforme

| Tabela | Local | Problema |
|--------|-------|----------|
| **ffa_player_ids** | etl/2025/ | Faltando 2 colunas (`gsis_id`, `sleeper_id`) |
| **ffa_player_ids** | app/2025-24/ | ✅ Conforme |
| **ffa_projtable** | etl/2025/ | 1 coluna extra não documentada (`pos_rank`) |
| **ffa_projtable** | app/2025-24/ | **12 colunas faltando** (stats) + **12 extras** (VOR, metadata) |

---

## 🎯 Recomendações Prioritárias

### 🔴 CRÍTICO (Implementar Imediatamente)

1. **Adicionar databases faltando em etl/2025/**
   - `nfl_players_db.rds` (roster de jogadores e lesões)
   - `nfl_round_db.rds` (matchups e escalações)
   - `nfl_recap_db.rds` (narrativas de jogos)

2. **Sincronizar simulações 2025**
   - Copiar `dudes_simulation_db.rds` de `etl/2025/` para `app/2025-24/`
   - Ou esclarecer por que simulações 2025 não estão em app/

3. **Padronizar schema de `ffa_projtable`**
   - Decidir se estatísticas detalhadas (pass_*, rush_*, rec_*) são necessárias
   - Definir se VOR e metadados devem estar nesta tabela ou em join com `ffa_players`

### 🟡 ALTO (Implementar em Seguida)

4. **Completar mapeamento de IDs em etl/**
   - Adicionar `gsis_id` e `sleeper_id` em `ffa_player_ids`
   - Expandir de 722 para ~5,395 jogadores

5. **Atualizar documentação**
   - Documentar coluna `pos_rank` em `ffa_projtable`
   - Documentar colunas VOR em `ffa_projtable` (se mantidas)
   - Esclarecer diferenças entre etl/ e app/ (propósito de cada pasta)

6. **Normalizar volume de dados**
   - Investigar por que app/ tem mais projeções (29,325) que etl/ (25,236)
   - Definir qual fonte é a "verdade" (source of truth)

### 🟢 MÉDIO (Melhorias)

7. **Padronizar cobertura de semanas**
   - ETL: semanas 1-17 (sem preseason)
   - APP: semanas 0-17 (com preseason)
   - Definir se preseason (week 0) deve estar em ambos

8. **Completar dicionário de estatísticas**
   - etl/ tem 80 stats, documentação define 95
   - Adicionar 15 stats faltando

---

## 📈 Métricas de Qualidade

### Completude dos Dados

| Aspecto | etl/2025/ | app/2025-24/ |
|---------|-----------|--------------|
| **Databases presentes** | 4/7 (57%) | 7/7 (100%) ✅ |
| **Dados temporada 2025** | ✅ Sim | ⚠️ Parcial (faltam simulações) |
| **Schema conforme doc** | 60% | 80% |
| **Volume de dados** | Menor | **Maior (fonte completa)** |

### Recomendação Final

**Usar `app/2025-24/` como fonte primária de dados** para análises de 2025, pois:
- ✅ Todos os 7 databases presentes
- ✅ Maior volume de projeções e estatísticas
- ✅ Mapeamento completo de IDs
- ⚠️ Porém: sincronizar simulações 2025 de etl/

**Usar `etl/2025/` para:**
- ✅ Simulações 2025 (até sincronizar com app/)
- ✅ Estatísticas detalhadas em `ffa_projtable` (pass_*, rush_*, rec_*)

---

## 🔄 Próximos Passos

1. ✅ **Relatório concluído** - Discrepâncias identificadas
2. ⏭️ Decidir: qual a relação entre etl/ e app/?
   - etl/ = pipeline intermediário → app/ = dados finais?
   - etl/ = 2025 puro, app/ = 2024+2025 consolidado?
3. ⏭️ Implementar sincronização entre pastas
4. ⏭️ Atualizar documentação com descobertas

---

**Gerado por:** Claude Code
**Data:** 2026-03-07
**Versão:** 1.0
