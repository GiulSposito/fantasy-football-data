# Would xFGW Have Won You More Games?


## Executive summary

[15-fgw-metrics](15-fgw-metrics.md) and
[16-fgw-persistence](16-fgw-persistence.md) test whether FGW describes
and predicts production. This report runs `fgw_analysis.md`’s central
test (Experiment 3, sections 10-13): **for every real historical
start/sit decision this league actually faced – a starter and the real
bench players eligible to replace them at that slot – would ranking by
projected points, by VOR (points above position replacement), or by xFGW
(win-probability shift) have picked someone different, and would that
pick have won more games?**

Bench alternatives are reconstructed from `rosterSlotId` (confirmed to
resolve cleanly to QB/RB/WR/TE/K/DST/bench, with slot 5 = FLEX pooling
RB/WR/TE), not the coarser `slotPosition` bucket
[11-manager-effect](11-manager-effect.md) had to work around.

    starter decisions with team-projection context (should be ~100%, same join): 4934 / 4934 = 100.0%

For each decision, the “pool” is the actual starter plus every real,
same-slot-eligible bench player on that team that week, each with a
hypothetical team total if they’d been swapped in for the incumbent –
using **projected** points (for the Points/VOR/xFGW policy decision,
made before the game) and **actual** points (to score what really would
have happened).

## Decision Flip Rate

Across 3537 real start/sit decisions with at least one eligible bench
alternative, xFGW disagreed with ranking by projected points in **93**
of them – a flip rate of **2.6%**. `fgw_analysis.md` section 12 frames
this as the test to run *before* looking at outcomes: a low flip rate
means the sophistication mostly doesn’t change anything in practice,
whatever the theory says.

## Did the flip help?

| situation | n | historical | points_policy | vor_policy | xfgw_policy |
|:---|---:|:---|:---|:---|:---|
| All decisions | 3537 | 50.0% | 48.9% | 48.9% | 48.8% |
| Decisions where xFGW and Points differ | 93 | 31.2% | 32.3% | 32.3% | 29.0% |

`historical` is what the real manager’s actual lineup that week produced
(win rate ≈ 50% everywhere, by construction of a win/loss league). The
other three columns are the hypothetical team win rate if *every*
decision in that row had instead followed that policy, holding every
other slot at its real, historical result.

## Calibration: does the win-probability model itself hold up ex-ante?

![](17-fgw-decision-backtest_files/figure-commonmark/calibration-1.png)

This is a harder test than [15-fgw-metrics](15-fgw-metrics.md)’ curve:
that one was fit and evaluated on the same real, *actual* scores. Here
the same `win_prob()` curve is fed each team’s **projected** total
instead – genuinely ex-ante, using only information available before the
games were played.

**Takeaway:** the flip rate is low (2.6%) – most start/sit calls simply
don’t have a same-slot alternative close enough for the win-probability
framing to matter, echoing `fgw_analysis.md` section 12’s “sofisticamos
a matemática e quase nunca mudamos a decisão” scenario. And on the 93
decisions where it *did* disagree with Points – small enough that this
is not a statistically powered test – xFGW’s hypothetical win rate did
not come out ahead of simply starting the higher-projected player.
Calibration is real but modest (Brier score clearly better than the 0.25
always-guess-50% baseline, but short of a sharp forecaster). Taken
together, this 3-season sample gives no evidence that xFGW would have
won this league more games than projected points already do – consistent
with `fgw_analysis.md` section 2’s own warning and section 19’s own
expectation, not a failure of the metric’s construction. The honest
reading of the doc’s H0/H1 framing: **H0 is not rejected here.**
