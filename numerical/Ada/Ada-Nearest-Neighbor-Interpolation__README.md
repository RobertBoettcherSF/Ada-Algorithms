# Nearest-Neighbor Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **nearest-neighbor
interpolation** (also called proximal interpolation or point sampling): the
piecewise-constant interpolant that returns the sample value whose site is
**closest** to the query. With Euclidean distance $d$, the interpolant on a
scattered set of sites $\{x_i\}$ with values $v_i$ is

$$
f(x)=v_{i^*(x)},
\qquad
i^*(x)=\arg\min_i\, d(x,x_i)
$$

(ties broken by the **lowest index**; in 2-D/3-D grids, independently per
axis — lexicographic in the multi-index). Cap $n\le 256$ scattered sites and
$N\le 64$ samples per regular-grid axis; educational `Float`. Optional
**Manhattan** distance for teaching metric dependence. Regular-grid
**round-to-nearest** indexing covers 1-D / 2-D / 3-D texture-style sampling.

Based on [Wikipedia: Nearest-neighbor interpolation](https://en.wikipedia.org/wiki/Nearest-neighbor_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)** — tensor-product Catmull–Rom on 3-D grids
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **Lanczos resampling** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Piecewise-constant NN | Closest sample wins |
| **Scattered** | Brute-force nearest | Educational; $n\le 256$ |
| **Grid** | Round-to-nearest index | Texture-style 1-D/2-D/3-D |
| **Metric** | Euclidean (default) | Optional Manhattan |
| **Ties** | Lower index | Lexicographic on grids |
| **Status** | `Ok` / `Empty` / `Out_Of_Domain` / `Ill_Started` | Result records |
| **Cap** | $n\le 256$, $N\le 64$/axis | `Max_Sites`, `Max_N` |

## Brief history

Nearest-neighbor interpolation is among the oldest and simplest multivariate
interpolants: ignore every sample except the closest one. In computer
graphics it appears as **point sampling** of textures (often with mipmaps).
Mathematically it is exactly the indicator of the **Voronoi diagram** of the
sample sites — each Voronoi cell is painted with its site’s value. The method
is discontinuous across Voronoi edges (and at mid-cell boundaries on a
regular grid), which is both its teaching virtue and its main practical
caveat.

## Algorithm (this package)

### Scattered points (1-D / 2-D)

Given sites $x_0,\ldots,x_{n-1}$ and values $v_i$:

1. Reject empty / unset clouds (`Empty`, `Ill_Started`).
2. Compute $d(q,x_i)$ for all $i$ (Euclidean or Manhattan).
3. Return $v_{i^*}$ for the minimal distance; on ties keep the **smallest**
   $i$ (first-wins under a strict $<$ update).

Complexity $O(n)$ per query — intentional for $n\le 256$.

### Regular grid (1-D / 2-D / 3-D)

Values live on the integer lattice $0..N-1$ (per axis). A query coordinate
$x\in[0,N-1]$ maps to

$$
i=\begin{cases}
\lfloor x\rfloor & \text{if }\{x\}\le 1/2,\\
\lfloor x\rfloor+1 & \text{if }\{x\}>1/2,
\end{cases}
$$

so exact midpoints $\{x\}=1/2$ prefer the **lower** index. Axes are rounded
independently (2-D/3-D). Queries outside the closed box
$[0,N_x-1]\times\cdots$ return `Out_Of_Domain`.

### Voronoi connection

For a fixed set of sites, the regions where a given site is nearest form its
**Voronoi cell**. Nearest-neighbor interpolation is precisely “paint each
Voronoi cell with its site’s sample value.” This package’s 2-D scattered
tests probe cell interiors, edges, and the multi-way tie at a square’s
center.

## API summary

| Symbol | Role |
| --- | --- |
| `Site_1D`, `Site_2D`, `Site_3D` | Sample locations |
| `Scattered_1D`, `Scattered_2D` | Packed clouds + values |
| `Grid_1D`, `Grid_2D`, `Grid_3D` | Regular lattices |
| `Max_Sites`, `Max_N` | Caps ($256$, $64$) |
| `Status` | `Ok` / `Empty` / `Out_Of_Domain` / `Ill_Started` |
| `Distance_Kind` | `Euclidean` / `Manhattan` |
| `Eval_Result`, `Nearest_Result` | Value / index / `Stat` / `Success` |
| `Near`, `Dist`, `Make_Site_*` | Numeric helpers |
| `Round_Index` | Midpoint → lower index |
| `Is_Valid_*`, `In_Domain` | Domain utilities |
| `Nearest_Index` | Brute-force nearest site |
| `Evaluate_Scattered` | 1-D / 2-D piecewise-constant NN |
| `Evaluate_Grid_1D`, `Evaluate_Grid_2D`, `Evaluate_Grid_3D` | Texture-style |
| `Get`, `Set` | Lattice accessors |
| `Make_Linear_1D`, `Make_Checkerboard_2D`, `Make_Ramp_3D` | Grid builders |
| `Make_Scattered_1D_Linear`, `Make_Scattered_Cloud_2D` | Cloud builders |
| `Make_Example_*` | Canonical examples |

## Limits and caveats

- **Discontinuous** — jumps across Voronoi edges / cell midplanes; not a
  smooth approximant.
- **Educational brute force** — $O(n)$ scan, no kd-tree / Voronoi diagram
  construction; fine for $n\le 256$.
- **Educational `Float`** — ordinary single precision; not a production
  texture or GIS kernel.
- **Grid domain** — queries outside $[0,N-1]$ (per axis) return
  `Out_Of_Domain` (no clamp-extrapolation of the query).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pnearest_neighbor_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `nearest_neighbor_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
nearest_neighbor_interpolation.ads
nearest_neighbor_interpolation.adb
nearest_neighbor_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Nearest-neighbor interpolation](https://en.wikipedia.org/wiki/Nearest-neighbor_interpolation)
2. [Wikipedia: Voronoi diagram](https://en.wikipedia.org/wiki/Voronoi_diagram) — geometric dual of NN cells.
3. Siblings: [Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation),
   [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation);
   upcoming Lanczos resampling.
