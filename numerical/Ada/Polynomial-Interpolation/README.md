# Polynomial Interpolation — Ada 2023

Educational, self-contained Ada 2023 **survey + runnable forms** package for
**polynomial interpolation**. Given distinct abscissae $x_0,\ldots,x_n$ and
values $y_i$, there is a **unique** polynomial $p$ of degree at most $n$ with
$p(x_i)=y_i$. This package evaluates that same interpolant in several classical
bases:

$$
\begin{aligned}
\text{Lagrange:}\quad
p(x)
&=
\sum_{i=0}^{n} y_i\,\ell_i(x),
\qquad
\ell_i(x)=\prod_{j\neq i}\frac{x-x_j}{x_i-x_j},\\
\text{Newton:}\quad
p(x)
&=
a_0+a_1(x-x_0)+\cdots+a_n(x-x_0)\cdots(x-x_{n-1}),\\
&\qquad a_k=f[x_0,\ldots,x_k]
\quad\text{(divided differences)},\\
\text{Neville:}\quad
p_{i,i}=y_i,\quad
p_{i,j}
&=
\frac{(x-x_i)\,p_{i+1,j}-(x-x_j)\,p_{i,j-1}}{x_j-x_i},\quad
p(x)=p_{0,n}(x).
\end{aligned}
$$

Optional **monomial** form $\sum c_k x^k$ via Vandermonde + GEPP is offered only
for tiny $n\le 8$ (ill-conditioned catalogue risk). Cap degree $n\le 16$,
educational `Float`. **Self-contained** — Neville is inlined here and does
**not** `with` the Ada-Neville sibling.

