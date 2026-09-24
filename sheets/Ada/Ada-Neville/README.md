# Neville's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing **Neville's
algorithm** for **polynomial interpolation evaluation**. Given distinct
abscissae $x_0,\ldots,x_n$ and values $y_i$, the unique polynomial $p$ of
degree at most $n$ with $p(x_i)=y_i$ is evaluated at a query $x$ by filling a
recursive tableau:

$$
\begin{aligned}
p_{i,i}(x) &= y_i,\\
p_{i,j}(x)
&=
\frac{(x-x_i)\,p_{i+1,j}(x)-(x-x_j)\,p_{i,j-1}(x)}{x_j-x_i},
\qquad 0\le i<j\le n,\\
p(x) &= p_{0,n}(x).
\end{aligned}
$$

Cap degree $n\le 16$, educational `Float`. Optional full tableau for teaching
and a **Lagrange** form cross-check for small $n$.

Based on [Wikipedia: Neville's algorithm](https://en.wikipedia.org/wiki/Neville's_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **[Ada-De-Casteljau](https://github.com/RobertBoettcherSF/Ada-De-Casteljau)** — Bézier evaluation / subdivision
- **[Ada-De-Boor](https://github.com/RobertBoettcherSF/Ada-De-Boor)** — B-spline evaluation
- **Polynomial interpolation** — upcoming
- **Pareto** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Recursive tableau $p_{i,j}$ | Same unique interpolant as Lagrange / Newton |
| **Evaluate** | $p(x)=p_{0,n}(x)$ | In-place $O(n^{2})$ Float ops |
| **Tableau** | Full upper triangle | `Evaluate_Tableau` for education |
| **Oracle** | Lagrange $\sum y_i\ell_i(x)$ | Tiny $n$ cross-check only |
| **Status** | `Ok` … `Ill_Started` | Incl. `Duplicate_Abscissa` |
| **Builders** | Linear / quad / Runge / sine | Packed `Sample` |
| **Degree** | $n\le 16$ | `Max_Degree = 16` |

## Brief history

Eric Harold Neville published the iterative interpolation scheme in 1934. It
is closely related to Newton divided differences and to Aitken's algorithm,
but organises the work as a tableau of nested linear interpolants. The method
evaluates the interpolant at one $x$ without forming monomial coefficients —
convenient for teaching and for modest-degree extrapolation tables. Complexity
is $O(n^{2})$ arithmetic operations per evaluation.

## Algorithm (this package)

Given distinct $x_0,\ldots,x_n$ and $y_0,\ldots,y_n$, and a query $x$:

1. Validate lengths ($\le 17$ points), reject duplicate abscissae.
2. Set $p_{i,i}\leftarrow y_i$.
3. For increasing span $j-i=1,\ldots,n$, apply the recurrence above.
4. Return $p_{0,n}(x)$.

An equivalent column form (Wikipedia “alternate notation”) overwrites a
length-$(n+1)$ work vector in place for `Evaluate`. `Evaluate_Tableau` keeps
the dense triangle for inspection of intermediate $p_{i,j}$.

## API summary

| Symbol | Role |
| --- | --- |
| `Abscissae`, `Ordinates` | 0-based $x_i$, $y_i$ arrays |
| `Sample` | Packed $X(0..N)$, $Y(0..N)$, `Valid` |
| `Tableau` | Dense $p_{i,j}$ storage |
| `Max_Degree` / `Max_Points` | Cap $n\le 16$ (17 points) |
| `Status` | `Ok` / `Duplicate_Abscissa` / `Too_Few_Points` / `Dimension_Error` / `Ill_Started` |
| `Eval_Result` | `Value` + `Stat` + `Success` |
| `Tableau_Result` | Full table + `Value` + `N` |
| `Near`, `Is_Distinct`, `Degree_Of` | Helpers |
| `Validate` | Pre-check before evaluate |
| `Evaluate` / `Evaluate_Tableau` | Neville core |
| `Evaluate_Lagrange` | Oracle for small $n$ |
| `Make_Linear`, `Make_Quadratic_Sample` | Builders |
| `Make_Runge_Sample`, `Make_Sine_Sample` | Classic samples |
| `Make_Example` | Dispatch by `Example_Kind` |
| `Slice_X` / `Slice_Y` | Views into a `Sample` |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  numerics library.
- **$O(n^{2})$ per evaluation** — fine for $n\le 16$; forming a Newton basis
  once is better for many queries.
- **Runge phenomenon** — high-degree interpolation on equally spaced nodes
  (e.g. the Runge sample $1/(1+25x^{2})$ on $[-1,1]$) can oscillate wildly
  between nodes; prefer Chebyshev nodes or piecewise/spline methods in
  practice.
- **Lagrange cross-check** — intended for tiny $n$; products of many factors
  lose `Float` accuracy before Neville's nested form does.
- **Duplicates** — coincident or near-coincident $x_i$ are rejected
  (`Duplicate_Abscissa`); the interpolant is otherwise unique.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pneville.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `neville.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
neville.ads
neville.adb
neville.gpr
tests.adb
```

## References

1. [Wikipedia: Neville's algorithm](https://en.wikipedia.org/wiki/Neville's_algorithm)
2. Neville, E.H.: Iterative interpolation. *J. Indian Math. Soc.* **20**, 87–120 (1934)
3. Press et al., *Numerical Recipes* — §3.1 Polynomial Interpolation and Extrapolation
4. Sibling READMEs: Ada-Spline-Interpolation, Ada-De-Casteljau, Ada-De-Boor;
   upcoming Polynomial interpolation, Pareto
