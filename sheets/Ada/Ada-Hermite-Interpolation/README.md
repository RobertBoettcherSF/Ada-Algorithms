# Hermite Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **Hermite
interpolation**: piecewise **cubic Hermite** matching values $y_i$ and
tangents $m_i$ at strictly increasing knots $x_i$. On each interval
$[x_i,x_{i+1}]$ with $\Delta=x_{i+1}-x_i$ and $t=(x-x_i)/\Delta$,

$$
f(x)=y_i\,h_{00}(t)+\Delta\,m_i\,h_{10}(t)
+y_{i+1}\,h_{01}(t)+\Delta\,m_{i+1}\,h_{11}(t),
$$

where the cubic Hermite basis on $t\in[0,1]$ is

$$
\begin{aligned}
h_{00}(t)&=2t^{3}-3t^{2}+1,\\
h_{10}(t)&=t^{3}-2t^{2}+t,\\
h_{01}(t)&=-2t^{3}+3t^{2},\\
h_{11}(t)&=t^{3}-t^{2}.
\end{aligned}
$$

Tangents may be **user-supplied** (`Fit`) or estimated by **finite
differences** (`Fit_FD`): $m_0=\delta_0$, $m_n=\delta_{n-1}$, interior
$m_k=(\delta_{k-1}+\delta_k)/2$ with secants
$\delta_i=(y_{i+1}-y_i)/(x_{i+1}-x_i)$. FD Hermite **may overshoot** —
contrast **[Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation)**
(Fritsch–Carlson). **Two-point** matching of $y,y'$ at endpoints yields the
unique cubic on an interval. An optional small **osculatory / Newton
confluent** sketch matches value and first derivative at several nodes as a
global polynomial (keep $n$ small). Cap $n\le 32$ points, educational
`Float`.

