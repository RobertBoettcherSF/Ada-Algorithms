# Simplex Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Dantzig’s simplex
algorithm** for **linear programming**. The package maintains a dense
**tableau**, selects pivots with **Bland’s anti-cycling rule**, and uses a
**two-phase** method (artificial variables) so that infeasible problems are
detected as well as optimal and unbounded ones.

Solves small LPs in standard form

$$
\max_{x}\, c^\top x
\quad\text{subject to}\quad
Ax\le b,\quad x\ge 0
$$

by appending slack variables (and artificials when a basic feasible start is
missing). Equality form with an existing basic feasible tableau is accepted
via `Solve`.

Based on [Wikipedia: Simplex algorithm](https://en.wikipedia.org/wiki/Simplex_algorithm)
(George B. Dantzig, late 1940s).

**Not** the Nelder–Mead “simplex” method (derivative-free heuristic search over
a geometric simplex of $n+1$ points). That sibling is
**[Ada-Nelder-Mead](../ada-nelder-mead/)**; this package is the LP tableau method.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Gauss-Newton](../ada-gauss-newton/)**,
**[Ada-BFGS](../ada-bfgs/)**, **[Ada-Nelder-Mead](../ada-nelder-mead/)**.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Walk vertices of the feasible polytope | Improving BFS each pivot |
| **Form** | Dense canonical tableau | $m\le 16$, $n\le 16$ (incl. slacks) |
| **Enter** | Bland: smallest $j$ with $\bar c_j<0$ | Anti-cycling |
| **Leave** | Min-ratio; Bland tie-break on basic index | Unbounded if no positive $a_{ij}$ |
| **Start** | Slacks if $b\ge 0$; else Phase I artificials | Two-phase → infeasibility |
| **Status** | `Optimal` / `Unbounded` / `Infeasible` | Plus objective and primal $x$ |
| **Contrast** | Dantzig LP simplex ≠ Nelder–Mead | Different problem class |

## Brief history

George Dantzig developed the simplex method in 1946–47 for US Air Force
planning, formulating linear inequalities with an explicit linear objective.
The name “simplex” (suggested by T. S. Motzkin) refers to simplicial cones at
polytope vertices, not to an explicit simplex data structure. Bland’s rule
(1977) is a simple deterministic pivot rule that **prevents cycling**. Interior-
point methods (Karmarkar and successors) are polynomial-time alternatives for
large LPs; this package is the classical dense educational tableau form.

## Problem statement

Given $A\in\mathbb{R}^{m\times n}$, $b\in\mathbb{R}^m$, $c\in\mathbb{R}^n$,
maximize $c^\top x$ subject to $Ax\le b$ and $x\ge 0$. Introduce nonnegative
**slack** variables $s$ so that

$$
Ax+s=b,\qquad x\ge 0,\quad s\ge 0.
$$

A **basic feasible solution** (BFS) sets $n$ nonbasic variables to zero and
reads the $m$ basic variables from the RHS. Each **pivot** exchanges one basic
and one nonbasic variable, moving to an adjacent vertex.

## Tableau (this package)

The dense tableau stores

$$
\begin{array}{c|cccc}
z & \bar c_1 & \cdots & \bar c_N \\\hline
b_1 & a_{11} & \cdots & a_{1N} \\
\vdots & \vdots & \ddots & \vdots \\
b_m & a_{m1} & \cdots & a_{mN}
\end{array}
$$

with $N$ including slacks (and temporary artificials). Row $0$ holds the
reduced costs for **maximization** (enter when $\bar c_j<0$). `Tableau.Basic(i)`
names the variable basic in row $i$.

## Bland’s rule (anti-cycling)

1. **Entering variable:** among columns with reduced cost $<-\texttt{Tol}$,
   choose the **smallest index**.
2. **Leaving variable:** among rows attaining the minimum nonnegative ratio
   $b_i/a_{ij}$ (over $a_{ij}>\texttt{Tol}$), leave the basic variable with the
   **smallest index**.

