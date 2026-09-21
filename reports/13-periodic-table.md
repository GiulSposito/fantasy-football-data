# A Fantasy Football Periodic Table


    periodic-table eligible player-seasons (>= min games): 2908 / 4120 = 70.6%

## Executive summary

Per-player-season features: production (mean points), volatility (SD of
points), CV (volatility / production) and availability (games played),
restricted to players with at least 6 games. `kmeans()` (base R, scaled
features) groups players into archetypes, which we label after the fact
from each cluster’s centroid – the labels are descriptive, not
categories that exist in the source data.

| cluster | production |        cv |     games |    n |
|:--------|-----------:|----------:|----------:|-----:|
| 4       | 15.8781241 | 0.5059643 | 14.121123 |  677 |
| 3       |  7.1853484 | 0.7378118 | 14.503460 | 1156 |
| 1       |  5.9286316 | 0.7602669 |  8.437947 |  838 |
| 2       |  1.9643322 | 1.7066976 |  9.698690 |  229 |
| 5       |  0.0118939 | 7.4844693 | 11.625000 |    8 |

![](13-periodic-table_files/figure-commonmark/scatter-1.png)

![](13-periodic-table_files/figure-commonmark/counts-1.png)

**Takeaway:** “Reliable star” is who you draft to win your league with
the least stress; “Boom/bust star” wins or loses your week for you;
“Bench lottery” is where late-round upside picks live.
