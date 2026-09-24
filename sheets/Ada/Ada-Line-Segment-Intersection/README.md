# Line segment intersection — Ada 2023

Educational, self-contained Ada 2023 **survey** of **planar line-segment
intersection**: classify how two closed segments meet, recover a unique
meeting point when it exists, report all intersecting pairs among a tiny
set by $O(n^2)$ all-pairs search, and optionally run a thin
**Bentley–Ottmann-style** sweep (`Find_All`) for proper crossings only
(`Max_Segments ≤ 32`). See
[Wikipedia: Line segment intersection](https://en.wikipedia.org/wiki/Line_segment_intersection)
and
[Wikipedia: Line–line intersection](https://en.wikipedia.org/wiki/Line–line_intersection).

This package is a **classroom sketch**. Predicates use ordinary `Real`
(`digits 15`) arithmetic with a fixed $\varepsilon$-threshold. It is
**not** a production computational geometry kernel (no adaptive exact
predicates / CGAL, no LEDA-style symbolic perturbation).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry / sweep siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Line-Segment-Intersection`) | Survey of **pair classification** + all-pairs / thin sweep reporting |
| **[Ada-Bentley-Ottmann](https://github.com/RobertBoettcherSF/Ada-Bentley-Ottmann)** | Full classroom **sweep-line reporting** of proper crossings |
| **[Ada-Sweep-And-Prune](https://github.com/RobertBoettcherSF/Ada-Sweep-And-Prune)** | Broad-phase **AABB** overlap candidates (sort-and-sweep) |
| **[Ada-Point-In-Polygon](https://github.com/RobertBoettcherSF/Ada-Point-In-Polygon)** | Ray casting / winding containment |
| **[Ada-Minimum-Bounding-Box](https://github.com/RobertBoettcherSF/Ada-Minimum-Bounding-Box)** | AABB / oriented min-area box on a point set |

README links only — **no** package `with` of siblings.

## Classification sketch

For closed segments $AB$ and $CD$, the educational taxonomy is:

| Kind | Meaning |
| --- | --- |
| `None` | Empty intersection |
| `Proper` | Relative interiors cross at a unique interior point |
| `Improper` | Unique meeting point involves an endpoint (shared endpoint or T-junction) |
| `Collinear_Overlap` | Supporting lines coincide and the segments share a positive-length interval |

### Orient2D

$$
\operatorname{Orient2D}(A,B,C)
  = (B_x-A_x)(C_y-A_y) - (C_x-A_x)(B_y-A_y)
$$

is twice the signed area of $\triangle ABC$: positive when $C$ is left of
directed $AB$, negative when right, near zero when collinear.

### Proper crossing

Segments properly intersect when each endpoint of one lies **strictly**
on opposite sides of the other:

$$
\begin{aligned}
\operatorname{Orient2D}(A,B,C)\cdot\operatorname{Orient2D}(A,B,D) &< 0, \\
\operatorname{Orient2D}(C,D,A)\cdot\operatorname{Orient2D}(C,D,B) &< 0.
\end{aligned}
$$

### Improper / T-junction / endpoint touch

If a single orientation is near zero and that endpoint lies on the other
closed segment (`On_Segment`), the meeting set is a unique point on the
boundary — reported as `Improper` (includes shared endpoints and
T-junctions).

### Collinear overlap

When all four orientations are near zero, project one segment onto the
parameter domain of the other and intersect with $[0,1]$. A positive-length
overlap is `Collinear_Overlap`; a single-parameter touch is `Improper`;
an empty projected interval is `None`.

### Unique point (line–line formula)

When the meeting set is a unique point, the supporting-line intersection
follows the usual parametric / Cramer form (see Line–line intersection).
For `Improper` cases the implementation prefers the lying-on endpoint
itself (educational robustness at T-junctions). Asking
`Intersection_Point` when the kind is `None` or `Collinear_Overlap`
raises `Invalid_Argument`.

## Naive all-pairs vs sweep

### Brute force — $O(n^2)$

`Brute_Force_Find_All` tests every unordered pair with
`Classify_Intersection` and records every `Kind /= None` entry (Proper,
Improper, and Collinear_Overlap). Transparent teaching oracle; fine for
$n \le 32$.

### Thin Bentley–Ottmann-style sweep — `Find_All`

A vertical sweep line moves left $\to$ right. Events are left endpoints,
right endpoints, and discovered **Proper** crossings of status neighbours.
The status structure is a dense array ordered by $y$ at the sweep
abscissa (not a balanced BST). Classic bound with a tree is
$O((n+k)\log n)$; this sketch uses linear status / queue scans, so
$O((n+k)\,n)$ — acceptable for `Max_Segments = 32`.

`Find_All` reports **Proper** crossings only (same policy as the
Bentley–Ottmann sibling). Degenerate improper / collinear cases remain
the job of the pair classifier and the brute-force reporter.

### When to use which

| Goal | Prefer |
| --- | --- |
| Classify a single pair (crossing / T / overlap / miss) | `Classify_Intersection` |
| Unique meeting point | `Intersection_Point` |
| All intersecting pairs including degeneracies | `Brute_Force_Find_All` |
| Proper crossings only, sweep narrative | `Find_All` |
| Production-scale $n$, exact predicates | CGAL / exact kernel (out of scope) |

## Educational robustness

Floating `Orient2D` / `On_Segment` use a fixed $\varepsilon$. They work for
well-separated classroom examples (axis-aligned crosses, T-junctions,
endpoint touches, parallel misses, collinear overlaps). Near-degenerate
zero-length segments and empty / oversized sets raise `Invalid_Argument`.
Production codes use exact predicates and perturbation (de Berg et al.;
LEDA).

## API sketch

| Operation | Role |
| --- | --- |
| `Classify_Intersection` | `None` / `Proper` / `Improper` / `Collinear_Overlap` |
| `Segments_Intersect` | `Classify /= None` |
| `Has_Unique_Intersection_Point` | Proper or Improper |
| `Intersection_Point` | Unique meeting point (else `Invalid_Argument`) |
| `Overlap_Representative` | Midpoint of a collinear overlap interval |
| `On_Segment` / `Orient2D` / `Is_Degenerate` | Geometric helpers |
| `Brute_Force_Find_All` | $O(n^2)$ all intersecting pairs (any kind) |
| `Find_All` / `Intersection_Count_Of` | Thin BO-style Proper crossings |
| `Filter_By_Kind` / `Same_Intersection_Set` | Teaching / test helpers |
| `Near` / `Near_Point` / `Dist2` | Floating comparisons |

Domain types: `Point`, `Segment`, `Segment_Array` / `Segment_Set`,
`Intersection_Kind`, `Intersection`, `Intersection_List`, `Real`.
Exception: `Invalid_Argument` on empty / oversized sets, near-degenerate
segments, or non-unique `Intersection_Point` requests.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
