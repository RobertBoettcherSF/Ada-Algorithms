# Odds Algorithm / Bruss Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Odds algorithm](https://en.wikipedia.org/wiki/Odds_algorithm)
(also known as the **Bruss algorithm**) — an optimal-stopping method for
**last-success** problems.

Named after [F. Thomas Bruss](https://en.wikipedia.org/wiki/Franz_Thomas_Bruss);
see Bruss (2000), *Sum the odds to one and stop*.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Odds** | $r_k = p_k / (1-p_k)$ | Undefined / ∞ if $p_k=1$ |
| **Threshold** | Sum $r_n+r_{n-1}+\cdots$ until $R\ge 1$ | Else $s=1$ |
| **Win prob.** | $w = Q_s R_s$ | $Q_s=\prod_{k=s}^n q_k$ |
| **Strategy** | Skip until $s$; stop on first success $k\ge s$ | Optimal |
| **Secretary** | Record probs $p_k=1/k$ | $s/n \approx 1/e$ |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Definitions (last-success)

Observe independent indicators $I_1,\ldots,I_n$ sequentially, with
$p_k = P(I_k=1)$, $q_k=1-p_k$, and odds $r_k=p_k/q_k$. The goal is to
**stop on the last success** (last $I_k=1$) at the moment it appears — no
recall of earlier observations.

## Algorithmic procedure

Sum odds **backward**:

$$
r_n + r_{n-1} + r_{n-2} + \cdots
$$

until the sum reaches or exceeds $1$. If that first happens at index $s$,
store

$$
R_s = r_n + \cdots + r_s, \qquad
Q_s = q_n q_{n-1}\cdots q_s.
$$

If the sum of all odds never reaches $1$, set $s=1$. Output:

1. $s$ — stopping threshold  
2. $w = Q_s R_s$ — win probability of the odds strategy  

**Sure success** ($p_k=1$): odds are infinite. This package substitutes a
large sentinel (`Huge_Odds`) so the backward sum forces a threshold at or
before that index; $Q_s$ becomes $0$ and reported $w$ is $0$
(indeterminate $\infty\cdot 0$ case — threshold remains well-defined).

## Odds strategy

Observe events in order and **stop on the first interesting event from index
$s$ onward** (if any). Implemented as `Should_Stop` / `Apply_Strategy`.

## Odds theorem

1. The odds strategy is **optimal** (maximizes $P(\text{stop on last }1)$).  
2. Its win probability equals $w=Q_s R_s$.  
3. If $R_s\ge 1$, then $w \ge 1/e \approx 0.367879\ldots$, and this bound is
   best possible.

## Applications

Clinical trials / compassionate use, sales / best-offer problems, classical
**secretary** (best-choice) problems via record probabilities $p_k=1/k$,
portfolio selection, parking / search, online maintenance, and continuous-time
analogues (Poisson arrivals).

## Features / public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Probability_Vector`, `Boolean_Array`, `Odds_Result`, `Max_N` | Domain |
| Odds | `Odds` | $r=p/(1-p)$ |
| Core | `Compute_Threshold` | $s, R_s, Q_s, w$ |
| Strategy | `Should_Stop`, `Apply_Strategy` | Online stopping |
| Helpers | `Uniform_P`, `Secretary_Record_Probabilities`, `Near` | Fixtures |
| Monte Carlo | `Simulate_Win_Rate` | Empirical check vs $w$ |

Strong typing uses `Real` (digits 12). Public subprograms carry `Pre` / `Post`
/ `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Usage

```ada
with Odds_Algorithm; use Odds_Algorithm;

declare
   P   : constant Probability_Vector := Uniform_P (5, 0.3);
   Res : constant Odds_Result := Compute_Threshold (P);
begin
   -- Res.Threshold_S, Res.Win_Probability, ...
   if Should_Stop (K => 4, Observation_Interesting => True,
                   Threshold_S => Res.Threshold_S) then
      null;  -- stop
   end if;
end;
```

Secretary-style records:

```ada
P : constant Probability_Vector := Secretary_Record_Probabilities (100);
R : constant Odds_Result := Compute_Threshold (P);
-- R.Threshold_S / 100 ≈ 1/e
```

## Building

```bash
cd /workspace/ada-odds-algorithm
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Podds_algorithm.gpr`. Object files go to
`obj/`, the test executable to `bin/tests`.

## Testing

```bash
make test
```

Rich standalone suite in `tests.adb` (Check harness, no `Ada.Assertions`
except final `pragma Assert (Fail_Count = 0)`): odds formula, hand-worked
thresholds, $s=1$ when $R<1$, $w=Q R$, strategy behaviour, zeros,
invalid inputs, sure success, secretary $s/n\approx 1/e$, theorem bound
$w\ge 1/e$, and Monte Carlo agreement with $w$.

## Project layout

```
ada-odds-algorithm/
  odds_algorithm.ads   # package specification
  odds_algorithm.adb   # package body
  odds_algorithm.gpr   # GNAT project
  tests.adb            # test main
  Makefile
  README.md
  .gitignore
```

## References

* F. T. Bruss (2000). *Sum the odds to one and stop*. Annals of Probability
  28(3):1384–1391. DOI:[10.1214/aop/1019160340](https://doi.org/10.1214/aop/1019160340)
* Wikipedia: [Odds algorithm](https://en.wikipedia.org/wiki/Odds_algorithm)
* Wikipedia: [Secretary problem](https://en.wikipedia.org/wiki/Secretary_problem)
* Bruss & Paindaveine (2000); Tamaki (2010); Matsui & Ano (2014–2017) — variants
