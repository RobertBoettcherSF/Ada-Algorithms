# Polygon triangulation — Ada 2023

Educational, self-contained Ada 2023 package for **polygon triangulation**
of a **simple polygon without holes** by **ear clipping** (two ears
theorem). Vertices are ordinary points; the output is a set of $n-2$
triangles with pairwise non-intersecting interiors whose union is the
polygon $P$. See
[Wikipedia: Polygon triangulation](https://en.wikipedia.org/wiki/Polygon_triangulation).

This package is a **classroom sketch** on small polygons
(`Max_Vertices = 64`): orientation and point-in-triangle predicates use
ordinary `Real` (`digits 15`) arithmetic. It is **not** a production
computational geometry kernel (no adaptive exact predicates / CGAL, no
Chazelle linear-time triangulation).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Delaunay / quasitriangulation / marching siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Polygon-Triangulation`) | Ear-clip a **simple polygon** into $n-2$ triangles (point vertices) |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Incremental **point-set** Delaunay (circumcircle cavity) |
| **[Ada-Quasitriangulation](https://github.com/RobertBoettcherSF/Ada-Quasitriangulation)** | Topological triangulation with **segment-sites** as vertices |
| **Ada-Delaunay-Triangulation** (ahead) | Survey / alternate point Delaunay constructions |
| **Ada-Marching-Triangles** (ahead) | Contour / isosurface triangulation on a grid (marching family) |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Any simple polygon with $n \ge 4$ vertices and no holes has at least two
**ears**: triangles formed by two boundary edges and a diagonal that lies
entirely inside $P$. Ear clipping repeatedly finds and removes an ear
until one triangle remains.

$$
\begin{align*}
&\text{while } |V| \ge 4: \\
&\quad\text{find ear tip } v_i \text{ (convex; no other } v_k \text{ in } \triangle v_{i-1}v_iv_{i+1}) \\
&\quad\text{emit } \triangle v_{i-1}v_iv_{i+1};\quad V \leftarrow V \setminus \{v_i\} \\
&\text{emit the final remaining triangle}
\end{align*}
$$

A convex $n$-gon also admits a trivial **fan** triangulation from one
vertex; the number of triangulations of a convex $n$-gon is the
$(n-2)$nd Catalan number. This package implements classical **ear
clipping** only ($O(n^{2})$ educational). Faster $O(n\log n)$ monotone
partition methods and Chazelle's linear-time algorithm exist but are out
of scope here.

### Educational robustness

Floating predicates (`Orient2D`, `Point_In_Triangle`, `Is_Ear`) use a
fixed $\varepsilon$-threshold. They work for well-separated classroom
examples but can misclassify near-collinear vertices or near-degenerate
ears. Production codes use filtered / exact arithmetic. Inputs should be
simple polygons without holes; `Is_Simple_Enough` is a lightweight
pre-check (bounds, no consecutive duplicates, non-zero area), not a full
simplicity proof.

Clockwise polygons are accepted: a working vertex ring is reversed to
CCW so convex / ear tests use positive orientation, while emitted
triangle indices still refer to the original vertex order.

## API sketch

| Operation | Role |
| --- | --- |
| `Triangulate_Ear_Clip` | Ear-clip triangulation; raises `Invalid_Argument` if $n<3$, $n>Max\_Vertices$, or degenerate |
| `Orient2D` / `CCW` / `Point_In_Triangle` | Geometric predicates |
| `Signed_Area` / `Area` / `Is_CCW` | Shoelace measures / orientation |
| `Is_Convex_Vertex` / `Is_Ear` | Vertex classification / ear-tip test |
| `Is_Simple_Enough` | Lightweight educational pre-check |
| `Triangle_Count_Of` / `Get_Triangle` / `Uses_Vertex` | Mesh accessors |

Domain types: `Point`, `Point_Array` (polygon), `Triangle` (vertex index
triple), `Triangulation`, `Real`. Exceptions: `Invalid_Argument`,
`Capacity_Exceeded`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
