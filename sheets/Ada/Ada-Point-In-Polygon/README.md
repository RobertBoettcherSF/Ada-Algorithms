# Point in polygon — Ada 2023

Educational, self-contained Ada 2023 package for the **point-in-polygon
(PIP)** problem: decide whether a query point in the plane lies
**inside**, **outside**, or **on the boundary** of a simple polygon.
Implements classical **ray casting** (even–odd / crossing number) and
the **winding number** (nonzero) rule, including Dan Sunday's
trigonometry-free winding update. See
[Wikipedia: Point in polygon](https://en.wikipedia.org/wiki/Point_in_polygon).

This package is a **classroom sketch** on small polygons
(`Max_Vertices = 64`). Predicates use ordinary `Real` (`digits 15`)
arithmetic. It is **not** a production computational geometry kernel
(no adaptive exact predicates / CGAL, no hierarchical point-location
structures).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with nesting / nearest-neighbor / MBB siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Point-In-Polygon`) | Single-query **ray casting** / **winding** containment for a simple polygon |
| **[Ada-Shoelace-Algorithm](https://github.com/RobertBoettcherSF/Ada-Shoelace-Algorithm)** | Polygon **area** / centroid from the shoelace sum |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Ear-clip a simple polygon into $n-2$ triangles |
| **Ada-Nesting** (ahead) | Nested / hierarchical containment & region nesting |
| **Ada-Nearest-Neighbor-Search** (ahead) | $k$-NN / spatial proximity queries |
| **Ada-MBB** (ahead) | Minimum bounding box / extent filters before PIP |

README links only — **no** package `with` of siblings.

## Algorithm sketch

### Even–odd (ray casting / crossing number)

Cast a horizontal ray from the query $P$ to $+\infty$ and count
intersections with polygon edges. By the Jordan curve theorem, an
**odd** count means $P$ is inside; **even** means outside:

$$
\text{inside}_{\text{even-odd}}(P)
  \iff
  \#\{\text{edge crossings of ray } P\!\to\!+\infty\} \bmod 2 = 1.
$$

Vertex hits and horizontal edges are handled by counting a crossing
only when the edge straddles $P_y$ with the upper endpoint strictly
above the ray (Wikipedia / Sunday convention), so a ray through a
vertex is not double-counted.

### Winding number (nonzero rule)

The winding number $wn(P)$ counts how many times the polygon boundary
wraps around $P$. Nonzero means inside. Sunday's algorithm updates
$wn$ with orientation tests only — no $\arctan$:

$$
\begin{align*}
wn &\leftarrow wn + 1
  &&\text{upward crossing with } \operatorname{Orient2D}(V_i,V_{i+1},P) > 0, \\
wn &\leftarrow wn - 1
  &&\text{downward crossing with } \operatorname{Orient2D}(V_i,V_{i+1},P) < 0, \\
\text{inside}_{\text{winding}}(P)
  &\iff wn(P) \neq 0.
\end{align*}
$$

For **simple** polygons both rules agree on the interior. They may
disagree on self-overlapping regions (e.g. a pentagram's central hole);
that case is out of educational scope here.

### Boundary policy (closed set)

Points within $\varepsilon$ of any edge (including vertices) are
reported by `On_Boundary`. `Contains_Even_Odd` and `Contains_Winding`
return **True** for those points (closed-polygon convention). For a
**strict interior** query use
$\neg\texttt{On\_Boundary}(P,\mathit{Poly}) \land \texttt{Contains\_*}(P,\mathit{Poly})$.

### Educational robustness

Floating predicates and the $\varepsilon$-boundary test are adequate for
well-separated classroom examples (unit square, rectangles, concave
arrowheads). Near-degenerate edges, near-ray vertices, or
self-intersecting inputs can misclassify; production codes use filtered
/ exact arithmetic and robust predicates. Inputs should be simple
polygons; this package does **not** prove simplicity.

## API sketch

| Operation | Role |
| --- | --- |
| `Contains_Even_Odd` | Even–odd fill: boundary or odd crossing number |
| `Contains_Winding` | Nonzero winding: boundary or $wn \neq 0$ |
| `Contains` | Convenience switch (`Use_Winding`) |
| `Crossing_Number` / `Winding_Number` | Raw counters (educational) |
| `On_Boundary` / `Point_On_Segment` | $\varepsilon$-edge / segment tests |
| `Orient2D` / `Near` / `Near_Point` / `Dist2` | Predicates & helpers |

Domain types: `Point`, `Point_Array` / `Polygon`, `Real`.
Exception: `Invalid_Argument` when $n < 3$ or $n > Max\_Vertices$.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
