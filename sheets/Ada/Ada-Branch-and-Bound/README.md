# Branch and Bound — Ada 2023

Educational Ada 2023 package for the **branch-and-bound** (BnB) paradigm:
systematic enumeration of a search tree with **optimistic bounds** and
**pruning** against an incumbent. The concrete maximizer is the **0-1
knapsack** problem with the **Dantzig fractional-knapsack** upper bound.

Based on [Wikipedia: Branch and bound](https://en.wikipedia.org/wiki/Branch_and_bound).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Combinatorial-Optimization](https://github.com/RobertBoettcherSF/Ada-Combinatorial-Optimization)** —
  survey of discrete problems / methods (knapsack, MST, TSP sketches)
- **[Ada-Dynamic-Programming](https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming)** —
  Bellman DP survey (exact knapsack DP, …)
- **[Ada-Integer-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Integer-Linear-Programming)** —
  ILP / discrete LP sketches
- **[Ada-Branch-and-Cut](https://github.com/RobertBoettcherSF/Ada-Branch-and-Cut)** —
  MILP BnB with optional Gomory cuts (LP relaxations)

Educational limits: items $n\le 32$, capacity $\le 10000$; exhaustive
baseline for comparison uses $n\le 20$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Paradigm** | Branch + bound + prune | Land–Doig (1960); Little et al. (TSP) |
| **Primary problem** | 0-1 knapsack maximize value | Include / exclude next item |
| **Bound** | Dantzig fractional knapsack | Density order $v_i/w_i$ |
| **Prune** | Bound $\le$ incumbent | Maximization |
| **Search** | Depth-first recursion | Greedy incumbent seed |
| **Stats** | `Nodes`, `Pruned` | For tests / teaching |
| **Baseline** | `Knapsack_Exhaustive` | Tiny $n$ masks |

## Branch-and-bound idea

Candidate solutions form a **rooted tree**. At a node $I$ representing a
subset $S_I$ of the search space:

1. **Branch** — split $I$ into child instances whose union covers the
   optima in $S_I$ (here: fix the next item to $0$ or $1$).
2. **Bound** — compute an optimistic estimate that no feasible completion
   under $I$ can beat (for maximization: an **upper** bound).
3. **Prune** — discard $I$ when that bound cannot improve the **incumbent**
   (best feasible value found so far). Without a useful bound, BnB
   degenerates to exhaustive search.

Generic minimization (Wikipedia skeleton) keeps an upper bound $B$ on the
optimum and discards nodes whose **lower** bound is $\ge B$. Maximization
is dual: keep a lower bound (incumbent) and discard when the **upper**
bound is $\le$ incumbent.

$$
\begin{aligned}
&\textbf{maximize } && \sum_{i=1}^{n} v_i x_i \\
&\textbf{subject to } && \sum_{i=1}^{n} w_i x_i \le C,\quad
  x_i\in\{0,1\}.
\end{aligned}
$$

## Dantzig fractional bound

Sort remaining items by decreasing density $\rho_i = v_i / w_i$. Fill the
remaining capacity greedily with whole items; for the first item that does
not fit, take the **fractional** piece

$$
\frac{c_{\mathrm{left}}}{w_j}\, v_j.
$$

The resulting value is an upper bound on any 0-1 completion (LP relaxation
of the knapsack). This package exposes it as `Fractional_Bound`.

Example: weights $[2,3,4]$, values $[6,5,4]$, capacity $5$. Densities
$3$, $5/3$, $1$. Take item $1$ (value $6$), then a full fractional item $2$
worth $5$, bound $= 11$. The integer optimum is $9$ (items $1$+$2$ do not
both fit; best is $6$ or $5{+}4$).

## Algorithm (0-1 knapsack BnB)

1. Optionally permute items into decreasing-density order
   (`Sort_By_Density`).
2. Seed the incumbent with a greedy integral fill along that order.
3. Depth-first: at position $p$ in the order, evaluate
   $\mathrm{value}+\mathrm{Fractional\_Bound}(\text{from }p)$.
4. If bound $\le$ incumbent, **prune** and count `Pruned`.
5. Else branch **include** (if weight fits) then **exclude**.
6. At a leaf, update the incumbent when the packed value improves.
7. Return best value, bit-selection, `Nodes`, and `Pruned`.

`Branch_Knapsack` is an alias of `Solve_Knapsack_BnB`.

## API (`Branch_And_Bound`)

| Group | Entry points |
| --- | --- |
| Caps | `Max_Items`, `Max_Capacity` |
| Types | `Parameters`, `Result`, `Weight_Array`, `Value_Array`, `Selection`, `Index_Array`, `Real` |
| Utils | `Total_Weight`, `Total_Value`, `Is_Feasible`, `Density`, `Density_Order`, `Same_Selection` |
| Bound | `Fractional_Bound` (ordered remaining / full instance overloads) |
| Solve | `Solve_Knapsack_BnB`, `Branch_Knapsack` |
| Baseline | `Knapsack_Exhaustive` ($n\le 20$) |

`Result` fields: `Best_Value`, `Best_Weight`, `Selected`, `N_Items`,
`Nodes`, `Pruned`, `Exact`, `Success`.

Named exception: `Invalid_Argument` (capacity above cap).

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbranch_and_bound.gpr
make test   # run bin/tests — expect ALL PASSED, Pass_Count ≥ 80
make clean
```

Root layout (exactly seven tracked source/project files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `branch_and_bound.ads`,
`branch_and_bound.adb`, `branch_and_bound.gpr`, `tests.adb`.

## Caveats

- Educational caps only; not a production MIP solver.
- Depth-first search with a greedy seed; no best-bound priority queue.
- Zero-weight positive-value items are always attractive to the bound and
  the search (density sentinel).
- Exhaustive comparison is limited to $n\le 20$ ($2^{n}$ masks).
- Floating `Real` bounds use a tiny tolerance only in tests; pruning uses
  `Optimistic <= Real (incumbent)` (safe for maximization, may prune
  slightly late on noisy floats — values here are small integers).
