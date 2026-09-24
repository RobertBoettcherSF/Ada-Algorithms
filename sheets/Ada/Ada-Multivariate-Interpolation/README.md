# Multivariate Interpolation — Ada 2023

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Multivariate interpolation](https://en.wikipedia.org/wiki/Multivariate_interpolation):
taxonomy of regular-grid and scattered methods in two and three dimensions,
with **runnable sketches** for nearest-neighbor (2-D grid), bilinear, bicubic
(Keys / Catmull–Rom), thin trilinear, and inverse-distance weighting (IDW) on
scattered 2-D clouds.

**Caveats:** sketches only; Tricubic / Lanczos / Kriging / Natural-neighbor /
RBF / tensor spline / Barnes are **catalogue-only** (`Not_Implemented`) — see
sibling packages linked below. Cap $N\le 32$ per axis (grids), $\le 64$
scattered sites; educational `Float`.

Based on [Wikipedia: Multivariate interpolation](https://en.wikipedia.org/wiki/Multivariate_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (README links only — **no** `with` deps):

- **[Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation)** — repeated linear on 2-D grids
- **[Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation)** — Keys / Catmull–Rom tensor cubic
- **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)** — 3-D tensor Catmull–Rom
- **[Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation)** — piecewise-constant nearest
- **[Ada-Lanczos-Resampling](https://github.com/RobertBoettcherSF/Ada-Lanczos-Resampling)** — sinc-windowed kernel resampling
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics

Upcoming: Monotone cubic, Linear, Lagrange, Hermite, Cubic, Birkhoff.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Regular grid** | Nearest / $n$-linear / $n$-cubic / Lanczos | Predetermined lattice |
| **Scattered** | IDW (runnable); Kriging / RBF / natural-neigh. | Catalogue or IDW sketch |
| **2-D** | Bilinear, Bicubic, Lanczos, Barnes | Image / DEM common case |
| **3-D** | Trilinear (sketch), Tricubic (sibling) | Volumes / bitmap volumes |
| **Taxonomy** | `Method_Kind` / `Recommend_Method` | Layout × dim × smoothness |
| **Runnable** | NN, Bi, Bc, Tri, IDW | Self-contained sketches |
| **Cap** | $N\le 32$, sites $\le 64$ | `Max_N` / `Max_Sites` |

## Brief history

When samples live on a **regular grid**, tensor-product schemes reuse 1-D
interpolants along each axis: nearest-neighbor (piecewise constant),
$n$-linear (bilinear / trilinear), and $n$-cubic (bicubic / tricubic), often
via Catmull–Rom / Keys cubic convolution. Image pipelines add **Lanczos**
sinc-windowed kernels. On **scattered** sites (no lattice), classical choices
include **inverse-distance weighting**, **natural-neighbor** (Voronoi areas),
**radial basis functions**, and geostatistical **kriging**. Multivariate
interpolation is central in geostatistics (DEMs), medical imaging, and
scientific visualization.

## Method taxonomy (this package)

| `Method_Kind` | Layout | Dim | Smoothness | Runnable? |
| --- | --- | --- | --- | --- |
| `Nearest_Neighbor` | regular / scattered | $2$–$3$ | piecewise const. | Yes (2-D grid) |
| `Bilinear` | regular | $2$ | $C^0$ | Yes |
| `Bicubic` | regular | $2$ | $C^1$-ish | Yes (Keys/CR) |
| `Trilinear` | regular | $3$ | $C^0$ | Yes (thin) |
| `Tricubic` | regular | $3$ | $C^1$-ish | **No** (sibling) |
| `Lanczos` | regular | $2$ | smooth kernel | **No** (sibling) |
| `Inverse_Distance` | scattered | $2$–$3$ | $C^0$ away from sites | Yes (2-D IDW) |
| `Kriging` | scattered / regular | $2$–$3$ | model-dependent | **No** |
| `Natural_Neighbor` | scattered | $2$ | $C^0$ | **No** |
| `Radial_Basis` | scattered | $2$–$3$ | often $C^1+$ | **No** |
| `Spline_Tensor` | regular | $2$–$3$ | $C^2$ cubics | **No** (sibling) |
| `Barnes` | scattered / regular | $2$ | successive Gauss | **No** |

### `Recommend_Method` heuristic

Educational chooser (not a production optimizer):

| Layout | Dim | Want | Recommendation |
| --- | --- | --- | --- |
| Scattered | any | `Piecewise_Constant` | `Nearest_Neighbor` |
| Scattered | any | else | `Inverse_Distance` |
| Regular | $2$ | `Piecewise_Constant` | `Nearest_Neighbor` |
| Regular | $2$ | `C0_Continuous` | `Bilinear` |
| Regular | $2$ | `C1_Smooth` | `Bicubic` |
| Regular | $3$ | `Piecewise_Constant` | `Nearest_Neighbor` |
| Regular | $3$ | `C0_Continuous` | `Trilinear` |
| Regular | $3$ | `C1_Smooth` | `Tricubic` (catalogue) |

## Runnable sketches

### Nearest-neighbor (2-D grid)

Round each coordinate to the nearest lattice index (ties $\rightarrow$ lower
index) and return that sample. Piecewise constant; discontinuous across cell
midplanes.

### Bilinear

On the unit cell with local coordinates $(t,u)\in[0,1]^2$:

$$
\begin{aligned}
f(t,u)
&=
(1-t)(1-u)\,F_{00}
+ t(1-u)\,F_{10}
+ (1-t)u\,F_{01}
+ t u\,F_{11}
\end{aligned}
$$

equivalently lerp in $x$ then in $y$. Affine fields $f=ax+by+c$ are reproduced
exactly.

### Bicubic (Keys / Catmull–Rom)

Uniform Catmull–Rom cubic Hermite ($\equiv$ Keys convolution with $a=-\tfrac12$)
along $x$ on each of four $y$-lines of the $4\times 4$ neighbourhood, then along
$y$. Odd (value) reflection at edges keeps affine fields exact on the closed
domain.

### Trilinear (thin)

Repeated lerp on the 3-D unit cell (eight corners). Affine fields
$f=ax+by+cz+d$ are exact.

### Inverse-distance weighting (scattered 2-D)

With Euclidean distances $d_i$ and power $P>0$:

$$
\hat u(x)
=
\frac{\sum_i w_i v_i}{\sum_i w_i},
\qquad
w_i=\frac{1}{d_i^{P}}
$$

(an exact site hit $d_i\approx 0$ returns $v_i$). Default $P=2$.

## API summary

| Symbol | Role |
| --- | --- |
| `Grid_2D`, `Grid_3D` | Packed regular lattices |
| `Scattered_2D` | Packed 2-D cloud for IDW |
| `Max_N` / `Max_Sites` | Caps $32$ / $64$ |
| `Status`, `Eval_Result` | Ok / OOD / Too_Small / Empty / Ill / Not_Implemented |
| `Method_Kind`, `Method_Info` | Taxonomy |
| `Data_Layout`, `Space_Dim`, `Smoothness` | Recommendation inputs |
| `Near`, `Lerp`, `Cubic_1D`, `Round_Index` | Helpers |
| `Recommend_Method`, `Supports_Runnable`, `Classify_Method` | Taxonomy queries |
| `Evaluate_Nearest_2D` | Round-to-nearest on 2-D grid |
| `Evaluate_Bilinear` | Multilinear 2-D |
| `Evaluate_Bicubic` | Keys / Catmull–Rom 2-D |
| `Evaluate_Trilinear` | Multilinear 3-D |
| `Evaluate_IDW` | Scattered inverse-distance |
| `Evaluate` | Dispatch on 2-D grid methods |
| `Make_Constant_*`, `Make_Affine_*`, `Make_Checkerboard_2D` | Builders |
| `Make_Example`, `Make_Unit_Square_Cloud` | Sample data |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  numerics library.
- **Catalogue stubs** — Tricubic / Lanczos / Kriging / … return
  `Not_Implemented`; use siblings for full treatments.
- **Odd reflection** — bicubic edge handling is for teaching affine exactness,
  not a claim of production boundary policy.
- **IDW** — brute-force $O(n)$ over $\le 64$ sites; no spatial index.
- **No `main.adb`** — `tests.adb` is the sole main unit.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pmultivariate_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
multivariate_interpolation.ads
multivariate_interpolation.adb
multivariate_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Multivariate interpolation](https://en.wikipedia.org/wiki/Multivariate_interpolation)
2. [Wikipedia: Bilinear interpolation](https://en.wikipedia.org/wiki/Bilinear_interpolation)
3. [Wikipedia: Bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation)
4. [Wikipedia: Trilinear interpolation](https://en.wikipedia.org/wiki/Trilinear_interpolation)
5. [Wikipedia: Inverse distance weighting](https://en.wikipedia.org/wiki/Inverse_distance_weighting)
6. [Wikipedia: Lanczos resampling](https://en.wikipedia.org/wiki/Lanczos_resampling)
7. Sibling READMEs: Ada-Bilinear / Bicubic / Tricubic / Nearest-Neighbor /
   Lanczos-Resampling / Spline-Interpolation; upcoming Monotone cubic /
   Linear / Lagrange / Hermite / Cubic / Birkhoff
