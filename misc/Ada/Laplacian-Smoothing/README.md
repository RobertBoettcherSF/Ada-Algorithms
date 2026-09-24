# Laplacian smoothing — Ada 2023

Educational, self-contained Ada 2023 package for **Laplacian smoothing**
(also **umbrella operator** / neighbour-average mesh smoothing): each free
vertex of a polygonal mesh is moved toward the average of its neighbours
with a step size $\lambda \in (0, 1]$. Optional **Dirichlet** pinning keeps
boundary (or tagged) vertices fixed. See
[Wikipedia: Laplacian smoothing](https://en.wikipedia.org/wiki/Laplacian_smoothing).

This package is a **classroom sketch** on tiny meshes
(`Max_Vertices = 64`, `Max_Degree = 16`, `Max_Iters = 64`). Positions use
ordinary `Real` (`digits 15`) arithmetic. It is **not** a production
geometry-processing stack (no cotangent weights, no Taubin $\lambda/\mu$
pass, no remeshing).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Algorithm sketch

For each free vertex $i$ with neighbour set $N(i)$:

$$
\begin{align*}
\bar{x}_i &= \frac{1}{|N(i)|}\sum_{j\in N(i)} x_j, \\
x_i &\leftarrow (1-\lambda)x_i + \lambda \bar{x}_i.
\end{align*}
$$

Updates are **Jacobi-style**: every average is taken from the input
positions of that step, then all free vertices are written together.
Isolated free vertices ($|N(i)| = 0$) are left unchanged. Pinned vertices
(`Fixed(i) = True`) are never moved.

Repeated application tends to shrink high-frequency detail (and, without
pinned boundaries, can shrink the whole mesh toward its centroid). A mesh
that is already a **Tutte embedding** (every free vertex at the average of
its neighbours) is a fixed point for any $\lambda$.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Laplacian-Smoothing`) | Neighbour-average vertex smoothing on an explicit adjacency mesh |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Ear-clip a simple polygon into $n-2$ triangles |
| **[Ada-Bowyer-Watson](https://github.com/RobertBoettcherSF/Ada-Bowyer-Watson)** | Incremental 2-D Delaunay triangulation |
| **Ada-Catmull-Clark** / **Ada-Loop-Subdivision** (ahead) | Subdivision surfaces (refine + smooth) |

README links only — **no** package `with` of siblings.

## API sketch

| Operation | Role |
| --- | --- |
| `Build_Adjacency` | Undirected adjacency from an edge list |
| `Add_Neighbor` / `Has_Neighbor` / `Empty_Adjacency` | Manual adjacency edits |
| `Neighbor_Average` | $\bar{x}_i$ for one vertex |
| `Smooth_Once` | One Jacobi Laplacian step (optional `Fixed`) |
| `Smooth` | $N$ iterations of `Smooth_Once` |
| `All_Free` | Convenience `Fixed_Flags` of all `False` |
| `Mean_Edge_Length` | Mean undirected edge length (sanity helper) |
| `Near` / `Near_Point` / `Dist` / `Dist2` / `Lerp` | Educational numerics |

Domain types: `Point`, `Point_Array`, `Adjacency` / `Adjacency_Array`,
`Fixed_Flags`, `Edge` / `Edge_Array`, `Real`. Exception:
`Invalid_Argument` on empty meshes, $\lambda \notin (0, 1]$, length /
bounds mismatches, self-loops, out-of-range endpoints, degree /
iteration capacity violations.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
