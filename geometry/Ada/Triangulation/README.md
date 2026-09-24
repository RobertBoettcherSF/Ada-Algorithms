# Triangulation (geometry) — Ada 2023 survey

Educational, self-contained Ada 2023 **survey** package for geometric
**triangulation**: a subdivision of a planar object into triangles that meet
**edge-to-edge** and **vertex-to-vertex**. By extension, higher-dimensional
objects are subdivided into simplices (e.g. tetrahedra in 3-D). See
[Wikipedia: Triangulation (geometry)](https://en.wikipedia.org/wiki/Triangulation_(geometry)).

This package is a **classroom sketch** on small inputs (`Max_Points = 64`).
Orientation, area, and in-circle predicates use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational geometry
kernel (no adaptive exact predicates / CGAL).

**Embedded drivers** (no sibling `with`):

| Driver | Idea |
| --- | --- |
| `Triangulate_Polygon` | Ear clipping of a simple polygon without holes ($n-2$ triangles) |
| `Triangulate_Point_Set` | Fan from an interior site / convex hull, else Bowyer–Watson-lite |
| `Fan_From_Vertex` / `Fan_From_Interior` | Explicit educational fan sketches |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Types of triangulation (survey)

| Kind | Object | Vertices | Typical goal |
| --- | --- | --- | --- |
| **Polygon triangulation** | Simple polygon $P$ (no holes here) | Vertices of $P$ only | $n-2$ triangles whose union is $P$ |
| **Point-set triangulation** | Discrete sites $\mathcal{P}\subset\mathbb{R}^{2}$ | Sites of $\mathcal{P}$ | Subdivision of $\operatorname{conv}(\mathcal{P})$ |
| **Delaunay triangulation** | Point set | Sites | Empty circumcircle / max–min angle |
| **Constrained Delaunay** | Polygon / PSLG | Input vertices (+ optional Steiner) | Respect required edges |
| **Mesh / FEM triangulation** | Domain to simulate | May add **Steiner** points | Quality triangles (angles, size) |

A triangulation $T$ of $\mathbb{R}^{d}$ is a locally finite simplicial complex
covering the space: any two simplices intersect in a common face or not at
all. In the plane ($d=2$), simplices are triangles.

### Polygon triangulation

Any simple $n$-gon without holes admits a triangulation into **exactly**
$n-2$ triangles using $n-3$ non-crossing diagonals:

$$
\#\{\text{triangles}\} = n - 2.
$$

Classical **ear clipping** (two ears theorem) repeatedly removes an ear tip
until one triangle remains. Faster $O(n\log n)$ monotone methods and
Chazelle’s linear-time algorithm exist; this package embeds $O(n^{2})$ ear
clipping only.

### Point-set triangulation

A point-set triangulation subdivides $\operatorname{conv}(\mathcal{P})$ so
that every simplex vertex lies in $\mathcal{P}$. Special cases:

- **Delaunay** — no site strictly inside any triangle’s circumcircle.
- **Minimum-weight triangulation** — minimize total edge length (NP-hard
  in general).
- **TIN** (cartography) — lift sites by elevation for terrain.

Educational drivers here: **fan** from an interior site onto the convex
hull (or hull fan when all sites are extreme), otherwise embedded
**Bowyer–Watson-lite** incremental construction.

### Delaunay / constrained / refinement (siblings)

Delaunay, constrained Delaunay, and quality refinement (Steiner points)
are surveyed in sibling packages — **README links only**, no `with`:

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Triangulation`) | Survey of triangulation kinds + polygon / point-set sketches |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Dedicated ear-clip polygon triangulation |
| **[Ada-Delaunay-Triangulation](https://github.com/RobertBoettcherSF/Ada-Delaunay-Triangulation)** | Survey + embedded Bowyer–Watson Delaunay |
| **[Ada-Rupperts-Algorithm](https://github.com/RobertBoettcherSF/Ada-Rupperts-Algorithm)** | Delaunay refinement / Steiner quality meshing (Ruppert) |

## Algorithm sketches

### Ear clipping (polygon)

$$
\begin{align*}
&\text{while } |V| \ge 4: \\
&\quad\text{find ear tip } v_i \text{ (convex; no other } v_k \text{ in } \triangle v_{i-1}v_iv_{i+1}) \\
&\quad\text{emit } \triangle v_{i-1}v_iv_{i+1};\quad V \leftarrow V \setminus \{v_i\} \\
&\text{emit the final remaining triangle}
\end{align*}
$$

### Fan from an interior site (point set)

When $\mathcal{P}$ has a unique interior site $p$ and hull vertices
$h_1,\ldots,h_b$ in CCW order:

$$
T = \{\,\triangle p\,h_j\,h_{j+1} : j=1,\ldots,b\,\}
\quad (h_{b+1}:=h_1).
$$

When all sites are on the hull, fan from one hull vertex. Multiple interior
sites fall through to Bowyer–Watson-lite.

### Bowyer–Watson-lite (fallback)

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

### Educational robustness

Floating predicates (`Orient2D`, `Point_In_Triangle`, `In_Circumcircle`)
use a fixed $\varepsilon$-threshold. They work for well-separated classroom
examples but can misclassify near-collinear or near-cocircular inputs.
Production codes use filtered / exact arithmetic.

## API sketch

| Operation | Role |
| --- | --- |
| `Triangulate_Polygon` | Ear-clip; raises `Invalid_Argument` if $n<3$, $n>Max\_Points$, or degenerate |
| `Triangulate_Point_Set` | Fan interior/hull or Bowyer–Watson-lite |
| `Fan_From_Vertex` / `Fan_From_Interior` | Explicit fan sketches |
| `Orient2D` / `CCW` / `Triangle_Area` / `Area` | Geometric measures |
| `Polygon_Triangle_Count` | Returns $n-2$ (0 if $n<3$) |
| `Point_In_Triangle` / `In_Circumcircle` | Predicates |
| `Is_Simple_Enough` / `Has_Near_Duplicate` / `Bounds_Of` | Pre-checks |
| `Triangle_Count_Of` / `Get_Triangle` / `Uses_Vertex` | Mesh accessors |

Domain types: `Point`, `Point_Array`, `Triangle`, `Mesh`, `Bounding_Box`,
`Real`. Exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
