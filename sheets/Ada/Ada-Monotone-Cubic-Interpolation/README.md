# Monotone Cubic Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **monotone cubic
interpolation**: a **cubic Hermite spline** whose tangents $m_i$ are chosen by
the **Fritsch–Carlson** method so that strictly monotone data
$(x_i,y_i)$ produce a monotone interpolant. Secants

$$
\delta_i=\frac{y_{i+1}-y_i}{x_{i+1}-x_i}
$$

initialize provisional tangents; endpoints use one-sided differences; opposite
signs or flat intervals force $m_i=0$; then $(\alpha_i,\beta_i)=(m_i/\delta_i,
m_{i+1}/\delta_i)$ is restricted to the circle of radius $3$ when
$\alpha_i^2+\beta_i^2>9$. Evaluation uses the Hermite basis on each interval.
Cap $n\le 64$ points, educational `Float`. Piecewise **linear** and plain
**finite-difference Hermite** (no FC restrict) are included for comparison.

Based on [Wikipedia: Monotone cubic interpolation](https://en.wikipedia.org/wiki/Monotone_cubic_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **[Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation)** — 2D cubic convolution
- **Linear interpolation** — upcoming
- **Lagrange interpolation** — upcoming
- **Hermite interpolation** — upcoming
- **Cubic interpolation** — upcoming
- **Birkhoff interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Cubic Hermite + FC tangents | Preserves monotonicity of data |
| **Secants** | $\delta_i=(y_{i+1}-y_i)/(x_{i+1}-x_i)$ | Provisional slopes |
| **Restrict** | $\alpha^2+\beta^2\le 9$ | Circle of radius $3$ (wiki) |
| **Evaluate** | Hermite $h_{00},h_{10},h_{01},h_{11}$ | `Evaluate(Spline, X)` |
| **Status** | `Ok` … `Ill_Started` | Incl. `Not_Strictly_Increasing`, `Out_Of_Domain` |
| **Extras** | Linear / FD Hermite | Comparison / overshoot contrast |
| **Cap** | $n\le 64$ | `Max_Points = 64` |

## Brief history

Cubic Hermite interpolation matches values and first derivatives at knots, but
arbitrary tangent choices can overshoot and destroy monotonicity. Fritsch and
Carlson (1980) gave sufficient conditions on the scaled tangents
$(\alpha_i,\beta_i)$ so that each cubic piece is monotone when the data are.
A simple sufficient restriction places $(\alpha_i,\beta_i)$ inside a circle of
radius $3$; that is the method implemented here (one pass). Linear interpolation
always preserves monotonicity but is only $C^0$; monotone cubics aim for smooth
$C^1$ pieces without spurious extrema.

## Algorithm (this package)

Given knots $(x_0,y_0),\ldots,(x_n,y_n)$ with $x_0<x_1<\cdots<x_n$:

1. Validate lengths ($\ge 2$, $\le 64$) and strictly increasing $x$.
2. Compute secants $\delta_i$ for $i=0,\ldots,n-1$.
3. Initialize $m_0=\delta_0$, $m_n=\delta_{n-1}$, and interior
   $m_k=(\delta_{k-1}+\delta_k)/2$; set $m_k=0$ at opposite-sign secants.
4. Where $\delta_i=0$, set $m_i=m_{i+1}=0$ (flat piece).
5. Set $\alpha_i=m_i/\delta_i$, $\beta_i=m_{i+1}/\delta_i$. If either is
   negative, zero the corresponding tangent (local extremum). If
   $\alpha_i^2+\beta_i^2>9$, scale by
   $$
   \tau_i=\frac{3}{\sqrt{\alpha_i^2+\beta_i^2}},\qquad
   m_i=\tau_i\,\alpha_i\,\delta_i,\quad
   m_{i+1}=\tau_i\,\beta_i\,\delta_i.
   $$
6. Evaluate on the interval with $x_i\le x\le x_{i+1}$:
   $$
   \Delta=x_{i+1}-x_i,\quad t=\frac{x-x_i}{\Delta},
   $$
   $$
   f(x)=y_i\,h_{00}(t)+\Delta\,m_i\,h_{10}(t)
   +y_{i+1}\,h_{01}(t)+\Delta\,m_{i+1}\,h_{11}(t).
   $$

`Fit_Hermite_FD` stops after step 3 (plus flat zeroing); `Fit_Linear` stores
nodes and lerps.

## API summary

| Symbol | Role |
| --- | --- |
| `Point`, `Points` | Packed $(x,y)$ samples |
| `Abscissae`, `Ordinates`, `Tangents` | Separate $x$ / $y$ / $m$ arrays |
| `Max_Points` | Hard cap ($64$) |
| `Status` | `Ok` / `Not_Strictly_Increasing` / `Too_Few_Points` / `Out_Of_Domain` / `Ill_Started` |
| `Spline_Kind` | `Monotone_Cubic` / `Finite_Difference_Hermite` / `Linear` |
| `Spline` | Knots, tangents $m_i$, kind, validity |
| `Fit_Result`, `Eval_Result` | Fit/eval + `Stat` + `Success` |
| `Near`, `Lerp`, `Make_Point` | Numeric helpers |
| `H00`, `H10`, `H01`, `H11` | Cubic Hermite basis |
| `Is_Strictly_Increasing`, `Is_Monotone_Samples` | Validation helpers |
| `In_Domain`, `Find_Interval` | Domain utilities |
| `Fit`, `Fit_Monotone` | Fritsch–Carlson fitter |
| `Fit_Hermite_FD`, `Fit_Linear` | Contrast / baseline fitters |
| `Evaluate` | Piecewise Hermite / linear evaluation |
| `Make_Linear_Data`, `Make_Increasing_Ramp` | Monotone builders |
| `Make_Sigmoid_Sample`, `Make_Non_Monotone_Sample` | Sample builders |
| `Make_Example`, `Split_XY` | Canonical examples / split |

## Limits and caveats

- **Fritsch–Carlson focus** — teaching default; FD Hermite / linear are
  optional extras for contrast (overshoot / $C^0$).
- **Educational `Float`** — ordinary single precision; not a production CAD
  kernel.
- **Strictly increasing $x$** — required; non-monotone $y$ still fits but FC
  flattens local extrema (piecewise monotone, not globally).
- **Domain** — evaluation outside $[x_0,x_n]$ returns `Out_Of_Domain` (no
  extrapolation).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pmonotone_cubic_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `monotone_cubic_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
monotone_cubic_interpolation.ads
monotone_cubic_interpolation.adb
monotone_cubic_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Monotone cubic interpolation](https://en.wikipedia.org/wiki/Monotone_cubic_interpolation)
2. Fritsch, F. N.; Carlson, R. E. (1980). "Monotone Piecewise Cubic
   Interpolation". *SIAM Journal on Numerical Analysis* **17** (2): 238–246.
3. Siblings: [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation),
   [Ada-Bicubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bicubic-Interpolation);
   upcoming Linear / Lagrange / Hermite / Cubic / Birkhoff.
