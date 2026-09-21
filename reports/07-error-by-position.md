# Which Position Is Hardest to Predict?


    error-by-position bridge match rate: 18162 / 27486 = 66.1%

## Executive summary

Using the same `ffa_projtable` consensus (`avg_type == "average"`) vs.
actual points as [03-booms-busts](03-booms-busts.md), we break the error
down by position to see which one the projection model consistently
struggles with most.

![](07-error-by-position_files/figure-commonmark/distribution-1.png)

![](07-error-by-position_files/figure-commonmark/ecdf-1.png)

![](07-error-by-position_files/figure-commonmark/ranking-1.png)

| pos |    n |  mae |  rmse | bias |
|:----|-----:|-----:|------:|-----:|
| QB  | 2148 | 6.96 | 14.93 | 0.07 |
| WR  | 5485 | 5.88 | 11.80 | 0.43 |
| RB  | 4338 | 5.45 | 10.98 | 0.44 |
| DST | 1515 | 4.78 |  6.97 | 0.46 |
| TE  | 3067 | 4.50 |  8.43 | 1.19 |
| K   | 1609 | 4.00 |  7.70 | 0.78 |

**Takeaway:** high-usage skill positions with more scoring pathways
(receiving + rushing, or big-play upside) tend to have both higher
average points and higher absolute error – the ranking above shows
whether that scales roughly with scoring volume or whether one position
is disproportionately hard to call relative to how many points is at
stake.
