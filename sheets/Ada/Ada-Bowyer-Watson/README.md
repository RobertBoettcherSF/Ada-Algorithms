# Bowyer–Watson algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Bowyer–Watson
algorithm**: incremental **2-D Delaunay triangulation** of a finite point
set. Sites are inserted one by one into a valid triangulation; every
triangle whose circumcircle contains the new site is deleted, leaving a
star-shaped polygonal hole that is then retriangulated to the new site.
A large **super-triangle** seeds the mesh; triangles that still touch a
super-triangle vertex are stripped at the end. The Delaunay triangulation
is the **dual** of the Voronoi diagram of the same sites. See
[Wikipedia: Bowyer–Watson algorithm](https://en.wikipedia.org/wiki/Bowyer–Watson_algorithm).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`): orientation and in-circle predicates use ordinary
`Real` (`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with triangulation / Voronoi siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Bowyer-Watson`) | Incremental Delaunay via cavity + hole retriangulation |
| **[Ada-Fortunes-Algorithm](https://github.com/RobertBoettcherSF/Ada-Fortunes-Algorithm)** (ahead) | Sweep-line Voronoi; dual yields Delaunay |
| **Ada-Voronoi-Diagram** (ahead) | Explicit Voronoi cells / half-edge mesh |
| **Ada-Delaunay-Triangulation** (ahead) | Survey / alternate constructions (flip, divide-and-conquer) |

README links only — **no** package `with` of siblings.

## Algorithm sketch

$$
\begin{align*}
T &\leftarrow \{\text{super-triangle}\} \\
\text{for each site } p &: \\
\quad B &\leftarrow \{ \tau \in T : p \in \operatorname{circumcircle}(\tau) \} \\
\quad H &\leftarrow \text{boundary edges of } \bigcup B \\
\quad T &\leftarrow (T \setminus B) \cup \{ \operatorname{tri}(e,p) : e \in H \} \\
T &\leftarrow T \setminus \{\tau : \tau \text{ meets a super vertex}\}
\end{align*}
$$

Expected complexity with adjacency walks is $O(n\log n)$; this educational
build scans all triangles per insertion ($O(n^{2})$ circumcircle tests).

### Educational robustness

Floating predicates (`Orient2D`, `In_Circumcircle`) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear or near-cocircular configurations.
Production codes use filtered / exact arithmetic (e.g. Shewchuk
predicates, CGAL kernels).

## API sketch

| Operation | Role |
| --- | --- |
| `Triangulate` | Bowyer–Watson Delaunay; raises `Invalid_Argument` if $<3$ sites, $>Max_Points$, or near-duplicates |
| `In_Circumcircle` / `Orient2D` / `CCW` | Geometric predicates |
| `Circumcenter` / `Circumradius2` | Circle helpers |
| `Bounds_Of` / `Has_Near_Duplicate` | Pre-checks |
| `Is_Delaunay_Edge_Empty` | Educational empty-circle verifier |
| `Triangle_Count_Of` / `Get_Triangle` / `Shares_Vertex` | Mesh accessors |

Domain types: `Point`, `Triangle` (vertex indices), `Triangulation`,
`Bounding_Box`, `Real`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
