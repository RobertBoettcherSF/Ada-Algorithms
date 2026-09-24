# Graham scan — Ada 2023

Educational, self-contained Ada 2023 package for the **2D Graham scan**
convex-hull algorithm: **polar-angle sort** around a pivot, then a
**stack** that discards right turns. See
[Wikipedia: Graham scan](https://en.wikipedia.org/wiki/Graham_scan).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Graham-Scan`) | Polar-sort + stack Graham scan |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Quicksort-style farthest-point divide-and-conquer |
| **[Ada-Kirkpatrick-Seidel](https://github.com/RobertBoettcherSF/Ada-Kirkpatrick-Seidel)** | Marriage-before-conquest hull ($O(n\log h)$ idea) |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB (embeds Andrew's chain) |
| **Ada-Jarvis-March** (ahead) | Gift wrapping ($O(nh)$) |
| **Ada-Chan** (ahead) | Output-sensitive Chan's algorithm |
| **Ada-Convex-Hull** (ahead) | Survey of planar convex-hull algorithms |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Graham (1972) builds the hull in **counterclockwise** order:

1. Pick the **pivot** $P_0$: lowest $y$-coordinate (then leftmost $x$).
2. **Sort** the remaining points by polar angle with $P_0$ (increasing
   from $+x$). Break same-ray ties by distance; keep only the
   **farthest** point on each ray.
3. **Scan** with a stack: for each next point $p$, pop while
   $\operatorname{Orient2D}(\mathit{next},\mathit{top},p) \le 0$
   (not a strict left turn), then push $p$.

### Orientation

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear.

Polar comparison around pivot $P$ uses the same cross product: $A$
precedes $B$ when $\operatorname{Orient2D}(P,A,B) > 0$; on a shared ray,
closer points sort before farther ones (then the ray-filter keeps the
farthest).

### Complexity

Sorting dominates: $O(n\log n)$. The stack pass is $O(n)$ because each
point is pushed and popped at most once. Overall $O(n\log n)$.

Andrew's **monotone chain** is the same stack idea with an $x$-sort
instead of a polar sort (upper + lower passes). An independent Andrew
oracle is exposed for tests.

### Educational robustness

Floating predicates (`Orient2D`, polar compare) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear vertices. Production codes use
filtered / exact arithmetic. Empty inputs and oversized sets
($n < 1$ or $n > Max\_Points$) raise `Invalid_Argument`. Near-duplicate
and collinear-on-edge points are dropped; a single point or collinear
segment returns $1$ or $2$ vertices.

## API sketch

| Operation | Role |
| --- | --- |
| `Convex_Hull` / `Hull_Vertex_Count` | Graham scan → CCW open ring |
| `Andrew_Monotone_Chain` | Teaching oracle ($O(n\log n)$) |
| `Orient2D` / `Polar_Less` | Predicate + polar compare |
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
