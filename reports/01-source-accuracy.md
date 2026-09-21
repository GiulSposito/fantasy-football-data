# Who Predicts Fantasy Football Best?


    source-accuracy bridge match rate: 24903 / 45365 = 54.9%

## Executive summary

Across 24903 source-level projections matched to real results, we rank
the 5 ffanalytics sources with enough matched observations (≥200) to
compare fairly by mean absolute error (MAE), check whether the best
source holds up by position and by season, and see whether the
ready-made consensus columns in `ffa_projtable` already beat the best
individual source. The other sources (Yahoo, NumberFire, FleaFlicker,
NFL, FanDuel, RTSports) only appear in one or two seasons with a handful
of matched rows each – shown in the appendix table for reference,
excluded from the headline ranking because their sample size makes any
rank noise, not signal.

![](01-source-accuracy_files/figure-commonmark/by-source-1.png)

![](01-source-accuracy_files/figure-commonmark/consensus-baseline-1.png)

## Does the best source change by position?

![](01-source-accuracy_files/figure-commonmark/by-source-pos-1.png)

## Does accuracy change during the season?

![](01-source-accuracy_files/figure-commonmark/by-week-1.png)

## Is the best source stable across seasons?

![](01-source-accuracy_files/figure-commonmark/by-season-rank-1.png)

## Do sources make the same mistakes?

This is where the data says something more interesting than a
correlation heatmap: among the 5 reliable sources, **0 player-weeks**
(of 24753) have more than one of them projecting the same game at the
same time. Coverage is fragmented by season instead (see the table
above) – CBS dominates most years, ESPN mostly 2022+,
FantasyPros/FantasySharks/FFToday thinner slices throughout – so there’s
no pair of sources with enough simultaneous coverage to compute a
meaningful residual correlation. Any claim about sources being
“independent” or “diverse” would be reading noise into a matrix built on
zero overlapping observations. See
[02-wisdom-of-crowd](02-wisdom-of-crowd.md) for what this means for
ensembling.

## Rankings (all sources, including thin-coverage ones)

| data_src      |     n |  mae | rmse | bias | reliable |
|:--------------|------:|-----:|-----:|-----:|:---------|
| FantasyPros   |  2083 | 2.39 | 3.76 | 0.86 | TRUE     |
| FantasySharks |   268 | 2.80 | 4.52 | 1.14 | TRUE     |
| ESPN          |  2287 | 3.93 | 5.70 | 0.77 | TRUE     |
| CBS           | 19480 | 4.64 | 6.41 | 0.65 | TRUE     |
| FFToday       |   635 | 5.30 | 7.28 | 0.73 | TRUE     |
| NFL           |    12 | 1.21 | 1.51 | 0.16 | FALSE    |
| Yahoo         |    84 | 1.63 | 3.53 | 1.15 | FALSE    |
| NumberFire    |    31 | 1.76 | 4.05 | 1.39 | FALSE    |
| FanDuel       |     5 | 1.82 | 2.92 | 1.06 | FALSE    |
| FleaFlicker   |    18 | 2.75 | 3.97 | 0.37 | FALSE    |

**Takeaway:** among sources with reliable sample sizes, CBS and ESPN
carry almost all of the matched observations but sit at the back of the
pack on MAE; FantasyPros and FantasySharks, on far fewer projections,
are the most accurate. The near-zero overlap between sources (previous
section) means “ensemble of individual sources” isn’t really testable in
this dataset — see [02-wisdom-of-crowd](02-wisdom-of-crowd.md) for what
*is* testable.
