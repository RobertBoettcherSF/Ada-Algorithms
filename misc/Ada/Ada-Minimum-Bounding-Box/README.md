# Minimum bounding box algorithms — Ada 2023

Educational, self-contained Ada 2023 package for **2D minimum bounding
box** algorithms: the easy **axis-aligned** enclosing rectangle (AABB)
and the **oriented** minimum-area enclosing rectangle (OBB) obtained by a
**rotating-calipers** style enumeration on the **convex hull**. See
[Wikipedia: Minimum bounding box algorithms](https://en.wikipedia.org/wiki/Minimum_bounding_box_algorithms).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Predicates and projections use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Minimum-Bounding-Box`) | AABB + min-area OBB on a point set (hull + calipers) |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on a **convex** polygon |
| **Ada-Convex-Hull** (ahead) | Standalone convex-hull survey (this package embeds Andrew's chain) |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon **area** via shoelace sum |

README links only — **no** package `with` of siblings.

## Algorithm sketch

It is enough to bound the **convex hull** of the input: the smallest
enclosing box of a point set equals that of its hull. The AABB is
immediate — take component-wise min/max. The hard part is choosing the
**orientation** of the box.

### Axis-aligned box (AABB)

For a point set $S$:

$$
\begin{aligned}
\operatorname{Min}_x &= \min_{(x,y)\in S} x, &
\operatorname{Max}_x &= \max_{(x,y)\in S} x, \\
\operatorname{Min}_y &= \min_{(x,y)\in S} y, &
\operatorname{Max}_y &= \max_{(x,y)\in S} y,
\end{aligned}
$$

$$
\operatorname{Area}_{\mathrm{AABB}}
  = (\operatorname{Max}_x - \operatorname{Min}_x)
    \,(\operatorname{Max}_y - \operatorname{Min}_y).
$$

### Convex hull (Andrew monotone chain)

An educational $O(n\log n)$ **Andrew monotone chain** builds the lower
and upper hulls of the lexicographically sorted unique points, then
concatenates them into a CCW open ring. Near-duplicate and near-collinear
vertices are dropped with a fixed $\varepsilon$-threshold.

### Oriented min-area box (rotating calipers / flush edges)

For a convex polygon, a side of a **minimum-area** enclosing rectangle
must be collinear with a hull edge (Freeman–Shapira; linear-time
enumeration via **rotating calipers**, Toussaint 1983). For each hull
edge $e_i = (H_i, H_{i+1})$ as a flush caliper base, project every hull
vertex onto the unit edge direction $u$ and its left normal $n$:

$$
u = \frac{H_{i+1}-H_i}{\|H_{i+1}-H_i\|},
\qquad
n = (-u_y,\, u_x).
$$

Let $[\min_u,\max_u]$ and $[\min_v,\max_v]$ be the projected extents.
The candidate box has

$$
\operatorname{width} = \max_u - \min_u,
\qquad
\operatorname{height} = \max_v - \min_v,
\qquad
\operatorname{area} = \operatorname{width}\cdot\operatorname{height}.
$$

Keep the candidate of least area. After the hull this pass is $O(h)$
($h$ = hull size); overall $O(n\log n)$ for a general point set.

### AABB vs OBB

For an axis-aligned square or rectangle the two areas coincide. For a
**rotated diamond** (square rotated $45^\circ$) the AABB is larger than
the OBB — a classic classroom contrast:

$$
\operatorname{Area}_{\mathrm{OBB}} \le \operatorname{Area}_{\mathrm{AABB}}.
$$

### Educational robustness

Floating predicates (`Orient2D`, projections) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear vertices. Production codes use
filtered / exact arithmetic. Empty inputs and oversized sets
($n < 1$ or $n > Max\_Points$) raise `Invalid_Argument`.

## API sketch

| Operation | Role |
| --- | --- |
| `Axis_Aligned_Bounding_Box` | Min/max coords + area ($O(n)$) |
| `Convex_Hull` / `Hull_Vertex_Count` | Andrew monotone-chain hull |
| `Min_Area_Oriented_Box` | Min-area OBB (corners / $w$ / $h$ / angle / area) |
| `Brute_Min_Area_OBB` | Teaching alias of the same flush-edge pass |
| `AABB_Area` / `AABB_Width` / `AABB_Height` | AABB accessors |
| `OBB_Area` / `OBB_Width` / `OBB_Height` / `OBB_Angle` / `OBB_Corner` | OBB accessors |
| `Orient2D` / `Dist2` / `Dist` / `Cross` / `Dot` | Geometric helpers |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Point_Set`, `Axis_Aligned_Box`,
`Oriented_Box`, `Real`. Exception: `Invalid_Argument` when $n < 1$ or
$n > Max\_Points$.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
