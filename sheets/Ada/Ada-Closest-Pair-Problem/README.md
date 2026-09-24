# Closest pair of points — Ada 2023

Educational, self-contained Ada 2023 package for the **2D Euclidean closest
pair of points** problem: find two points in a finite set with the smallest
distance. Implements both the naïve **$O(n^2)$ brute force** and the classic
**$O(n\log n)$ Shamos / Bentley–Shamos divide-and-conquer** algorithm (presort
by $X$ and $Y$, midline strip of width $2\delta$, at most **seven** higher-$Y$
neighbors). See
[Wikipedia: Closest pair of points problem](https://en.wikipedia.org/wiki/Closest_pair_of_points_problem).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Distances use ordinary `Real` (`digits 15`) arithmetic.
It is **not** a production computational-geometry kernel (no adaptive exact
predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Closest-Pair-Problem`) | 2D closest pair (brute + D&C) |
| **[Ada-Nearest-Neighbor-Search](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Search)** | 1-NN / $k$-NN / radius search, tiny $k$-d tree |
| **[Ada-Collision-Detection](https://github.com/RobertBoettcherSF/Ada-Collision-Detection)** | Discrete 2D collision (AABB, circles, SAT) |
| **[Ada-Bentley-Ottmann](https://github.com/RobertBoettcherSF/Ada-Bentley-Ottmann)** | Sweep-line segment intersections |
| **[Ada-Graham-Scan](https://github.com/RobertBoettcherSF/Ada-Graham-Scan)** | Polar-sort + stack convex hull |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Farthest-point divide-and-conquer hull |

README links only — **no** package `with` of siblings.

## Problem statement

Given $n$ points $P = \{p_1,\ldots,p_n\}$ in the Euclidean plane, compute

$$
\delta^\star = \min_{i \neq j}\ \|p_i - p_j\|_2
$$

and a pair $(i^\star, j^\star)$ attaining that minimum. Duplicate points yield
$\delta^\star = 0$. The algebraic decision-tree lower bound is
$\Omega(n\log n)$ (via element uniqueness); the deterministic divide-and-conquer
algorithm meets $O(n\log n)$.

## Brute force — $O(n^2)$

Check all $\binom{n}{2}$ unordered pairs and keep the minimum Euclidean
distance. Correct for every metric; used here as an oracle that the
divide-and-conquer result must match on every test set.

## Divide-and-conquer — $O(n\log n)$

Classical planar algorithm (Preparata–Shamos / Bentley–Shamos teaching form):

1. **Presort** a copy of the points by $X$-coordinate into $P_x$ and by
   $Y$-coordinate into $P_y$ (ties broken stably by the other coordinate,
   then by encounter index).
2. **Recurse** on the left and right halves of $P_x$ (partition $P_y$ into
   the same halves, preserving $Y$-order). Let
   $\delta = \min(\delta_L, \delta_R)$.
3. Form the **midline strip** of all points with
   $|x - x_{\mathrm{mid}}| < \delta$, already ordered by $Y$.
4. For each strip point, compare it only to the next **at most seven**
   neighbors with higher $Y$ (and stop early when the $Y$-gap reaches
   $\delta$). Update $\delta$ if a closer pair appears.

Overall cost is $O(n\log n)$: sorting once, then linear work per recursion
level across a balanced tree of depth $O(\log n)$.

### Why at most seven neighbors?

Suppose every pair in the strip is at least $\delta$ apart. Around any
point $p$, the axis-aligned rectangle of size $\delta \times 2\delta$
covering the higher-$Y$ half of the strip can be tiled by **eight** boxes of
side $\delta/2$. Each such box holds at most one point (diameter of a
$\delta/2$ square is $\delta/\sqrt{2} < \delta$). One box is occupied by $p$
itself, so at most **seven** other points can lie in the remaining boxes —
hence it suffices to inspect the next seven higher-$Y$ strip neighbors.

$$
\operatorname{diam}\Bigl(\bigl[0,\tfrac{\delta}{2}\bigr]^2\Bigr)
  = \tfrac{\delta}{\sqrt{2}} < \delta.
$$

### Complexity summary

| Method | Time | Space |
| --- | --- | --- |
| `Brute_Force` | $O(n^2)$ | $O(n)$ |
| `Divide_And_Conquer` | $O(n\log n)$ | $O(n)$ |
| `Closest_Pair` (default) | $O(n\log n)$ via D&C | $O(n)$ |

Randomized linear-time algorithms exist in higher models (Rabin; Khuller–Matias)
but are out of scope for this classroom package.

### Educational robustness

Floating comparisons use a fixed $\varepsilon$-threshold (`Near` /
`Near_Point`). They work for well-separated classroom examples but can
mis-order near-ties. Inputs with $n < 2$ or $n > Max\_Points$ raise
`Invalid_Argument`. Collinear points, grids, and exact duplicates
(distance $0$) are supported.

## API sketch

| Operation | Role |
| --- | --- |
| `Brute_Force` | $O(n^2)$ all-pairs closest pair |
| `Divide_And_Conquer` | $O(n\log n)$ Shamos D&C |
| `Closest_Pair` | Default = D&C; overload takes `Method_Kind` |
| `Dist` / `Dist2` | Euclidean / squared distance |
| `Near` / `Near_Point` | Educational floating comparisons |

**Result.** `Pair_Result` carries `Index_A`, `Index_B` (with
`Index_A < Index_B`) and `Distance`. Indices are **1-based positions in the
dense $1..n$ copy** of the argument in encounter order (`Points'First` maps
to $1$).

**Domain types.** `Real`, `Point`, `Point_Array` / `Point_Set`,
`Method_Kind` (`Brute`, `Divide_Conquer`). Exception: `Invalid_Argument`
when $n < 2$ or $n > Max\_Points$.

## Build & test

```bash
make
make test
```

`gnatmake -gnatwa -gnat2022 -Pclosest_pair_problem.gpr` must be warning-clean.
The test driver prints `Results: N PASS, 0 FAIL` and covers exceptions,
hand-computed distances, duplicates, collinear / grid / regular $n$-gon
sets, and brute ≡ D&C agreement on many pseudo-random instances.

## References

- [Closest pair of points problem](https://en.wikipedia.org/wiki/Closest_pair_of_points_problem) (Wikipedia)
- M. I. Shamos & D. Hoey, *Closest-point problems*, FOCS 1975
- J. L. Bentley & M. I. Shamos, *Divide-and-conquer in multidimensional space*, STOC 1976
- Preparata & Shamos, *Computational Geometry: An Introduction*
