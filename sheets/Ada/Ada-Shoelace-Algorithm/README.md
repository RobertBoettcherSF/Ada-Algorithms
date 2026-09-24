# Shoelace algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **shoelace formula**
(also **Gauss's area formula** / **surveyor's formula**): the area of a
**simple polygon** whose vertices are given by Cartesian coordinates.
Successive edge determinants are cross-multiplied like threading
shoelaces. See
[Wikipedia: Shoelace algorithm](https://en.wikipedia.org/wiki/Shoelace_algorithm).

This package is a **classroom sketch** on small polygons
(`Max_Vertices = 64`). Measures use ordinary `Real` (`digits 15`)
arithmetic. It is **not** a production computational geometry kernel
(no adaptive exact predicates / CGAL).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Contrast with triangulation / geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Shoelace-Algorithm`) | Polygon **area** (and centroid) from vertex ring via shoelace sum |
| **[Ada-Polygon-Triangulation](https://github.com/RobertBoettcherSF/Ada-Polygon-Triangulation)** | Ear-clip a simple polygon into $n-2$ triangles |
| **[Ada-Triangulation](https://github.com/RobertBoettcherSF/Ada-Triangulation)** | Survey of triangulation kinds + educational drivers |
| **Ada-Rotating-Calipers** (ahead) | Diameter / width / antipodal pairs on a convex hull |
| **Ada-Point-In-Polygon** (ahead) | Ray casting / winding tests for containment |

README links only — **no** package `with` of siblings.

## Algorithm sketch

Given a planar simple polygon with vertices
$P_i = (x_i, y_i)$, $i = 1,\ldots,n$, and the closing convention
$(x_{n+1}, y_{n+1}) = (x_1, y_1)$:

$$
A = \frac{1}{2}\left|\sum_{i=1}^{n}(x_i y_{i+1} - x_{i+1} y_i)\right|.
$$

The signed sum (without the absolute value) is positive for a
**counterclockwise** (CCW) vertex order and negative for **clockwise**
(CW). Equivalent forms (trapezoid, triangle / determinant listing) appear
on Wikipedia; this package implements the classical determinant sum.

The same cross terms yield the polygon **centroid** for $A \neq 0$:

$$
\begin{align*}
C_x &= \frac{1}{6A}\sum_{i=1}^{n}(x_i + x_{i+1})(x_i y_{i+1} - x_{i+1} y_i), \\
C_y &= \frac{1}{6A}\sum_{i=1}^{n}(y_i + y_{i+1})(x_i y_{i+1} - x_{i+1} y_i).
\end{align*}
$$

### Educational robustness

Floating sums are adequate for well-separated classroom examples (unit
square, rectangles, the Wikipedia pentagon). Near-degenerate or
self-overlapping inputs can misbehave; production codes use filtered /
exact arithmetic. Inputs should be simple polygons; this package does
**not** prove simplicity.

## API sketch

| Operation | Role |
| --- | --- |
| `Signed_Area` | Signed shoelace area (with $1/2$); $+$ CCW, $-$ CW |
| `Area` | Absolute area $\|Signed\_Area\|$ |
| `Is_CCW` / `Is_CW` | Orientation from signed area vs $\varepsilon$ |
| `Centroid` | Centroid from the same cross terms |
| `Determinant_Sum` | $\sum(x_i y_{i+1}-x_{i+1} y_i) = 2\cdot Signed\_Area$ |
| `Near` / `Near_Point` | Educational floating comparisons |

Domain types: `Point`, `Point_Array` / `Polygon`, `Real`.
Exception: `Invalid_Argument` when $n < 3$, $n > Max\_Vertices$, or
centroid of a near-zero-area polygon.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
