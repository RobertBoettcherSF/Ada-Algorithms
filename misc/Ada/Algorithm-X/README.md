# Knuth’s Algorithm X — Ada 2023

Educational, self-contained Ada 2023 package implementing **Donald Knuth’s
Algorithm X** for the **exact cover** problem on a clear **dense 0-1
incidence matrix** with **active row/column masks**. This is the abstract
search procedure that DLX accelerates with dancing links — here the matrix
reduction is written out explicitly so the recursion and MRV heuristic are
easy to follow.

Based on [Wikipedia: Knuth’s Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X).
Related: [Exact cover](https://en.wikipedia.org/wiki/Exact_cover),
[Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links)** —
  sparse circular doubly linked DLX implementation of the same search
- **[Ada-Exact-Cover](https://github.com/RobertBoettcherSF/Ada-Exact-Cover)** —
  exact-cover problem framing (when published)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: rows $\le 64$, columns $\le 64$, stored solutions
$\le 64$, N-queens $N\le 6$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Dense `Incidence` 0-1 matrix | Caps $64\times 64$ |
| **Reduction** | `Active_Row` / `Active_Col` masks | Snapshot + `Restore` |
| **Column choice** | MRV (fewest active $1$s) | Among **primary** cols |
| **Secondary cols** | Active but never chosen | N-queens diagonals |
| **Demos** | Knuth textbook matrix; tiny N-queens | Contrast to DLX sibling |
| **API** | `Build_*`, `Select_Row`, `Solve` / `Solve_All` | `Count_Solutions` |

## Exact cover

Given universe $U=\{1,\ldots,n\}$ and a collection of subsets of $U$, an
**exact cover** is a subcollection that partitions $U$: every element appears
in exactly one chosen set. As a 0-1 matrix $A$ with a column per element and
a row per set, the goal is a set of rows such that each **primary** column
contains a $1$ in exactly one selected row.

## Algorithm X (pseudocode)

Depth-first, nondeterministic search on the reduced matrix:

1. If no primary columns remain active, the partial selection is a solution.
2. Otherwise choose an active primary column $c$ (here: fewest active $1$s;
   ties broken by smallest index).
3. For each active row $r$ with $A_{r,c}=1$:
   - include $r$ in the partial solution;
   - for each column $j$ with $A_{r,j}=1$, delete every row $i$ with
     $A_{i,j}=1$, then delete column $j$;
   - recurse on the reduced matrix;
   - restore active masks (backtrack).

If $c$ has no remaining $1$, the branch fails. Any deterministic column rule
finds all solutions; Knuth’s MRV heuristic greatly prunes the tree.

$$
\text{choose } c=\arg\min_{c\ \mathrm{active\ primary}}\bigl|\{r\ \mathrm{active}:A_{r,c}=1\}\bigr|
$$

## Algorithm X vs dancing links (DLX)

| | This package (`Algorithm_X`) | Sibling `Dancing_Links` |
| --- | --- | --- |
| Storage | Dense boolean matrix + masks | Sparse node pool, L/R/U/D links |
| Delete / undo | Flip `Active_*`, then `Restore` | `Cover` / `Uncover` splice |
| Clarity | Matches Wikipedia steps literally | Same search, $O(1)$ link updates |
| Best for | Teaching the algorithm | Larger / sparser instances |

Same search tree, same MRV rule, same N-queens encoding idea — different
data structure. Do **not** `with` the DLX package from this one; compare them
side by side via the README links.

## Primary vs secondary columns

**Primary** columns must be covered exactly once and are candidates for
`Choose_Column`. **Secondary** columns (e.g. N-queens diagonals) are still
deactivated when a selected row touches them — so at most one selected row
uses each — but success only requires that no **primary** columns remain.

## Knuth’s textbook example

Universe $U=\{1,\ldots,7\}$ and sets

$$
\begin{align*}
A&=\{1,4,7\},&
B&=\{1,4\},&
C&=\{4,5,7\},\\
D&=\{3,5,6\},&
E&=\{2,3,6,7\},&
F&=\{2,7\}.
\end{align*}
$$

The unique exact cover is $\{B,D,F\}$ (1-based matrix rows $2,4,6$).
`Build_Knuth_Example` loads this matrix; MRV first selects column $1$.

## N-queens encoding

For board size $N\le 6$, matrix rows are the $N^2$ placements $(r,c)$.
Columns:

- **Primary:** $N$ row constraints + $N$ column constraints
- **Secondary:** $2N-1$ diagonals $r-c+N$ and $2N-1$ diagonals $r+c-1$

Total columns $6N-2$. Known solution counts: $N=4\to 2$, $N=5\to 10$,
$N=6\to 4$.

## API (`Algorithm_X`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Rows`, `Max_Columns`, `Max_Solutions`, `Max_Queens_N` | Educational bounds |
| Types | `Solver`, `Solution`, `Bool_Matrix`, `Active_State` | Dense matrix + masks |
| Build | `Clear`, `Build_From_Matrix`, `Build_From_Row_Sets` | 0-1 matrix → solver |
| Inspect | `Column_Ones`, `Active_Primary_Count`, `State_Fingerprint` | Tests / teaching |
| Primitives | `Choose_Column`, `Select_Row`, `Snapshot`, `Restore` | Dense Algorithm X |
| Search | `Solve`, `Solve_All`, `Count_Solutions` | Depth-first search |
| Queens | `Build_N_Queens`, `N_Queens_Count`, `N_Queens_Solve` | Exact-cover demo |
| Textbook | `Build_Knuth_Example`, `Knuth_Example_Solution_Count` | Unique $\{2,4,6\}$ |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Knuth’s Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X)
- [Wikipedia: Exact cover](https://en.wikipedia.org/wiki/Exact_cover)
- [Wikipedia: Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links)
- D. E. Knuth, *Dancing Links*, arXiv:cs/0011047
- Sibling: [Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
