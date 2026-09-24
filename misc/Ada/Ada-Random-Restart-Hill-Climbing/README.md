# Random-Restart Hill Climbing — Ada 2023

Educational, self-contained Ada 2023 package implementing **random-restart
hill climbing** (also called **shotgun hill climbing**) — repeatedly run
**steepest-descent** local search from random starts and keep the globally
best local optimum found.

Based on [Wikipedia: Hill climbing](https://en.wikipedia.org/wiki/Hill_climbing)
(§ Random-restart hill climbing; redirect
[Random-restart hill climbing](https://en.wikipedia.org/wiki/Random-restart_hill_climbing)).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Tabu-Search](../ada-tabu-search/)** (tabu memory +
aspiration), **[Ada-Simulated-Annealing](../ada-simulated-annealing/)**
(Metropolis cooling), and **[Ada-Random-Search](../ada-random-search/)**
(budgeted sampling without a neighborhood walk). Random restart escapes
local optima by **re-sampling the start**, not by accepting uphill moves.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Local step** | Steepest descent | Strictly better neighbor only |
| **Restart** | Fresh random $x_0$ | Keep best local optimum $x_m$ |
| **Config** | `Max_Restarts`, `Max_Climb_Steps`, `Seed`, `Step` | Seeded LCG |
| **Demos** | OneMax / Hamming, Sphere / Double_Well / Two_Basin, TSP 2-opt | $n\le 32$ bits; $n\le 10$ cities |
| **Track** | `Best_Cost`, `Restarts_Used`, `Climbs` | Aggregate improving moves |

## Algorithm

**Hill climb** (discrete steepest descent / ascent for minimization):

$$
x \leftarrow \arg\min_{x'\in N(x)} f(x')
\quad\text{while}\quad
\min_{x'\in N(x)} f(x') < f(x).
$$

Stop at a local optimum (empty improving neighborhood) or after
`Max_Climb_Steps`. This package uses **steepest descent**: every neighbor
is evaluated and the single best strict improvement is taken (not
first-improvement).

**Random restart** (shotgun):

$$
\begin{aligned}
&\text{for } r = 1\ldots R:\\
&\qquad x_0 \sim \text{Uniform(domain)},\quad
  x_m \leftarrow \mathrm{HillClimb}(x_0),\\
&\qquad\text{if } f(x_m) < f^\star \text{ then }
  (x^\star,f^\star)\leftarrow(x_m,f(x_m)).
\end{aligned}
$$

$R=0$ yields an empty / sentinel result (no climbs).

## Why restarts help

Plain hill climbing is trapped by local maxima / minima. Random restart
does not change the local operator; it only samples many basins. On a
landscape with two wells, a start near the shallow basin converges there,
while a start near the deep basin finds the global optimum — enough
restarts make the latter likely.

$$
f_{\mathrm{TwoBasin}}(x)=\min\bigl((x-2)^2+1,\;(x+3)^2\bigr).
$$

## Concrete neighborhoods

| Demo | State | Neighbor | Cost |
| --- | --- | --- | --- |
| `Hill_Climb_OneMax` / Hamming | bit-string | flip bit $i$ | zeros / Hamming to target |
| `Hill_Climb_1D` | $x\in[L_o,H_i]$ | $x\pm\mathrm{Step}$ (clamped) | $f(x)$ (Sphere, Double_Well, …) |
| `Hill_Climb_TSP` | tour $n\le 10$ | 2-opt reverse $(i,j)$ | closed tour length |

OneMax is encoded as **minimizing the number of zeros** (Hamming distance
to the all-ones string).

## Versus siblings

| | Random restart HC | Tabu search | Simulated annealing |
| --- | --- | --- | --- |
| Escape | New random start | Tabu + optional worsen | Metropolis $e^{-\Delta E/T}$ |
| Neighbor | Best improving only | Best admissible | Random proposal |
| Memory | None (restart budget) | Short-term attribute list | Temperature only |

## API (`Random_Restart_Hill_Climbing`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Config`, `Result`, `Bit_Result`, `Cont_Result`, `TSP_Result` | Budgets, stats |
| Helpers | `Near`, `Clamp`, `Flip_Bit`, `Hamming_Distance` | Tolerance / bits |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Natural` | Seeded LCG |
| Bits | `Hill_Climb_OneMax`, `Hill_Climb_Hamming`, `Random_Restart_*` | OneMax / Hamming |
| Continuous | `Hill_Climb_1D`, `Random_Restart_1D`, `Sphere_1D`, `Double_Well`, `Two_Basin` | $\pm\mathrm{Step}$ |
| TSP | `Tour_Length`, `Apply_2Opt`, `Hill_Climb_TSP`, `Random_Restart_TSP` | 2-opt $n\le 10$ |

Named exception: `Invalid_Argument`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Hill climbing](https://en.wikipedia.org/wiki/Hill_climbing)
  (random-restart / shotgun section)
- [Wikipedia: Random-restart hill climbing](https://en.wikipedia.org/wiki/Random-restart_hill_climbing)
  (redirect)
- Russell & Norvig, *Artificial Intelligence: A Modern Approach*
- Sibling: [Ada-Tabu-Search](../ada-tabu-search/)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)
- Sibling: [Ada-Random-Search](../ada-random-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
