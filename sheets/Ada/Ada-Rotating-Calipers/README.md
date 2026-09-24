# Rotating calipers — Ada 2023

Educational, self-contained Ada 2023 package for the **rotating calipers**
method on a **convex polygon**: generate **antipodal pairs**, compute the
**diameter** (maximum distance between vertices), and the **width**
(minimum distance between parallel supporting lines). An educational
sketch of a **minimum-area oriented bounding rectangle** is included.
See
[Wikipedia: Rotating calipers](https://en.wikipedia.org/wiki/Rotating_calipers).

This package is a **classroom sketch** on small convex polygons
(`Max_Vertices = 64`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Rotating-Calipers`) | Antipodal pairs / diameter / width on a **convex** polygon |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon **area** (and centroid) via shoelace sum |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Ear-clip a simple polygon into $n-2$ triangles |
| **Ada-Convex-Hull** (ahead) | Build the convex hull that calipers expect as input |
| **Ada-Minimum-Bounding-Box** (ahead) | Deeper OBB / AABB survey building on caliper passes |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Imagine a spring-loaded vernier caliper rotated around the outside of a
convex polygon $P$ given in counterclockwise (CCW) order. Whenever one
blade lies flat against an edge, the opposite contact is an **antipodal**
vertex (or edge). A full rotation enumerates all antipodal pairs in
$O(n)$ time (Shamos 1978; the name is due to Toussaint).

Using cross products instead of explicit angles (Preparata–Shamos), for
each edge $e_i = (P_i, P_{i+1})$ advance an antipodal index $k$ while the
signed height still increases:

$$
\operatorname{Orient2D}(P_i, P_{i+1}, P_{k+1})
  > \operatorname{Orient2D}(P_i, P_{i+1}, P_k).
$$

Then $(P_i, P_k)$ and related contacts are antipodal. Parallel edges
(equal heights) contribute both endpoints of the opposite edge.

### Diameter

$$
\operatorname{diam}(P) = \max_{i,j}\,\|P_i - P_j\|
  = \max\{\|P_a - P_b\| : (a,b)\ \text{antipodal}\}.
$$

### Width

The **width** is the minimum distance between parallel supporting lines.
For each edge, the distance from the edge line to its antipodal vertex is
a candidate; take the minimum:

$$
\operatorname{width}(P)
  = \min_i \frac{|\operatorname{Orient2D}(P_i, P_{i+1}, P_{k(i)})|}
                {\|P_{i+1} - P_i\|}.
$$

### Minimum-area bounding rectangle (sketch)

With one caliper flush on each edge in turn, the four supporting lines
form an oriented bounding box. Track the candidate of least area
($O(n)$ educational pass).

### Educational robustness

Floating predicates (`Orient2D`, distance comparisons) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear vertices. Production codes use
filtered / exact arithmetic. Inputs must be **strictly convex**; call
`Ensure_Convex_CCW` (done internally by caliper entry points) or raise
`Invalid_Argument`. Clockwise convex inputs are reversed to CCW.

## API sketch

| Operation | Role |
| --- | --- |
| `Ensure_Convex_CCW` | Validate strict convexity; return dense CCW copy |
| `Antipodal_Pairs` | $O(n)$ antipodal vertex pairs |
| `Diameter` / `Diameter_Squared` / `Diameter_Endpoints` | Maximum vertex distance |
| `Width` | Minimum caliper separation |
| `Min_Area_Rect` | Educational min-area OBB sketch |
| `Brute_Diameter` / `Brute_Width` | $O(n^{2})$ oracles for tests |
| `Orient2D` / `Dist2` / `Dist` / `Cross` / `Dot` | Geometric helpers |
| `Is_Convex` / `Is_CCW` / `Signed_Area` | Validation / measures |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Polygon`, `Antipodal_Pair`,
`Antipodal_List`, `Bounding_Rect`, `Real`. Exception:
`Invalid_Argument` when $n < 3$, $n > Max\_Vertices$, or not strictly
convex.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
