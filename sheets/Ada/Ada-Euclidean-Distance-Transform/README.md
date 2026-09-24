# Euclidean distance transform — Ada 2023

Educational, self-contained Ada 2023 package for the **Euclidean distance
transform** (also called a **distance map** or **distance field**) on a
small binary 2-D grid. Each pixel is labelled with its Euclidean distance
to the nearest **feature** (foreground / obstacle) pixel.

See
[Wikipedia: Distance transform](https://en.wikipedia.org/wiki/Distance_transform).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`). Classroom bounds: `Max_Width = Max_Height = 64`. Ordinary
`Real` (`digits 15`) arithmetic — **not** a production vision stack.

Part of the **RobertBoettcherSF** Ada algorithm series.

## What it computes

Given a binary image $I$ where feature pixels are the set $F$:

$$
\mathrm{DT}(p) \;=\; \min_{q \in F}\; \|p - q\|_2,
\qquad
\mathrm{DT}^2(p) \;=\; \min_{q \in F}\; \|p - q\|_2^2.
$$

Feature pixels themselves store $0$. This package uses **True** $=$
feature / foreground (distance $0$) and **False** $=$ background.

Common related metrics on grids (not all implemented here) include
Manhattan (city-block) and Chebyshev; the **exact Euclidean** case needs
care on the discrete lattice.

## Algorithms (classroom)

| Method | Complexity (grid $n = W\cdot H$) | Exact? | Role |
| --- | --- | --- | --- |
| **Naive** `Squared_Distance_Transform` | $O(n^2)$ / $O(n\cdot\|F\|)$ | Yes | Primary educational EDT |
| **Meijster-style** separable | $O(n)$ | Yes | Column 1-D DT + row parabola envelope |
| **3–4 chamfer** two-pass | $O(n)$ | No | Teaching contrast with exact EDT |

The Meijster sketch follows the classic separable exact EDT idea
(column distances, then lower envelope of parabolas
$f_i(x) = (x-i)^2 + G(i)^2$ per row). The chamfer pass uses local
weights $3$ (orthogonal) and $4$ (diagonal), then scales by $1/3$ so
orthogonal steps read as distance $\approx 1$.

## Contrast with geometry siblings

| Package | Idea |
| --- | --- |
| **This package** (`Ada-Euclidean-Distance-Transform`) | Exact / approximate distance maps on binary grids |
| **[Ada-Geometric-Hashing](https://github.com/RobertBoettcherSF/Ada-Geometric-Hashing)** | Model↔scene recognition via quantized basis hashing |
| **Ada-Quickhull** (ahead) | Fast 2-D convex hull |

README links only — **no** package `with` of siblings.

## API sketch

| Operation | Role |
| --- | --- |
| `Squared_Distance_Transform` | Exact squared EDT (naive classroom scan) |
| `Distance_Transform` | Exact Euclidean map $=\sqrt{\mathrm{DT}^2}$ |
| `Meijster_Squared_Distance_Transform` | Exact squared EDT (separable sketch) |
| `Chamfer_Distance_Transform` | Approximate 3–4 chamfer map |
| `Distance_At` / `Squared_Distance_At` | Safe cell accessors |
| `Has_Feature` / `Feature_Count` / `Width_Of` / `Height_Of` | Image introspection |
| `Near` | Educational floating comparison |

Domain types: `Binary_Image`, `Distance_Map`, `Squared_Distance_Map`,
`Real`. Exception: `Invalid_Argument` on empty images (zero rows or
columns), oversized grids, featureless images, or out-of-range
`Distance_At` / `Squared_Distance_At` indices.

## Build & test

```bash
make
make test
```

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).

## License

Educational example code for the RobertBoettcherSF Ada algorithm series.
