# De Boor's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **De Boor's
algorithm** for **B-spline curve evaluation**. A degree-$p$ B-spline with
control points $c_0,\ldots,c_n$ and nondecreasing knot vector
$t_0,\ldots,t_{n+p+1}$ is evaluated at parameter $x$ by a triangular scheme
that generalizes De Casteljau:

$$
\begin{aligned}
d_{j}&:=c_{j+k-p},\quad j=0,\ldots,p,\\
d_{j}&:=(1-\alpha_{j})\,d_{j-1}+\alpha_{j}\,d_{j},
\quad j=p,\ldots,r\quad(r=1,\ldots,p),\\
\alpha_{j}&:=\frac{x-t_{j+k-p}}{t_{j+1+k-r}-t_{j+k-p}},\\
S(x)&=d_{p},
\end{aligned}
$$

where $k$ is the span index with $x\in[t_{k},t_{k+1})$ (and $k=n$ at the
right endpoint). Cap degree $p\le 8$, at most $32$ controls, educational
`Float`, supports 1-D / 2-D / 3-D. Focus: **uniform** and **simple clamped
open** knot vectors; a cubic Bézier is recovered when the knots are
$[0,0,0,0,1,1,1,1]$.

Based on [Wikipedia: De Boor's algorithm](https://en.wikipedia.org/wiki/De_Boor_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau)** — Bézier evaluation / subdivision
- **Spline interpolation** — upcoming
- **Neville's algorithm** — upcoming
- **Polynomial interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Local De Boor triangle | Generalizes De Casteljau; $O(p^{2})$ |
| **Span** | Binary search `Find_Span` | $x\in[t_{k},t_{k+1})$; right end $\to n$ |
| **Evaluate** | $S(x)=d_{p}$ | `Evaluate` / `Evaluate_Curve` (1-D / 2-D / 3-D) |
| **Knots** | Clamped open / Bézier | `Make_Uniform_Clamped`, `Make_Bezier_Knots` |
| **Status** | `Ok` … `Ill_Started` | Incl. `Out_Of_Domain`, `Invalid_Knots` |
| **Cross-check** | Tiny cubic Casteljau oracle | Bézier knots $\equiv$ De Casteljau |
| **Degree** | $p\le 8$ | `Max_Controls = 32` |

## Brief history

Carl de Boor introduced a numerically stable, polynomial-time scheme for
evaluating splines in B-spline form — the natural generalization of Paul de
Casteljau's algorithm from Bernstein–Bézier polynomials to piecewise
polynomials with local support. The method is a standard building block in
CAGD and numerical analysis: once the knot span containing $x$ is known, only
$p+1$ controls participate, and the triangle reuses the same convex
combinations that appear in the Cox–de Boor recurrence, without forming the
basis functions explicitly. Complexity is $O(p^{2})$ per evaluation (plus
$O(\log n)$ or $O(n)$ to find the span).

## Algorithm (this package)

Given controls $c_0,\ldots,c_n$, knots $t_0,\ldots,t_{n+p+1}$, degree $p$,
and parameter $x\in[t_{p},t_{n+1}]$:

1. Validate knots (nondecreasing, correct length, multiplicities).
2. Find span index $k$ (`Find_Span`).
3. Seed $d_j\leftarrow c_{j+k-p}$ for $j=0,\ldots,p$.
4. For $r=1,\ldots,p$, update $d_j$ downward in $j$ with weights $\alpha_j$.
5. Return $S(x)=d_p$.

Clamped open constructions repeat the end knots $p+1$ times so the curve
interpolates $c_0$ and $c_n$. A Bézier curve of degree $p$ is exactly the
B-spline with knots $t_0=\cdots=t_p=a$, $t_{p+1}=\cdots=t_{2p+1}=b$.

## API summary

| Symbol | Role |
| --- | --- |
| `Point_2D`, `Point_3D` | Educational `Float` points |
| `Controls_1D` / `_2D` / `_3D` | 0-based control polygons $c_0..c_n$ |
| `Knot_Vector` | 0-based knots $t_0..t_{n+p+1}$ |
| `Max_Degree`, `Max_Controls` | Caps ($8$, $32$) |
| `Status` | `Ok` / `Out_Of_Domain` / `Invalid_Knots` / `Dimension_Error` / `Ill_Started` |
| `Eval_Result_*`, `Span_Result` | Value/point + `Stat` + `Success` |
| `Lerp`, `Near`, `Dist`, `Add`, `Sub`, `Scale` | Geometry helpers |
| `Is_Valid_Knots`, `Find_Span`, `In_Domain` | Knot / span utilities |
| `Evaluate` / `Evaluate_Curve` | De Boor evaluation |
| `Make_Uniform_Clamped`, `Make_Bezier_Knots` | Knot builders |
| `Make_Linear_*`, `Make_Cubic_Bezier_*` | Control builders |
| `Make_Linear_Interpolant_*`, `Make_Cubic_Bezier_As_BSpline_2D` | Curve records |
| `Make_Example_2D` / `_1D` | Canonical teaching curves |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production CAGD
  kernel or NURBS library.
- **Clamped / uniform focus** — builders emphasize open clamped and Bézier
  knots; arbitrary non-uniform vectors are accepted if `Is_Valid_Knots`
  holds, but are not the teaching default.
- **$O(p^{2})$ per evaluation** — fine for $p\le 8$; rational weights (NURBS)
  and surfaces are out of scope.
- **Domain** — evaluation outside $[t_p,t_{n+1}]$ returns `Out_Of_Domain`
  (no polynomial extrapolation flag, unlike the De Casteljau sibling).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pde_boor.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `de_boor.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
de_boor.ads
de_boor.adb
de_boor.gpr
tests.adb
```

## References

1. [Wikipedia: De Boor's algorithm](https://en.wikipedia.org/wiki/De_Boor_algorithm)
2. Carl de Boor, *A Practical Guide to Splines* — classical treatment.
3. Sibling: [Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau); upcoming Spline interpolation, Neville, Polynomial interpolation.
