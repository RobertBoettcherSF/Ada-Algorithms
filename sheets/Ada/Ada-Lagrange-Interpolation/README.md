# Lagrange Interpolation — Ada 2023

Educational, self-contained Ada 2023 package implementing **Lagrange
polynomial interpolation**. Given distinct abscissae $x_0,\ldots,x_n$ and
values $y_i$, the unique polynomial $p$ of degree at most $n$ with
$p(x_i)=y_i$ is written in the classical Lagrange basis:

$$
p(x)=\sum_{i=0}^{n} y_i\,\ell_i(x),\qquad
\ell_i(x)=\prod_{j\neq i}\frac{x-x_j}{x_i-x_j}.
$$

The package also implements the **barycentric** first and second forms for
education. With weights

$$
w_i=\frac{1}{\prod_{j\neq i}(x_i-x_j)},
$$

the forms are

$$
\begin{aligned}
\text{first:}\quad
p(x)
&=
\ell(x)\sum_{i=0}^{n}\frac{w_i}{x-x_i}\,y_i,
\qquad
\ell(x)=\prod_{j=0}^{n}(x-x_j),\\
\text{second:}\quad
p(x)
&=
\frac{\sum_{i=0}^{n}\frac{w_i}{x-x_i}\,y_i}
{\sum_{i=0}^{n}\frac{w_i}{x-x_i}}.
\end{aligned}
$$

Cap degree $n\le 16$, educational `Float`. Optional `Basis_Polynomial` exposes
$\ell_i(x)$. Cross-check helpers verify classical $\equiv$ barycentric; nodes
are exact by construction (within Float).

Based on [Wikipedia: Lagrange polynomial](https://en.wikipedia.org/wiki/Lagrange_polynomial).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Neville](https://github.com/RobertBoettcherSF/Ada-Neville)** — Neville tableau evaluation
- **[Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation)** — survey (Lagrange / Newton / Neville / monomial)
- **[Ada-Linear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Linear-Interpolation)** — lerp / piecewise-linear tables
- **Hermite** — upcoming
- **Cubic** — upcoming
- **Birkhoff** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Classical $\sum y_i\ell_i(x)$ | Unique degree-$\le n$ interpolant |
| **Basis** | $\ell_i(x)=\prod_{j\neq i}(x-x_j)/(x_i-x_j)$ | `Basis_Polynomial` |
| **Barycentric** | Weights $w_i$; first / second form | Second preferred numerically |
| **Cross-check** | Classical $\equiv$ barycentric | `Forms_Agree` |
| **Status** | `Ok` … `Ill_Started` | Incl. `Duplicate_Abscissa` |
| **Builders** | Linear / quad / Runge / sine | Packed `Sample` |
| **Degree** | $n\le 16$ | `Max_Degree = 16` |

## Brief history

Joseph-Louis Lagrange published the barycentric-looking product form of the
interpolating polynomial in the late 18th century (the modern “Lagrange
formula”). The same unique interpolant appears in Newton divided-difference
and Neville tableau presentations; the classical product basis is pedagogically
transparent ($\ell_i(x_k)=\delta_{ik}$) but can be numerically fragile for
large $n$. The **barycentric** rewrite (first and especially second form)
reuses stable weights $w_i$ and is preferred for repeated evaluation.

## Algorithm (this package)

Given distinct $x_0,\ldots,x_n$ and $y_0,\ldots,y_n$, and a query $x$:

1. Validate lengths ($\le 17$ points), reject duplicate abscissae.
2. **Classical:** for each $i$, form $\ell_i(x)$ as a product over $j\neq i$,
   accumulate $\sum y_i\ell_i(x)$.
3. **Barycentric:** build $w_i=1/\prod_{j\neq i}(x_i-x_j)$ once; if $x=x_k$
   return $y_k$; else evaluate first or second form.
4. Optional: expose a single $\ell_i(x)$ via `Basis_Polynomial`.

Complexity is $O(n^{2})$ per classical evaluation; barycentric is $O(n)$ per
query after $O(n^{2})$ weight setup.

## API summary

| Symbol | Role |
| --- | --- |
| `Abscissae`, `Ordinates` | 0-based $x_i$, $y_i$ arrays |
| `Weights` | Barycentric $w_i$ storage |
| `Sample` | Packed $X(0..N)$, $Y(0..N)$, `Valid` |
| `Max_Degree` / `Max_Points` | Cap $n\le 16$ (17 points) |
| `Status` | `Ok` / `Duplicate_Abscissa` / `Too_Few_Points` / `Dimension_Error` / `Ill_Started` |
| `Eval_Result` | `Value` + `Stat` + `Success` |
| `Weight_Result` | `W(0..N)` + `N` + status |
| `Barycentric_Form` | `First_Form` / `Second_Form` |
| `Near`, `Is_Distinct`, `Degree_Of` | Helpers |
| `Validate` | Pre-check before evaluate |
| `Build_Weights` | $w_i=1/\prod_{j\neq i}(x_i-x_j)$ |
| `Evaluate` | Classical $\sum y_i\ell_i(x)$ |
| `Basis_Polynomial` | Single $\ell_i(x)$ |
| `Evaluate_Barycentric` | First / second form (default second) |
| `Forms_Agree` | Classical $\equiv$ both barycentric forms |
| `Make_Linear`, `Make_Quadratic_Sample` | Builders |
| `Make_Runge_Sample`, `Make_Sine_Sample` | Classic samples |
| `Make_Example` | Dispatch by `Example_Kind` |
| `Slice_X` / `Slice_Y` | Views into a `Sample` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  numerics library.
- **Runge phenomenon** — high-degree interpolation on equally spaced nodes
  (e.g. the Runge sample $1/(1+25x^{2})$ on $[-1,1]$) can oscillate wildly
  between nodes; prefer Chebyshev nodes or piecewise/spline methods in
  practice.
- **Barycentric preferred numerically** — classical products of many factors
  lose `Float` accuracy sooner; reuse `Build_Weights` + second form for
  repeated queries.
- **Duplicates** — coincident or near-coincident $x_i$ are rejected
  (`Duplicate_Abscissa`); the interpolant is otherwise unique.
- **Sibling survey** — Ada-Polynomial-Interpolation already lists Lagrange as
  one form among Newton / Neville / monomial; this package focuses deeply on
  the Lagrange basis and barycentric variants.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Plagrange_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `lagrange_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
lagrange_interpolation.ads
lagrange_interpolation.adb
lagrange_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Lagrange polynomial](https://en.wikipedia.org/wiki/Lagrange_polynomial)
2. Berrut, J.-P., Trefethen, L.N.: Barycentric Lagrange interpolation.
   *SIAM Rev.* **46**(3), 501–517 (2004)
3. Press et al., *Numerical Recipes* — §3.1 Polynomial Interpolation
4. Sibling READMEs: Ada-Neville, Ada-Polynomial-Interpolation,
   Ada-Linear-Interpolation; upcoming Hermite, Cubic, Birkhoff
