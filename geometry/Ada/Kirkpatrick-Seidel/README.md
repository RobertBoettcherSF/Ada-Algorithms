# Kirkpatrick–Seidel — Ada 2023

Educational, self-contained Ada 2023 package for the **2D Kirkpatrick–Seidel**
convex-hull algorithm ("**marriage before conquest**" / gift-wrapping
refinement). See
[Wikipedia: Kirkpatrick–Seidel algorithm](https://en.wikipedia.org/wiki/Kirkpatrick–Seidel_algorithm).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates use ordinary `Real` (`digits 15`) arithmetic.
The bridge step uses a clear brute-force supporting-line scan rather than the
full median-of-slopes $O(n)$ machinery — still producing **correct hulls** for
the tests, but **not** claiming production asymptotic constants. It is **not**
a production computational geometry kernel (no adaptive exact predicates /
CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Kirkpatrick-Seidel`) | Marriage-before-conquest hull ($O(n\log h)$ idea) |
| **[Ada-Quickhull](https://github.com/RobertBoettcherSF/Ada-Quickhull)** | Quicksort-style farthest-point divide-and-conquer |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB + min-area OBB (embeds Andrew's chain) |
| **Ada-Graham-Scan** (ahead) | Polar-sort + stack Graham scan |
| **Ada-Jarvis-March** (ahead) | Gift wrapping ($O(nh)$) |
| **Ada-Chan** (ahead) | Output-sensitive Chan's algorithm |
| **Ada-Convex-Hull** (ahead) | Survey of planar convex-hull algorithms |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Classical divide-and-conquer hulls **conquer** first (recurse on left/right
halves) and **marry** later (find bridges between the two hulls). Kirkpatrick &
Seidel (1986) reverse the order — **marriage before conquest**:

1. Find the **median** $x$-coordinate; split $S$ into left set $L$ and right
   set $R$.
2. Compute the **upper bridge** (upper common tangent) that crosses the median
   vertical line — an edge $a\in L$, $b\in R$ of the final upper hull.
3. **Discard** points that cannot contribute further upper-hull edges (strictly
   under the bridge, or between $a$ and $b$ in $x$).
4. Recurse on the surviving left and right subsets; concatenate.
5. Repeat symmetrically for the **lower hull**; assemble both into a
   **counterclockwise** open ring.

### Orientation

Twice the signed area of triangle $ABC$ (left-of-line test):

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (B_y-A_y)(C_x-A_x).
$$

$\operatorname{Orient2D} > 0$ means $C$ is left of directed $AB$ (CCW);
$< 0$ means right (CW); $\approx 0$ means collinear.

### Upper bridge (classroom)

For vertically separated $L$ and $R$, an **upper bridge** is a directed edge
$a\to b$ ($a\in L$, $b\in R$) such that every point of $L\cup R$ lies on or
**below** the line:

$$
\operatorname{Orient2D}(a,b,p) \le 0 \quad \forall\, p\in L\cup R.
$$

This educational body scans candidate pairs (clear $O(|L|\cdot|R|\cdot n)$
check). The original paper finds a bridge in linear time via median-of-slopes
candidate pruning — omitted here for classroom clarity.

### Complexity idea

At recursion depth $i$ there are at most $2^i$ subproblems, each of size at
most $n/2^i$, and each subproblem discovers one hull edge. With $h$ hull
vertices the depth is $O(\log h)$, giving the celebrated

$$
O(n\log h)
$$

bound when bridges are linear-time. Gift wrapping is $O(nh)$; non-output-
sensitive sorts are $O(n\log n)$.

### Educational robustness

Floating predicates use a fixed $\varepsilon$-threshold. They work for
well-separated classroom examples but can misclassify near-collinear vertices.
Empty inputs and oversized sets ($n < 1$ or $n > Max\_Points$) raise
`Invalid_Argument`. Near-duplicate and collinear-on-edge points are dropped; a
single point or collinear segment returns $1$ or $2$ vertices.

An independent **Andrew monotone chain** oracle is exposed for tests to
cross-check Kirkpatrick–Seidel on small sets.

## API sketch

| Operation | Role |
| --- | --- |
| `Convex_Hull` / `Hull_Vertex_Count` | KS upper+lower → CCW open ring |
| `Upper_Bridge` / `Lower_Bridge` | Marriage step across a vertical split |
| `Andrew_Monotone_Chain` | Teaching oracle ($O(n\log n)$) |
| `Orient2D` / `Cross` / `Dot` | Predicates / helpers |
| `Dist2` / `Dist` | Squared / Euclidean distance |
| `Signed_Area` / `Is_CCW` | Hull orientation checks |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Point_Set`, `Bridge_Edge`, `Real`.
Exception: `Invalid_Argument` when $n < 1$ or $n > Max\_Points$ (hull), or
when a bridge set is empty.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
