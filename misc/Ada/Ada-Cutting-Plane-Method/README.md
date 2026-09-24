# Cutting-Plane Method — Ada 2023

Educational, self-contained Ada 2023 package implementing **cutting-plane**
methods for small dense problems:

1. **Gomory-style ILP cuts** — solve the LP relaxation with an **embedded
   Bland tableau simplex**, generate a **Gomory fractional cut** from a
   fractional basic row, add the cut, and reoptimize (dual restore + primal)
   until the decision vector is integer (or a cut / pivot budget is hit).
2. **Kelley sketch** — minimize a simple **max-of-affines** convex
   piecewise-linear $f$ by iteratively adding **supporting hyperplane** cuts
   from a subgradient and resolving an LP master problem over a box.

Caps: $m,n\le 12$ (including slacks / cut columns). **No** `with`-clause
dependency on the sibling simplex package (tableau ideas only).

Based on [Wikipedia: Cutting-plane method](https://en.wikipedia.org/wiki/Cutting-plane_method)
(Ralph E. Gomory for MILP; Kelley / Kelley–Cheney–Goldstein for convex
nondifferentiable minimization).

Sibling LP (vertex / tableau):
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)**.
Future: **Branch-and-Cut** (cuts inside branch-and-bound).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **ILP idea** | LP relax → separate → cut → repeat | Gomory fractional cuts |
| **LP engine** | Embedded dense Bland tableau | Two-phase + dual restore |
| **Cut** | $\sum_j \{ \bar a_{ij}\} x_j \ge \{\bar b_i\}$ | From fractional tableau row |
| **Convex** | Kelley master $\min t$ s.t. $t\ge a^\top x+\beta$ | Max-of-affines $f$ |
| **Status** | `Optimal` / `Infeasible` / `Iteration_Limit` / `Unbounded` | Plus $x$, $z$ |
| **Limits** | $m\le 12$, $n\le 12$ | Educational dense |

## Brief history

Cutting planes for integer programming were introduced by **Ralph Gomory** in
the 1950s. Alone they were long considered numerically fragile; from the
mid-1990s they became central inside **branch-and-cut** (with careful
numerics). **Kelley’s method** (and related bundle methods) applies the same
“add a linear inequality that cuts off the current point” idea to general
convex (possibly nonsmooth) minimization via subgradients.

## Gomory ILP sketch

Given a pure integer program

$$
\max_x\; c^\top x
\quad\text{subject to}\quad
Ax\le b,\quad x\ge 0,\quad x\in\mathbb{Z}^n,
$$

drop integrality and solve the LP relaxation with the embedded simplex. At an
optimal tableau row for a basic variable,

$$
x_i + \sum_j \bar a_{ij}\, x_j = \bar b_i.
$$

If $\bar b_i$ is not integer, the **Gomory fractional cut** is

$$
\sum_j \{\bar a_{ij}\}\, x_j \ge \{\bar b_i\},
\qquad
\{u\} = u - \lfloor u \rfloor \in [0,1).
$$

This package appends the cut (new slack, negative RHS), restores feasibility
with a **dual-simplex** step, then reoptimizes until $x$ is integer within
`Integer_Tol`, or `Max_Cuts` / pivot budgets expire.

### Classic example

$$
\max\; x+y
\quad\text{s.t.}\quad
2x+2y\le 3,\quad x,y\ge 0\text{ integer}.
$$

LP optimum $1.5$ (fractional); cutting planes reach IP optimum $1$ at
$(1,0)$ or $(0,1)$.

## Kelley sketch

For $f(x)=\max_{k=1..K}(a_k^\top x + b_k)$, start from a box midpoint, evaluate
$f$ and a **subgradient** $g\in\partial f(x)$, add the supporting inequality
$t \ge g^\top x + \beta$ with $\beta = f(x)-g^\top x$, and solve the master LP

$$
\min_{x,t}\; t
\quad\text{s.t.}\quad
\text{all accumulated cuts},\quad
x\in[x_{\mathrm{lo}},x_{\mathrm{hi}}].
$$

Stop when master $t$ matches $f(x)$ within tolerance.

## API summary

| Symbol | Role |
| --- | --- |
| `Config` | `Max_Cuts`, `Max_Pivots`, `Tol`, `Integer_Tol` |
| `Result` | `Stat`, `Objective`, `X`, `N_Vars`, `N_Cuts`, `N_Pivots`, `Success` |
| `Maximize_LP` | Embedded Bland LP: $\max c^\top x$ s.t. $Ax\le b$, $x\ge 0$ |
| `Solve_ILP_Cutting_Planes` | Gomory cutting-plane loop for pure IP |
| `Gomory_Cut_From_Row` | Build fractional cut from a tableau row |
| `Is_Integer_Vector` / `Near` / `Frac` | Numeric helpers |
| `Solve_Kelley` | Kelley master for max-of-affines over a box |
| `Eval_Max_Of_Affines` / `Subgradient_Max_Of_Affines` | Convex oracle |

Tableau helpers (`Build_Tableau`, `Pivot`, `Select_Entering`, …) mirror the
sibling simplex layout for tests and education.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022`. Expect `Pass_Count ≥ 100`, `Fail_Count=0`.

## Caveats

- **Educational**, not a production MILP / convex solver: tiny dense caps,
  naive Gomory generation (no MIR, no lift-and-project, no cut pool management).
- Classic **Gomory fractional cuts** assume **integer** $A,b$ (so slacks are
  integer when $x$ is); non-integer RHS needs mixed-integer Gomory / GMI.
- Numerical instability is the classical Gomory weakness; this code uses plain
  `digits 15` floats and simple tolerances.
- Mixed-integer (some continuous vars) and equality-only forms are out of
  scope; Pure IP + $\le$ inequalities only.
- Kelley here is a **sketch** for max-of-affines on a box, not a full bundle
  method with aggregation / trust regions.
- Empty GitHub remote exists for this title; **do not push** from this task.

## Layout

Exactly seven root files (no `main.adb`):

- `cutting_plane_method.ads` / `.adb` — package
- `cutting_plane_method.gpr` — GNAT project
- `Makefile` — `all` / `test` / `clean`
- `tests.adb` — standalone test driver
- `README.md` — this file
- `.gitignore` — `obj/` / `bin/`
