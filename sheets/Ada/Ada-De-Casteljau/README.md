# De Casteljau's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **De Casteljau's
algorithm** for **Bézier curve evaluation** and **subdivision**. A degree-$n$
curve with control points $P_0,\ldots,P_n$ is evaluated by recursive linear
interpolation:

$$
\begin{aligned}
P_i^{(0)} &= P_i,\\
P_i^{(r)} &= (1-t)\,P_i^{(r-1)} + t\,P_{i+1}^{(r-1)},\\
B(t) &= P_0^{(n)}.
\end{aligned}
$$

The same pyramid yields a **split** at $t$: the left control polygon is
$(P_0^{(0)},P_0^{(1)},\ldots,P_0^{(n)})$ and the right is
$(P_0^{(n)},P_1^{(n-1)},\ldots,P_n^{(0)})$. Cap degree $n\le 16$, educational
`Float`, supports 1-D / 2-D / 3-D. Optional direct Bernstein evaluation
cross-checks tiny degrees.

Based on [Wikipedia: De Casteljau's algorithm](https://en.wikipedia.org/wiki/De_Casteljau's_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **De Boor algorithm** — upcoming (B-spline evaluation)
- **Spline interpolation** — upcoming
- **Neville's algorithm** — upcoming
- **Polynomial interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Recursive lerp pyramid | Numerically stable vs monomial form |
| **Evaluate** | $B(t)=P_0^{(n)}$ | `Evaluate` (1-D / 2-D / 3-D) |
| **Split** | Left / right polygons | `Split` at any $t$ |
| **Cross-check** | Bernstein $\sum P_i b_{i,n}(t)$ | Tiny degrees only |
| **Status** | `Ok` … `Dimension_Error` | Incl. `Extrapolated` for $t\notin[0,1]$ |
| **Builders** | Line / quad / cubic examples | Unit-square corners, S-curve |
| **Degree** | $n\le 16$ | `Max_Degree = 16` |

## Brief history

Paul de Casteljau developed the algorithm at Citroën around 1959 as a
numerically robust way to evaluate polynomials in Bernstein form — the same
basis later popularized by Pierre Bézier at Renault. The method remains a
standard building block in CAGD: evaluation, subdivision, and (via repeated
splits) rendering of Bézier curves and surfaces. Complexity is
$O(d\,n^{2})$ in dimension $d$ and degree $n$; faster schemes exist for
special cases, but De Casteljau is prized for stability and for producing the
subdivision polygons “for free.”

## Algorithm (this package)

Given controls $P_0,\ldots,P_n$ and parameter $t$:

1. Copy $P_i^{(0)}\leftarrow P_i$.
2. For $r=1,\ldots,n$, set
   $P_i^{(r)}\leftarrow (1-t)P_i^{(r-1)}+t\,P_{i+1}^{(r-1)}$ for
   $i=0,\ldots,n-r$.
3. Return $B(t)=P_0^{(n)}$.
4. Optionally harvest the left/right control polygons from the pyramid for
   `Split`.

Typically $t\in[0,1]$; values outside that interval are allowed and reported
as `Extrapolated`.

## API summary

| Symbol | Role |
| --- | --- |
| `Point_2D`, `Point_3D` | Educational `Float` points |
| `Controls_1D` / `_2D` / `_3D` | 0-based control polygons $P_0..P_n$ |
| `Max_Degree` | Hard degree cap ($16$) |
| `Status` | `Ok` / `Extrapolated` / `Empty` / `Degree_Too_High` / `Dimension_Error` |
| `Eval_Result_*` | Point/value + `Stat` + `Success` |
| `Split_Result_*` | `Left`, `Right`, `Degree`, `Stat`, `Success` |
| `Lerp`, `Near`, `Dist`, `Add`, `Sub`, `Scale` | Geometry helpers |
| `Binomial`, `Bernstein` | Basis for direct evaluation |
| `Evaluate` / `Evaluate_Bernstein` | De Casteljau vs Bernstein |
| `Split` | Subdivide at $t$ |
| `Make_Line_*`, `Make_Quadratic_2D`, `Make_Cubic_*` | Builders |
| `Make_Example_2D` / `_1D` | Canonical teaching polygons |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production CAGD
  kernel.
- **$O(n^{2})$ per evaluation** — acceptable for $n\le 16$; faster methods
  (Horner on converted bases, forward differencing, GPU shaders) exist.
- **Extrapolation** — $t\notin[0,1]$ is permitted with `Extrapolated` status;
  geometric meaning is the polynomial extension, not an arc-length clamp.
- **Bernstein cross-check** — intended for tiny degrees; large binomial
  coefficients can lose `Float` accuracy before De Casteljau does.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pde_casteljau.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `de_casteljau.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
de_casteljau.ads
de_casteljau.adb
de_casteljau.gpr
tests.adb
```

## References

1. [Wikipedia: De Casteljau's algorithm](https://en.wikipedia.org/wiki/De_Casteljau's_algorithm)
2. Farin, *Curves and Surfaces for CAGD* — classical treatment of Bernstein /
   Bézier form and subdivision.
3. Sibling READMEs (upcoming): De Boor, Spline interpolation, Neville,
   Polynomial interpolation.
