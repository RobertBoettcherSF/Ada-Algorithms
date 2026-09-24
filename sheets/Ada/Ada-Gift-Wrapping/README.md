# Gift wrapping (Jarvis march) — Ada 2023

Educational, self-contained Ada 2023 package for the **2D gift wrapping**
algorithm (**Jarvis march**): start at an extreme point and repeatedly
choose the next hull vertex by the most counterclockwise turn until the
wrap closes. See
[Wikipedia: Gift wrapping algorithm](https://en.wikipedia.org/wiki/Gift_wrapping_algorithm).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Gift-Wrapping`) | Jarvis march gift wrapping ($O(nh)$) |
| **[Ada-Graham-Scan](https://github.com/RobertBoettcherSF/Ada-Graham-Scan)** | Polar-sort + stack Graham scan |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Quicksort-style farthest-point divide-and-conquer |
| **[Ada-Kirkpatrick-Seidel](https://github.com/RobertBoettcherSF/Ada-Kirkpatrick-Seidel)** | Marriage-before-conquest hull ($O(n\log h)$ idea) |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB (embeds Andrew's chain) |
| **Ada-Chan** (ahead) | Output-sensitive Chan's algorithm ($O(n\log h)$) |
| **Ada-Convex-Hull** (ahead) | Survey of planar convex-hull algorithms |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Jarvis (1973) builds the hull in **counterclockwise** order:

1. Pick the **start** $P_0$: leftmost $x$-coordinate (then lowest $y$).
2. From the current hull vertex $P_i$, scan all points and choose
   $P_{i+1}$ so that every other point lies to the **left** of (or on)
   the directed line $P_i P_{i+1}$ — equivalently, the candidate that
   makes the most counterclockwise turn (smallest polar angle). On a
   shared ray keep only the **farthest** extreme point.
3. Advance $i \leftarrow i+1$ until $P_h = P_0$ again (wrap closed).

The walk is like winding a string around the set of points.

### Orientation

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear.

### Complexity

The inner scan checks every input point; the outer loop runs once per
hull vertex. Total time is $O(nh)$, where $h$ is the number of hull
vertices — an **output-sensitive** algorithm. It is competitive when
$h$ is very small relative to $n$; otherwise $O(n\log n)$ methods
(Graham scan, Andrew monotone chain) or Chan's $O(n\log h)$ algorithm
are preferable.

Andrew's **monotone chain** is an independent $O(n\log n)$ oracle
exposed for tests (same CCW extreme-vertex set on classroom examples).

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
| `Convex_Hull` / `Jarvis_March` | Gift wrapping → CCW open ring |
| `Hull_Vertex_Count` | Length of the hull |
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
