# Benson's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing a **bi-objective**
simplification of **Benson's algorithm** for multi-objective linear programs
(MOLP) / vector linear programs (VLP). The goal is to recover **nondominated
extreme points** of the **upper image**

$$
\mathcal{P} = P[S] + \mathbb{R}_{+}^{2},
\qquad
S = \{x : Ax \le b,\ x\ge 0\},
$$

in outcome space $y = Px \in \mathbb{R}^{2}$ (minimize both objectives).

This is **not** a full general-$q$ VLP outer-approximation solver (see
[Bensolve](http://www.bensolve.org/)). It matches the **spirit** of Benson:
scalarized LPs + cutting / refining an outer view of $\mathcal{P}$ until
efficient extreme outcomes are listed. For $q=2$ the practical engine is
**dichotomic weighted-sum** search plus an optional weight grid, with an
**embedded Bland tableau simplex** for each scalarization.

Based on [Wikipedia: Benson's algorithm](https://en.wikipedia.org/wiki/Benson%27s_algorithm)
(Harold Benson; outer approximation of the upper image by cutting planes).

Sibling LP packages:
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)**,
**[Ada-Cutting-Plane-Method](../ada-cutting-plane-method/)**
(tableau / cutting-plane ideas only; **no** `with`-clause dependency).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Problem** | Bi-objective MOLP $\min (c_1^\top x,\ c_2^\top x)$ | $Ax\le b$, $x\ge 0$ |
| **Upper image** | $\mathcal{P}=P[S]+\mathbb{R}_{+}^{2}$ | Nondominated extremes |
| **Engine** | Dichotomic weighted sums + weight grid | Educational $q=2$ |
| **LP** | Embedded dense Bland two-phase tableau | Sibling simplex ideas |
| **Status** | `Optimal` / `Infeasible` / `Empty_Front` / … | Plus front list |
| **Limits** | $n\le 8$, $m\le 12$, front $\le 16$ | Educational dense |

## Honesty: simplified vs full Benson

Full Benson maintains a polyhedral **outer approximation** of $\mathcal{P}$,
picks an unverified vertex $v$, solves a projection / dual LP, and adds a
**supporting halfspace** until every efficient extreme point is known (works
for general $q$ and polyhedral ordering cones).

This package:

1. Finds **lexicographic / endpoint** scalarizations ($\lambda=0$ and $\lambda=1$).
2. Samples a **weight grid** $\lambda\in[0,1]$.
3. Runs **dichotomic** weighted sums between consecutive front points
   (normal to the chord; insert if a better supported point appears).
4. Filters **Pareto-dominated** duplicates and sorts by $y_1$.

That recovers **supported nondominated extreme outcomes** for small bi-objective
LPs—the same points Benson targets when $q=2$—without a full vertex enumeration
of an outer polyhedron in higher dimension.

## Problem statement

$$
\min_{x}\; (c_1^\top x,\ c_2^\top x)
\quad\text{subject to}\quad
Ax\le b,\quad x\ge 0.
$$

(Wikipedia often writes $Ax\ge b$; both are interchangeable by sign flip.)
A point $y\in\mathbb{R}^{2}$ is **dominated** if some other feasible outcome
$\tilde y$ satisfies $\tilde y\le y$ componentwise with at least one strict
inequality. Extreme points of the nondominated set of $\mathcal{P}$ are the
targets.

### Weighted-sum scalarization

For $\lambda\in[0,1]$,

$$
\min_x\; \lambda\, c_1^\top x + (1-\lambda)\, c_2^\top x
\quad\text{s.t.}\quad Ax\le b,\ x\ge 0
$$

yields a **supported** nondominated outcome when $\lambda\in(0,1)$. Endpoints
$\lambda\in\{0,1\}$ recover individual minima.

### Dichotomic step

Given consecutive front points $y^A,y^B$, take weights proportional to the
outward normal $(y^B_2-y^A_2,\ y^A_1-y^B_1)$, resolve the weighted LP, and
recurse if a new extreme appears strictly better than the chord.

## Classic demo (triangle front)

$$
\min\;(x,y)
\quad\text{s.t.}\quad
x+y\ge 1,\quad x\le 2,\quad y\le 2,\quad x,y\ge 0.
$$

Nondominated extreme outcomes: $(0,1)$ and $(1,0)$ (the segment between them
is the continuous Pareto front; extremes of the upper image are these vertices).

## API summary

| Symbol | Role |
| --- | --- |
| `Config` | `Max_Pivots`, `Max_Dichotomy`, `Weight_Grid`, `Tol` |
| `Result` | `Stat`, `Points`, `N_Points`, `N_LP_Solves`, `N_Pivots`, `Success` |
| `Front_Point` | Outcome `Y`, preimage `X`, `N_Vars`, `Valid` |
| `Solve_Biobjective` | Dichotomic + grid recovery of nondominated extremes |
| `Weighted_Sum_Solve` | Single $\lambda$-scalarization → `Front_Point` |
| `Is_Dominated` / `Is_Weakly_Dominated` | Pareto tests (minimization) |
| `Eval_Objectives` | $y=(c_1^\top x,\ c_2^\top x)$ |
| `Near` / `Outcome_Near` / `Vec_Near` | Numeric helpers |
| `Maximize_LP` / `Minimize_LP` | Embedded Bland LP |
| Tableau helpers | `Build_Tableau`, `Pivot`, `Select_Entering`, … |

## Build and test

```bash
make clean && make
make test
```

Requires GNAT (`gnatmake`) with `-gnatwa -gnat2022`. The test harness
`tests.adb` is the only main; expect `Pass_Count ≥ 100` and `Fail_Count=0`.

## Layout

| File | Role |
| --- | --- |
| `bensons_algorithm.ads` | Package specification |
| `bensons_algorithm.adb` | Package body |
| `bensons_algorithm.gpr` | GNAT project |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Standalone test main |
| `README.md` | This document |
| `.gitignore` | `obj/` `bin/` |

## References

- [Wikipedia: Benson's algorithm](https://en.wikipedia.org/wiki/Benson%27s_algorithm)
- Harold Benson — outer approximation of the outcome set for MOLP / VLP
- Sibling: [Ada-Simplex-Algorithm](../ada-simplex-algorithm/),
  [Ada-Cutting-Plane-Method](../ada-cutting-plane-method/)
