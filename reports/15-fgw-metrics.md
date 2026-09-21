# Fantasy Game Wins: Does Win-Probability Beat Points?


    team-week score-to-outcome match rate: 720 / 734 = 98.1%

## Executive summary

[Byron Cobalt’s
FGW](https://byron-cobalt.com/2021/09/19/introducing-the-fantasy-game-wins-fgw-fantasy-football-player-scoring-system/)
reframes player value as *how much a score shifted your team’s win
probability*, not the raw point total. We build three versions against
this league’s real 2023-2025 data (`fgw_analysis.md` at the repo root is
the source brief this series works from):

- **FGW-classic** – reproduces the original method: a normal
  approximation of the league’s team-score spread converts a player’s
  points above their position’s replacement-level starter into a
  win-probability shift.
- **eFGW** – same idea, but `P(Win | TeamScore)` comes from this
  league’s own empirical score/outcome history instead of an assumed
  normal curve.
- **xFGW** – the *ex-ante* version: uses projected points (not actual)
  to ask what a player was *expected* to shift, the form a decision tool
  would actually need.

Section 2 of `fgw_analysis.md` raises the sharpest test first: since a
monotonic transform of points can never change a start/sit ranking, FGW
only earns its keep if it captures something points don’t – here, that a
player’s marginal value depends on their team’s score level, not just
their own delta.

![](15-fgw-metrics_files/figure-commonmark/win-prob-curve-1.png)

The curve is steep and monotonic through the middle of the score range
and flattens at the extremes (blowouts and near-shutouts rarely flip on
a few more points) – exactly the S-shape the normal-approximation
`Impact` term in FGW-classic assumes, but built from this league’s own
outcomes rather than a generic distribution.

    starter-to-actual-points match rate: 6313 / 6606 = 95.6%

## FGW-classic and eFGW (retrospective, from actual points)

`delta` is points above the replacement-level starter at that position
and season. **FGW-classic** runs it through a normal CDF using the
league’s overall team-score SD (24 points). **eFGW** instead asks the
empirical curve above: “how much did this player’s real score move my
team from its actual total to what a replacement-level starter would
have produced instead?” Both correlate strongly with each other (r =
0.83) but are not the same metric – eFGW’s win-probability curve
flattens in blowouts, so it doesn’t reward garbage-time padding the way
a symmetric normal CDF does.

## xFGW (ex-ante, from projected points)

    starter-to-projection match rate: 4934 / 6606 = 74.7%

**xFGW** repeats eFGW’s construction but with each player’s *projected*
points and the team’s *projected* total (teammates held at their actual
performance, this player’s slot swapped between their projection and
replacement level) – the version a manager could actually compute before
kickoff. Within the same team-week, xFGW is **not** a monotonic
rescaling of projected points (r = 0.61, not 1): the same point delta
shifts win probability more or less depending on how close the team’s
projected total already sits to the empirical curve’s steep middle
section – the exact effect `fgw_analysis.md` section 2 predicted would
be needed for FGW to ever say something points can’t.

## Do these metrics describe real season outcomes better than points?

| metric                           | corr_with_wins |
|:---------------------------------|---------------:|
| Points                           |          0.864 |
| FGW-classic                      |          0.859 |
| Points above replacement (delta) |          0.858 |
| eFGW                             |          0.646 |

![](15-fgw-metrics_files/figure-commonmark/playoffs-1.png)

**Takeaway:** raw season points already correlate strongly with real
wins (r = 0.86) – there isn’t much room for any transformation of the
same underlying production to add. FGW-classic tracks points closely, as
expected from a monotonic transform of (mostly) the same signal. eFGW’s
flattening at the extremes pulls its win correlation *below* points’ –
it’s deliberately discounting blowout production that padded a score
without changing the outcome, which is a different (and arguably more
honest) notion of “value” than “did this team score a lot,” not a data
problem. This matches `fgw_analysis.md` section 19’s own expectation:
FGW is a genuinely different lens on *what happened*, but that’s a
retrospective/descriptive claim, not yet a decision claim –
[16-fgw-persistence](16-fgw-persistence.md) and
[17-fgw-decision-backtest](17-fgw-decision-backtest.md) test whether
either version actually helps you decide something.
