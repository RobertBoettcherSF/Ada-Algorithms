# Quickhull — Ada 2023

Educational, self-contained Ada 2023 package for the **2D Quickhull**
convex-hull algorithm: a divide-and-conquer method analogous to
**quicksort**. See
[Wikipedia: Quickhull](https://en.wikipedia.org/wiki/Quickhull).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Quickhull`) | 2D Quickhull divide-and-conquer hull |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB (embeds Andrew's chain) |
| **Ada-Graham-Scan** (ahead) | Polar-sort + stack Graham scan |
| **Ada-Jarvis-March** (ahead) | Gift wrapping ($O(nh)$) |
| **Ada-Chan** (ahead) | Output-sensitive Chan's algorithm |
| **Ada-Convex-Hull** (ahead) | Survey of planar convex-hull algorithms |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Quickhull finds the **leftmost** and **rightmost** extremes $A$ and $B$
(always on the hull). The directed line $AB$ partitions the remaining
points into two sides. On each side the algorithm picks the point $C$
farthest from the line, forms triangle $ACB$, discards interior points,
and recurses on the two new edges — exactly the quicksort-style split.

### Orientation and distance

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear.

Perpendicular distance from $P$ to the line through $A$ and $B$:

$$
\operatorname{dist}(P; AB)
  = \frac{|\operatorname{Orient2D}(A,B,P)|}{\|B-A\|}.
$$

On a fixed base $AB$, maximising distance is equivalent to maximising
$|\operatorname{Orient2D}|$.

### Recurrence (planar)

1. Find extremes $A$ (min $x$, then min $y$) and $B$ (max $x$, then max $y$).
2. Partition into points strictly left of $A\to B$ (upper) and left of
   $B\to A$ (lower).
3. Recursively: farthest point $C$ on a side; ignore points inside
   $\triangle PCQ$; continue on $P\to C$ and $C\to Q$.
4. Assemble the hull in **counterclockwise** order:
   $A$, upper arc, $B$, lower arc.

Expected behaviour is often $O(n\log h)$ on favourable distributions;
worst case is $O(n^{2})$ (similar to quicksort's unbalanced pivot).

### Educational robustness

Floating predicates (`Orient2D`, distance comparisons) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear vertices. Production codes use
filtered / exact arithmetic. Empty inputs and oversized sets
($n < 1$ or $n > Max\_Points$) raise `Invalid_Argument`. Near-duplicate
and collinear-on-edge points are dropped; a single point or collinear
segment returns $1$ or $2$ vertices.

An independent **Andrew monotone chain** oracle is exposed for tests to
cross-check Quickhull on small sets.

## API sketch

| Operation | Role |
| --- | --- |
| `Convex_Hull` / `Hull_Vertex_Count` | 2D Quickhull → CCW open ring |
| `Andrew_Monotone_Chain` | Teaching oracle ($O(n\log n)$) |
| `Orient2D` / `Distance_To_Line` | Predicate + farthest-point metric |
| `Dist2` / `Dist` / `Cross` / `Dot` | Geometric helpers |
| `Signed_Area` / `Is_CCW` | Hull orientation checks |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Point_Set`, `Real`. Exception:
`Invalid_Argument` when $n < 1$ or $n > Max\_Points$.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
