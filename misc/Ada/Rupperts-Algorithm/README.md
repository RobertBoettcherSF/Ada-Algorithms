# Ruppert's algorithm — Ada 2023

Educational, self-contained Ada 2023 package for **Ruppert's algorithm**:
**2-D Delaunay refinement** / quality mesh generation. Starting from a
Delaunay triangulation of input sites (and an optional planar
straight-line graph of constrained segments), the algorithm inserts
**Steiner points** — circumcenters of poor-quality (skinny) triangles, or
midpoints of **encroached** segments — until every triangle meets a
prescribed **minimum angle** bound (or an educational Steiner budget /
point-capacity limit is reached). See
[Wikipedia: Ruppert's algorithm](https://en.wikipedia.org/wiki/Ruppert's_algorithm).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`, small `Max_Steiner`). Orientation, in-circle, and
encroachment tests use ordinary `Real` (`digits 15`) arithmetic. It is
**not** a production mesh generator (**not** [Triangle](https://www.cs.cmu.edu/~quake/triangle.html) /
**not** CGAL), and it does **not** claim Ruppert's theoretical termination
guarantees (~$20.7^\circ$ for non-acute input) under floating-point caps.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with meshing / Delaunay siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Rupperts-Algorithm`) | Delaunay refinement via Steiner circumcenters / segment midpoints |
| **Ada-Chews-Second-Algorithm** (ahead) | Chew's second algorithm; often preferred in Triangle for some inputs |
| **Ada-Bowyer-Watson** (ahead / sibling) | Incremental Delaunay cavity retriangulation (embedded here, no `with`) |
| **Ada-Delaunay-Triangulation** (ahead) | Survey / alternate Delaunay constructions |

README links only — **no** package `with` of siblings. Incremental Delaunay
used inside `Refine` is **embedded** (Bowyer–Watson style).

## Algorithm sketch

Wikipedia-style main loop (educational pseudocode):

$$
\begin{align*}
T &\leftarrow \operatorname{Delaunay}(P) \\
Q &\leftarrow \{\text{encroached segments}\} \cup \{\text{skinny triangles}\} \\
\text{while } Q \neq \emptyset &\text{ and Steiner budget remains:} \\
\quad &\text{if } Q \text{ has encroached segment } s: \\
\quad &\quad \text{insert midpoint of } s \text{ into } T \\
\quad &\text{else for skinny } t \in Q: \\
\quad &\quad c \leftarrow \operatorname{circumcenter}(t) \\
\quad &\quad \text{if } c \text{ encroaches some segment } s: \text{ split } s \\
\quad &\quad \text{else: insert } c \text{ into } T \\
\quad &\text{update } Q
\end{align*}
$$

A triangle is treated as skinny when its smallest corner angle is below
the caller’s $Min\_Angle\_Degrees$ threshold. Full Ruppert uses a
circumradius-to-shortest-edge ratio; the angle form is equivalent for
classroom purposes ($\alpha_{\min}$ bound).

### Educational robustness

Floating predicates (`Orient2D`, `In_Circumcircle`, diametral encroachment)
use a fixed $\varepsilon$-threshold. They work for well-separated classroom
examples but can misclassify near-collinear / near-cocircular cases.
Production codes use filtered / exact arithmetic and carefully engineered
segment recovery (e.g. Shewchuk’s Triangle).

## API sketch

| Operation | Role |
| --- | --- |
| `Refine` | Point-set Delaunay refinement; Steiner budget `Max_Steiner` |
| `Refine_With_Segments` | Same + simplified PSLG encroachment / midpoint splits |
| `Triangulate` | Embedded Bowyer–Watson Delaunay |
| `In_Circumcircle` / `Circumcenter` / `Orient2D` | Geometric predicates |
| `Angle_Degrees_At` / `Triangle_Min_Angle_Degrees` / `Is_Skinny` | Quality |
| `Encroaches_Segment` / `Point_Encroaches_Any_Segment` | Diametral test |
| `Mesh_Min_Angle_Degrees` / `Count_Skinny` / `Aspect_Ratio` | Mesh metrics |
| `Bounds_Of` / `Has_Near_Duplicate` | Pre-checks |

Domain types: `Point`, `Segment`, `Triangle`, `Triangulation`,
`Refine_Result`, `Bounding_Box`, `Real`.

Raises `Invalid_Argument` for bad point counts, near-duplicates, or
angle bounds outside $(0, 60)$ degrees.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
