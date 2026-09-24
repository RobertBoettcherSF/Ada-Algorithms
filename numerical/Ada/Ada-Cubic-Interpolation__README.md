# Cubic Interpolation — Ada 2023

Educational, self-contained Ada 2023 **survey** package for **cubic
interpolation** in the sense of the Wikipedia *Cubic Hermite spline* page
and the common signal / image **Catmull–Rom / Keys cubic convolution**
path (also the spreadsheet topic label “Cubic interpolation”). It gathers
three complementary flavours:

1. **Catmull–Rom / Keys** on a uniform 1-D lattice — the same local
   4-point stencil as
   [Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation)’s
   1-D factor (`Cubic_1D`, $a=-\tfrac12$).
2. The **unique global degree-$\le 3$ interpolant** through four distinct
   points (Newton divided differences ≡ Lagrange).
3. A **thin piecewise cubic Hermite** with finite-difference tangents
   (cross-link
   [Ada-Hermite-Interpolation](https://github.com/RobertBoettcherSF/Ada-Hermite-Interpolation)
   for the full Hermite API; contrast
   [Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation)
   / Fritsch–Carlson and
   [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)
   / natural cubics).

Cap $N\le 64$ samples, educational `Float`.

Based on [Wikipedia: Cubic Hermite spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline)
(Catmull–Rom / cardinal / cubic convolution context).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Hermite-Interpolation](https://github.com/RobertBoettcherSF/Ada-Hermite-Interpolation)** — general piecewise cubic Hermite / osculatory
- **[Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation)** — Fritsch–Carlson monotone cubics
- **[Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation)** — tensor-product Catmull–Rom / Keys on 2-D grids
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubic splines
- **Birkhoff interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Catmull–Rom / Keys** | Local 4-point `Cubic_1D` on `Grid_1D` | Same as bicubic’s 1-D; odd reflection |
| **Four-point global** | Newton divided differences | Unique cubic through 4 distinct $x_i$ |
| **Thin Hermite-FD** | Piecewise $h_{00}\ldots h_{11}$ + FD $m_i$ | Cross-link Ada-Hermite |
| **Domain (CR / Hermite)** | Closed sample interval | `Out_Of_Domain` — no query extrapolation |
| **Status** | `Ok` … `Duplicate_Abscissa` | Incl. `Too_Few_Points`, `Ill_Started` |
| **Builders** | Ramp / known cubic / sine | Grids and FD examples |
| **Cap** | $N\le 64$ | `Max_N = 64` |

## Brief history

Cubic Hermite pieces match values and first derivatives at interval ends;
chaining them with shared nodal tangents yields a $C^{1}$ spline. Choosing
those tangents is a separate design: **Catmull–Rom** (a cardinal spline
with zero tension) sets

$$
m_k=\frac{p_{k+1}-p_{k-1}}{2}
$$

on a uniform parameter, which is algebraically the same as **Keys cubic
convolution** with $a=-\tfrac12$ — the workhorse “cubic interpolation” in
image / signal resampling. Separately, any four distinct abscissae determine
a unique degree-$\le 3$ polynomial (Newton or Lagrange). This package teaches
those three views side by side; it is **not** the Fritsch–Carlson monotone
cubic nor the natural $C^{2}$ spline (see siblings).

## Algorithm (this package)

### Catmull–Rom / Keys on `Grid_1D`

Samples $V(i)$ live on the integer lattice $i=0..N-1$ ($N\ge 4$). A query
$x$ falls in a unit cell with origin $i_0=\lfloor x\rfloor$ (right endpoint
uses the last cell) and local $t=x-i_0\in[0,1]$. Evaluate

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

with odd reflection $V(-1)=2V(0)-V(1)$, $V(N)=2V(N-1)-V(N-2)$ so affine
fields stay exact on $[0,N-1]$. Exposed helper: `Cubic_1D`.

### Global cubic through four points

Given distinct $(x_i,y_i)_{i=0}^{3}$, build Newton coefficients $a_0..a_3$
by divided differences and evaluate

$$
p(x)=a_0+a_1(x-x_0)+a_2(x-x_0)(x-x_1)+a_3(x-x_0)(x-x_1)(x-x_2).
$$

Equivalent to the Lagrange form; no domain clamp (global polynomial).
Coincident $x_i$ → `Duplicate_Abscissa`.

### Thin piecewise cubic Hermite (FD)

On each $[x_i,x_{i+1}]$ with $\Delta=x_{i+1}-x_i$ and $t=(x-x_i)/\Delta$,

$$
f(x)=y_i\,h_{00}(t)+\Delta\,m_i\,h_{10}(t)
+y_{i+1}\,h_{01}(t)+\Delta\,m_{i+1}\,h_{11}(t),
$$

with FD tangents $m_0=\delta_0$, $m_n=\delta_{n-1}$, interior
$m_k=(\delta_{k-1}+\delta_k)/2$ and secants
$\delta_i=(y_{i+1}-y_i)/(x_{i+1}-x_i)$. May overshoot — use the monotone
sibling when shape preservation matters.

## API summary

| Symbol | Role |
| --- | --- |
| `Grid_1D` | Uniform lattice $V(i)$ on $0..N-1$ |
| `Sample_1D`, `Hermite_Spline` | Sorted table / thin FD Hermite |
| `Max_N` | Hard cap ($64$) |
| `Status` | `Ok` / `Too_Few_Points` / `Out_Of_Domain` / `Ill_Started` / `Duplicate_Abscissa` |
| `Eval_Result`, `Fit_Result` | Value or spline + `Stat` / `Success` |
| `Near`, `Lerp`, `Cubic_1D` | Numeric / Keys–Catmull–Rom helpers |
| `H00` … `H11` | Cubic Hermite basis (thin path) |
| `Is_Valid_Grid`, `Large_Enough_Catmull_Rom`, `In_Domain` | Domain utilities |
| `Is_Strictly_Increasing` | Abscissa check |
| `Get`, `Set` | Lattice accessors |
| `Evaluate_Catmull_Rom` | Keys / Catmull–Rom on `Grid_1D` |
| `Interpolate_Four_Points` | Unique cubic through 4 points (scalar / array) |
| `Fit_FD`, `Evaluate_FD_Hermite` | Thin FD Hermite |
| `Make_Empty_Grid`, `Make_Ramp_Grid` | Builders |
| `Make_Known_Cubic_Grid`, `Make_Sine_Grid` | Known $t^{3}-2t^{2}+t$ / $\sin$ |
| `Make_Known_Cubic_Four` | Four knots of the known cubic |
| `Make_Example_Grid`, `Make_Example_FD` | Canonical examples |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  DSP or CAD kernel.
- **Survey scope** — Catmull–Rom / four-point / thin FD Hermite only;
  no Fritsch–Carlson, no natural $C^{2}$ spline, no 2-D bicubic (siblings).
- **Uniform CR grid** — integer lattice with unit spacing; non-uniform
  Catmull–Rom (centripetal / chordal) is out of scope.
- **Four-point API** — exactly four distinct abscissae; longer tables use
  Hermite-FD or the spline / Lagrange siblings.
- **Domain** — CR and Hermite queries outside the closed sample interval
  return `Out_Of_Domain` (the global four-point polynomial is unclamped).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pcubic_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `cubic_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
cubic_interpolation.ads
cubic_interpolation.adb
cubic_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Cubic Hermite spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline)
2. [Wikipedia: Bicubic interpolation](https://en.wikipedia.org/wiki/Bicubic_interpolation)
   (Keys cubic convolution / Catmull–Rom)
3. R. G. Keys, *Cubic convolution interpolation for digital image processing*,
   IEEE Trans. Acoust., Speech, Signal Process. (1981).
4. Siblings: [Ada-Hermite-Interpolation](https://github.com/RobertBoettcherSF/Ada-Hermite-Interpolation),
   [Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation),
   [Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation),
   [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation);
   upcoming Birkhoff.
