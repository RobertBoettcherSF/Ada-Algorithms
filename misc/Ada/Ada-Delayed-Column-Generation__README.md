# Delayed Column Generation — Ada 2023

Educational, self-contained Ada 2023 package implementing **delayed column
generation** (also called **column generation**) for linear programs with
implicitly huge column sets. The demo application is the classical
**cutting-stock** LP: a restricted master problem (RMP) is solved repeatedly,
and a **pricing** subproblem proposes improving patterns until none remain.

Based on
[Wikipedia: Delayed column generation](https://en.wikipedia.org/wiki/Delayed_column_generation)
and
[Wikipedia: Column generation](https://en.wikipedia.org/wiki/Column_generation)
(Gilmore–Gomory cutting stock; Dantzig–Wolfe decomposition is the broader
framework — sibling **Ada-Dantzig-Wolfe** forthcoming).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only):
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)**,
**[Ada-Cutting-Plane-Method](../ada-cutting-plane-method/)**,
**[Ada-Branch-and-Cut](../ada-branch-and-cut/)**
(embedded Bland tableau ideas only — **no** `with`-clause dependency).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Master** | Restricted LP over current patterns $\lambda_j$ | Dense educational |
| **Objective** | $\min \sum_j c_j\lambda_j$ (cutting stock: $c_j=1$) | Cover demands |
| **Pricing** | Unbounded integer knapsack on duals $\pi$ | DP over width $W$ |
| **Enter column** | When reduced cost $c_j-\pi^\top a_j<0$ | Equiv. $\pi^\top a>c$ |
| **RMP solver** | Embedded Bland two-phase tableau | Caps below |
| **Start** | Trivial single-item patterns | $\lfloor W/w_i\rfloor$ of type $i$ |
| **Limits** | Items $\le 8$, $W\le 50$, columns $\le 64$ | Educational |

## Brief history

**Column generation** solves LPs whose constraint matrices have enormously many
columns by maintaining only a **restricted master** and generating columns on
demand. Gilmore and Gomory (1961–63) applied the idea to cutting stock;
**Dantzig–Wolfe decomposition** (1960) is the general block-angular form.
“Delayed” column generation emphasizes that columns are created only when
pricing proves they can improve the RMP.

## Cutting-stock RMP

Given rod length $W$, item widths $w_i$ and demands $d_i$ ($i=1,\dots,m$), a
**pattern** (column) $a\in\mathbb{Z}_+^m$ satisfies

$$
\sum_{i=1}^m w_i a_i \le W.
$$

The master LP (LP relaxation of the integer cutting-stock model) is

$$
\min_{\lambda\ge 0}\;\sum_j c_j\lambda_j
\quad\text{subject to}\quad
\sum_j a_{ij}\lambda_j \ge d_i\quad(i=1,\dots,m),
$$

with $c_j=1$ when each pattern uses one rod. Only a small pool of patterns is
kept; dual multipliers $\pi\ge 0$ of the cover rows are used for pricing.

## Pricing subproblem

For duals $\pi$, the reduced cost of a candidate pattern $a$ with cost $c$ is

$$
\bar c(a)=c-\pi^\top a.
$$

An improving column exists when $\bar c(a)<0$, i.e. when the knapsack value
$\pi^\top a$ exceeds $c$. This package solves

$$
\max_a\;\pi^\top a
\quad\text{subject to}\quad
\sum_i w_i a_i\le W,\quad a_i\in\mathbb{Z}_+,
$$

by a dense DP over capacity $0..W$ (`Price_Knapsack`). If the optimum is
$\le c$ (within `Tol`), the RMP duals are optimal for the full master and
column generation stops.

## Algorithm sketch

1. Seed the pool with **trivial single-item** patterns
   $a^{(i)}$ having $a^{(i)}_i=\lfloor W/w_i\rfloor$.
2. **Solve_RMP**: minimize $\sum c_j\lambda_j$ over the current pool (encoded as
   a maximization tableau with negated costs / negated $\ge$ rows; Bland
   two-phase simplex).
3. Read duals $\pi$; call **Price_Knapsack**.
4. If an improving pattern is found and the pool is not full, **Add_Column**
   and repeat; else stop (`Optimal`, or `Column_Limit` / `Iteration_Limit`).

## API summary

| Symbol | Role |
| --- | --- |
| `Config` | `Max_Iters`, `Max_Columns`, `Max_Pivots`, `Tol` |
| `Result` / `RMP_Result` | Status, objective, $\lambda$, duals, pool |
| `Solve_Cutting_Stock` | Full delayed CG on widths / demand / $W$ |
| `Solve_RMP` | Master LP over a column pool |
| `Price_Knapsack` | Pricing DP |
| `Reduced_Cost` | $c-\pi^\top a$ |
| `Init_Trivial_Patterns` / `Add_Column` / `Pattern_Exists` | Pool helpers |
| `Near` | Absolute tolerance compare |

## Build and test

```bash
make clean && make
make test
```

`make` runs `gnatmake -gnatwa -gnat2022` via `delayed_column_generation.gpr`
(main: `tests.adb`). Expect `Pass_Count` $\ge 100$ and `Fail_Count=0`.

## Caveats

- Educational dense code: not a production MIP/CG solver.
- Returns the **LP relaxation** of cutting stock (fractional $\lambda$ allowed);
  integer pattern counts need a further IP / branch-and-price step.
- Caps: $m\le 8$, $W\le 50$, pool $\le 64$; dual extraction assumes the
  surplus-column path of the embedded $\ge$-row transform.
- No `with` of sibling packages; Bland simplex is embedded locally.

## License

For educational use in the Ada algorithm series.
