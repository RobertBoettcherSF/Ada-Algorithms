# Jump-and-Walk algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Jump-and-Walk**
algorithm: **point location in a planar triangulation** with almost no
preprocessing beyond the triangulation and its triangle–triangle adjacency.
A small set of candidate triangles is sampled (the **jump**); the walk
starts from the sample whose **centroid** is closest to the query $Q$, then
steps triangle-to-triangle toward $Q$ in the Lawson / Green–Sibson style
until the containing simplex is found. See
[Wikipedia: Jump-and-Walk algorithm](https://en.wikipedia.org/wiki/Jump-and-Walk_algorithm).

Jump-and-Walk is a folklore improvement over a single random start; formal
analysis on random Delaunay triangulations is due to Devroye–Mücke–Zhu
(2-D) and Mücke–Saias–Zhu (3-D). The method appears in practice in
**Qhull**, **Triangle**, and **CGAL**.

This package is a **classroom sketch** on small meshes
(`Max_Triangles = 64`): orientation and inclusion use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production computational
geometry kernel (no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Jump-And-Walk`) | Point location: random jump + adjacency walk |
| **Ada-GJK** (ahead) | Distance / intersection of convex bodies |
| **Ada-Geometric-Hashing** (ahead) | Spatial hashing / candidate filtering for queries |

README links only — **no** package `with` of siblings.

## Algorithm sketch

**Jump.** Draw a small sample of triangle indices
$S = \{T_1,\ldots,T_k\}$ (educational default $k = 8$, clamped to mesh
size). Choose

$$
T_\star = \arg\min_{T \in S}\ \| c(T) - Q \|^2
$$

where $c(T)$ is the centroid of triangle $T$.

**Walk (Lawson / Green–Sibson).** From $T_\star$, while $Q$ is not in the
current triangle $\triangle ABC$ (CCW), cross the first oriented edge
$e$ with $\operatorname{Orient2D}(e,Q) < 0$ into the neighbor across $e$.
If that neighbor is missing (boundary sentinel $-1$), report **not
found** — $Q$ lies outside the triangulated domain.

$$
\begin{align*}
T &\leftarrow T_\star \\
\text{while } Q \notin T &: \\
\quad e &\leftarrow \text{first edge of } T \text{ with } Q \text{ to the right} \\
\quad \text{if } \operatorname{nbr}(T,e) = -1 &\text{ then return outside} \\
\quad T &\leftarrow \operatorname{nbr}(T,e) \\
\text{return } T
\end{align*}
$$

Expected walk length on random Delaunay meshes is sublinear in the
number of triangles under standard models; this educational build uses a
fixed sample budget and a hard step cap of `Max_Triangles`.

### Educational robustness

`Orient2D` / `Point_In_Triangle` use a fixed $\varepsilon$-threshold.
They work for well-separated classroom examples but can misclassify
near-degenerate configurations. Production codes use filtered / exact
arithmetic (e.g. Shewchuk predicates, CGAL kernels). A walk that exits
across a boundary returns locate result $0$ (outside); an empty mesh
raises `Invalid_Argument`.

## API sketch

| Operation | Role |
| --- | --- |
| `Locate` / `Locate_Jump_And_Walk` | Jump sample + walk; optional RNG `Seed`; empty mesh → `Invalid_Argument` |
| `Walk_From` | Pure Lawson walk from a given start triangle (teaching) |
| `Orient2D` / `CCW` / `Point_In_Triangle` | Geometric predicates |
| `Centroid` / `Dist2` / `Near` | Helpers for jump scoring |
| `Build_Convex_Fan` | Fan triangulation of a CCW convex polygon + adjacency |
| `Triangle_Count_Of` / `Get_Triangle` / `Get_Neighbors` | Mesh accessors |

Domain types: `Point`, `Triangle` (vertex indices), `Adjacency`
(neighbor per opposite edge, $-1$ on boundary), `Mesh`, `Real`.
Locate returns `Locate_Result` in $0 .. Max_Triangles$ ($0$ = outside /
not found).

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
