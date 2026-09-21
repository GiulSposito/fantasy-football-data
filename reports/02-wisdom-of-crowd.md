# The Wisdom of the Fantasy Crowd


    wisdom-of-crowd bridge match rate: 25444 / 45975 = 55.3%

## A data-shape finding first

The natural “wisdom of the crowd” test would average each source’s
*simultaneous* projection for the same player-week and see if the
average beats any individual source. That test needs several sources to
actually cover the same player-week at the same time. In this dataset’s
`ffa_proj_source_points` table, at `tag == "final"`, **0% of
player-weeks (0 of 46627) have more than one source recorded** —
essentially every player-week has exactly one `data_src` row. The 11
sources were not all scraped in parallel for the same game across most
of 2020-2025; coverage is fragmented by season instead (see
[01-source-accuracy](01-source-accuracy.md)’s season table). So a
row-level ensemble of *this* table isn’t buildable at meaningful scale —
we pivot to the only genuine multi-source consensus the data does
contain: `ffa_projtable`’s precomputed
`avg_type %in% c("average", "robust")` columns, built upstream from a
wider scrape than what survived into `ffa_proj_source_points`.

## Does the ready-made consensus beat a single source?

![](02-wisdom-of-crowd_files/figure-commonmark/consensus-vs-source-1.png)

![](02-wisdom-of-crowd_files/figure-commonmark/consensus-by-pos-1.png)

| method                |     n |  mae |  rmse |  bias | kind                    |
|:----------------------|------:|-----:|------:|------:|:------------------------|
| FantasySharks         |   268 | 2.80 |  4.52 |  1.14 | individual source       |
| FantasyPros           |  2157 | 2.81 |  5.70 |  0.98 | individual source       |
| ffa_projtable robust  |  7281 | 3.91 |  5.70 |  1.10 | ffa_projtable consensus |
| FFToday               |   635 | 5.30 |  7.28 |  0.73 | individual source       |
| ffa_projtable average | 18162 | 5.42 | 10.89 |  0.55 | ffa_projtable consensus |
| CBS                   | 19813 | 6.28 | 17.94 |  2.35 | individual source       |
| ESPN                  |  2407 | 6.60 | 18.71 | -0.98 | individual source       |

**Takeaway:** check whether either `ffa_projtable` consensus column
beats the best reliable individual source from
[01-source-accuracy](01-source-accuracy.md). If it does, that’s real
evidence for “wisdom of crowds” even though we can’t reconstruct which
raw sources fed it row-by-row in this dataset. If not, the apparent
benefit of “consensus” in fantasy football media may just be inheriting
whichever source dominates the input scrape (CBS, by volume — see report
01), not genuine error reduction from averaging.
