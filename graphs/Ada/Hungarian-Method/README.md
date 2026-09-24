# Hungarian Method (Kuhn–Munkres) — Ada 2023

Educational, self-contained Ada 2023 package implementing the classical
**Hungarian method** / **Kuhn–Munkres** algorithm for the **assignment
problem**: given an $n\times n$ cost matrix $C$, find a permutation $\pi$
minimizing (or maximizing) the assignment cost

$$
\sum_{i=1}^{n} C_{i,\pi(i)}.
$$

Equivalently, a minimum-cost perfect matching in the complete bipartite
graph of $n$ workers and $n$ jobs. This package uses a clear dual
$O(n^{3})$ formulation (row/column potentials, tight edges, successive
augmentations) that is equivalent to the classical matrix
star/prime/cover presentation.

Based on [Wikipedia: Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm)
(Harold Kuhn, 1955; James Munkres, 1957; anticipated by Carl Gustav Jacobi,
published 1890).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Combinatorial-Optimization](https://github.com/RobertBoettcherSF/Ada-Combinatorial-Optimization)** —
  combinatorial optimization survey / umbrella (**forthcoming**)
- Related series repos: https://github.com/RobertBoettcherSF/

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Problem** | Assignment / bipartite min-cost matching | Square $n\times n$ |
| **Algorithm** | Kuhn–Munkres dual $O(n^{3})$ | Potentials + augmenting paths |
| **Maximize** | `Maximize_Assignment` via $-C$ | Same solver |
| **Costs** | Educational `Integer` (`Cost`) | Exact textbook checks |
| **Rectangular** | `Pad_To_Square` | Fill dummy rows/cols |
| **Dim** | $n\le 16$ | Tests focus $n\le 8$ |

## Brief history

Harold **Kuhn** (1955) published the method and named it “Hungarian”
because it builds on combinatorial lemmas of **Dénes Kőnig** and
**Jenő Egerváry**. **James Munkres** (1957) showed the procedure is
(strongly) polynomial; the algorithm is therefore also called
**Kuhn–Munkres**. In 2006 it was recognized that **Carl Gustav Jacobi**
had already solved the assignment problem in the 19th century (Latin
publication, 1890). The original presentation was $O(n^{4})$;
**Edmonds–Karp** and independently **Tomizawa** observed an $O(n^{3})$
refinement. The method anticipated later **primal–dual** algorithms;
**Ford–Fulkerson** extended related ideas to maximum flow.

## Assignment problem

Workers $S=\{1,\ldots,n\}$ and jobs $T=\{1,\ldots,n\}$ with costs
$c(i,j)$. Seek a bijection $\pi:S\to T$ of minimum total cost. In matrix
form this is

$$
\min_{P}\operatorname{Tr}(PC),
$$

where $P$ ranges over permutation matrices. Maximization is the same
problem on $-C$. A feasible dual **potential** $y$ on $S\cup T$ satisfies
$y(i)+y(j)\le c(i,j)$; the Hungarian method grows a matching of **tight**
edges ($y(i)+y(j)=c(i,j)$) until it is perfect, at which point matching
cost equals potential value and both are optimal.

## Matrix steps (classical view)

An equivalent matrix formulation (Wikipedia) proceeds by:

1. **Row reduce** — subtract each row minimum; optionally **column
   reduce**.
2. **Star** independent zeros; **cover** columns that contain starred
   zeros.
3. **Prime** uncovered zeros; adjust covers / build an **alternating
   path**; when stuck, subtract the uncovered minimum from uncovered
   entries (and add it on double-covered positions), then continue.

This package implements the dual potential form of the same ideas
(educational $O(n^{3})$ code path), returning the starred assignment.

## API summary

| Symbol | Role |
| --- | --- |
| `Cost`, `Cost_Matrix` | Integer costs; dense 1-based educational matrix |
| `Assignment` | Row $\to$ column map (`Assignment(I)=J`) |
| `Result` | `Total`, `Mapping`, `N`, `Success` |
| `Max_N` | Hard dimension cap ($16$) |
| `Minimize_Assignment` | Kuhn–Munkres minimum-cost assignment |
| `Maximize_Assignment` | Maximum-cost assignment (via negate) |
| `Assignment_Cost` | $\sum_i C(i,A(i))$ with permutation check |
| `Is_Square` / `Is_Permutation` | Validation helpers |
| `Pad_To_Square` | Rectangular $\to$ square with `Fill` |
| `Negate` | Entrywise $-C$ |

Square input is required for the solvers. For an $m\times k$ matrix with
$m,k\le\texttt{Max\_N}$, call `Pad_To_Square` first (use `Fill => 0` for
minimization dummies).

## Limits and caveats

- **Dense $n\le 16$**, educational `Integer` costs — not a production
  sparse / approximate matcher; no Jonker–Volgenant LAPJV tuning.
- **Square** matrices only at the solver boundary; rectangular instances
  must be padded explicitly (documented).
- Multiple optima: any minimum-cost permutation may be returned; tests
  accept all optima when uniqueness is not guaranteed.
- `Large_Cost` bounds admissible magnitudes for the dual implementation;
  keep $|C_{ij}|$ and $n\cdot\max|C_{ij}|$ well below that sentinel.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Phungarian_method.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`;
`tests.adb` is the sole main unit listed in `hungarian_method.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
hungarian_method.ads
hungarian_method.adb
hungarian_method.gpr
tests.adb
```

## References

1. Kuhn, H. W. (1955). The Hungarian method for the assignment problem.
   *Naval Research Logistics Quarterly*.
2. Munkres, J. (1957). Algorithms for the assignment and transportation
   problems. *Journal of the Society for Industrial and Applied
   Mathematics*.
3. [Wikipedia: Hungarian algorithm](https://en.wikipedia.org/wiki/Hungarian_algorithm)
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
