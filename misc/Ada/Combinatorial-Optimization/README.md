# Combinatorial Optimization — Ada 2023

Educational **survey** package for **combinatorial optimization**: find an
optimal object from a finite (or discrete) set of feasible solutions.
Taxonomy tags mark problems and methods as **Implemented** (self-contained
sketches in this repo) vs **Forthcoming** (sibling packages). Exact
algorithms, approximation heuristics, and metaheuristics are distinguished
in the method table.

Based on [Wikipedia: Combinatorial optimization](https://en.wikipedia.org/wiki/Combinatorial_optimization).
Related: knapsack, assignment / Hungarian, TSP, MST, set cover, integer
linear programming (ILP), GRASP, genetic algorithms, dynamic programming.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Hungarian-Method](https://github.com/RobertBoettcherSF/Ada-Hungarian-Method)** —
  Kuhn–Munkres exact assignment ($O(n^{3})$ matrix form)
- **[Ada-GRASP](https://github.com/RobertBoettcherSF/Ada-GRASP)** —
  greedy randomized adaptive search (metaheuristic)
- **[Ada-Dynamic-Programming](https://github.com/RobertBoettcherSF/Ada-Dynamic-Programming)** —
  Bellman DP survey (knapsack, LCS, edit distance, …)
- **[Ada-Integer-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Integer-Linear-Programming)** —
  ILP / discrete LP sketches
- **[Ada-Exact-Cover](https://github.com/RobertBoettcherSF/Ada-Exact-Cover)** —
  exact cover (related to set cover / dancing links)
- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  population metaheuristic survey

Educational limits: knapsack $n\le 20$, capacity $\le 100$; MST vertices
$\le 12$; TSP / assignment $n\le 8$ (factorial brute-force).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Definition** | Opt over discrete feasible set | Wikipedia NPO framing |
| **Exact** | DP, exhaustive, Kruskal MST | Tiny caps |
| **Approx** | Greedy density, 2-opt | Not FPTAS |
| **Metaheuristics** | Forthcoming tags | GRASP / GA siblings |
| **Taxonomy** | `Problem_Kind` / `Method_Kind` | Implemented vs Forthcoming |
| **Sketches** | Knapsack, MST, Assignment, TSP | Self-contained |

## Definition

Combinatorial optimization seeks

$$
x^{\star}\in\arg\min_{x\in\mathcal{F}}\, f(x)
$$

(or $\arg\max$) where the feasible set $\mathcal{F}$ is finite or discrete.
Classic problems include the **0-1 knapsack**, **assignment**, **TSP**,
**MST**, **set cover**, and **ILP**. Exhaustive search is often intractable;
practice uses exact special-structure algorithms, branch-and-bound, DP,
approximation algorithms, and metaheuristics.

### Exact vs approximate vs metaheuristic

- **Exact:** DP knapsack, exhaustive subsets / permutations, Kruskal MST
  (when the graph is connected), Hungarian assignment (sibling).
- **Approximate / local:** greedy-by-density knapsack; steepest **2-opt** TSP.
- **Metaheuristic (forthcoming here):** GRASP, genetic algorithms — see
  sibling READMEs.

Corresponding decision problems ask whether a feasible $x$ exists with
$f(x)\le m_{0}$ (or $\ge m_{0}$).

## Implemented sketches

### 0-1 knapsack

Maximize $\sum_i v_i x_i$ s.t. $\sum_i w_i x_i\le C$, $x_i\in\{0,1\}$.

- `Knapsack_DP` — classic $O(nC)$ table + reconstruction.
- `Knapsack_Exhaustive` — $2^{n}$ masks (tiny $n$).
- `Knapsack_Greedy_Density` — sort by $v_i/w_i$, take while capacity allows
  (`Exact => False`).

### MST (Kruskal)

Undirected dense `Cost_Matrix`; absent edges use `No_Edge`. Kruskal +
Union-Find returns a spanning tree of total weight $\sum_e w_e$ when
connected (`Success`), else a forest.

### Assignment

`Assignment_Cost` sums $C_{i,\pi(i)}$ for a permutation $\pi$.
`Assignment_Brute_Force` enumerates $n!$ permutations for $n\le 8$.
Polynomial exact matching is **Forthcoming** → Ada-Hungarian-Method.

### TSP

`TSP_Brute_Force` fixes city $1$ and permutes the rest ($(n-1)!$).
`TSP_Two_Opt` / `Two_Opt_Improve` steepest 2-opt local search
(`Exact => False`).

## API (`Combinatorial_Optimization`)

| Group | Entry points |
| --- | --- |
| Caps | `Max_Items`, `Max_Capacity`, `Max_Vertices`, `Max_Cities`, `Max_Assign` |
| Taxonomy | `Problem_Kind`, `Method_Kind`, `Classify_Problem`, `Classify_Method`, `Problem_Name`, `Method_Name`, `Implemented`, `Forthcoming` |
| Knapsack utils | `Total_Weight`, `Total_Value`, `Is_Feasible`, `Density` |
| Knapsack solvers | `Knapsack_DP`, `Knapsack_Exhaustive`, `Knapsack_Greedy_Density` |
| MST | `MST_Kruskal` |
| Assignment | `Assignment_Cost`, `Is_Permutation`, `Assignment_Brute_Force` |
| TSP | `Tour_Length`, `TSP_Brute_Force`, `Two_Opt_Improve`, `TSP_Two_Opt` |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Method / problem taxonomy

| `Problem_Kind` | Status | Family |
| --- | --- | --- |
| `Knapsack` | Implemented | packing |
| `Assignment` | Implemented (brute) | matching |
| `TSP` | Implemented | routing |
| `MST` | Implemented | graphs |
| `Set_Cover` | Forthcoming | covering |
| `ILP` | Forthcoming | polyhedral |

| `Method_Kind` | Status | Exactness |
| --- | --- | --- |
| `Exhaustive` | Implemented | exact |
| `Dynamic_Programming` | Implemented | exact |
| `Branch_and_Bound` | Forthcoming | exact |
| `Greedy` | Implemented | approx |
| `Local_Search` | Implemented | approx |
| `GRASP` | Forthcoming | metaheuristic |
| `Hungarian` | Forthcoming | exact |
| `Metaheuristic` | Forthcoming | metaheuristic |

## Complexity notes

Knapsack DP is $O(nC)$ time and space (educational table). Exhaustive
knapsack is $O(2^{n})$. Assignment / TSP brute-force are $O(n!)$ /
$O((n-1)!)$. Kruskal on a dense $n$-vertex graph is dominated by sorting
$O(n^{2})$ edges. 2-opt local search has no optimality guarantee.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pcombinatorial_optimization.gpr
make test   # run bin/tests — expect ALL PASSED, Fail_Count=0, Pass_Count 80+
make clean
```

No `main.adb`: `tests.adb` is the sole main. Do **not** push from this
workspace unless explicitly requested.

## Limits and caveats

- Caps: $n\le 20$ items, $C\le 100$; MST $n\le 12$; TSP / assignment
  $n\le 8$. Factorial sketches are demos, not solvers for real instances.
- Greedy knapsack is **not** an FPTAS; it can be arbitrarily suboptimal.
- Hungarian, GRASP, full ILP, set cover, branch-and-bound, and genetic
  algorithms are intentionally **not** implemented here (`Forthcoming` +
  sibling links).
- Dense `Cost_Matrix` only for MST/TSP/assignment (no sparse graph ADT).
- Educational code: clarity over industrial MIP / TSP engines.

## References

- Wikipedia: Combinatorial optimization; Knapsack problem; Assignment
  problem; Travelling salesman problem; Minimum spanning tree; Hungarian
  algorithm; GRASP; Dynamic programming; Integer programming.
- Papadimitriou & Steiglitz, *Combinatorial Optimization*.
- Korte & Vygen, *Combinatorial Optimization: Theory and Algorithms*.
