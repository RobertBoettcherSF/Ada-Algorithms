# Delaunay triangulation — Ada 2023 (survey)

Educational, self-contained Ada 2023 **survey** package for **2-D Delaunay
triangulation** of a finite point set. A triangulation is Delaunay when
**no site lies strictly inside the circumcircle** of any triangle (the
empty-circle property). Equivalently, among all triangulations of the
same sites it **maximizes the minimum angle**, and therefore tends to
avoid skinny “sliver” triangles. Named after Boris Delaunay (1934). See
[Wikipedia: Delaunay triangulation](https://en.wikipedia.org/wiki/Delaunay_triangulation).

This package is a **classroom sketch** on small point sets
(`Max_Points = 64`). Orientation and in-circle predicates use ordinary
`Real` (`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

**Implementation:** `Triangulate` embeds **Bowyer–Watson** incremental
construction (super-triangle → insert sites by cavity + hole
retriangulation → strip super vertices). The package does **not** `with`
sibling algorithm packages.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Dual of the Voronoi diagram

The Delaunay triangulation of a discrete point set $P$ in general position
is the **dual graph** of the [Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram)
of $P$:

- Circumcenters of Delaunay triangles are **Voronoi vertices**.
- If two Delaunay triangles share an edge, their circumcenters are joined
  by a Voronoi edge.
- Infinite Voronoi rays correspond to hull edges of the Delaunay mesh.

Special cases (collinear sites; four or more cocircular sites) make the
relationship ambiguous or degenerate — the classroom code assumes
well-separated, non-collinear educational inputs.

## Definition and properties

For sites $P$ in the plane, a triangulation $DT(P)$ is Delaunay when

$$
\forall\, \triangle ABC \in DT(P),\quad
\forall\, p \in P \setminus \{A,B,C\}:\quad
p \notin \operatorname{int}\bigl(\operatorname{circumcircle}(ABC)\bigr).
$$

Useful planar facts (see Wikipedia):

| Property | Note |
| --- | --- |
| Empty circumcircle | Defining local/global condition |
| Max–min angle | Smallest angle in $DT(P)$ is at least as large as in any other triangulation of $P$ |
| Convex hull | Union of triangles $=$ $\operatorname{conv}(P)$ |
| Triangle count | With $n$ sites and $b$ hull vertices: at most $2n-2-b$ triangles |
| Nearest-neighbor graph | Subgraph of the Delaunay graph |
| Geometric spanner | Planar stretch factor known $< 2$ |

Non-uniqueness: when four or more sites are cocircular (e.g. a rectangle),
either diagonal of the quadrilateral yields a Delaunay triangulation.

## Algorithms (survey)

| Method | Idea |
| --- | --- |
| **Bowyer–Watson** (this package) | Incremental: delete triangles whose circumcircles contain the new site; retriangulate the star-shaped hole |
| **Flip legalization** | Start from any triangulation; flip illegal edges ($D$ inside $\operatorname{circumcircle}(ABC)$) until all edges are legal |
| **Fortune sweep (dual)** | Compute the Voronoi diagram by a parabolic sweep; the dual is Delaunay |
| **Lift to 3-D** | Map $(x,y)\mapsto(x,y,x^{2}+y^{2})$; lower convex hull projects to Delaunay |
| **Divide-and-conquer** | Classic $O(n\log n)$ Guibas–Stolfi / Dwyer variants |

Bowyer–Watson sketch as implemented here:

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

Flip criterion (exposed as `Edge_Needs_Flip` for teaching; not used as the
primary constructor):

$$
\text{edge } AB \text{ of } \triangle ABC \text{ is illegal}
\quad\Leftrightarrow\quad
D \in \operatorname{int}\bigl(\operatorname{circumcircle}(ABC)\bigr)
$$

for the opposite vertex $D$ of the adjacent triangle.

### Educational robustness

Floating predicates (`Orient2D`, `In_Circumcircle`) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom examples
but can misclassify near-collinear or near-cocircular configurations.
Production codes use filtered / exact arithmetic (e.g. Shewchuk
predicates, CGAL kernels).

## Contrast with meshing / Voronoi siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Delaunay-Triangulation`) | Survey + embedded Bowyer–Watson Delaunay |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Dedicated incremental cavity algorithm |
| **Ada-Fortunes-Algorithm** (sibling) | Sweep-line Voronoi; dual yields Delaunay |
| **Ada-Voronoi-Diagrams** (sibling) | Explicit Voronoi cells / half-edge mesh |
| **Ada-Rupperts-Algorithm** (sibling) | Delaunay refinement / Steiner quality meshing |
| **Ada-Chews-Second-Algorithm** (sibling) | Chew’s second algorithm (alternate refinement) |

README links only — **no** package `with` of siblings. Incremental Delaunay
inside `Triangulate` is **embedded**.

## API sketch

| Operation | Role |
| --- | --- |
| `Triangulate` | Embedded Bowyer–Watson Delaunay; raises `Invalid_Argument` if $<3$ sites, $>Max_Points$, or near-duplicates |
| `In_Circumcircle` / `Orient2D` / `CCW` | Geometric predicates |
| `Circumcenter` / `Circumradius2` | Circle helpers |
| `Bounds_Of` / `Has_Near_Duplicate` | Pre-checks |
| `Is_Delaunay` / `Is_Delaunay_Edge_Empty` | Empty-circle verifier over all triangles |
| `Edge_Needs_Flip` | Flip legalization sketch (illegal-edge test) |
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
