# Exact Cover — Ada 2023

Educational, self-contained Ada 2023 **survey** of the **exact cover**
problem: formal definition, incidence-matrix framing, verification helpers
(`Is_Exact_Cover`, `Is_Partial_Cover`, `Conflicts`), and a **naive /
backtracking bitset solver** for tiny instances (optional MRV). A method
taxonomy points to Algorithm X, dancing links (DLX), and integer LP as
*forthcoming* here — see sibling packages for those solvers.

Based on [Wikipedia: Exact cover](https://en.wikipedia.org/wiki/Exact_cover).
Related: [Knuth’s Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X),
[Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Algorithm-X](https://github.com/RobertBoettcherSF/Ada-Algorithm-X)** —
  dense-matrix Algorithm X (explicit active row/column masks)
- **[Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links)** —
  sparse circular doubly linked DLX implementation of the same search
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: universe $|X|\le 64$, subsets $\le 64$, stored
solutions $\le 64$. Pentomino / Sudoku-scale instances are intentionally
out of scope — use the Algorithm X / DLX siblings.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Representation** | Bit masks (`Unsigned_64`) per subset | Caps $\|X\|\le 64$ |
| **Verification** | `Is_Exact_Cover` / `Is_Partial_Cover` | Union + disjointness |
| **Search** | Naive DFS + optional MRV | `Solve_Backtrack`, `Count_Covers` |
| **Empty subsets** | Free at leaf ($2^{k}$ variants) | Wikipedia NOPE |
| **Taxonomy** | `Method_Kind` + `Classify` | Only naive implemented here |
| **Demos** | Knuth matrix; NOPE; partition toy | Tiny textbooks |

## Definition

Given a collection $\mathcal{S}$ of subsets of a set $X$, an **exact cover**
is a subcollection $\mathcal{S}^{*}\subseteq\mathcal{S}$ such that the
members of $\mathcal{S}^{*}$ are **pairwise disjoint** and their union is
exactly $X$:

$$
\bigcup_{S\in\mathcal{S}^{*}} S = X
\quad\text{and}\quad
S_i\cap S_j=\emptyset\ \text{for distinct}\ S_i,S_j\in\mathcal{S}^{*}.
$$

Equivalently, every element of $X$ lies in **exactly one** chosen subset.
As a $0$-$1$ **incidence matrix** (rows = members of $\mathcal{S}$,
columns = elements of $X$), an exact cover is a set of rows such that each
column contains a $1$ in exactly one selected row.

## Relation to Algorithm X and DLX

| | This package (`Exact_Cover`) | [Ada-Algorithm-X](https://github.com/RobertBoettcherSF/Ada-Algorithm-X) | [Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links) |
| --- | --- | --- | --- |
| Role | Problem survey + checker + tiny solver | Knuth Algorithm X (dense) | DLX (sparse links) |
| Storage | Row bit masks | Boolean matrix + active masks | Node pool L/R/U/D |
| Search | Naive DFS / optional MRV | Algorithm X + MRV | Same search, $O(1)$ splice |
| Best for | Definitions, taxonomy, toys | Teaching Algorithm X steps | Larger / sparser covers |

Do **not** `with` the sibling packages from this one; compare them via the
README links. Integer linear programming is catalogued as `Integer_LP`
(*Forthcoming*) for survey completeness.

## Empty subsets

An empty member of $\mathcal{S}$ never covers an element, so any exact
cover remains exact after freely adjoining any subset of the empty rows.
The Wikipedia **NOPE** example ($N=\emptyset$, $O=\{1,3\}$, $P=\{1,2,3\}$,
$E=\{2,4\}$) therefore has **two** exact covers: $\{O,E\}$ and $\{N,O,E\}$.
The backtracker solves on nonempty rows, then expands $2^{k}$ empty-row
combinations at each leaf.

## Classic examples

**Knuth / Wikipedia detailed matrix.** Universe $X=\{1,\ldots,7\}$ and

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

Unique exact cover $\mathcal{S}^{*}=\{B,D,F\}$ (1-based subset indices
$\{2,4,6\}$).

**Partition toy.** $X=\{1,2,3\}$ with all seven nonempty subsets — exact
covers are the **set partitions** of a $3$-set (Bell number $B_3=5$).

## API (`Exact_Cover`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Universe_Size`, `Max_Subset_Count`, `Max_Solutions` | Educational bounds |
| Types | `Instance`, `Selection`, `Bit_Set`, `Bool_Matrix` | Bitset incidence |
| Bits | `Element_Bit`, `Universe_Mask`, `Popcount`, `Bit_Is_Set` | Mask helpers |
| Build | `Clear`, `Set_Universe`, `Add_Subset`, `From_Incidence_Matrix` | Construct instances |
| Verify | `Conflicts`, `Is_Partial_Cover`, `Is_Exact_Cover`, `Cover_Count_Of` | Checker |
| Search | `Solve_Backtrack`, `Solve_All`, `Count_Covers` | Naive DFS (+ MRV) |
| Examples | `Build_Knuth_Example`, `Build_NOPE_Example`, `Build_Partition_Toy` | Textbooks |
| Taxonomy | `Method_Kind`, `Classify`, `Method_Name`, `Implemented`, `Forthcoming` | Survey map |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

`Method_Kind` values: `Naive_Backtrack` (**Implemented**), `Algorithm_X`,
`Dancing_Links`, `Integer_LP` (all three **Forthcoming** in this repo).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Exact cover](https://en.wikipedia.org/wiki/Exact_cover)
- [Wikipedia: Knuth’s Algorithm X](https://en.wikipedia.org/wiki/Knuth%27s_Algorithm_X)
- [Wikipedia: Dancing Links](https://en.wikipedia.org/wiki/Dancing_Links)
- D. E. Knuth, *Dancing Links*, arXiv:cs/0011047
- Sibling: [Ada-Algorithm-X](https://github.com/RobertBoettcherSF/Ada-Algorithm-X)
- Sibling: [Ada-Dancing-Links](https://github.com/RobertBoettcherSF/Ada-Dancing-Links)
- Series: https://github.com/RobertBoettcherSF/

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
