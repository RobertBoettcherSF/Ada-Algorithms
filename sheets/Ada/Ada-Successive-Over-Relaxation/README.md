# Successive Over-Relaxation (SOR) — Ada 2023

Educational, self-contained Ada 2023 package implementing the classical
**Successive Over-Relaxation (SOR)** method of **David M. Young Jr.** and
**Stanley P. Frankel** (1950) for dense linear systems $Ax=b$. SOR
extrapolates the **Gauss–Seidel** update with a relaxation factor
$\omega\in(0,2)$; the special case $\omega=1$ is exactly Gauss–Seidel
(exposed here as `Solve_Gauss_Seidel`).

Based on [Wikipedia: Successive over-relaxation](https://en.wikipedia.org/wiki/Successive_over-relaxation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel)** — forthcoming classical GS smoother
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver
- **[Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm)** — $O(n)$ tridiagonal TDMA
- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — forthcoming dense GE / GEPP

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Extrapolated Gauss–Seidel | Young / Frankel (1950) |
| **Update** | $(1-\omega)x_i + (\omega/a_{ii})(\cdots)$ | Uses new left / old right |
| **$\omega$** | $(0,2)$; $\omega=1$ is GS | Over-relax $\omega>1$, under $\omega<1$ |
| **Stop** | $\|r\|_2\le$ `Tol` or `Max_Iter` | Default budget $10\,000$ |
| **Builders** | DD / Poisson 1D / diag+ones | `Make_Example` |
| **Checks** | Residual, row DD, symmetry | Teaching helpers |
| **Cap** | $n\le 32$ | `Max_N = 32` dense |

## Brief history

Over-relaxation ideas predate digital computers (Richardson, Southwell), but
**Young** and **Frankel** (1950) formulated SOR so that a fixed $\omega$ could
be applied automatically on early machines. For consistently ordered SPD
matrices with known Jacobi spectral radius $\mu$, an optimal
$\omega_{\mathrm{opt}}$ can roughly quarter the asymptotic error constant
relative to Gauss–Seidel.

## Problem statement

Solve the square system

$$
A x = b,\qquad A\in\mathbb{R}^{n\times n},\quad x,b\in\mathbb{R}^{n}.
$$

Write $A=D+L+U$ with $D$ the diagonal, $L$ the strict lower triangle, and
$U$ the strict upper triangle. Gauss–Seidel uses newly computed components
immediately; SOR blends the old value with that Gauss–Seidel candidate via
$\omega$.

## SOR iteration (this package)

Component form (Wikipedia):

$$
x_i^{(k+1)}
=
(1-\omega)\,x_i^{(k)}
+
\frac{\omega}{a_{ii}}
\left(
b_i
-
\sum_{j<i} a_{ij}\,x_j^{(k+1)}
-
\sum_{j>i} a_{ij}\,x_j^{(k)}
\right),
\quad i=1,\ldots,n.
$$

Equivalently, in matrix notation,

$$
x^{(k+1)}
=
(1-\omega)\,x^{(k)}
+
\omega\,D^{-1}
\bigl(b - L x^{(k+1)} - U x^{(k)}\bigr).
$$

Convergence for the classical SOR operator requires
$\omega\in(0,2)$ (necessary when $A$ is SPD). A practical sufficient
condition for many educational examples is **strict diagonal dominance**
(or SPD Poisson-type structure). This package iterates until
$\|b-Ax\|_2\le$ `Tol` or the iteration budget is exhausted.

When $\omega=1$ the update collapses to classical **Gauss–Seidel**;
`Solve_Gauss_Seidel` is a thin wrapper that forces $\omega=1$.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Parameters` | `Omega`, `Tol`, `Max_Iter` (`0` ⇒ default budget) |
| `Result` | `X`, `Iterations`, `Success`, `Residual` (+ `N`, `Stat`) |
| `Mat_Vec`, `Dot`, `Norm2` | Dense BLAS-1/2 helpers |
| `Is_Symmetric`, `Is_Diagonally_Dominant` | Light structural checks |
| `Residual`, `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Make_Example` | DD / Poisson 1D / diag+ones builders |
| `Solve_SOR` | Young/Frankel successive over-relaxation |
| `Solve_Gauss_Seidel` | Wrapper with $\omega=1$ |

## Limits and caveats

- **Dense $n\le 32$**, educational `Float` — not a production sparse /
  multigrid smoother; no red–black ordering, no SSOR, no Chebyshev
  acceleration.
- **$\omega\in(0,2)$** is enforced; values outside that open interval
  return `Bad_Omega`. A zero / tiny diagonal returns `Zero_Diagonal`.
- Convergence is **not guaranteed** for arbitrary $A$. Prefer strictly
  diagonally dominant or SPD Poisson-ish systems (the builders). Optimal
  $\omega$ depends on the spectrum and is not computed here.
- Finite-precision residuals may stall above machine epsilon; choose `Tol`
  accordingly (defaults are teaching-oriented).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Psuccessive_over_relaxation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `successive_over_relaxation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
successive_over_relaxation.ads
successive_over_relaxation.adb
successive_over_relaxation.gpr
tests.adb
```

## References

1. Young, D. M., Jr. (1950). *Iterative methods for solving partial
   difference equations of elliptic type* (doctoral thesis).
2. Frankel, S. P. (1950). Convergence rates of iterative treatments of
   partial differential equations. *Mathematical Tables and Other Aids to
   Computation*.
3. [Wikipedia: Successive over-relaxation](https://en.wikipedia.org/wiki/Successive_over-relaxation)
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
