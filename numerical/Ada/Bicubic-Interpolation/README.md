# Bicubic Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **bicubic
interpolation** of a scalar field sampled on a regular 2D lattice. Locally
the interpolant has the monomial form

$$
f(x,y)=\sum_{i=0}^{3}\sum_{j=0}^{3} a_{ij}\,x^{i}y^{j}
$$

(16 coefficients). This package realises that form as a **tensor product of
one-dimensional Catmull–Rom / Keys** cubics (cubic convolution with
parameter $a=-\tfrac12$) applied sequentially along $x$, then $y$ — the
same family used by the Ada-Tricubic sibling. Cap $N\le 64$ samples per
axis, educational `Float`. A thin **bilinear** evaluator is included for
comparison tests (no `with` of Ada-Bilinear-Interpolation). Optional
`Resize_2D` samples a new lattice via bicubic evaluation.

Based on [Wikipedia: Bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation)** — repeated linear on 2-D grids
- **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)** — tensor-product Catmull–Rom on 3-D grids
- **[Ada-Lanczos-Resampling](https://github.com/RobertBoettcherSF/Ada-Lanczos-Resampling)** — sinc-window signal / image filter
- **[Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation)** — piecewise-constant / Voronoi
- **Multivariate / Monotone cubic / Linear** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Local bicubic on regular grid | 16 dof / unit square |
| **Realisation** | Tensor-product Catmull–Rom / Keys | Nested 1-D cubics ($a=-\tfrac12$) |
| **Baseline** | Bilinear | 4 corners of the cell |
| **Domain** | $[0,N_x-1]\times[0,N_y-1]$ | Continuous query coords |
| **Boundaries** | Odd (value) reflection | Keeps affine fields exact |
| **Resize** | Map new lattice → `Evaluate_Bicubic` | Needs source $N\ge 4$ / axis |
| **Status** | `Ok` … `Ill_Started` | Incl. `Out_Of_Domain`, `Too_Small_Grid` |
| **Cap** | $N\le 64$ / axis | `Max_N = 64` |

## Brief history

Bicubic interpolation extends cubic interpolation to two dimensions and is
widely used in image resampling (alongside bilinear and nearest-neighbour).
Wikipedia describes three classical routes: Lagrange polynomials, cubic
splines, and **cubic convolution** (Keys). This package teaches the
separable cubic-convolution / Catmull–Rom path: four samples along each
axis of a $4\times 4$ neighbourhood, nested as univariate cubics — short
to implement, easy to relate to the Ada-Tricubic sibling, and exact on
affine fields when edges use odd reflection.

## Algorithm (this package)

Grid values $V(i,j)$ live on the integer lattice
$i=0..N_x-1$, $j=0..N_y-1$. A query $(x,y)$ falls in a unit cell with
origin $(i_0,j_0)=\bigl(\lfloor x\rfloor,\lfloor y\rfloor\bigr)$ (right
endpoints use the last cell) and local coordinates
$t_x=x-i_0$, $t_y=y-j_0\in[0,1]$.

**Bilinear.** Lerp the four cell corners along $x$, then $y$
(needs $N\ge 2$ per axis).

**Bicubic (Catmull–Rom / Keys).** For each of the four rows of the
$4\times 4$ neighbourhood indexed by
$(i_0-1..i_0+2,\,j_0-1..j_0+2)$, evaluate the uniform cubic

$$
\begin{aligned}
\mathrm{CR}(p_{-1},p_0,p_1,p_2;t)
&=
\tfrac12\bigl(
2p_0
+(-p_{-1}+p_1)\,t
\\
&\qquad
+(2p_{-1}-5p_0+4p_1-p_2)\,t^{2}
+(-p_{-1}+3p_0-3p_1+p_2)\,t^{3}
\bigr)
\end{aligned}
$$

along $x$; then the same cubic along $y$ on the resulting four values.
This is Keys cubic convolution with $a=-\tfrac12$ (Catmull–Rom). Lattice
samples outside $[0,N-1]$ use **odd reflection**
($V(-1)=2V(0)-V(1)$, etc.) so affine fields $f=a+bx+cy$ stay exact on the
closed domain. Requires $N\ge 4$ per axis. Exposed helper: `Cubic_1D`.

**Resize.** Output index $(i',j')$ maps to source

$$
x=i'\cdot\frac{N_x-1}{N'_x-1}
\qquad(N'_x>1),\qquad x=0\ (N'_x=1)
$$

(and likewise for $y$), then `Evaluate_Bicubic`.

## API summary

| Symbol | Role |
| --- | --- |
| `Grid_2D`, `Grid_Values` | Packed regular lattice $V(i,j)$ |
| `Max_N` | Hard cap ($64$) per axis |
| `Status` | `Ok` / `Out_Of_Domain` / `Too_Small_Grid` / `Ill_Started` |
| `Eval_Result`, `Resize_2D_Result` | Value or grid + `Stat` / `Success` |
| `Near`, `Lerp`, `Cubic_1D` | Numeric / Keys–Catmull–Rom helpers |
| `Is_Valid_Grid`, `In_Domain` | Domain utilities |
| `Large_Enough_Bilinear`, `Large_Enough_Bicubic` | Size checks |
| `Get`, `Set` | Lattice accessors |
| `Evaluate_Bilinear` | Multilinear baseline |
| `Evaluate_Bicubic` | Tensor-product Catmull–Rom / Keys |
| `Resize_2D` | Bicubic sampling onto a new size |
| `Make_Empty`, `Make_Constant_Field` | Builders |
| `Make_Affine_Field` | $V=A i+B j+C$ |
| `Make_Checkerboard`, `Make_Separable_Quadratic` | Checker / $i^{2}+j^{2}$ |
| `Make_Separable_Cubic` | $i^{3}+j^{3}$ |
| `Make_Example` | Canonical examples by `Example_Kind` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  texture or GIS kernel.
- **Regular-grid focus** — integer lattice with unit spacing; no scattered
  data, no arbitrary meshes.
- **Catmull–Rom / Keys path** — teaches the separable cubic-convolution
  view; Hermite forms that need explicit $f_x,f_y,f_{xy}$ at corners are
  documented on Wikipedia but not coded here.
- **Domain** — queries outside $[0,N_x-1]\times[0,N_y-1]$ return
  `Out_Of_Domain` (no extrapolation of the query point).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbicubic_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `bicubic_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
bicubic_interpolation.ads
bicubic_interpolation.adb
bicubic_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation)
2. R. G. Keys, *Cubic convolution interpolation for digital image processing*,
   IEEE Trans. Acoust., Speech, Signal Process. (1981).
3. Siblings: [Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation),
   [Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation),
   [Ada-Lanczos-Resampling](https://github.com/RobertBoettcherSF/Ada-Lanczos-Resampling),
   [Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation);
   upcoming Multivariate / Monotone cubic / Linear.
