# Bentley–Ottmann algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Bentley–Ottmann**
sweep-line algorithm that **reports all proper intersections** among a
set of planar line segments. It extends the earlier **Shamos–Hoey**
detection idea (stop at the first crossing). See
[Wikipedia: Bentley–Ottmann algorithm](https://en.wikipedia.org/wiki/Bentley–Ottmann_algorithm).

This package is a **classroom sketch** on small segment sets
(`Max_Segments = 32`). The status structure is a dense array sorted by
$y$ at the sweep abscissa (not a balanced BST). Predicates use ordinary
`Real` (`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL, no LEDA-style
symbolic perturbation).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry / sweep siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Bentley-Ottmann`) | Sweep-line **reporting** of proper segment–segment crossings |
| **Ada-Line-Segment-Intersection** (survey, next) | Broader survey of pair / multi-segment intersection methods |
| **[Ada-Sweep-And-Prune](https://github.com/RobertBoettcherSF/Ada-Sweep-And-Prune)** | Broad-phase **AABB** overlap candidates (sort-and-sweep) |
| **[Ada-Point-In-Polygon](https://github.com/RobertBoettcherSF/Ada-Point-In-Polygon)** | Ray casting / winding containment |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB / oriented min-area box on a point set |

README links only — **no** package `with` of siblings.

## Algorithm sketch

A vertical sweep line $L$ moves left $\to$ right across the plane. The
continuous motion is discretised into **events**: left endpoints, right
endpoints, and discovered **crossing** points of segments that are
adjacent along $L$.

### Data structures

1. **Event queue** $Q$ — priority queue of potential events ordered by
   abscissa (then ordinate, then kind). Educational: a dense array kept
   sorted by `Event_Before`.
2. **Sweep status** $T$ — the segments currently crossed by $L$, ordered
   by the $y$-coordinate of their intersection with $L$. Educational: a
   dense array (`Max_Segments ≤ 32`), not a red–black tree.

### Event processing (Bentley & Ottmann 1979)

$$
\begin{aligned}
\text{Left endpoint of } s &\colon
  \text{insert } s \text{ into } T;\
  \text{enqueue crossings of } s \text{ with neighbours}; \\
\text{Right endpoint of } s &\colon
  \text{delete } s \text{ from } T;\
  \text{enqueue crossing of former neighbours}; \\
\text{Crossing of } s,t &\colon
  \text{report the point};\
  \text{swap } s,t \text{ in } T;\
  \text{enqueue new outer neighbour crossings}.
\end{aligned}
$$

With a balanced status tree the classic bound is
$O((n+k)\log n)$ for $n$ segments and $k$ crossings. This sketch uses
linear status scans, so total time is $O((n+k)\,n)$ — fine for
$n \le 32$.

### Proper intersection predicate

Segments $AB$ and $CD$ **properly** intersect when each endpoint of one
lies strictly on opposite sides of the other:

$$
\begin{aligned}
\operatorname{Orient2D}(A,B,C)\cdot\operatorname{Orient2D}(A,B,D) &< 0, \\
\operatorname{Orient2D}(C,D,A)\cdot\operatorname{Orient2D}(C,D,B) &< 0.
\end{aligned}
$$

Shared endpoints, T-junctions at an endpoint, and **overlapping
collinear** overlaps are **not** reported — limited educational handling
of those degeneracies. Production codes use exact predicates and
perturbation (de Berg et al.; LEDA).

### Shamos–Hoey cousin (`Any_Intersection`)

Same sweep, but return as soon as the first proper crossing is found
(detection only). This sheet skips a standalone Shamos–Hoey package; the
early-exit entry point is the educational cousin.

### Educational robustness

Floating `Orient2D` / `Y_At_X` use a fixed $\varepsilon$-threshold. They
work for well-separated classroom examples (axis-aligned crosses, simple
polygons' diagonals, random general-position segments). Crossing events
that gather several active segments through one point reverse that status
block in the de Berg style (educational multi-concurrencies). Overlapping
**collinear** overlaps and T-junctions at endpoints remain unreported
(limited handling). Empty inputs and oversized sets ($n < 1$ or
$n > Max\_Segments$) raise `Invalid_Argument`.

## API sketch

| Operation | Role |
| --- | --- |
| `Find_Intersections` | Report all proper crossings (point + index pair) |
| `Intersection_Count_Of` | Count of reported crossings |
| `Any_Intersection` | Shamos–Hoey-style early-exit detection |
| `Brute_Force_Intersections` | $O(n^2)$ oracle for teaching / tests |
| `Segments_Properly_Intersect` / `Intersection_Point` | Pair predicates |
| `Orient2D` / `Event_Before` / `Y_At_X` / `Left_Of` / `Right_Of` | Sweep helpers |
| `Same_Intersection_Set` | Order-independent multiset compare |
| `Near` / `Near_Point` / `Dist2` | Floating comparisons |

Domain types: `Point`, `Segment`, `Segment_Array` / `Segment_Set`,
`Intersection`, `Intersection_List`, `Event`, `Event_Queue`,
`Sweep_Status`, `Real`. Exception: `Invalid_Argument` when $n < 1$ or
$n > Max\_Segments$.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