If every basic variable is strictly positive, each pivot improves $z$ and no
basis repeats. Degenerate BFSs can stall without improving $z$; Bland’s rule
still guarantees **finite termination** (no cycling).

## Two-phase method

When some $b_i<0$, the slack basis is not feasible. `Build_Tableau` negates
those rows and adds **artificial** variables so an identity basis exists, then
builds a Phase-I objective equivalent to maximizing $-\sum a_k$ (minimize the
sum of artificials).

- **Phase I:** run Bland simplex on the Phase-I row. If the optimum is
  strictly negative, artificials cannot all vanish ⇒ **`Infeasible`**.
- **Phase II:** drop artificial columns and maximize the original objective.
  A Phase-II entering column with no positive pivot entry ⇒ **`Unbounded`**.

(The Big-M method is an alternative single-phase encoding; this package uses
explicit two-phase.)

## One iteration (sketch)

1. `Select_Entering` (Bland) on the active objective row.
2. If none → **Optimal**; stop.
3. `Select_Leaving` (min-ratio + Bland); if none → **Unbounded**.
4. `Pivot` (Gauss–Jordan) and update `Basic`.
5. Repeat until optimal, unbounded, or `Max_Pivots` exhausted.

## Versus Nelder–Mead “simplex”

| | Dantzig simplex (this) | Nelder–Mead |
| --- | --- | --- |
| Problem | Linear program $c^\top x$, $Ax\le b$ | Smooth / black-box $\min f(x)$ |
| Object named “simplex” | Polytope vertex / basis exchange | $n+1$ sample points in $\mathbb{R}^n$ |
| Guarantee (LP) | Finite (with Bland); exact optimum | Heuristic; no LP optimality |
| Derivatives | None (tableau algebra) | None (value-only) |

Prefer **this package** for small dense LPs. Prefer **Nelder–Mead** for
derivative-free nonlinear search. Prefer **BFGS** / **Gauss–Newton** when
gradients (or residuals) are available for unconstrained or NLS problems.

## Built-in textbook checks (in `tests.adb`)

| Case | Form | Expected |
| --- | --- | --- |
| Classic | $\max 3x+5y$ s.t. $x\le 4$, $2y\le 12$, $3x+2y\le 18$ | $(2,6)$, $z=36$ |
| Unbounded | $\max x$ s.t. $x-y\le 1$ | `Unbounded` |
| Infeasible | $\max x$ s.t. $x\le 1$, $x\ge 2$ | `Infeasible` (Phase I) |
| Phase I→II | $\max x$ s.t. $x\ge 1$, $x\le 4$ | $x=4$, $z=4$ |

## API (`Simplex_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Matrix`, `Vector`, `Tableau`, `Config`, `Result`, `Status` | Domain |
| Helpers | `Near`, `Vec_Near`, `Active_Obj_Row` | Numerics / Phase-I row |
| Core | `Is_Optimal`, `Select_Entering`, `Select_Leaving`, `Pivot`, `Build_Tableau`, `Extract_Primal` | Tableau ops |
| Drivers | `Solve`, `Maximize` | Two-phase Bland simplex |

Named exception: `Invalid_Argument` (empty / oversized problem, near-zero
pivot).

`Config` defaults: `Max_Pivots=500`, `Tol=1e-10`.

`Result` fields: `Stat`, `Objective`, `X`, `N_Vars`, `N_Pivots`, `Success`
(`Success` is true iff `Stat=Optimal`).

Limits: `Max_Constraints=16`, `Max_Vars=16` (decision + slack + artificial
columns).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Simplex algorithm](https://en.wikipedia.org/wiki/Simplex_algorithm)
- Dantzig, G. B. *Linear Programming and Extensions*, Princeton, 1963
- Bland, R. G. “New finite pivoting rules for the simplex method,”
  *Mathematics of Operations Research*, 2(2), 1977
- Sibling packages in this series: Gauss–Newton, BFGS, Nelder–Mead
