# Gilbert–Johnson–Keerthi distance algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the
**Gilbert–Johnson–Keerthi (GJK)** distance algorithm in **2-D**: compute the
**minimum distance** between two **convex polygons** (and a boolean
**intersection** test) using only **support functions** on the **Minkowski
difference**. See
[Wikipedia: Gilbert–Johnson–Keerthi distance algorithm](https://en.wikipedia.org/wiki/Gilbert–Johnson–Keerthi_distance_algorithm).

This package is a **classroom sketch** on small convex polygons
(`Max_Vertices = 32`). Predicates and distances use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry / physics kernel (no EPA penetration depth, no incremental warm
start, no Montanari signed-volume sub-algorithm).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Gilbert-Johnson-Keerthi`) | Min distance / intersection of two **convex** shapes via GJK |
| **[Ada-Rotating-Calipers](https://github.com/RobertBoettcherSF/Ada-Rotating-Calipers)** | Antipodal pairs / diameter / width on **one** convex polygon |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon **area** (and centroid) via shoelace sum |
| **Ada-Collision-Detection** (ahead) | Broader collision pipeline building on GJK / EPA |
| **Ada-Geometric-Hashing** (ahead) | Spatial hashing / broad-phase pairing ahead of GJK |

README links only — **no** package `with` of siblings.

## Algorithm sketch

GJK (Gilbert, Johnson & Keerthi, 1988) never builds the Minkowski difference
$C = A - B = \{a - b : a \in A,\ b \in B\}$ explicitly. It only needs a
**support** query:

$$
\operatorname{Support}(S, \vec{d})
  = \arg\max_{p \in S}\, p \cdot \vec{d}.
$$

For polytopes this is the farthest vertex in direction $\vec{d}$. The support
of the Minkowski difference is

$$
\operatorname{Support}(A - B, \vec{d})
  = \operatorname{Support}(A, \vec{d})
  - \operatorname{Support}(B, -\vec{d}).
$$

Starting from an initial direction, GJK iteratively grows a **simplex** on
$C$ toward the origin. In 2-D the simplex is a **point**, a **segment**, or a
**triangle**. At each step a `NearestSimplex` reduction keeps the feature of
the simplex closest to the origin and yields a new search direction.

- If the simplex **contains the origin**, then $0 \in C$ and $A \cap B
  \neq \emptyset$ (distance $0$).
- If a new support point does not advance past the origin along the search
  direction, the shapes are **separated** and the distance is the length of
  the closest point of the current simplex to the origin:

$$
\operatorname{dist}(A,B)
  = \min_{c \in C}\, \|c\|
  = \min_{a \in A,\ b \in B}\, \|a - b\|.
$$

### Educational boolean loop (intersection)

Pseudocode adapted from the Wikipedia overview:

```
A := Support(P, d0) − Support(Q, −d0)
S := {A};  D := −A
loop
  A := Support(P, D) − Support(Q, −D)
  if A · D < 0 then reject          -- separated
  S := S ∪ {A}
  S, D, hit := NearestSimplex(S)
  if hit then accept                -- origin in simplex
```

### Educational robustness

Floating predicates and distance comparisons use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-tangencies. Production codes use EPA for
penetration depth, incremental frames for warm starts, and more robust
Johnson / signed-volume sub-algorithms. Inputs must be **strictly convex**;
`Distance` / `Intersect` call `Ensure_Convex_CCW` (or raise
`Invalid_Argument`). Clockwise convex inputs are reversed to CCW.

## API sketch

| Operation | Role |
| --- | --- |
| `Support` | Farthest vertex of a polygon in a direction |
| `Support_Minkowski` | $\operatorname{Support}(A,d) - \operatorname{Support}(B,-d)$ |
| `Distance` / `Distance_Squared` / `Distance_Info` | Min distance between two convex polygons |
| `Intersect` | Boolean GJK intersection (incl. boundary touch) |
| `Ensure_Convex_CCW` | Validate strict convexity; return dense CCW copy |
| `Regular_Polygon` / `Axis_Aligned_Square` | Teaching shape constructors |
| `Orient2D` / `Dist2` / `Dist` / `Cross` / `Dot` / `Perp` | Geometric helpers |
| `Is_Convex` / `Is_CCW` / `Signed_Area` / `Centroid` | Validation / measures |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point` / `Vec2`, `Point_Array` / `Polygon`,
`Distance_Result`, `Real`. Exception: `Invalid_Argument` when a polygon is
empty, $n < 3$, $n > Max\_Vertices$, or not strictly convex.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