Based on [Wikipedia: Hermite interpolation](https://en.wikipedia.org/wiki/Hermite_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation)** — Fritsch–Carlson monotone cubics
- **[Ada-Lagrange-Interpolation](https://github.com/RobertBoettcherSF/Ada-Lagrange-Interpolation)** — classical / barycentric Lagrange
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **Cubic interpolation** — upcoming
- **Birkhoff interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Piecewise cubic Hermite | Match $y_i$ and $m_i$ |
| **Basis** | $h_{00},h_{10},h_{01},h_{11}$ | `H00` … `H11`, `Evaluate_Cubic_Interval` |
| **Tangents** | User / FD / two-point | `Fit`, `Fit_FD`, `Fit_Two_Point` |
| **Osculatory** | Newton confluent (small $n$) | Value + first derivative globally |
| **Status** | `Ok` … `Dimension_Error` | Incl. `Out_Of_Domain`, `Not_Strictly_Increasing` |
| **Builders** | Known cubic / sine / ramp | Analytic derivatives where applicable |
| **Cap** | $n\le 32$ | `Max_Points = 32` |

## Brief history

Charles Hermite generalized Lagrange interpolation so that a polynomial (or
piecewise polynomial) matches not only values but also derivatives at nodes.
The elementary **cubic Hermite** piece is uniquely determined by $y$ and $y'$
at two endpoints; chaining pieces with shared nodal tangents yields a $C^{1}$
spline. Estimating tangents from data alone (finite differences, Catmull–Rom,
Fritsch–Carlson, …) is a separate design choice: this package teaches the
general Hermite evaluator and simple FD estimates, without monotonicity
constraints. The **osculatory** (Newton confluent / divided-difference) form
builds one global polynomial when several value+derivative pairs are given.

## Algorithm (this package)

### Piecewise cubic Hermite

Given knots $(x_0,y_0),\ldots,(x_n,y_n)$ and tangents $m_0,\ldots,m_n$ with
$x_0<x_1<\cdots<x_n$:

1. Validate lengths ($\ge 2$, $\le 32$), equal $x/y/m$ sizes, strict ↑ $x$.
2. Store knots and tangents (`Fit`) or compute FD tangents (`Fit_FD`).
3. Locate interval $i$ with $x_i\le x\le x_{i+1}$; set
   $\Delta=x_{i+1}-x_i$, $t=(x-x_i)/\Delta$.
4. Evaluate with $h_{00},h_{10},h_{01},h_{11}$ as above.
5. Queries outside $[x_0,x_n]$ return `Out_Of_Domain` (no extrapolation).

`Fit_Two_Point` is the $n=1$ case: the unique cubic matching
$(y_0,m_0)$ and $(y_1,m_1)$.

### Osculatory Newton confluent (optional)

For $n+1\le 8$ distinct nodes with $y_i$ and $m_i=y'_i$, double each abscissa
in a divided-difference table, replace first-order confluent entries by $m_i$,
and evaluate the Newton form of degree at most $2n+1$. Educational only;
prefer piecewise Hermite for many knots.

## API summary

| Symbol | Role |
| --- | --- |
| `Point`, `Points` | Packed $(x,y)$ samples |
| `Abscissae`, `Ordinates`, `Tangents` | Separate $x$ / $y$ / $m$ arrays |
| `Max_Points` | Hard cap ($32$) |
| `Max_Osculatory_Nodes` | Cap for global osculatory ($8$) |
| `Status` | `Ok` / `Not_Strictly_Increasing` / `Too_Few_Points` / `Out_Of_Domain` / `Ill_Started` / `Dimension_Error` |
| `Fit_Kind` | `User_Tangents` / `Finite_Difference` / `Two_Point` |
| `Spline` | Knots, tangents $m_i$, kind, validity |
| `Fit_Result`, `Eval_Result` | Fit/eval + `Stat` + `Success` |
| `Near`, `Make_Point` | Numeric helpers |
| `H00`, `H10`, `H01`, `H11` | Cubic Hermite basis |
| `Is_Strictly_Increasing`, `In_Domain`, `Find_Interval` | Validation / domain |
| `Evaluate_Cubic_Interval` | Unique cubic on one interval |
| `Fit`, `Fit_FD`, `Fit_Two_Point` | Fitters |
| `Evaluate` | Piecewise Hermite evaluation |
| `Evaluate_Osculatory` | Newton confluent (small $n$) |
| `Make_Known_Cubic`, `Make_Sine_Sample` | Analytic builders |
| `Make_Linear_Ramp`, `Make_Example` | Ramp / canonical examples |
| `Split_XY` | Unpack `Points` into $x$, $y$ |

## Limits and caveats

- **General Hermite, not monotone** — FD / user tangents can overshoot; use
  Ada-Monotone-Cubic-Interpolation when monotonicity is required.
- **Educational `Float`** — ordinary single precision; not a production CAD
  or CAGD kernel.
- **Strictly increasing $x$** — required for piecewise fit and osculatory.
- **Domain** — piecewise `Evaluate` outside $[x_0,x_n]$ returns
  `Out_Of_Domain`; osculatory is a global polynomial (no clamp).
- **Osculatory cap** — $n+1\le 8$ nodes; high-degree Float polynomials are
  fragile (Runge-like behaviour).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Phermite_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `hermite_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
hermite_interpolation.ads
hermite_interpolation.adb
hermite_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Hermite interpolation](https://en.wikipedia.org/wiki/Hermite_interpolation)
2. [Wikipedia: Cubic Hermite spline](https://en.wikipedia.org/wiki/Cubic_Hermite_spline)
3. Burden, R. L.; Faires, J. D. — *Numerical Analysis* (Hermite / osculatory
   divided differences)
4. Siblings: [Ada-Monotone-Cubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Monotone-Cubic-Interpolation),
   [Ada-Lagrange-Interpolation](https://github.com/RobertBoettcherSF/Ada-Lagrange-Interpolation),
   [Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation);
   upcoming Cubic / Birkhoff
