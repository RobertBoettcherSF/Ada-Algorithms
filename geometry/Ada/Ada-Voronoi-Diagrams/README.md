# Voronoi diagrams — Ada 2023 educational survey

Self-contained Ada 2023 classroom sketch of **2-D Voronoi diagrams**: a
partition of the plane into cells of nearest sites (seeds / generators).
For sites $p_1,\ldots,p_n$ the cell of $p_k$ is

$$
R_k = \{ x \in \mathbb{R}^{2} : d(x,p_k) \le d(x,p_j)\ \forall j \ne k \}.
$$

Each cell is a convex polygon (possibly unbounded) obtained as the
intersection of half-planes bounded by **perpendicular bisectors** of
site pairs. Vertices of the diagram are points with three or more equally
nearest sites. See
[Wikipedia: Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram).

## Duality with Delaunay triangulation

The Voronoi diagram of a point set is the **dual** of its Delaunay
triangulation:

| Voronoi | Delaunay |
| --- | --- |
| Vertex (circumcenter) | Triangle |
| Edge (bisector piece) | Edge between two sites |
| Cell of site $p$ | Star of triangles around $p$ |

This package builds a small Delaunay mesh with an **embedded
Bowyer–Watson-style** incremental sketch (copied helpers; **no**
`with` of sibling packages), then derives:

1. **Voronoi vertices** = circumcenters of Delaunay triangles.
2. **Bounded Voronoi edges** = segments joining circumcenters of triangles
   that share a Delaunay edge.
3. **Unbounded rays** = hull Delaunay edges dualize to rays from the
   unique adjacent circumcenter along the outward perpendicular bisector.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`). Classroom bound: `Max_Sites = 64`. Floating predicates use
ordinary `Real` (`digits 15`) — **not** a production CGAL / exact kernel.

Part of the **RobertBoettcherSF** Ada algorithm series.

## Fortune sweep vs incremental dual

| Approach | Idea |
| --- | --- |
| **This survey** (`Ada-Voronoi-Diagrams`) | Incremental Delaunay → dual Voronoi vertices / edges |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Incremental Delaunay alone (cavity + hole retriangulation) |
| **[Ada-Fortunes-Algorithm](https://github.com/RobertBoettcherSF/Ada-Fortunes-Algorithm)** (ahead) | Sweep-line Voronoi ($O(n\log n)$); dual yields Delaunay |

Fortune’s algorithm maintains a beach line of parabolas while a
horizontal sweep line advances; circle events emit Voronoi vertices.
Incremental dual construction (as here) is simpler to teach for tiny
point sets and makes the Delaunay–Voronoi correspondence explicit.

README links only — **no** package `with` of siblings.

### Educational robustness

Predicates (`Orient2D`, `In_Circumcircle`) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear or near-cocircular configurations.
Production codes use filtered / exact arithmetic (Shewchuk predicates,
CGAL kernels).

## API sketch

| Operation | Role |
| --- | --- |
| `Delaunay_From_Sites` | Embedded Bowyer–Watson Delaunay; raises `Invalid_Argument` if $<3$ sites, $>Max_Sites$, or near-duplicates |
| `Build_Voronoi` | Dual Voronoi vertices + bounded/unbounded edges |
| `Nearest_Site` | Brute-force cell membership (closest site index) |
| `Midpoint` / `Perpendicular_Direction` / `On_Perpendicular_Bisector` | Bisector concepts |
| `In_Circumcircle` / `Orient2D` / `CCW` / `Circumcenter` | Geometric predicates |
| `Dist2` / `Distance` / `Near` / `Near_Point` | Metric helpers |
| `Bounds_Of` / `Has_Near_Duplicate` | Pre-checks |
| `Is_Delaunay_Empty_Circle` | Educational empty-circle verifier |
| `Count_Bounded_Edges` / `Count_Unbounded_Edges` | Edge tallies |
| Accessors | `Triangle_Count_Of`, `Get_Triangle`, `Voronoi_Vertex_Count_Of`, `Get_Voronoi_Vertex`, `Get_Voronoi_Edge`, … |

Domain types: `Point`, `Triangle`, `Triangulation`, `Voronoi_Vertex`,
`Voronoi_Edge`, `Voronoi_Diagram`, `Bounding_Box`, `Real`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
