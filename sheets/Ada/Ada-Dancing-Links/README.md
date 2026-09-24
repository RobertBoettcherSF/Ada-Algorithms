# Dancing Links (DLX) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Donald Knuth’s
dancing links** technique for **Algorithm X** on **exact cover** problems.
A sparse 0-1 matrix is stored as a toroidal circular doubly linked list of
nodes; `Cover` / `Uncover` splice links so that backtracking restores
structure by letting the links “dance.”

Based on [Wikipedia: Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links)
(Knuth, arXiv cs/0011047). Related:
[Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X),
[Exact cover](https://en.wikipedia.org/wiki/Exact_cover).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Exact-Cover](https://github.com/RobertBoettcherSF/Ada-Exact-Cover)** —
  exact-cover problem framing (when published)
- **Algorithm X** sibling (when published) —
  https://github.com/RobertBoettcherSF/ (series root)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: columns $\le 64$, nodes $\le 2048$, stored solutions
$\le 64$, N-queens $N\le 8$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Fixed pool of `Node` records | Indices, not heap `access` |
| **Links** | Circular L/R/U/D + `Col` | Root header at node $0$ |
| **Cover / Uncover** | Knuth splice | Exact reverse on backtrack |
| **Column choice** | MRV (min `Size`) | Among **primary** headers |
| **Secondary cols** | Linked vertically only | Never chosen; optional cover |
| **Demos** | Knuth textbook matrix; N-queens; $2\times 2$ dominoes | Caps keep search small |
| **API** | `Build_*`, `Cover`/`Uncover`, `Solve` / `Solve_All` | `Count_Solutions` |

## Exact cover and Algorithm X

Given a 0-1 matrix, select a subset of rows so that each **primary**
column contains a $1$ in exactly one selected row. Algorithm X is the
obvious depth-first search:

1. If no primary columns remain, the partial selection is a solution.
2. Otherwise choose a primary column $c$ (here: fewest $1$s).
3. For each row $r$ that still has a $1$ in $c$: select $r$, cover every
   column touched by $r$, recurse, then uncover (backtrack).

## Dancing links splice

Removing node $x$ from a circular doubly linked list:

$$
x.\mathrm{left}.\mathrm{right} \leftarrow x.\mathrm{right},\quad
x.\mathrm{right}.\mathrm{left} \leftarrow x.\mathrm{left}
$$

Restoring $x$ (left/right of $x$ were **not** modified):

$$
x.\mathrm{left}.\mathrm{right} \leftarrow x,\quad
x.\mathrm{right}.\mathrm{left} \leftarrow x
$$

`Cover(c)` unlinks header $c$ horizontally, then for each data node $i$
down column $c$, walks right and splices each $j\neq i$ out of its
vertical list, decrementing that column’s `Size`. `Uncover(c)` walks the
same nodes in reverse order and restores links — the dance.

## Primary vs secondary columns

**Primary** headers sit in Root’s horizontal circular list and must be
covered. **Secondary** headers (e.g. N-queens diagonals) are *not* linked
from Root, so `Choose_Column` never picks them, but rows that touch them
still call `Cover`/`Uncover` so at most one selected row uses each
secondary column.

## N-queens encoding

For board size $N$, matrix rows are the $N^2$ placements $(r,c)$.
Columns:

- **Primary:** $N$ row constraints + $N$ column constraints
- **Secondary:** $2N-1$ diagonals $r-c+\mathrm{const}$ and $2N-1$
  diagonals $r+c$

Total columns $6N-2$ (fits the $64$-column cap for $N\le 8$). Known
solution counts: $N=4\to 2$, $N=5\to 10$, $N=6\to 4$, $N=7\to 40$,
$N=8\to 92$.

## API (`Dancing_Links`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Columns`, `Max_Nodes`, `Max_Solutions`, `Max_Queens_N` | Educational bounds |
| Types | `Node`, `Solver`, `Solution`, `Bool_Matrix`, `Node_Id` | Fixed pools |
| Build | `Clear`, `Build_From_Matrix`, `Build_From_Row_Sets` | 0-1 matrix → DLX |
| Inspect | `Header_Size`, `Primary_Header_Count`, `Structure_Fingerprint` | Tests / teaching |
| Primitives | `Choose_Column`, `Cover`, `Uncover` | Knuth DLX |
| Search | `Solve`, `Solve_All`, `Count_Solutions` | Algorithm X |
| Queens | `Build_N_Queens`, `N_Queens_Count`, `N_Queens_Solve` | Exact-cover demo |
| Textbook | `Build_Knuth_Example`, `Knuth_Example_Solution_Count` | Unique $\{1,4,5\}$ |

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

- [Wikipedia: Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links)
- [Wikipedia: Knuth’s Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X)
- [Wikipedia: Exact cover](https://en.wikipedia.org/wiki/Exact_cover)
- D. E. Knuth, *Dancing Links*, arXiv:cs/0011047
- Sibling: [Ada-Exact-Cover](https://github.com/RobertBoettcherSF/Ada-Exact-Cover)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
