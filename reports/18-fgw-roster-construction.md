# Is a Waiver Add Worth More Than Its VOR?


## Executive summary

`fgw_analysis.md`’s Experiment 4 asks whether a
`RosterValue(p) = Σ [P(Win | Roster + p) − P(Win | Roster)]` rule would
pick better waiver adds than simply ranking by VOR. Of the four building
blocks this FGW series depends on, Monte Carlo player simulations are by
far the weakest: `simType %in% c("proj_src", "current_season_his")` in
`dudes_players_simulations` only covers **14 season-weeks total** (2023
weeks 1-11, 2024 weeks 2-4) and **nothing at all in 2025**. A real
backtest the way [17-fgw-decision-backtest](17-fgw-decision-backtest.md)
runs one isn’t possible on that little data, so this report is scoped
down to what `fgw_analysis.md`’s own framing already anticipates for the
weakest-evidence experiment: **one concrete, real, retrospective case
study**, not a general claim. Treat this report’s conclusion as
illustrative, not as evidence at the same confidence level as 15-17.

## The case: a real RB2 decision, 2024 week 2

Team 8 started Zach Charbonnet at RB2 in week 2 of 2024, with only
Raheem Mostert as an actual same-position bench alternative. Weeks 3-4
are the horizon this simulation coverage reaches, and both were
genuinely tight team-projection-vs-opponent matchups (this team’s
projected total sat within a few points of the opponent’s real score
both weeks) – exactly the kind of context where a marginal roster
decision could plausibly matter, unlike the blowout weeks that made most
decisions in [17-fgw-decision-backtest](17-fgw-decision-backtest.md)
irrelevant to the outcome regardless of who started.

`RosterValue(p)` here is the average, across the 2 horizon weeks, of
P(Team + candidate’s simulated score \> opponent’s real score) − nothing
subtracted yet, since we’re ranking candidates directly rather than
reporting a lift. `avg_proj` is each candidate’s own simulated median
score, averaged across the same 2 weeks (`ffa_projtable` doesn’t cover
most bench RBs, so the simulation’s own median stands in as the
“projected points” comparator).

![](18-fgw-roster-construction_files/figure-commonmark/plot-1.png)

| name               | avg_proj | roster_value | is_incumbent |
|:-------------------|---------:|:-------------|:-------------|
| Zach Charbonnet    |     16.4 | 100.0%       | TRUE         |
| Kenneth Walker III |     18.9 | 100.0%       | FALSE        |
| Najee Harris       |      8.8 | 100.0%       | FALSE        |
| Devin Singletary   |     13.2 | 100.0%       | FALSE        |
| Austin Ekeler      |     11.2 | 100.0%       | FALSE        |
| Alexander Mattison |     12.3 | 95.0%        | FALSE        |
| Justice Hill       |      7.9 | 84.3%        | FALSE        |
| Rico Dowdle        |      7.8 | 69.9%        | FALSE        |
| Tank Bigsby        |      5.7 | 67.4%        | FALSE        |
| Ezekiel Elliott    |      7.1 | 64.6%        | FALSE        |

**Takeaway:** in this one case, RosterValue and the simulation’s own
projected points rank candidates almost identically (Spearman r ≈ 0.93
across all 24 candidates) – most of RosterValue’s ranking power is,
again, just points in a different unit, the same conclusion
[15-fgw-metrics](15-fgw-metrics.md) and
[17-fgw-decision-backtest](17-fgw-decision-backtest.md) reached with the
empirical win-probability curve instead of simulation draws. What
RosterValue adds here is confirmation, not surprise: the real historical
start (Charbonnet) sits in the top tier of both rankings, and the team’s
actual bench alternative (Mostert) sits at the very bottom – the
manager’s real decision checks out. That’s a reassuring result for this
one team-week, not a general finding; with 2 usable horizon weeks, no
2025 simulation coverage at all, and one illustrative team picked
specifically because it was a close matchup, this report cannot and does
not claim RosterValue beats VOR at scale the way
[17-fgw-decision-backtest](17-fgw-decision-backtest.md) tested for
start/sit. A real answer to `fgw_analysis.md`’s Experiment 4 would need
either a broader simulation dataset than this league currently keeps, or
running the same `win_prob_model()`-based approach 15-17 use with
projections instead of simulations – which this report intentionally
avoided, to keep at least one part of the FGW series grounded in the
doc’s own “literally simulate it” framing (section 7) rather than
another normal-approximation shortcut.
