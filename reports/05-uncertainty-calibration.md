# Does Projection Uncertainty Mean Anything?


    uncertainty-calibration bridge match rate (incl. sd_pts/floor/ceiling non-NA): 18023 / 27486 = 65.6%

## Executive summary

`ffa_projtable` carries `sd_pts`, `floor` and `ceiling` alongside every
projection. If those numbers mean anything, “high uncertainty” players
should actually show larger errors, and `actual` should land inside
`[floor, ceiling]` a stable, sensible share of the time.
`floor`/`ceiling` aren’t documented anywhere as a fixed nominal interval
(e.g. not stated to be an 80% or 95% band), so this report reports the
*observed* coverage rather than testing against an assumed target.

![](05-uncertainty-calibration_files/figure-commonmark/calibration-by-tercile-1.png)

## Interval coverage

![](05-uncertainty-calibration_files/figure-commonmark/coverage-1.png)

| uncertainty |  coverage |    n |
|:------------|----------:|-----:|
| low         | 0.1566245 | 6008 |
| medium      | 0.2103862 | 6008 |
| high        | 0.2909938 | 6007 |

**Takeaway:** if MAE climbs cleanly from the low to the high `sd_pts`
tercile, the model’s self-reported uncertainty is doing real work, not
just decoration. If coverage is roughly flat across positions and
tercile groups, `floor`/`ceiling` behaves like a consistent interval
rather than one that’s only calibrated for some positions.
