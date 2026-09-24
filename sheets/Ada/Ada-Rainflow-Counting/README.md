# Rainflow-Counting Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Rainflow-counting algorithm](https://en.wikipedia.org/wiki/Rainflow-counting_algorithm)
— the fatigue cycle-counting method of **Tatsuo Endo** and **M. Matsuishi**
(1968; English presentation 1974). The algorithm converts a varying
load/stress history into a set of constant-amplitude reversals with
equivalent fatigue damage, matching the closed loops of a stress–strain
hysteresis curve.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Turning points** | Collapse plateaus; keep extrema | Peaks / valleys + ends |
| **Primary count** | Four-point method | $A$-$B$-$C$-$D$ containment |
| **Residuals** | Optional half-cycles | Count $0.5$ |
| **Closed block** | Start at largest peak, wrap | Repeated load sequences |
| **Damage** | Miner's rule + power-law $S$–$N$ | $D=\sum n_i/N_i$ |

## Purpose

Rainflow counting is used when estimating the **fatigue life** of a component
under spectrum loading. Smaller interruption cycles are extracted first; the
material then resumes the outer hysteresis path as if the interruption had
not occurred. Each extracted cycle can be fed into Miner's linear damage rule
or into a crack-growth model.

## History

- **1968** — Matsuishi & Endo introduce the method (Japan Society of
  Mechanical Engineering).
- **1974** — English presentation; Dowling & Morrow popularise it in the U.S.
- **1982** — Downing & Socie publish widely used stack algorithms (ASTM
  E1049-85 includes rainflow among standard practices).
- **1987** — Rychlik gives a mathematical definition enabling closed-form
  statistics of the load signal.

## Algorithm

### Turning points

Non-extrema and plateaus are removed first. Consecutive equal samples are
collapsed; local peaks and valleys (plus the first and last samples) remain.
The range between levels $X$ and $Y$ is

$$
r(X,Y)=|X-Y|.
$$

### Four-point method (primary API)

For each adjacent quadruple of turning points $A$-$B$-$C$-$D$:

- If the interval $[\min(B,C),\max(B,C)]$ lies **within or equal to**
  $[\min(A,D),\max(A,D)]$ (equivalently $r(B,C)\le r(A,D)$ with $B,C$ between
  $A$ and $D$), then $B$-$C$ is a rainflow cycle.
- Count that full cycle (count $1.0$), remove $B$ and $C$, and restart from
  the beginning of the remaining sequence.
- When no further pairs qualify, optionally emit consecutive residual pairs
  as **half-cycles** (count $0.5$).

For a **repeated load block**, start at the largest peak and wrap (append
that peak) to obtain a closed set of full cycles.

### Miner's rule helper

With cycle counts $n_i$ and lives $N_i$ at the corresponding amplitude,

$$
D=\sum_i \frac{n_i}{N_i}.
$$

This package supplies a simple power-law life model

$$
N(S)=\frac{C}{S^{m}}\quad(S>0),
$$

via `Power_Law_Life` / `Total_Damage`, plus an optional callback form
`Total_Damage_With`.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Real_Array`, `Cycle`, `Cycle_Result` | Domain model |
| Helpers | `Near`, `Range_Of` | Numerics / $r(X,Y)$ |
| Turning points | `Extract_Turning_Points` | Reduce history |
| Counting | `Count_Cycles_Four_Point`, `Count_Cycles` | Four-point (+ closed) |
| Queries | `Full_Cycle_Count`, `Half_Cycle_Count`, `Equivalent_Full_Cycles` | Summaries |
| Damage | `Power_Law_Life`, `Total_Damage`, `Total_Damage_With` | Miner $D$ |

Each `Cycle` exposes `From_Level`, `To_Level`, `Range_Val`, `Amplitude`
($=\mathrm{range}/2$), `Mean`, and `Count` ($1.0$ or $0.5$).

Capacity is bounded by `Max_N` (fixed-size educational arrays). Named
exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
`make test` runs `bin/tests` and expects `Fail_Count = 0`.

## Layout

| File | Role |
| --- | --- |
| `rainflow_counting.ads` / `.adb` | Package spec / body |
| `rainflow_counting.gpr` | GNAT project (`Main => tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Standalone assertion suite |
| `README.md` | This document |
| `.gitignore` | `obj/` `bin/` |

## References

- [Rainflow-counting algorithm — Wikipedia](https://en.wikipedia.org/wiki/Rainflow-counting_algorithm)
- Matsuishi, M.; Endo, T. (1968). Fatigue of metals subjected to varying stress.
- Downing, S.D.; Socie, D.F. (1982). Simple rainflow counting algorithms.
  *International Journal of Fatigue*.
- ASTM E1049-85 — Standard practices for cycle counting in fatigue analysis.
