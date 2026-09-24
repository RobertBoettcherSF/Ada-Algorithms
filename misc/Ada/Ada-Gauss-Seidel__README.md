# Gauss–Seidel Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the classical
**Gauss–Seidel** iterative method (also known as the **Liebmann** method or
**method of successive displacement**) for dense linear systems $Ax=b$.
Each component update uses newly computed values immediately within the
sweep; only one storage vector is required. This is exactly **SOR with**
$\omega=1$ (see the sibling Successive Over-Relaxation package).

Based on [Wikipedia: Gauss–Seidel method](https://en.wikipedia.org/wiki/Gauss%E2%80%93Seidel_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Successive-Over-Relaxation](https://github.com/RobertBoettcherSF/Ada-Successive-Over-Relaxation)** — Young/Frankel SOR ($\omega\in(0,2)$; $\omega=1$ is GS)
- **[Ada-Jacobi](https://github.com/RobertBoettcherSF/Ada-Jacobi)** — simultaneous (previous-iterate only) displacement
- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — dense GE / GEPP
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver
- **[Ada-Stones-Method](https://github.com/RobertBoettcherSF/Ada-Stones-Method)** — Stone SIP / incomplete LU smoother

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Successive displacement | Gauss / Seidel / Liebmann |
| **Update** | $(1/a_{ii})(b_i - \sum_{j<i}\cdots - \sum_{j>i}\cdots)$ | New left / old right |
| **Relation** | SOR with $\omega=1$ | No Omega parameter here |
| **Stop** | $\|r\|_2\le$ `Tol` or `Max_Iter` | Default budget $10\,000$ |
| **Builders** | DD / Poisson 1D / diag+ones / non-convergent | `Make_Example` |
| **Checks** | Residual, row DD, symmetry | Teaching helpers |
| **Cap** | $n\le 32$ | `Max_N = 32` dense |

## Brief history

Carl Friedrich **Gauss** and Philipp Ludwig von **Seidel** developed early
forms of successive substitution for linear systems arising in surveying and
astronomy. The method became a standard smoother and stand-alone iterative
solver long before digital computers; on modern machines it is often viewed as
the $\omega=1$ special case of **successive over-relaxation** (Young / Frankel,
1950). Wikipedia also records the name **Liebmann method**.

## Problem statement

Solve the square system

$$
A x = b,\qquad A\in\mathbb{R}^{n\times n},\quad x,b\in\mathbb{R}^{n}.
$$

Decompose $A = L_* + U$ where $L_*$ is lower triangular (including the
diagonal) and $U$ is strictly upper triangular. The Gauss–Seidel step is

$$
L_*\, x^{(k+1)} = b - U\, x^{(k)}.
$$

## Gauss–Seidel iteration (this package)

Component form (Wikipedia):

$$
x_i^{(k+1)}
=
\frac{1}{a_{ii}}
\left(
b_i
-
\sum_{j<i} a_{ij}\,x_j^{(k+1)}
-
\sum_{j>i} a_{ij}\,x_j^{(k)}
\right),
\quad i=1,\ldots,n.
$$

The implementation overwrites $x$ **in place**: indices $j<i$ already hold
the new values, while $j>i$ still hold the previous iterate. Convergence is
guaranteed when $A$ is **strictly diagonally dominant**, or **symmetric
positive definite** (SPD), or an invertible H-matrix / irreducibly diagonally
dominant matrix; other matrices may still converge if the spectral radius of
the iteration operator is $<1$. This package stops when $\|b-Ax\|_2\le$ `Tol`
or the iteration budget is exhausted.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Parameters` | `Tol`, `Max_Iter` (`0` ⇒ default budget); no Omega |
| `Result` | `X`, `Iterations`, `Success`, `Residual` (+ `N`, `Stat`) |
| `Status` | `Converged`, `Iteration_Limit`, `Zero_Diagonal`, `Ill_Started`, `Dimension_Error` |
| `Mat_Vec`, `Dot`, `Norm2` | Dense BLAS-1/2 helpers |
| `Is_Symmetric`, `Is_Diagonally_Dominant`, `Is_Strictly_Diagonally_Dominant` | Structural checks |
| `Residual`, `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Make_Example` | DD / Poisson 1D / diag+ones / non-convergent builders |
| `Solve` | Classical Gauss–Seidel (≡ SOR with $\omega=1$) |

## Limits and caveats

- **Dense $n\le 32$**, educational `Float` — each iteration is $O(n^2)$; not a
  production sparse / multigrid smoother; no red–black ordering, no SSOR.
- A zero / tiny diagonal returns `Zero_Diagonal`. Convergence is **not
  guaranteed** for arbitrary $A$. Prefer strictly diagonally dominant or SPD
  Poisson-ish systems (the builders). The `Non_Convergent` example is an
  educational contrast that typically hits `Iteration_Limit`.
- Finite-precision residuals may stall above machine epsilon; choose `Tol`
  accordingly (defaults are teaching-oriented).
- For tunable relaxation, use the sibling **Ada-Successive-Over-Relaxation**
  package ($\omega\in(0,2)$).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgauss_seidel.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `gauss_seidel.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
gauss_seidel.ads
gauss_seidel.adb
gauss_seidel.gpr
tests.adb
```

## References

1. Gauss, C. F.; Seidel, P. L. von — successive substitution for linear
   systems (19th century surveying / astronomy tradition).
2. Young, D. M., Jr. (1950). *Iterative methods for solving partial
   difference equations of elliptic type* (doctoral thesis) — SOR view with
   $\omega=1$ recovering Gauss–Seidel.
3. [Wikipedia: Gauss–Seidel method](https://en.wikipedia.org/wiki/Gauss%E2%80%93Seidel_method)
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
