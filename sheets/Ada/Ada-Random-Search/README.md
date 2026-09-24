# Random Search — Ada 2023

Educational, self-contained Ada 2023 package implementing **random search**
for **hyperparameter / black-box optimization** — sample configurations
uniformly (or **log-uniformly**) at random and keep the best objective value
under a fixed evaluation budget.

Based on [Wikipedia: Hyperparameter optimization § Random search](https://en.wikipedia.org/wiki/Hyperparameter_optimization#Random_search)
(Bergstra & Bengio, *JMLR* **13**, 281–305, 2012).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Simulated-Annealing](../ada-simulated-annealing/)**,
**[Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/)** — sequential
metaheuristics on continuous landscapes; this package is the embarrassingly
parallel **budgeted sampling** baseline.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Sample i.i.d. points in a box | No sequential model |
| **Uniform** | $x\sim\mathcal{U}[L_o,H_i]$ | Default continuous box |
| **Log-uniform** | $x=\exp(U(\log L_o,\log H_i))$ | Positive scales ($C$, $\eta$, $\gamma$) |
| **Sense** | Minimize or maximize | Keep best-so-far |
| **Compare** | Optional 2-D grid search | Same evaluation budget |
| **Dim** | $1\ldots 8$ | `Search_1D` / `Search_ND` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Why random search (Bergstra & Bengio)

Grid search evaluates a Cartesian product of discretized axes. If only a
**few** hyperparameters strongly affect the objective (low **effective
dimensionality**), most grid evaluations waste budget on irrelevant axes.
Random search draws a new value for **every** coordinate on every trial, so
with budget $T$ it explores $T$ distinct values per important dimension,
while a grid with $T=n^d$ cells explores only $n$ values per axis.

$$
T_{\mathrm{grid}}=n^{d},\qquad
\#\{\text{distinct values on axis }i\}_{\mathrm{grid}}=n,
\quad
\#\{\text{distinct values on axis }i\}_{\mathrm{random}}=T.
$$

Empirically, random search often finds good regions **faster** than grid
search in high-$d$ spaces when the response surface is sparse in its
important coordinates.

## Sampling

**Uniform** on a closed interval:

$$
x = L_o + U\cdot(H_i-L_o),\qquad U\sim\mathcal{U}[0,1).
$$

**Log-uniform** (positive hyperparameters such as learning rates or SVM
$C$, $\gamma$):

$$
x=\exp\bigl(U(\log L_o,\log H_i)\bigr),\qquad L_o>0.
$$

Equal mass is placed on each order of magnitude between $L_o$ and $H_i$.

## Algorithm sketch

1. Fix bounds $[L_o^{(j)},H_i^{(j)}]$ for $j=1\ldots d$ and budget $T$.
2. For $t=1\ldots T$: sample $x_t$ (uniform or log-uniform per coordinate);
   evaluate $f(x_t)$; if better than the incumbent under the chosen sense
   (min/max), update $(x^\star,f^\star)$.
3. Return the incumbent. Trials $=0$ yields an empty result (no evaluations).

Grid comparison helper: `Grid_Search_2D` builds an $N_x\times N_y$ mesh over
a rectangle (same objective / sense) for head-to-head budgets.

## Needle-in-haystack demo

Objective with **one** important coordinate:

$$
f(x,y)=(x-0.75)^2
$$

($y$ ignored). A coarse $3\times 3$ grid on $[0,1]^2$ places $x\in\{0,0.5,1\}$
and cannot beat $f=0.0625$, while random search with nine draws often samples
closer to $x=0.75$ — the Bergstra–Bengio intuition in miniature.

## API (`Random_Search`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Bound`, `Bounds`, `Config`, `Result`, `Sampling_Kind`, `Sense` | Box, budget, min/max |
| Helpers | `Near`, `Clamp` | Tolerance / projection |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform` | Seeded LCG |
| Sample | `Sample_Uniform`, `Sample_Log_Uniform`, `Sample_Point` | Draws in bounds |
| Objectives | `Quadratic_1D`, `Shifted_Quadratic_1D`, `Needle_1D`, `Sphere_ND`, `Needle_Haystack_2D`, `Rastrigin_2D`, `Neg_Sphere_ND`, `Log10_Squared_1D`, … | Test landscapes |
| Drivers | `Search_1D`, `Search_ND`, `Minimize`, `Maximize` | Random search |
| Grid | `Grid_Search_2D` | Budget-matched baseline |

Named exception: `Invalid_Argument` (empty / inverted bounds, non-positive
log-uniform limits, null objective).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Hyperparameter optimization — Random search](https://en.wikipedia.org/wiki/Hyperparameter_optimization#Random_search)
- J. Bergstra, Y. Bengio, *Random Search for Hyper-Parameter Optimization*,
  Journal of Machine Learning Research **13**, 281–305 (2012)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)
- Sibling: [Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
