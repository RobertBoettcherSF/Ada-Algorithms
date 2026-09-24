# Tricubic Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **tricubic
interpolation** of a scalar field sampled on a regular 3D lattice. Locally
the interpolant has the monomial form

$$
f(x,y,z)=\sum_{i=0}^{3}\sum_{j=0}^{3}\sum_{k=0}^{3} a_{ijk}\,x^{i}y^{j}z^{k}
$$

(64 coefficients). This package realises that form as a **tensor product of
one-dimensional Catmull–Rom** cubics (cubic Hermite with centered
finite-difference tangents) applied sequentially along $x$, then $y$, then
$z$ — equivalent to the nested $\mathrm{CINT}$ construction on Wikipedia.
Cap $N\le 16$ samples per axis, educational `Float`. **Trilinear**
interpolation is included as a simpler sibling baseline for comparison.

Based on [Wikipedia: Tricubic interpolation](https://en.wikipedia.org/wiki/Tricubic_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **[Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation)** — Lagrange / Newton / etc.
- **Nearest-neighbor** — upcoming
- **Lanczos resampling** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Local tricubic on regular grid | 64 dof / unit cube |
| **Realisation** | Tensor-product Catmull–Rom | Nested 1-D cubics (Wikipedia $\mathrm{CINT}$) |
| **Baseline** | Trilinear | 8 corners of the cell |
| **Domain** | $[0,N_x-1]\times[0,N_y-1]\times[0,N_z-1]$ | Continuous query coords |
| **Boundaries** | Odd (value) reflection | Keeps affine fields exact |
| **Status** | `Ok` … `Ill_Started` | Incl. `Out_Of_Domain`, `Too_Small_Grid` |
| **Cap** | $N\le 16$ / axis | `Max_N = 16` |

## Brief history

Tricubic interpolation extends cubic interpolation to three dimensions. One
classical route (Lekien–Marsden and related work) solves a $64\times 64$
linear system for the monomial coefficients from values and derivatives on
the unit cube. Another route — used here — notes that the same local cubic
is obtained by **sequential univariate cubic interpolators** along each
axis. That tensor-product view is short to implement, easy to teach, and
matches the nested $\mathrm{CINT}$ formulas on the Wikipedia page.

## Algorithm (this package)

Grid values $V(i,j,k)$ live on the integer lattice
$i=0..N_x-1$, $j=0..N_y-1$, $k=0..N_z-1$. A query $(x,y,z)$ falls in a
unit cell with origin $(i_0,j_0,k_0)=\bigl(\lfloor x\rfloor,\lfloor y\rfloor,\lfloor z\rfloor\bigr)$
(right endpoints use the last cell) and local coordinates
$t_x=x-i_0$, $t_y=y-j_0$, $t_z=z-k_0\in[0,1]$.

**Trilinear.** Lerp the eight cell corners along $x$, then $y$, then $z$
(needs $N\ge 2$ per axis).

**Tricubic (Catmull–Rom).** For each of the $4\times 4$ lines of the
$4\times 4\times 4$ neighbourhood indexed by
$(i_0-1..i_0+2,\,j_0-1..j_0+2,\,k_0-1..k_0+2)$, evaluate the uniform
Catmull–Rom cubic

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

along $x$; repeat the same cubic along $y$ on the resulting $4\times 4$
face, then along $z$. Lattice samples outside $[0,N-1]$ use **odd
reflection** ($V(-1)=2V(0)-V(1)$, etc.) so affine fields
$f=a+bx+cy+dz$ stay exact on the closed domain. Requires $N\ge 4$ per
axis.

## API summary

| Symbol | Role |
| --- | --- |
| `Grid_3D`, `Grid_Values` | Packed regular lattice $V(i,j,k)$ |
| `Max_N` | Hard cap ($16$) per axis |
| `Status` | `Ok` / `Out_Of_Domain` / `Too_Small_Grid` / `Ill_Started` |
| `Eval_Result` | `Value` + `Stat` + `Success` |
| `Near`, `Lerp` | Numeric helpers |
| `Is_Valid_Grid`, `In_Domain` | Domain utilities |
| `Large_Enough_Trilinear`, `Large_Enough_Tricubic` | Size checks |
| `Get`, `Set` | Lattice accessors |
| `Evaluate_Trilinear` | Multilinear baseline |
| `Evaluate_Tricubic` | Tensor-product Catmull–Rom |
| `Make_Empty`, `Make_Constant_Field` | Builders |
| `Make_Linear_Field` | $V=i+2j+3k$ ($f=x+2y+3z$) |
| `Make_Separable_Quadratic`, `Make_Separable_Cubic` | $i^{2}+j^{2}+k^{2}$, $i^{3}+j^{3}+k^{3}$ |
| `Make_Example` | Canonical examples by `Example_Kind` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  volume-rendering or CFD kernel.
- **Regular-grid focus** — integer lattice with unit spacing; no scattered
  data, no anisotropic cells.
- **Catmull–Rom path** — teaches the tensor-product view; the dense
  Lekien–Marsden $64\times 64$ solve is documented on Wikipedia but not
  coded here.
- **Domain** — queries outside $[0,N_x-1]\times[0,N_y-1]\times[0,N_z-1]$
  return `Out_Of_Domain` (no extrapolation of the query point).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Ptricubic_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `tricubic_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
tricubic_interpolation.ads
tricubic_interpolation.adb
tricubic_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Tricubic interpolation](https://en.wikipedia.org/wiki/Tricubic_interpolation)
2. F. Lekien and J. Marsden, *Tricubic interpolation in three dimensions*,
   Int. J. Numer. Meth. Engng (2005) — coefficient / derivative formulation.
3. Siblings: [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation),
   [Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation);
   upcoming Nearest-neighbor, Lanczos resampling.
