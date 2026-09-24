# Linear Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **linear
interpolation** (lerp): the straight-line interpolant between two known
points, piecewise-linear tables on sorted abscissae, optional end-segment
**extrapolation**, and **inverse lerp** when ordinates are strictly
monotone. The two-point formula

$$
y=y_0+(x-x_0)\frac{y_1-y_0}{x_1-x_0}
$$

is equivalent to the parameter form

$$
L(t)=(1-t)\,a+t\,b.
$$

Cap $n\le 64$ points; educational `Float`.

Based on [Wikipedia: Linear interpolation](https://en.wikipedia.org/wiki/Linear_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation)** — repeated linear blend on 2-D grids
- **[Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation)** — Fritsch–Carlson cubic Hermite
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **Lagrange interpolation** — upcoming
- **Hermite interpolation** — upcoming
- **Cubic interpolation** — upcoming
- **Birkhoff interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Two-point** | Slope / $L(t)=(1-t)a+tb$ | `Interpolate_Two_Points`, `Lerp` |
| **Table** | Piecewise linear on sorted $x_i$ | `Fit` / `Evaluate` |
| **Clamp** | `Lerp` clamps $t\in[0,1]$ | `Lerp_Unclamped` does not |
| **Extrapolate** | Optional end-segment flag | Else `Out_Of_Domain` |
| **Inverse** | $t=(v-a)/(b-a)$; table via $y$-search | Needs strictly monotone $y$ |
| **Status** | `Ok` … `Singular` | Incl. `Duplicate_Or_Unordered` |
| **Cap** | $n\le 64$ | `Max_Points = 64` |

## Brief history

Linear interpolation is the simplest case of polynomial interpolation
($n=1$) and the workhorse of numerical tables, computer graphics
(parameter blending), and signal resampling. Given two samples, the
interpolant is the unique straight line through them; on a sorted table
one applies that formula on each consecutive pair (piecewise linear,
$C^0$). Inverse lerp recovers the parameter (or the abscissa) when the
mapping is invertible — here, when $y$ is strictly monotone.

## Algorithm (this package)

**Two known points.** For $(x_0,y_0)$ and $(x_1,y_1)$ with $x_1\neq x_0$,

$$
y=y_0+(x-x_0)\frac{y_1-y_0}{x_1-x_0}.
$$

Equivalently with $t=(x-x_0)/(x_1-x_0)$:

$$
L(t)=(1-t)\,y_0+t\,y_1.
$$

`Lerp` clamps $t$ to $[0,1]$; `Lerp_Unclamped` and
`Interpolate_Two_Points` allow $t$ outside $[0,1]$ (extrapolation on the
line). Coincident $x$ → `Singular`.

**Piecewise table.** Given knots $(x_0,y_0),\ldots,(x_n,y_n)$ with
$x_0<x_1<\cdots<x_n$:

1. Validate lengths ($\ge 2$, $\le 64$) and strictly increasing $x$
   (else `Duplicate_Or_Unordered` / `Too_Few_Points` / `Ill_Started`).
2. Locate interval $i$ with $x_i\le x\le x_{i+1}$ (binary search;
   right endpoint uses $i=n-1$).
3. Evaluate with unclamped lerp on that segment.
4. If $x\notin[x_0,x_n]$: use the nearest end segment when
   `Extrapolate`, else `Out_Of_Domain`.

**Inverse.** `Inverse_Lerp(A,B,V)` returns $t=(V-A)/(B-A)$ (`Singular`
if $A=B$). `Inverse_Evaluate` requires strictly monotone $y$, finds the
$y$-segment containing the query, inverse-lerps, and maps back to $x$.

## API summary

| Symbol | Role |
| --- | --- |
| `Point`, `Points` | Packed $(x,y)$ samples |
| `Abscissae`, `Ordinates` | Separate $x$ / $y$ arrays |
| `Max_Points` | Hard cap ($64$) |
| `Status` | `Ok` / `Duplicate_Or_Unordered` / `Too_Few_Points` / `Out_Of_Domain` / `Ill_Started` / `Singular` |
| `Table` | Knots, extrapolate flag, validity |
| `Fit_Result`, `Eval_Result` | Fit/eval + `Stat` + `Success` |
| `Near`, `Make_Point` | Numeric helpers |
| `Lerp`, `Lerp_Unclamped` | Clamped / unclamped parameter blend |
| `Inverse_Lerp` | Parameter from value ($a\neq b$) |
| `Interpolate_Two_Points` | Closed two-point formula |
| `Is_Strictly_Increasing`, `Is_Strictly_Monotone` | Validation helpers |
| `In_Domain`, `Find_Interval` | Domain utilities |
| `Fit` | Build piecewise-linear `Table` |
| `Evaluate` | Piecewise lerp (+ optional extrapolate) |
| `Inverse_Evaluate` | Inverse on monotone tables |
| `Make_Linear_Data`, `Make_Increasing_Ramp` | Line / ramp builders |
| `Make_Decreasing_Ramp`, `Make_Quadratic_Sample` | More sample builders |
| `Make_Example`, `Split_XY` | Canonical examples / split |

## Limits and caveats

- **Piecewise linear** — $C^0$ only; no derivative continuity (see
  monotone cubic / spline siblings for $C^1$/$C^2$).
- **Educational `Float`** — ordinary single precision; not a production
  CAD / DSP kernel.
- **Strictly increasing $x$** — required for `Fit`; duplicate or
  unordered abscissae → `Duplicate_Or_Unordered`.
- **Inverse** — needs strictly monotone $y$; non-monotone tables still
  fit for forward evaluation but return `Singular` on inverse.
- **Domain** — default evaluation outside $[x_0,x_n]$ is
  `Out_Of_Domain`; set `Extrapolate => True` at `Fit` to continue the
  end segments.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Plinear_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `linear_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
linear_interpolation.ads
linear_interpolation.adb
linear_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Linear interpolation](https://en.wikipedia.org/wiki/Linear_interpolation)
2. Siblings: [Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation),
   [Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation),
   [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation);
   upcoming Lagrange / Hermite / Cubic / Birkhoff.