Based on [Wikipedia: Polynomial interpolation](https://en.wikipedia.org/wiki/Polynomial_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Neville](https://github.com/RobertBoettcherSF/Ada-Neville)** — Neville tableau focus
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics (prefer under Runge)
- **[Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau)** — Bézier evaluation / subdivision
- **Pareto** — upcoming
- **Tricubic** — upcoming
- **Nearest-neighbor** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Uniqueness** | One $p$ of deg $\le n$ | Distinct $x_i$ required |
| **Lagrange** | $\sum y_i\ell_i(x)$ | Oracle / tiny $n$ |
| **Newton** | DD table + nested eval | Build once, many queries |
| **Neville** | Recursive tableau | Inline; no sibling `with` |
| **Monomial** | Vandermonde + GEPP | Tiny $n\le 8$ only |
| **Taxonomy** | `Method_Kind` / `Recommend` | Runge → spline sibling |
| **Cross-check** | `Forms_Agree` | Lagrange ≡ Newton ≡ Neville |
| **Degree** | $n\le 16$ | `Max_Degree = 16` |

## Brief history

Lagrange (1795) wrote the interpolant as a linear combination of cardinal
basis polynomials. Newton organised the same object via **divided differences**,
enabling stable nested evaluation and cheap updates when a point is added.
Neville (1934) and Aitken gave tableau schemes that evaluate $p(x)$ without
forming coefficients. The monomial / Vandermonde route is pedagogically clear
but numerically fragile for moderate $n$. High-degree interpolation on
equispaced nodes can diverge between nodes — **Runge's phenomenon** — which
motivates piecewise / spline methods.

## Algorithm (this package)

1. Validate lengths ($\le 17$ points) and reject duplicate / near-duplicate
   abscissae (`Duplicate_Abscissa`).
2. **Lagrange:** accumulate $y_i\prod_{j\neq i}(x-x_j)/(x_i-x_j)$.
3. **Newton:** fill divided differences
   $$
   f[x_i]=y_i,\qquad
   f[x_i,\ldots,x_{i+k}]
   =
   \frac{f[x_{i+1},\ldots,x_{i+k}]-f[x_i,\ldots,x_{i+k-1}]}{x_{i+k}-x_i},
   $$
   then evaluate with Horner-like nesting in the Newton basis.
4. **Neville:** in-place column form of the $p_{i,j}$ recurrence (same as the
   Ada-Neville sibling, copied inline for self-containment).
5. **Monomial (optional):** assemble $V_{ij}=x_i^j$, solve $Vc=y$ by GEPP, Horner
   in the monomial basis; refuse $n>\texttt{Max\_Monomial\_Degree}$.

`Forms_Agree` checks that the three main evaluators return pairwise-near values
on the same query.

## Uniqueness and Runge

With distinct $x_i$, the interpolating polynomial of degree at most $n$ is
**unique** — Lagrange, Newton, and Neville are different *representations* of
the same $p$. Uniqueness does **not** imply good approximation of an underlying
$f$ between nodes. The classic Runge example
$f(x)=1/(1+25x^{2})$ on $[-1,1]$ with equispaced nodes shows wild oscillation as
$n$ grows. Practical remedies: Chebyshev nodes, or abandon a single global
polynomial in favour of **splines** (see Ada-Spline-Interpolation) or local
methods (upcoming nearest-neighbor / tricubic).

## API summary

| Symbol | Role |
| --- | --- |
| `Abscissae`, `Ordinates` | 0-based $x_i$, $y_i$ arrays |
| `Sample` | Packed $X(0..N)$, $Y(0..N)$, `Valid` |
| `Tableau`, `Newton_Coeffs`, `Monomial_Coeffs` | Storage types |
| `Max_Degree` / `Max_Points` / `Max_Monomial_Degree` | Caps $16$ / $17$ / $8$ |
| `Status` | `Ok` / `Duplicate_Abscissa` / `Too_Few_Points` / `Dimension_Error` / `Ill_Started` / `Singular` |
| `Eval_Result`, `DD_Result`, `Tableau_Result`, `Monomial_Result` | Result records |
| `Method_Kind`, `Recommend` | Taxonomy + educational notes |
| `Near`, `Is_Distinct`, `Degree_Of` | Helpers |
| `Validate` | Pre-check before evaluate |
| `Evaluate_Lagrange` | Lagrange form |
| `Build_Divided_Differences` | Newton DD table + $a_k$ |
| `Evaluate_Newton` | Nested Newton eval (build+eval or coeffs) |
| `Evaluate_Neville` / `Evaluate_Neville_Tableau` | Neville core |
| `Fit_Monomial` / `Evaluate_Monomial` | Optional Vandermonde path |
| `Forms_Agree` | Cross-check three main forms |
| `Make_Linear`, `Make_Quadratic_Sample` | Builders |
| `Make_Runge_Sample`, `Make_Sine_Sample` | Classic samples |
| `Make_Example` | Dispatch by `Example_Kind` |
| `Slice_X` / `Slice_Y` | Views into a `Sample` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  numerics library.
- **Global degree-$n$ poly** — fine for teaching and tiny $n$; for equispaced
  high $n$ prefer the spline sibling.
- **Vandermonde** — intentionally capped; GEPP may return `Singular` on
  pathological data.
- **Lagrange products** — lose accuracy before Newton / Neville for larger $n$.
- **Duplicates** — coincident or near-coincident $x_i$ are rejected.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Ppolynomial_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `polynomial_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
polynomial_interpolation.ads
polynomial_interpolation.adb
polynomial_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Polynomial interpolation](https://en.wikipedia.org/wiki/Polynomial_interpolation)
2. [Wikipedia: Neville's algorithm](https://en.wikipedia.org/wiki/Neville's_algorithm)
3. [Wikipedia: Newton polynomial](https://en.wikipedia.org/wiki/Newton_polynomial)
4. Press et al., *Numerical Recipes* — §3.1 Polynomial Interpolation and Extrapolation
5. Sibling READMEs: Ada-Neville, Ada-Spline-Interpolation, Ada-De-Casteljau;
   upcoming Pareto / Tricubic / Nearest-neighbor
