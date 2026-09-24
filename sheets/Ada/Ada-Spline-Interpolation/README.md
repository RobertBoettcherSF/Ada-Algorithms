# Spline Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **spline
interpolation**, focused on the classic **natural cubic spline** through
points $(x_i,y_i)$ with strictly increasing abscissae. Second derivatives
$M_i=S''(x_i)$ solve a tridiagonal system (natural: $M_0=M_n=0$) via the
**Thomas algorithm**; each piece is evaluated in the cubic moment form

$$
\begin{aligned}
S(x)
&=
\frac{M_i}{6h_i}(x_{i+1}-x)^3
+
\frac{M_{i+1}}{6h_i}(x-x_i)^3
\\
&\quad+
\Bigl(y_i-\frac{M_i h_i^2}{6}\Bigr)\frac{x_{i+1}-x}{h_i}
+
\Bigl(y_{i+1}-\frac{M_{i+1}h_i^2}{6}\Bigr)\frac{x-x_i}{h_i},
\end{aligned}
$$

on $[x_i,x_{i+1}]$ with $h_i=x_{i+1}-x_i$. Cap $n\le 32$ points, educational
`Float`. Optional **clamped** cubic (given end derivatives) and piecewise
**linear** / **quadratic** baselines.

Based on [Wikipedia: Spline interpolation](https://en.wikipedia.org/wiki/Spline_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-De-Boor](https://github.com/RobertBoettcherSF/Ada-De-Boor)** — B-spline evaluation
- **[Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau)** — Bézier evaluation / subdivision
- **Neville's algorithm** — upcoming
- **Polynomial interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Piecewise cubics, $C^2$ | Avoids Runge oscillation of high-degree polys |
| **Moments** | $M_i=S''(x_i)$ | Natural: $M_0=M_n=0$ |
| **Solve** | Dense Thomas | Self-contained tridiagonal $O(n)$ |
| **Evaluate** | Moment / Hermite form | `Evaluate(Spline, X)` |
| **Status** | `Ok` … `Out_Of_Domain` | Incl. `Not_Strictly_Increasing`, `Singular` |
| **Extras** | Clamped / linear / quad | Optional baselines |
| **Cap** | $n\le 32$ | `Max_Points = 32` |

## Brief history

Physical “splines” were flexible rulers forced through draft knots; the
mathematical cubic spline mimics that elasticity by requiring continuous
value, first, and second derivatives at joins. Natural end conditions set
curvature to zero beyond the outer knots ($M_0=M_n=0$). The resulting
tridiagonal system is uniquely solvable for distinct $x_i$ and is the
standard teaching route to smooth interpolation without a single global
high-degree polynomial.

## Algorithm (this package)

Given knots $(x_0,y_0),\ldots,(x_n,y_n)$ with $x_0<x_1<\cdots<x_n$:

1. Validate lengths and strictly increasing $x$; reject $n+1>32$.
2. Set $h_i:=x_{i+1}-x_i$. For natural cubics, assemble the interior
   tridiagonal equations for $M_1,\ldots,M_{n-1}$ with $M_0=M_n=0$:
   $$
   \frac{h_{i-1}}{6}M_{i-1}+\frac{h_{i-1}+h_i}{3}M_i+\frac{h_i}{6}M_{i+1}
   =
   \frac{y_{i+1}-y_i}{h_i}-\frac{y_i-y_{i-1}}{h_{i-1}}.
   $$
3. Solve with Thomas (`Thomas`).
4. Evaluate with the moment formula on the interval containing the query
   $x\in[x_0,x_n]$.

Clamped cubics replace the natural rows with end-derivative conditions
involving $S'(x_0)$ and $S'(x_n)$. Linear / quadratic fitters store the
nodes and evaluate by lerp or local Lagrange triples.

## API summary

| Symbol | Role |
| --- | --- |
| `Point`, `Points` | Packed $(x,y)$ samples |
| `Abscissae`, `Ordinates` | Separate $x$ / $y$ arrays |
| `Max_Points` | Hard cap ($32$) |
| `Status` | `Ok` / `Not_Strictly_Increasing` / `Too_Few_Points` / `Dimension_Error` / `Singular` / `Ill_Started` / `Out_Of_Domain` |
| `Spline_Kind` | `Natural_Cubic` / `Clamped_Cubic` / `Linear` / `Quadratic` |
| `Spline` | Knots, $M_i$, kind, validity |
| `Fit_Result`, `Eval_Result` | Fit/eval + `Stat` + `Success` |
| `Near`, `Lerp`, `Make_Point` | Numeric helpers |
| `Is_Strictly_Increasing`, `In_Domain`, `Find_Interval` | Domain utilities |
| `Thomas` | Self-contained tridiagonal solve |
| `Fit_Natural_Cubic`, `Fit_Clamped_Cubic` | Cubic fitters |
| `Fit_Linear`, `Fit_Quadratic` | Baseline fitters |
| `Evaluate` | Piecewise evaluation |
| `Make_Linear_Data`, `Make_Quadratic_Sample`, `Make_Sine_Sample` | Sample builders |
| `Make_Example`, `Split_XY` | Canonical examples / split |

## Limits and caveats

- **Natural cubic focus** — teaching default; clamped / linear / quadratic
  are optional extras.
- **Educational `Float`** — ordinary single precision; not a production
  CAD / CAGD kernel.
- **Dense Thomas** — clear $O(n)$ code for $n\le 32$; no sparse BLAS or
  multiprecision.
- **Domain** — evaluation outside $[x_0,x_n]$ returns `Out_Of_Domain` (no
  extrapolation).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pspline_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `spline_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
spline_interpolation.ads
spline_interpolation.adb
spline_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Spline interpolation](https://en.wikipedia.org/wiki/Spline_interpolation)
2. Carl de Boor, *A Practical Guide to Splines* — classical treatment of
   interpolating and B-splines.
3. Siblings: [Ada-De-Boor](https://github.com/RobertBoettcherSF/Ada-De-Boor),
   [Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau);
   upcoming Neville, Polynomial interpolation.
