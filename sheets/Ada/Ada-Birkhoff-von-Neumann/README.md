# Birkhoff–von Neumann Theorem — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Birkhoff–von Neumann theorem** for **doubly stochastic matrices**:
every doubly stochastic matrix $A$ is a convex combination of
permutation matrices

$$
A = \sum_{k} \lambda_k P_k, \qquad
\lambda_k \ge 0, \qquad
\sum_k \lambda_k = 1.
$$

The classroom **Birkhoff algorithm** peels off supported permutation
matrices: while the residual is not zero, find a perfect matching in the
bipartite **support graph** (entries above a zero tolerance), take
$\theta$ as the minimum of those entries, subtract $\theta P$, and
accumulate $(\theta,P)$. Cap $n\le 8$; dense educational `Long_Float`
matrices.

Based on
[Wikipedia: Doubly stochastic matrix — Birkhoff–von Neumann theorem](https://en.wikipedia.org/wiki/Doubly_stochastic_matrix#Birkhoff%E2%80%93von_Neumann_theorem)
(also known simply as Birkhoff’s theorem; sheet title:
**Birkhoff–von Neumann theorem**).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Sinkhorn-Knopp](https://github.com/RobertBoettcherSF/Ada-Sinkhorn-Knopp)** —
  Sinkhorn–Knopp scaling to a doubly stochastic matrix (**forthcoming**,
  next/last sibling). Contrast: Sinkhorn *produces* a DS matrix from a
  positive matrix via diagonal scaling; Birkhoff–von Neumann *decomposes*
  an already DS matrix into permutation matrices. No `with` of that package
  here.
- Related series repos: https://github.com/RobertBoettcherSF/

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Theorem** | DS $=$ conv(permutation matrices) | Birkhoff polytope $B_n$ |
| **Algorithm** | Birkhoff peeling | Support matching + $\theta$ subtract |
| **Matching** | DFS / backtracking | Classroom $n\le 8$ |
| **Scalars** | Educational `Long_Float` (`Real`) | Tolerance for “zero” |
| **Builders** | Identity / Uniform / Toy / Wiki $3\times 3$ | Convex combinations |
| **Check** | Reconstruct and compare | `Matrices_Near` / `Reconstruct_Near` |

## Brief history

**Garrett Birkhoff** (1946) proved that the set of $n\times n$ doubly
stochastic matrices is the convex hull of the permutation matrices; the
vertices of the **Birkhoff polytope** $B_n$ are exactly those permutation
matrices. **John von Neumann** contributed related work on the geometry of
the set of doubly stochastic matrices, and the result is commonly called the
**Birkhoff–von Neumann theorem**. A standard proof uses **Hall’s marriage
theorem** on the bipartite support graph: every nonempty set of rows has a
neighbourhood of columns at least as large, so a perfect matching exists
among the positive entries; subtracting a scaled permutation matrix reduces
the number of positive cells until nothing remains.

## Doubly stochastic matrices

A square matrix $X=(x_{ij})$ with nonnegative entries is **doubly
stochastic** (bistochastic) when every row and every column sums to $1$:

$$
\sum_{i} x_{ij} = \sum_{j} x_{ij} = 1.
$$

It is therefore both left- and right-stochastic. The class of all such
$n\times n$ matrices is the Birkhoff polytope $B_n$, a convex body of
affine dimension $(n-1)^2$ inside $\mathbb{R}^{n^2}$.

## Birkhoff algorithm (this package)

1. Start with a doubly stochastic residual $R \leftarrow A$.
2. While $R\not\approx 0$: find a permutation $\pi$ with
   $R_{i,\pi(i)} > \mathrm{Tol}$ for all $i$ (perfect matching in the
   support).
3. Set $\theta := \min_i R_{i,\pi(i)}$, record the term
   $(\theta, P_\pi)$, and replace $R \leftarrow R - \theta P_\pi$.
4. The collected coefficients satisfy $\sum \lambda_k = 1$ (exact
   arithmetic) and reconstruct $A$.

The decomposition need not be unique. For teaching sizes the support
matching is a straightforward DFS/backtracking search.

## Wikipedia $3\times 3$ walk-through

For

$$
X = \frac{1}{12}
\begin{pmatrix}
7 & 0 & 5 \\
2 & 6 & 4 \\
3 & 6 & 3
\end{pmatrix}
$$

one admissible first permutation matrix is

$$
P =
\begin{pmatrix}
0 & 0 & 1 \\
1 & 0 & 0 \\
0 & 1 & 0
\end{pmatrix},
\qquad
\lambda = \frac{2}{12},
$$

and $X - \lambda P$ remains a nonnegative multiple of a doubly stochastic
matrix with one more zero. Continuing yields a full Birkhoff–von Neumann
decomposition (available via `Wikipedia_Example_3x3` and `Decompose`).

## Contrast: Sinkhorn–Knopp (sibling)

**Sinkhorn’s theorem** says any matrix with strictly positive entries can
be scaled to a doubly stochastic matrix by positive diagonal matrices
(row and column scaling). The **Sinkhorn–Knopp** algorithm iterates those
normalizations. That sibling *constructs* a point of $B_n$; this package
*expresses* a point of $B_n$ as a convex combination of vertices. They
are complementary educational tools, not linked Ada units.

## API summary

| Symbol | Role |
| --- | --- |
| `Real`, `Matrix` | `Long_Float` educational dense matrices |
| `Permutation` | Row $\to$ column map |
| `Term` / `Decomposition` | $(\lambda, \pi)$ list from Birkhoff peeling |
| `Max_N` / `Max_Terms` | Caps ($8$ / $64$) |
| `Is_Doubly_Stochastic` | Nonnegative + row/col sums $\approx 1$ |
| `Find_Support_Permutation` | DFS perfect matching on support |
| `Decompose` / `Birkhoff_Decomposition` | Birkhoff algorithm |
| `Reconstruct` / `Reconstruct_Near` | $\sum \lambda_k P_k$ and check |
| `Convex_Combination` | Build DS from known perms |
| `Identity` / `Uniform` / `Make_Toy_DS` | Constructors |
| `Wikipedia_Example_3x3` | Textbook $3\times 3$ |
| `Invalid_Argument` | Non-square / not DS / no matching |

## Build and test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022` via `birkhoff_von_neumann.gpr`. Expect
zero warnings and a green test summary (`ALL PASSED`).

```bash
make clean
```

## License / intent

Educational reference code for the RobertBoettcherSF Ada 2023 algorithm
series. Not optimized for production-scale matching or high-precision
polytope algorithms.
