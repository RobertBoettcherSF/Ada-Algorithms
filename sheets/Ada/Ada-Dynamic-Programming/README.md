# Dynamic Programming — Ada 2023

Educational, self-contained Ada 2023 **survey / classic-examples** package
for **dynamic programming** (Bellman): problems with **optimal substructure**
and **overlapping subproblems**, solved by **memoization** (top-down) or
**tabulation** (bottom-up). Includes bounded Integer demos of Fibonacci,
0/1 knapsack, unbounded coin change, LCS, Levenshtein edit distance,
matrix-chain ordering, unique grid paths, and rod cutting.

**Honest scope:** educational tables with caps $n\le 64$, capacity
$\le 256$, string length $\le 64$, Fibonacci index $\le 92$. Not a
production solver for large ILPs or string corpora.

Based on [Wikipedia: Dynamic programming](https://en.wikipedia.org/wiki/Dynamic_programming).

Siblings (full GitHub URLs; README links only — **no** `with` deps):

| Package | Role |
| --- | --- |
| [Ada-Chain-Matrix-Multiplication](https://github.com/RobertBoettcherSF/Ada-Chain-Matrix-Multiplication) | Dedicated matrix-chain package (when present) |
| [Ada-Ellipsoid-Method](https://github.com/RobertBoettcherSF/Ada-Ellipsoid-Method) | Convex feasibility / Khachiyan ellipsoid |
| [Ada-Branch-and-Bound](https://github.com/RobertBoettcherSF/Ada-Branch-and-Bound) | Tree search / bounding (when present) |
| [Ada-Combinatorial-Optimization](https://github.com/RobertBoettcherSF/Ada-Combinatorial-Optimization) | Combinatorial survey umbrella (when present) |
| [Ada-Integer-Linear-Programming](https://github.com/RobertBoettcherSF/Ada-Integer-Linear-Programming) | ILP survey incl. 0–1 knapsack DP |
| [Ada-Branch-and-Cut](https://github.com/RobertBoettcherSF/Ada-Branch-and-Cut) | B&B + cuts |

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Optimal substructure + overlapping subproblems | Bellman |
| **Fill** | Tabulation (default) / memoization (Fib) | `Fill_Strategy` |
| **Taxonomy** | `Problem_Kind` + `Problem_Info` tags | Survey helpers |
| **Fib** | Bottom-up + top-down memo | $F(n)$ up to $n=92$ |
| **Knapsack** | 0/1 DP; optional selection | Capacity $\le 256$ |
| **Coins** | Min coins **and** combination count | Unbounded |
| **LCS / Edit** | 2-D string DP | Length $\le 64$ |
| **Matrix chain** | Cost + split table | Classic CLRS dims |
| **Paths / rod** | Grid path count; rod cutting | Small grids / rods |

## Bellman intuition

Dynamic programming simplifies a decision by breaking it into simpler
subproblems. When an optimal solution contains optimal solutions to
subproblems (**optimal substructure**) and the same subproblems recur
(**overlapping subproblems**), storing answers avoids exponential
recomputation.

In the discrete optimization setting, a value function $V$ often obeys a
**Bellman equation**. Schematically, for a finite horizon with state $y$
and feasible action $a$,

$$
V_{i-1}(y)=\max_{a}\bigl\{g_i(y,a)+V_i(T_i(y,a))\bigr\},
$$

working **backward** from a terminal $V_n$. Equivalently, many CS textbooks
write a recurrence for a table entry $dp[\cdot]$ and fill it by increasing
subproblem size (**tabulation**) or by recursion with a cache
(**memoization**).

Example — Fibonacci:

$$
F(0)=0,\quad F(1)=1,\quad F(n)=F(n-1)+F(n-2)\ (n\ge 2).
$$

Example — 0/1 knapsack with capacity $W$ and items $(w_i,v_i)$:

$$
dp[i][w]=\max\bigl(dp[i-1][w],\,dp[i-1][w-w_i]+v_i\bigr)
\quad(w\ge w_i).
$$

Example — Levenshtein distance (unit costs):

$$
d(i,j)=\min\bigl\{d(i-1,j)+1,\;d(i,j-1)+1,\;d(i-1,j-1)+[a_i\ne b_j]\bigr\}.
$$

## Classic examples in this package

1. **Fibonacci** — `Fibonacci` (tabulation, $O(1)$ extra space) and
   `Fibonacci_Memo` (top-down memo table). Cap $n\le 92$ (`Fib_Value`).
2. **0/1 knapsack** — `Knapsack_01` max value; `Knapsack_01_With_Selection`
   reconstructs a boolean selection vector.
3. **Unbounded coin change** — `Min_Coins` (fewest coins, or $-1$ if
   impossible) and `Coin_Combinations` (number of **unordered**
   combinations; amount $0$ → $1$).
4. **LCS** — `LCS_Length` and `LCS_String` (one valid subsequence).
5. **Edit distance** — `Edit_Distance` with insert/delete/substitute cost $1$.
6. **Matrix-chain order** — `Matrix_Chain_Cost` / `Matrix_Chain_Order`
   (min scalar multiplications + `Split` table). Dimension array length
   $p+1$ for $p$ matrices.
7. **Grid paths / rod cutting** — `Unique_Paths(m,n)` (only right/down);
   `Rod_Cutting` (CLRS-style unbounded cuts).

## Taxonomy API

`Problem_Kind` enumerates the demos. `Classify` returns `Problem_Info`
with `Uses_Optimal_Substructure`, `Uses_Overlapping_Subproblems`,
`Default_Strategy`, and a hint `Typical_Table_Dims` ($1$ or $2$).
Helpers: `Problem_Name`, `Strategy_Name`, `Problem_Count`.

## API (`Dynamic_Programming`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Fib_N`, `Max_Items`, `Max_Capacity`, `Max_String_Len`, … | Educational bounds |
| Taxonomy | `Problem_Kind`, `Fill_Strategy`, `Classify`, `Uses_*` | Survey tags |
| Fib | `Fibonacci`, `Fibonacci_Memo` | Tabulation / memo |
| Knapsack | `Knapsack_01`, `Knapsack_01_With_Selection` | 0/1 DP |
| Coins | `Min_Coins`, `Coin_Combinations` | Unbounded |
| Strings | `LCS_Length`, `LCS_String`, `Edit_Distance` | 2-D DP |
| Matrices | `Matrix_Chain_Cost`, `Matrix_Chain_Order` | Chain order |
| Other | `Unique_Paths`, `Rod_Cutting` | Paths / cutting |

Exceptions: `Invalid_Argument`, `Impossible` (reserved for callers).

## Build & test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pdynamic_programming.gpr
make test   # runs bin/tests; expect Fail_Count = 0
make clean
```

Root layout (exactly seven files; **no** `main.adb`):

`.gitignore`, `Makefile`, `README.md`, `dynamic_programming.ads`,
`dynamic_programming.adb`, `dynamic_programming.gpr`, `tests.adb`.

## Caveats

- **Integer educational demos** — not arbitrary-precision; Fibonacci stops
  at $n=92$ (signed 64-bit). Large coin/knapsack products can overflow
  `Natural` if you push dims past the documented caps.
- **One LCS / one split** — reconstruction returns **a** valid answer when
  several optima exist.
- **Coin combinations** count unordered combinations (outer loop over
  denominations), not permutations.
- Sibling repos are linked for the series; this package has **no** Ada
  `with` dependencies on them.

## License

Educational code for the RobertBoettcherSF Ada algorithm series.
