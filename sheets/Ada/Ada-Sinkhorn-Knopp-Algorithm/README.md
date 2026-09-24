# Sinkhorn–Knopp Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Sinkhorn–Knopp algorithm** for matrix scaling: alternately rescale the
rows and columns of a nonnegative matrix $A$ so that the iterates approach
a **doubly stochastic** matrix (or a matrix with prescribed positive
marginals). By **Sinkhorn’s theorem**, when $A$ has strictly positive
entries there exist positive diagonal matrices $D_1$ and $D_2$ such that

$$
D_1 A D_2
$$

is doubly stochastic (unique up to a positive reciprocal trade-off between
$D_1$ and $D_2$). Cap $n\le 32$; dense educational `Long_Float` matrices.

Based on
[Wikipedia: Sinkhorn's theorem](https://en.wikipedia.org/wiki/Sinkhorn%27s_theorem)
and
[Emergent Mind: Sinkhorn–Knopp algorithm](https://www.emergentmind.com/topics/sinkhorn-knopp-algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Birkhoff-von-Neumann](https://github.com/RobertBoettcherSF/Ada-Birkhoff-von-Neumann)** —
  Birkhoff–von Neumann *decomposition* of an already doubly stochastic
  matrix into a convex combination of permutation matrices. Contrast:
  Sinkhorn–Knopp *produces* a DS matrix (or prescribed-marginal coupling)
  from a nonnegative matrix via diagonal scaling; Birkhoff–von Neumann
  *expresses* a DS matrix as $\sum_k \lambda_k P_k$. No `with` of that
  package here.
- Related series repos: https://github.com/RobertBoettcherSF/

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Theorem** | $D_1 A D_2$ doubly stochastic | Sinkhorn (positive $A$) |
| **Algorithm** | Alternate row / column scaling | Sinkhorn–Knopp / IPF |
| **Stop** | $\max_i\|r_i-t^r_i\|$, $\max_j\|c_j-t^c_j\| \le \varepsilon$ | Or max iterations |
| **Scalars** | Educational `Long_Float` (`Real`) | $n\le 32$ |
| **Builders** | Ones / Toy / Hilbert / Transport kernel | Positive demos |
| **Marginals** | All-ones or prescribed $t^r,t^c$ | Rectangular OK with targets |

## Brief history

**Richard Sinkhorn** (1964) proved that every square matrix with strictly
positive entries can be scaled to a doubly stochastic matrix by positive
diagonal matrices. **Paul Knopp** joined Sinkhorn in analysing the natural
iterative method that alternately normalises rows and columns to sum to
one. The same iteration is essentially **iterative proportional fitting**
(IPF) from survey statistics. In the 2010s the algorithm became central to
**entropy-regularised optimal transport** (“Sinkhorn distances”) in machine
learning, where a Gibbs kernel $K_{ij}=\mathrm{e}^{-C_{ij}/\varepsilon}$ is
scaled to prescribed supply/demand marginals.

## Sinkhorn–Knopp step

Starting from a nonnegative matrix $A^{(0)}=A$ with positive row and column
sums (total support in the classical theory), one iteration is:

1. **Row normalisation.** For each row $i$,
   $$
   A^{(k+1/2)}_{ij}
   =
   A^{(k)}_{ij}\cdot\frac{t^r_i}{\sum_{j'} A^{(k)}_{ij'}}.
   $$
2. **Column normalisation.** For each column $j$,
   $$
   A^{(k+1)}_{ij}
   =
   A^{(k+1/2)}_{ij}\cdot\frac{t^c_j}{\sum_{i'} A^{(k+1/2)}_{i'j}}.
   $$

For the doubly stochastic problem take $t^r_i=t^c_j=1$. The accumulated
row and column factors build $D_1$ and $D_2$. This package stops when the
maximum absolute marginal residual falls below $\varepsilon$, or when a
maximum iteration count is reached.

## Contrast: Birkhoff–von Neumann (sibling)

The Birkhoff–von Neumann theorem says every doubly stochastic matrix lies
in the convex hull of the permutation matrices (the vertices of the
**Birkhoff polytope** $B_n$). That sibling *decomposes* a point of $B_n$;
this package *constructs* a point of $B_n$ (or a transportation polytope
slice with given margins) by diagonal scaling. Complementary classroom
tools — not linked Ada units.

## API summary

| Symbol | Role |
| --- | --- |
| `Real`, `Matrix`, `Vector` | `Long_Float` educational dense types |
| `Sinkhorn_Result` | Scaled block, $D_1$/$D_2$ factors, residual, iters |
| `Max_N` | Cap ($32$) |
| `Is_Nonnegative` / `Is_Strictly_Positive` | Entry predicates |
| `Row_Sums` / `Col_Sums` / `Max_Marginal_Residual` | Marginals |
| `Is_Nearly_Doubly_Stochastic` | Nonnegative + sums $\approx 1$ |
| `Normalize_Rows` / `Normalize_Columns` | One half-step (optional targets) |
| `Iterate` | Fixed number of Sinkhorn pairs |
| `Solve` | Until $\varepsilon$ or max iters; optional marginals |
| `Scaled_Matrix` | Extract unconstrained scaled block |
| `Ones_Matrix` / `Positive_Toy` / `Hilbert_Like` | Constructors |
| `Transportation_Kernel` | Gibbs kernel $\mathrm{e}^{-(i-j)^2/\varepsilon}$ |
| `Invalid_Argument` | Empty / negative / zero row or column / bad targets |

## Build and test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022` via `sinkhorn_knopp_algorithm.gpr`. Expect
zero warnings and a green test summary (`ALL PASSED`).

```bash
make clean
```

## License / intent

Educational reference code for the RobertBoettcherSF Ada 2023 algorithm
series. Not optimized for production-scale entropic OT or accelerated
Sinkhorn (overrelaxation / Krylov).
