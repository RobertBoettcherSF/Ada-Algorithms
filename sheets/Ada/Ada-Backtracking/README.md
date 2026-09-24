# Backtracking in Ada 2023

## Project Overview

**Backtracking** is a class of algorithms for constraint satisfaction and
enumeration: it **incrementally builds** partial candidates and
**abandons** (“backtracks”) a candidate as soon as it cannot possibly be
completed to a valid solution. When a cheap **reject** test exists,
whole subtrees of the potential search tree are skipped — often far
faster than brute-force listing of every complete candidate.

This package is an **Ada 2023 (ISO/IEC 8652:2023)** educational kit of
three classic demos:

| Demo | Partial candidate | Reject (prune) | Educational bound |
| --- | --- | --- | --- |
| **N-Queens** (`Solve_N_Queens` / `Count_N_Queens`) | $k$ queens in first $k$ rows | mutual attack | $N\le\mathrm{Max\_N}=14$ |
| **Subset sum** (`Subset_Sum`) | include/exclude prefix | residual vs remaining $+/-$ capacity | $n\le\mathrm{Max\_Subset\_N}=40$ |
| **Graph colouring** (`Color_Graph`) | colours for vertices $1..k$ | neighbour colour clash | $V\le 16$, $K\le 8$ |

Primary source:
[Wikipedia — Backtracking](https://en.wikipedia.org/wiki/Backtracking).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Backtracking`) | Build + prune; DFS on the potential tree |
| **[Ada-Brute-Force-Search](https://github.com/RobertBoettcherSF/Ada-Brute-Force-Search)** | Full generate-and-test; **no** prune |
| **[Ada-Branch-and-Bound](https://github.com/RobertBoettcherSF/Ada-Branch-and-Bound)** | Tree search with optimistic **numeric** bounds |
| **[Ada-Breadth-First-Search](https://github.com/RobertBoettcherSF/Ada-Breadth-First-Search)** / **[Ada-Depth-First-Search](https://github.com/RobertBoettcherSF/Ada-Depth-First-Search)** | Graph traversal, not CSP backtrack |

README links only — **no** package `with` of siblings. If `reject` always
returns false, backtracking degenerates to brute-force enumeration of the
potential search tree (Wikipedia).

## Wikipedia skeleton

Six procedural parameters over instance data $P$:

- $\mathrm{root}(P)$ — partial candidate at the root
- $\mathrm{reject}(P,c)$ — true only if $c$ is not worth completing
- $\mathrm{accept}(P,c)$ — true if $c$ solves $P$
- $\mathrm{first}(P,c)$ / $\mathrm{next}(P,s)$ — children of $c$
- $\mathrm{output}(P,c)$ — use a solution

$$
\begin{align*}
&\mathbf{procedure}\ \mathrm{backtrack}(P,c): \\
&\quad \mathbf{if}\ \mathrm{reject}(P,c):\ \mathbf{return} \\
&\quad \mathbf{if}\ \mathrm{accept}(P,c):\ \mathrm{output}(P,c) \\
&\quad s \leftarrow \mathrm{first}(P,c) \\
&\quad \mathbf{while}\ s \neq \Lambda:\ \mathrm{backtrack}(P,s);\ s \leftarrow \mathrm{next}(P,s)
\end{align*}
$$

The **actual** tree traversed is only the unpruned part of the **potential**
tree. Efficiency hinges on `reject` firing as close to the root as possible.

## Algorithms

### 1. N-Queens — `Solve_N_Queens` / `Count_N_Queens`

Place $N$ queens on an $N\times N$ board so that no two share a row,
column, or diagonal. Partial candidates are placements of $k$ queens in
rows $1..k$ (distinct columns). `reject` is true when any two among those
$k$ attack each other.

$$
\begin{align*}
&\text{place row } r = 1..N:\ \text{try columns } c = 1..N \\
&\quad \mathbf{if}\ \mathrm{Safe}(1..r-1,\, r,c):\ \text{place }(r,c);\ \text{recurse } r+1 \\
&\quad \text{else prune that branch}
\end{align*}
$$

Known solution counts (OEIS A000170): $N=4\to 2$, $N=5\to 10$,
$N=6\to 4$, $N=7\to 40$, $N=8\to 92$, $N=9\to 352$, $N=10\to 724$.
Boards $N=2,3$ have **zero** solutions. Brute force without prune would
explore up to $N^N$ placements; column/diagonal reject cuts this
dramatically.

`Solve_N_Queens` returns one placement (or `False`); `Count_N_Queens`
enumerates all. Raises `Invalid_Argument` when $N>\mathrm{Max\_N}$.

### 2. Subset sum — `Subset_Sum`

Decide whether a subset of array $A$ sums to $\mathit{Target}$. At index
$i$ with partial sum $s$, the residual need is $T-s$. Prune when

$$
T-s > \sum_{j\ge i}\max(0,A_j)
\quad\text{or}\quad
T-s < \sum_{j\ge i}\min(0,A_j).
$$

(Empty subset sums to $0$.) On success, `Chosen(I)` marks membership.
Without prune, the same tree has $2^n$ leaves — the approach taken by
`Brute_Force_Search.Subset_Sum_Exists` via bit masks.

Raises `Invalid_Argument` when $n>\mathrm{Max\_Subset\_N}$ or
`Chosen` bounds mismatch `A`.

### 3. Graph colouring — `Color_Graph`

Assign each vertex a colour in $1..K$ so adjacent vertices differ.
Partial candidates colour vertices $1..k$ in order; `reject` when the
newest colour equals a neighbour already coloured. Educational graphs
stay at $V\le\mathrm{Max\_Vertices}=16$, $K\le\mathrm{Max\_Colors}=8$.

## API (`Backtracking`)

| Group | Entry points |
| --- | --- |
| Caps | `Max_N`, `Max_Subset_N`, `Max_Vertices`, `Max_Colors` |
| Types | `Queen_Array`, `Element_Array`, `Boolean_Array`, `Adjacency_Matrix`, `Color_Array` |
| N-Queens | `Solve_N_Queens`, `Count_N_Queens`, `Is_Safe_Placement` |
| Subset sum | `Subset_Sum`, `Subset_Sum_Exists` |
| Colouring | `Color_Graph`, `Is_Valid_Colouring` |

Named exception: `Invalid_Argument`.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Pbacktracking.gpr
make test   # run bin/tests — expect ALL PASSED, ~120–200+ checks
make clean
```

Requires GNAT with Ada 2022/2023 support (`-gnat2022`). Zero warnings under
`-gnatwa`.

## License / attribution

Educational material for the RobertBoettcherSF Ada algorithm series.
Algorithm descriptions follow the public Wikipedia article on backtracking.
