# Grid Search — Ada 2023

Educational, self-contained Ada 2023 package implementing **grid search**
(parameter sweep) for **hyperparameter / black-box optimization** — build a
finite discrete axis per dimension, evaluate the objective on the full
**Cartesian product**, and return the best configuration (min or max).

Based on [Wikipedia: Hyperparameter optimization § Grid search](https://en.wikipedia.org/wiki/Hyperparameter_optimization#Grid_search).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling package: **[Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search)** — replaces
exhaustive enumeration with a fixed budget of independent random (or
log-uniform) samples; often preferable when only a few axes matter (low
effective dimensionality).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Exhaustive Cartesian product | Every tuple evaluated |
| **Axis** | Sorted unique discrete values | $\le 16$ points / axis |
| **Grid** | Up to $d\le 6$ axes | `Make_Grid` / linspace helpers |
| **Sense** | Minimize or maximize | Keep best-so-far |
| **Card.** | $\prod_j n_j$ | `Cardinality` |
| **Enum.** | Lex odometer / `Point_At` | Last axis fastest |
| **Demos** | Sphere, multimodal 1-D, SVM toy | Built-in objectives |

## Why grid search

Given finite sets $A_1,\ldots,A_d$ for each hyperparameter, grid search
evaluates

$$
\mathcal{G}=A_1\times A_2\times\cdots\times A_d
$$

and returns

$$
x^\star=\arg\min_{x\in\mathcal{G}} f(x)
\quad\text{(or $\arg\max$)}.
$$

Continuous or unbounded parameters must be **manually bounded and
discretized** first (e.g. linspace or a hand-picked set such as
$C\in\{10,100,1000\}$, $\gamma\in\{0.1,0.2,0.5,1.0\}$ for an RBF SVM).
The method is **embarrassingly parallel** (independent evaluations) but
suffers the **curse of dimensionality**: $|\mathcal{G}|=\prod_j |A_j|$
grows exponentially in $d$.

## Contrast with random search

With budget $T=n^d$, a regular grid explores only $n$ distinct values per
axis, while random search explores up to $T$ distinct values on every
axis. When the response surface has **low effective dimensionality**,
random search often finds good regions with the same evaluation count —
see sibling **[Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search)** (Bergstra &
Bengio, *JMLR* 2012).

$$
T_{\mathrm{grid}}=n^{d},\qquad
\#\{\text{distinct values on axis }i\}_{\mathrm{grid}}=n,
\quad
\#\{\text{distinct values on axis }i\}_{\mathrm{random}}=T.
$$

## Algorithm sketch

1. Build one discrete `Axis` per dimension (`Build_Axis` sorts/dedupes;
   `Build_Linspace_Axis` places $N$ inclusive endpoints on $[L_o,H_i]$).
2. Assemble a `Grid` (`Make_Grid`); reject empty axes.
3. For each lexicographic rank $r=1\ldots\prod_j n_j$, form $x_r$
   (`Point_At` / `Enumerate`) and evaluate $f(x_r)$.
4. Keep the incumbent under the chosen sense (min/max); return
   `Result` with best point, value, evaluation count, and rank.

## Built-in demos

| Objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Linspace box finds near-zero at origin |
| `Multimodal_1D` | basins near $0.2$ and $0.8$ | Global among grid samples |
| `Neg_Sphere` | $-\sum_i x_i^2$ | Maximize demo |
| `SVM_Toy_Score` | peak near $C=100$, $\gamma=0.1$ | Discrete $(C,\gamma)$ sweep |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min at $(1,\ldots,1)$ |

## API (`Grid_Search`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Axis`, `Grid`, `Config`, `Result`, `Sense` | Discrete product space |
| Axis | `Build_Axis`, `Build_Linspace_Axis`, `Axis_Length`, `Get_Value` | Construction |
| Grid | `Make_Grid`, `Cardinality`, `Point_At`, `Enumerate` | Product / visit |
| Helpers | `Near`, `Default_Config` | Tolerance / config |
| Objectives | `Sphere`, `Multimodal_1D`, `Neg_Sphere`, `SVM_Toy_Score`, `Shifted_Sphere` | Demos |
| Drivers | `Search`, `Minimize`, `Maximize` | Exhaustive sweep |

Named exception: `Invalid_Argument` (empty axis / empty grid, null
objective, out-of-range index).

Capacity: $d\le 6$, $\le 16$ points per axis (max $|\mathcal{G}|=16^6$).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Hyperparameter optimization — Grid search](https://en.wikipedia.org/wiki/Hyperparameter_optimization#Grid_search)
- Sibling: [Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search)
- J. Bergstra, Y. Bengio, *Random Search for Hyper-Parameter Optimization*,
  Journal of Machine Learning Research **13**, 281–305 (2012)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
