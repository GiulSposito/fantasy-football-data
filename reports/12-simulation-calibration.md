# Did the Model Know?


    simulation-to-actual match rate: 4221 / 6575 = 64.2%

## Executive summary

For each simulated player-week we have quantiles at
5/15/30/50/70/85/95%. If the simulation is well-calibrated, the actual
result should fall below the 50% quantile about half the time, inside
`[15%, 85%]` about 70% of the time, and inside `[5%, 95%]` about 90% of
the time. This report is scoped to
`simType %in% c("proj_src", "current_season_his")` and seasons 2023-2024
– the only simulation methodology with real, overlapping coverage in
this dataset (see note above).

![](12-simulation-calibration_files/figure-commonmark/reliability-1.png)

| simType            |    n | label               | observed | nominal |
|:-------------------|-----:|:--------------------|---------:|--------:|
| current_season_his | 3994 | below q50           |    0.516 |     0.5 |
| current_season_his | 3994 | inside \[q15, q85\] |    0.335 |     0.7 |
| current_season_his | 3994 | inside \[q05, q95\] |    0.415 |     0.9 |
| proj_src           |  227 | below q50           |    0.374 |     0.5 |
| proj_src           |  227 | inside \[q15, q85\] |    0.304 |     0.7 |
| proj_src           |  227 | inside \[q05, q95\] |    0.388 |     0.9 |

**Takeaway:** points above the diagonal mean the simulation is
under-confident (actual results land inside the interval more often than
promised) – safe but not sharp. Points below mean it’s over-confident,
which is the riskier failure mode for anyone making decisions off these
quantiles.
