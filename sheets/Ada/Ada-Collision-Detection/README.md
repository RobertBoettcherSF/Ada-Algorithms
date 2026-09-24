# Collision detection — Ada 2023 (educational survey)

Educational, self-contained Ada 2023 package for a **discrete 2-D collision
detection** survey: **narrow-phase** geometric tests and **broad-phase**
candidate pairing. See
[Wikipedia: Collision detection](https://en.wikipedia.org/wiki/Collision_detection).

This package is a **classroom sketch** on small scenes
(`Max_Objects = 64`, `Max_Vertices = 32`). Predicates use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production physics engine (no BVH,
no GJK/EPA, no continuous collision detection).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Broad vs narrow phase

Collision pipelines usually split into two stages:

1. **Broad phase** — cheap rejection of pairs that cannot collide. Typical
   structures: AABB trees, BVHs, **sweep-and-prune**, spatial hashing / grids.
2. **Narrow phase** — precise geometric tests on the surviving candidate
   pairs: sphere–sphere, AABB–AABB, **SAT** for convex polygons, GJK, etc.

This package implements discrete (per-frame) tests only. Continuous collision
detection (CCD) and GJK are mentioned as related siblings; they are **not**
`with`’d here.

## Narrow-phase tests

### Axis-aligned bounding boxes (AABB)

Two AABBs overlap iff their projections overlap on **every** axis. Boxes use
**closed** intervals $[M_x, X_x] \times [M_y, X_y]$: edge and corner contact
count as overlapping.

$$
\operatorname{overlap}(A,B)
  \iff
  A_X^{\max} \ge B_X^{\min}
  \;\wedge\;
  B_X^{\max} \ge A_X^{\min}
  \;\wedge\;
  A_Y^{\max} \ge B_Y^{\min}
  \;\wedge\;
  B_Y^{\max} \ge A_Y^{\min}.
$$

### Circles

Two circles collide when the distance between centers is at most the sum of
radii (closed; touching counts):

$$
\|c_1 - c_2\|^2 \le (r_1 + r_2)^2.
$$

### Separating Axis Theorem (SAT) for convex polygons

For two **convex** polygons given as CCW vertex rings, project both shapes
onto the outward normals of every edge. If any axis has disjoint projections,
the polygons are separated; otherwise they overlap (closed projections:
touching edges/vertices count).

$$
\text{separated on } \hat{n}
  \iff
  \max_i (a_i \cdot \hat{n})
  <
  \min_j (b_j \cdot \hat{n})
  \;\vee\;
  \max_j (b_j \cdot \hat{n})
  <
  \min_i (a_i \cdot \hat{n}).
$$

### Segment intersection

`Segments_Intersect` reports proper crossings and improper cases (endpoint on
segment, collinear overlap). Degenerate zero-length segments raise
`Invalid_Argument`.

## Broad-phase pairing

### Brute force

`Brute_Force_Pairs` tests all $\binom{n}{2}$ pairs in $O(n^2)$ — fine for
classroom $n \le 64$.

### Sweep-and-prune (sort-and-sweep)

`Sweep_And_Prune_Pairs` projects AABBs onto the **X** axis, sorts endpoints,
and sweeps while maintaining an **active set**. When a new interval starts, it
is paired with every active box and confirmed with a full AABB (Y) overlap
test. On equal X values, starts are ordered before ends so closed touching
intervals still report. Expected cost $O(n \log n + k)$ with $k$ candidates.

Sibling package **Ada-Sweep-And-Prune** explores temporal coherence and 3-D;
this survey keeps a thin single-axis sketch without depending on it.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Collision-Detection`) | Discrete 2-D survey: AABB / circle / SAT + brute / SAP |
| **[Ada-Gilbert-Johnson-Keerthi](https://github.com/RobertBoettcherSF/Ada-Gilbert-Johnson-Keerthi)** | GJK distance / intersection for convex polygons |
| **[Ada-Sweep-And-Prune](https://github.com/RobertBoettcherSF/Ada-Sweep-And-Prune)** | Full sweep-and-prune broad phase (coherence, 3-D) |
| **[Ada-Bentley-Ottmann](https://github.com/RobertBoettcherSF/Ada-Bentley-Ottmann)** | Sweep-line segment intersections |

README links only — **no** package `with` of siblings. CCD / GJK / EPA remain
out of scope for this survey.

## API sketch

| Operation | Role |
| --- | --- |
| `AABB_Overlap` | Closed AABB–AABB test |
| `Circle_Overlap` | Closed circle–circle (centers+radii or `Circle` records) |
| `Convex_Polygons_Overlap` | SAT for convex CCW polygons |
| `Segments_Intersect` | Proper / improper segment intersection |
| `Brute_Force_Pairs` | $O(n^2)$ AABB or circle candidate pairs |
| `Sweep_And_Prune_Pairs` | Sort X-intervals, report overlapping AABB pairs |
| `Find_Colliding_AABBs` / `Find_Colliding_Circles` | Narrow index pairs via brute force |
| `Make_AABB` / `Make_Circle` | Validated constructors |
| `Near` / `Dot` / `Cross` / `Dist2` / `Orient2D` | Geometric helpers |
| `Append_Pair` / `Normalize_Pairs` / `Same_Pair_Set` | Pair-list utilities |

Domain types: `Point`, `AABB`, `Circle`, `Polygon` / `Point_Array`,
`Pair` / `Pair_List`, `Real`. Exception: `Invalid_Argument` on empty or
oversized arrays, negative radius, `Max < Min` AABB, polygon $n < 3$ for SAT,
degenerate segments, etc.

**Closed-overlap convention:** touching edges, corners, and tangent circles
all count as colliding (`Max_A >= Min_B` style inequalities, and
$\|c_1-c_2\| \le r_1+r_2$).

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

Empty GitHub repo (do not push from this workspace unless asked):
https://github.com/RobertBoettcherSF/Ada-Collision-Detection
