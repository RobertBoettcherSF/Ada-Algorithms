# Quasitriangulation — Ada 2023

Educational, self-contained Ada 2023 package for **quasi-triangulation**: a
subdivision of a geometric object into simplices whose **vertices are
arbitrary sloped line segments** (not points). The result is a
**topological triangulation**, not a classical geometric triangulation of a
point set, and it may share some **Delaunay-like** characteristics. See
[Wikipedia: Quasitriangulation](https://en.wikipedia.org/wiki/Quasitriangulation).

This package is a **classroom sketch** on small segment sets
(`Max_Segments = 32`): orientation and intersection predicates use ordinary
`Real` (`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL, no true segment
Delaunay).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with Delaunay / polygon-triangulation siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Quasitriangulation`) | Topological triangulation with **segment-sites** as vertices |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Incremental **point** Delaunay (circumcircle cavity) |
| **[Ada-Voronoi-Diagrams](https://github.com/RobertBoettcherSF/Ada-Voronoi-Diagrams)** | Voronoi cells dual to point Delaunay |
| **Ada-Delaunay-Triangulation** (ahead) | Survey / alternate point Delaunay constructions |
| **Ada-Polygon-Triangulation** (ahead) | Classical triangulation of a simple polygon (point vertices) |

README links only — **no** package `with` of siblings.

## Concept sketch

Wikipedia (short): a quasi-triangulation subdivides into simplices whose
"vertices" are line segments of arbitrary slope. That is **not** a
geometric triangulation of points; it **is** a topological triangulation,
and may resemble Delaunay in some combinatorial / empty-region senses.

$$
\begin{align*}
V &= \{\text{oriented segments } s_i\} \\
F &= \{\text{2-simplices } (s_u,s_v,s_w)\} \\
&\quad\text{(combinatorial faces; sites are segments)} \\
\chi &= |V| - |E| + |F| \;=\; 1 \quad\text{(triangulated disk)}
\end{align*}
$$

Classical point triangulation is the special case where every site
degenerates to a point ($A \approx B$). This package exposes
`Is_Classical_Point_Setting` vs `Is_Quasi_Setting` for that contrast.

### Educational construction

`Build_From_Segments` rejects proper crossings and degeneracies, places a
**midpoint proxy** at each segment, fans a tiny triangulation of those
proxies, and stores faces as **segment-index triples**. The embedding of
faces is a combinatorial / topological sketch — not a claim that the
segment bodies themselves tile the plane as Euclidean triangles.

`Refine_Toward_Delaunay_Like` is a **documented stub**: it only restores
CCW midpoint orientation. It does **not** implement Lawson flips, empty
circumcircle optimization, or a Voronoi-of-segments kernel.

### Educational robustness

Floating predicates (`Orient2D`, `Classify_Intersection`) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear or near-touching configurations.
Production codes use filtered / exact arithmetic.

## API sketch

| Operation | Role |
| --- | --- |
| `Build_From_Segments` | Quasi-mesh from non-crossing positive-length segments |
| `From_Point_Sites` | Classical point case wrapped as zero-length segments |
| `Classify_Intersection` / `Segments_Properly_Cross` | Segment meeting tests |
| `Orient2D` / `CCW` / `Midpoint` / `Segment_Length` | Geometric helpers |
| `Is_Quasi_Setting` / `Is_Classical_Point_Setting` | Point vs segment sites |
| `Is_Topological_Triangulation` / `Euler_Check` / `Face_Count` | Combinatorial checks |
| `Refine_Toward_Delaunay_Like` | Educational Delaunay-like stub |
| `Get_Segment` / `Get_Face` / `Get_Edge` | Mesh accessors |

Domain types: `Point`, `Segment`, `Simplex`, `Edge`, `Quasi_Mesh`,
`Intersection_Kind`, `Real`. Exceptions: `Invalid_Argument`,
`Capacity_Exceeded`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
