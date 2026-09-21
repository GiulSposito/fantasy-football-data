# It’s Football, Dudes! — Data Explorations


## The chain this dataset lets you trace

Most sports datasets only let you ask “what happened?” This one lets you
trace a longer chain: **what happened → what was projected to happen →
how uncertain was that projection → what decision did a manager make
with it.** Six seasons (2020-2025) of projections from up to 11 sources,
real weekly results, injury status, Monte Carlo simulations, and actual
league rosters/matchups make that chain traceable end to end, not just
approximated from box scores.

The 18 reports below work through that chain: projection accuracy and
crowd-wisdom first, then how surprising and predictable individual
players are, then whether the model’s own uncertainty estimates and
simulations are calibrated, then how injuries, scarcity, schedule luck
and manager decisions turn “prediction” into “outcome.” Reports 15-18
are a self-contained series testing one specific idea end to end –
whether converting points into win-probability terms (Fantasy Game Wins)
beats just using points – against real league data instead of taking the
idea on faith (`fgw_analysis.md` at the repo root is the source brief).

**Headline numbers** (recomputed live from `dataset/`, not hardcoded):
the most accurate reliably-sampled projection source is **FantasyPros**
(MAE 2.39 points, n=2083); 5 of the 11 scraped sources have enough
matched observations (≥200) to compare fairly; and projections matched
to real results at an **54.9%** rate overall, reflecting real gaps
(byes, unmatched IDs), not a data bug.

## Reports

| \# | Report | What it asks |
|----|----|----|
| 01 | [Who Predicts Fantasy Football Best?](01-source-accuracy.md) | Which projection source has the lowest error, overall and by position/season? |
| 02 | [The Wisdom of the Fantasy Crowd](02-wisdom-of-crowd.md) | Does a multi-source consensus beat picking one good source? |
| 03 | [Booms, Busts and Surprises](03-booms-busts.md) | Who blows past or misses their projection, once or consistently? |
| 04 | [Who Is Actually Predictable?](04-predictability.md) | Separating reliable stars from boom/bust volatility. |
| 05 | [Does Projection Uncertainty Mean Anything?](05-uncertainty-calibration.md) | Do `sd_pts`/`floor`/`ceiling` actually track real error? |
| 06 | [The Cost of a Questionable Tag](06-injury-economics.md) | How injury status relates to projected and actual production. |
| 07 | [Which Position Is Hardest to Predict?](07-error-by-position.md) | Decomposing projection error by position. |
| 08 | [The Shifting Shape of Fantasy Scoring](08-positional-evolution.md) | Has WR production overtaken RB across 2020-2025? |
| 09 | [Stars, Starters and Replacement Players](09-value-over-replacement.md) | Empirical Value Over Replacement and positional scarcity. |
| 10 | [Was Your Team Good, or Just Lucky?](10-schedule-luck.md) | All-play record vs. actual record, 2023-2025. |
| 11 | [The Manager Effect](11-manager-effect.md) | Who leaves the most points on the bench? |
| 12 | [Did the Model Know?](12-simulation-calibration.md) | Are the Monte Carlo simulation quantiles calibrated? |
| 13 | [A Fantasy Football Periodic Table](13-periodic-table.md) | Clustering players into production/volatility archetypes. |
| 14 | [Career Fingerprints](14-career-fingerprint.md) | Weekly production heatmaps for the top all-time scorers. |
| 15 | [Fantasy Game Wins: Does Win-Probability Beat Points?](15-fgw-metrics.md) | Building FGW/eFGW/xFGW and checking whether they describe real season outcomes better than points. |
| 16 | [Does FGW Persist?](16-fgw-persistence.md) | Does trailing FGW predict a player’s next few weeks better than points or projections? |
| 17 | [Would xFGW Have Won You More Games?](17-fgw-decision-backtest.md) | A historical start/sit policy backtest: Points vs. VOR vs. xFGW. |
| 18 | [Is a Waiver Add Worth More Than Its VOR?](18-fgw-roster-construction.md) | A single retrospective RosterValue case study from real simulation data. |

## Reading these reports

Every report prints a join/match-rate sanity check near the top and
calls out its own simplifications and data-coverage limits explicitly in
the text (e.g. report 10 is scoped to 2023-2025, report 12 to two
simulation types) – these are honest limits of the source data, not
caveats to be skipped past. See `reports/R/_common.R` for the shared
join/metric helpers every report builds on, and the repo’s `CLAUDE.md`
for the full data model.
