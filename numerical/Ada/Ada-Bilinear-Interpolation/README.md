# Bilinear Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **bilinear
interpolation** of a scalar field sampled on a regular 2-D lattice.
On each unit cell the interpolant is the repeated linear blend (first
along $x$, then along $y$), equivalently the closed four-corner form

$$
f(x,y)\approx (1-t)(1-u)\,f_{00}+t(1-u)\,f_{10}+(1-t)u\,f_{01}+t u\,f_{11}
$$

with local coordinates $(t,u)\in[0,1]\times[0,1]$. Although each step is
linear in the samples and in the local coordinate, the interpolant as a
whole is **quadratic in position**. Cap $N\le 64$ samples per axis;
educational `Float`. A **linear 1-D** helper and optional `Resize_2D`
(bilinear sampling onto a new lattice) are included for teaching.

Based on [Wikipedia: Bilinear interpolation](https://en.wikipedia.org/wiki/Bilinear_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)** — tensor-product Catmull–Rom on 3-D grids (includes trilinear)
- **[Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation)** — piecewise-constant / Voronoi
- **[Ada-Lanczos-Resampling](https://github.com/RobertBoettcherSF/Ada-Lanczos-Resampling)** — sinc-window signal / image filter
- **Ada-Bicubic** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Repeated linear interp on 2-D grid | Or closed four-corner form |
| **1-D helper** | Linear lerp on a unit interval | Teaching / separable view |
| **Domain** | $[0,N_x-1]\times[0,N_y-1]$ | Continuous query coords |
| **Resize** | Map new lattice → `Evaluate` | Identity when sizes match |
| **Status** | `Ok` … `Ill_Started` | Incl. `Out_Of_Domain`, `Too_Small_Grid` |
| **Cap** | $N\le 64$ / axis | `Max_N = 64` |

## Brief history

Bilinear interpolation is one of the basic resampling techniques in
computer vision and image processing (also called bilinear filtering or
bilinear texture mapping). It generalises linear interpolation to two
variables by applying it twice — once per axis — on the four corners of
the cell that contains the query. The same formula appears for arbitrary
convex quadrilaterals via a bilinear map of the unit square; this package
teaches the **regular-grid** case from Wikipedia.

## Algorithm (this package)

Grid values $V(i,j)$ live on the integer lattice
$i=0..N_x-1$, $j=0..N_y-1$. A query $(x,y)$ falls in a unit cell with
origin $(i_0,j_0)=\bigl(\lfloor x\rfloor,\lfloor y\rfloor\bigr)$ (right
endpoints use the last cell) and local coordinates
$t=x-i_0$, $u=y-j_0\in[0,1]$.

**Linear 1-D.** On samples $s_0,\ldots,s_{N-1}$,
$f(x)=(1-t)\,s_{i_0}+t\,s_{i_0+1}$ (needs $N\ge 2$).

**Bilinear.** Let $f_{00}=V(i_0,j_0)$, $f_{10}=V(i_0+1,j_0)$,
$f_{01}=V(i_0,j_0+1)$, $f_{11}=V(i_0+1,j_0+1)$. Then either

$$
\begin{aligned}
f_0 &= (1-t)\,f_{00}+t\,f_{10},\\
f_1 &= (1-t)\,f_{01}+t\,f_{11},\\
f(x,y) &= (1-u)\,f_0+u\,f_1,
\end{aligned}
$$

or the expanded closed form above. Both are coded (`Evaluate` uses
nested `Lerp`; `Evaluate_Unit_Square` is the closed form). Needs
$N_x,N_y\ge 2$. Affine fields $f=ax+by+c$ are reproduced exactly
(within `Float`).

**Resize.** Output index $(i',j')$ maps to source

$$
x=i'\cdot\frac{N_x-1}{N'_x-1}
\qquad(N'_x>1),\qquad x=0\ (N'_x=1)
$$

(and likewise for $y$), then `Evaluate`. Integer identity
$N'=N$ preserves an affine field up to `Float` noise.

## API summary

| Symbol | Role |
| --- | --- |
| `Grid_1D`, `Grid_2D` | Packed regular lattices |
| `Max_N` | Hard cap ($64$) per axis |
| `Status` | `Ok` / `Out_Of_Domain` / `Too_Small_Grid` / `Ill_Started` |
| `Eval_Result`, `Resize_2D_Result` | Value or grid + `Stat` / `Success` |
| `Near`, `Lerp` | Numeric helpers |
| `Is_Valid_Grid`, `In_Domain` | Domain utilities |
| `Large_Enough_Linear`, `Large_Enough_Bilinear` | Size checks |
| `Get`, `Set` | Lattice accessors |
| `Evaluate_Linear_1D` | 1-D linear helper |
| `Evaluate` | Bilinear on `Grid_2D` |
| `Evaluate_Unit_Square` | Closed four-corner formula |
| `Resize_2D` | Bilinear sampling onto a new size |
| `Make_Constant_*`, `Make_Linear_*` | Constant / affine builders |
| `Make_Checkerboard_2D`, `Make_Ramp_2D` | Checker / $V=i+2j$ |
| `Make_Example` | Canonical examples by `Example_Kind` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  texture or GIS kernel.
- **Regular-grid focus** — integer lattice with unit spacing; no scattered
  data, no arbitrary quadrilateral meshes.
- **Quadratic in position** — bilinear is linear in each sample and in each
  local coordinate separately, but the product $tu$ makes it quadratic
  overall (Wikipedia).
- **Domain** — queries outside $[0,N_x-1]\times[0,N_y-1]$ return
  `Out_Of_Domain` (no extrapolation of the query point).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbilinear_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `bilinear_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
bilinear_interpolation.ads
bilinear_interpolation.adb
bilinear_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Bilinear interpolation](https://en.wikipedia.org/wiki/Bilinear_interpolation)
2. Siblings: [Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation),
   [Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation),
   [Ada-Lanczos-Resampling](https://github.com/RobertBoettcherSF/Ada-Lanczos-Resampling);
   upcoming Ada-Bicubic.
