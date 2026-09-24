# Chew's second algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Chew's second algorithm**:
**2-D Delaunay refinement** / quality mesh generation over a planar
straight-line graph (PSLG). Starting from a Delaunay triangulation of input
sites plus constrained segments, the algorithm inserts **Steiner points** —
circumcenters of poor-quality (skinny) triangles, or midpoints of segments
that reject a circumcenter under the Chew opposite-side / encroachment rule —
until every triangle meets a prescribed **minimum angle** bound (educational
default $30^\circ$), or a Steiner budget / point-capacity limit is reached. See
[Wikipedia: Chew's second algorithm](https://en.wikipedia.org/wiki/Chew's_second_algorithm)
(redirects to Delaunay refinement; the notes distinguish Chew vs Ruppert).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`, small `Max_Steiner`). Orientation, in-circle, opposite-side,
and diametral tests use ordinary `Real` (`digits 15`) arithmetic. It is
**not** a production mesh generator (**not** [Triangle](https://www.cs.cmu.edu/~quake/triangle.html) /
**not** CGAL), and it does **not** claim Chew's theoretical termination /
grading guarantees (often cited up to about $28.6^\circ$) under floating-point
caps.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with meshing / Delaunay siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Chews-Second-Algorithm`) | Chew's second algorithm; opposite-side rejection + diametral Steiner cleanup |
| **Ada-Rupperts-Algorithm** (sibling) | Ruppert refinement; encroached-segment queue before circumcenters |
| **Ada-Bowyer-Watson** (sibling) | Incremental Delaunay cavity retriangulation (embedded here, no `with`) |
| **Ada-Delaunay-Triangulation** (survey) | Survey / alternate Delaunay constructions |

README links only — **no** package `with` of siblings. Incremental Delaunay
used inside `Refine` is **embedded** (Bowyer–Watson style).

### Chew vs Ruppert (classroom)

| | **Chew (this package)** | **Ruppert (sibling)** |
| --- | --- | --- |
| Trigger to split a segment | Circumcenter of skinny $t$ lies on the **opposite side** of constrained segment $s$ from $t$, or encroaches $s$ | Circumcenter **encroaches** $s$ (diametral circle); encroached segments are preferred in a queue |
| On split | Insert midpoint of $s$; **remove** prior circumcenter Steiner points inside the diametral ball of $s$ | Insert midpoint; no Chew-style diametral Steiner cleanup in the educational sketch |
| Typical cited angle | Up to about $28.6^\circ$ (theory); classroom default $30^\circ$ | About $20.7^\circ$ classical; practical variants higher |

## Algorithm sketch

Wikipedia-style main loop (educational pseudocode):

$$
\begin{align*}
T &\leftarrow \operatorname{Delaunay}(P) \\
\text{while skinny } t &\text{ remains and Steiner budget allows:} \\
\quad c &\leftarrow \operatorname{circumcenter}(t) \\
\quad &\text{if } c \text{ is opposite-side of some constrained } s \text{ from } t \\
\quad &\quad\text{(or } c \text{ encroaches } s\text{):} \\
\quad &\quad \text{split } s \text{ at midpoint;} \\
\quad &\quad \text{drop prior circumcenter Steiners in diametral ball of } s \\
\quad &\text{else: insert } c \text{ into } T \\
\quad &\text{retriangulate}
\end{align*}
$$

A triangle is treated as skinny when its smallest corner angle is below
the caller’s $Min\_Angle\_Degrees$ threshold (default
$Default\_Min\_Angle = 30$).

### Educational robustness

Floating predicates (`Orient2D`, `In_Circumcircle`, diametral encroachment,
`Circumcenter_Opposite_Side`) use a fixed $\varepsilon$-threshold. They work
for well-separated classroom examples but can misclassify near-collinear /
near-cocircular cases. Production codes use filtered / exact arithmetic and
carefully engineered segment recovery (e.g. Shewchuk’s Triangle, where Chew’s
second algorithm is a common default quality mesher).

## API sketch

| Operation | Role |
| --- | --- |
| `Refine` | PSLG Chew refine: `Points`, `Segments`, angle, Steiner budget |
| `Triangulate` | Embedded Bowyer–Watson Delaunay |
| `In_Circumcircle` / `Circumcenter` / `Orient2D` | Geometric predicates |
| `Angle_Degrees_At` / `Triangle_Min_Angle_Degrees` / `Is_Skinny` | Quality |
| `Encroaches_Segment` / `Point_Encroaches_Any_Segment` | Diametral test |
| `Circumcenter_Opposite_Side` | Chew opposite-side rejection |
| `Mesh_Min_Angle_Degrees` / `Count_Skinny` / `Aspect_Ratio` | Mesh metrics |
| `Bounds_Of` / `Has_Near_Duplicate` | Pre-checks |

Domain types: `Point`, `Segment`, `Triangle`, `Triangulation`,
`Refine_Result`, `Bounding_Box`, `Real`.

Raises `Invalid_Argument` for bad point counts, near-duplicates, bad
segment indices, or angle bounds outside $(0, 60)$ degrees.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
