# Marching triangles — Ada 2023

Educational, self-contained Ada 2023 package for **marching triangles**:
surface reconstruction that transforms a **cloud of points** lying on a
3-D surface into a **polygon mesh**. The classroom sketch seeds a compact
non-degenerate triangle from nearest-neighbour geometry, then grows an
**advancing front** by attaching new triangles along boundary edges to
nearby unused samples. This is a faster alternative (for small clouds) to
full 3-D **Delaunay**-based surface reconstruction. See
[Wikipedia: Marching triangles](https://en.wikipedia.org/wiki/Marching_triangles).

This package is a **classroom sketch** on small clouds
(`Max_Points = 64`): distances and normals use ordinary `Real`
(`digits 15`) arithmetic. It is **not** a production surface-reconstruction
kernel (no CGAL Advancing Front priority queue, no Poisson / Hoppe SDF,
no robust exact predicates).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Empty GitHub skeleton:
[Ada-Marching-Triangles](https://github.com/RobertBoettcherSF/Ada-Marching-Triangles)
(do not push from this workspace unless asked).

## Contrast with Delaunay / marching siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Marching-Triangles`) | Point-cloud → triangle mesh via seed + advancing front |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Incremental **2-D point-set** Delaunay (circumcircle cavity) |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Ear-clip a **simple polygon** (not a free 3-D cloud) |
| **[Ada-Marching-Cubes](https://github.com/RobertBoettcherSF/Ada-Marching-Cubes)** | **Isosurface** extraction on a scalar **grid** (256 cube cases) |
| **Ada-Marching-Squares** / **Ada-Marching-Tetrahedrons** | 2-D / tetrahedral marching-family isosurfaces |

README links only — **no** package `with` of siblings.

Marching **triangles** (this package) meshes an unorganized **point cloud**.
Marching **cubes** extracts a level set $f(\mathbf{x})=c$ from a sampled
scalar field. Do not confuse the two.

## Algorithm sketch

$$
\begin{align*}
\tau_0 &\leftarrow \arg\min_{\triangle ijk} \operatorname{perimeter}(\triangle ijk)
  \quad\text{s.t. area}(\triangle ijk)>\varepsilon \\
T &\leftarrow \{\tau_0\};\quad F \leftarrow \partial \tau_0
  \quad\text{(frontier edge set)} \\
\text{while } &\exists\, e=ij\in F \text{ with a valid nearby sample } p: \\
\quad p &\leftarrow \arg\min \operatorname{score}(e,p)
  \quad\text{(midpoint distance + sliver penalty)} \\
\quad T &\leftarrow T \cup \{\triangle ijp\};\quad
  F \leftarrow F \mathbin{\triangle} \{ij,jp,pi\}
\end{align*}
$$

### Educational heuristics

1. **Seed** — among all triples with area $>\varepsilon$, pick the
   smallest perimeter (compact local triangle).
2. **Candidate radius** — for frontier edge $ij$, only consider points
   within $\texttt{Candidate\_Radius\_Factor}\cdot\|p_i-p_j\|$ of the
   edge midpoint (default factor $2.5$).
3. **Score** — prefer points near the midpoint; lightly penalize
   high $\mathrm{perimeter}^{2}/\mathrm{area}$ slivers.
4. **Manifold / fold guard** — reject a candidate if either new edge
   would already have two incident triangles, or if it is same-side and
   nearly coplanar with the existing face of the frontier edge (avoids
   double-covering planar patches). Out-of-plane or opposite-side points
   remain allowed (small polyhedra / patch closing).
5. **Closing pass** — if no unused point fits, allow an already-meshed
   vertex that shares a frontier edge (fills planar patches).

Complexity of this educational build is $O(|T|\cdot n)$ distance scans
(no spatial index). Production advancing-front codes use a 3-D Delaunay
filter and a priority queue of plausible candidates.

### Educational robustness

Floating helpers (`Dist3`, `Normal_Of_Triangle`, area tests) use a fixed
$\varepsilon$-threshold. They work for well-separated classroom clouds
but can misclassify near-degenerate or highly non-uniform samples.
Noisy real-world scans need preprocessing (normals, smoothing, outlier
rejection) that is out of scope here.

## API sketch

| Operation | Role |
| --- | --- |
| `Reconstruct_Mesh` | Seed + advancing-front meshing; raises `Invalid_Argument` if $<3$ / $>Max_Points$ points, near-duplicates, or no seed |
| `Find_Seed_Triangle` | Compact non-degenerate seed (indices remapped so `Cloud'First` → 1) |
| `Dist3` / `Dist3_Squared` / `Dot` / `Cross` / `Length` / `Normalize` | 3-D vector helpers |
| `Normal_Of_Triangle` / `Triangle_Area` | Face geometry |
| `Make_Edge_Key` / `Same_Edge` / `Contains_Edge` / `Toggle_Boundary_Edge` | Frontier edge-set helpers |
| `Has_Near_Duplicate` | Pre-check |
| `Triangle_Count_Of` / `Get_Triangle` / `All_Indices_In_Range` | Mesh accessors |

Domain types: `Point3`, `Point_Array` (cloud), `Triangle` (vertex indices),
`Mesh`, `Edge_Key`, `Boundary_Edge_Set`, `Real`.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
