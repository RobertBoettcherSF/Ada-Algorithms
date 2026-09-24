# Schensted algorithm in Ada 2022

Educational Ada package implementing **Schensted row insertion** (the insertion half of the [Robinson–Schensted–Knuth (RSK) correspondence](https://en.wikipedia.org/wiki/Schensted_algorithm)).

Reference: [Schensted algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Schensted_algorithm)

## What it does

Given a permutation (or more generally a word) $w = w_1 w_2 \ldots w_n$, Schensted insertion builds a Young tableau $P$ by inserting the letters one by one with **row bumping**:

1. To insert $x$ into a row, find the **leftmost** entry strictly greater than $x$.
2. Replace that entry by $x$ and **bump** the old value into the next row.
3. If no such entry exists, **append** $x$ to the row (creating a new box).

Cascading bumps continue until some row accepts the value by appending. The final $P$ is the **insertion tableau**. In full RSK a **recording tableau** $Q$ of the same shape stores the step index at which each new box appeared.

### Longest increasing subsequence

A classical theorem of Schensted states that the length of a **longest increasing subsequence** (LIS) of $w$ equals the length of the **first row** of $P$:

$$
\operatorname{LIS}(w) = \lambda_1(P)
$$

where $\lambda(P)$ is the shape (partition) of $P$. Dually, the length of a longest *decreasing* subsequence equals the number of rows of $P$.

## Package API (`Schensted`)

| Entity | Role |
|--------|------|
| `Max_N` | Maximum $n$ (64) |
| `Word` | `array (Positive range <>) of Positive` |
| `Tableau` | Private Young tableau |
| `Invalid_Argument` | Empty/oversized word, non-permutation, bad index |
| `Empty_Tableau` | Zero-box tableau |
| `Insert` | Single row-insertion step |
| `Insert_Word` | Build insertion tableau $P$ from a permutation of $1..n$ |
| `Insert_Word_RSK` | Build both $P$ and recording tableau $Q$ |
| `First_Row_Length` / `LIS_Length` | Schensted LIS connection |
| `Is_Valid_Tableau` | Strict row/column increase + partition shape |
| `Element`, `Row_Length`, `Num_Rows`, `Num_Boxes` | Accessors |
| `Equal`, `Shape_Equal`, `Image` | Comparison / debug |

Words passed to `Insert_Word` / `LIS_Length` / `Insert_Word_RSK` must be permutations of $1..n$ with $1 \le n \le \texttt{Max\_N}$.

## Build and test

```text
make          # gnatmake -gnatwa -gnat2022 -Pschensted.gpr
make test     # runs bin/tests → "Results: N PASS, 0 FAIL"
make clean
```

Requires GNAT (Ada 2022). Objects go to `obj/`, the test executable to `bin/tests`. There is no `main.adb`; `tests.adb` is the sole main unit.

## Example

For $w = (2,4,3,1)$:

$$
P =
\begin{array}{cc}
1 & 3 \\
2 \\
4
\end{array}
$$

First row length $2$ matches $\operatorname{LIS}(w)=2$ (e.g. $2,4$ or $2,3$).

## Layout

```text
ada-schensted/
  .gitignore
  Makefile
  README.md
  schensted.ads    -- package spec
  schensted.adb    -- package body
  schensted.gpr    -- GNAT project
  tests.adb        -- unit tests (main)
  obj/  bin/       -- build products (gitignored)
```

## License / intent

Teaching material for combinatorial algorithms in Ada. Not affiliated with Wikipedia; algorithm description adapted from the public Schensted / RSK literature.
