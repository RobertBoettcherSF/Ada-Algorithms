# Thomas Algorithm (TDMA) — Ada 2023

Educational, self-contained Ada 2023 package implementing the **tridiagonal
matrix algorithm** (TDMA), also known as the **Thomas algorithm** (after
Llewellyn Thomas): a simplified $O(n)$ form of Gaussian elimination for
tridiagonal linear systems

$$
a_i x_{i-1} + b_i x_i + c_i x_{i+1} = d_i,\qquad i=1,\ldots,n,
$$

with the boundary convention $a_1=0$ and $c_n=0$. Cap $n\le 256$, dense
educational `Float`.

Based on [Wikipedia: Tridiagonal matrix algorithm](https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — forthcoming dense GE / GEPP
- **[Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel)** — forthcoming iterative smoother
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver
- **[Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)** — COO / CSR / CSC + SpMV

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Specialized GE for tridiagonal $A$ | No fill beyond the three diagonals |
| **Forward** | Compute modified $c'_i$, $d'_i$ | Eliminate subdiagonal |
| **Back-sub** | $x_n=d'_n$, then $x_i=d'_i-c'_i x_{i+1}$ | $O(n)$ |
| **Stability** | Diagonally dominant or SPD | Else prefer GEPP |
| **Builders** | Poisson 1D $(-1,2,-1)$ / constant | `Make_Poisson_1D*` |
| **Checks** | Residual $\|r\|_2$, row DD | Teaching helpers |
| **Cap** | $n\le 256$ | `Max_N = 256` |

## Brief history

Thomas' algorithm is classical specialized Gaussian elimination for
tridiagonal systems. Such matrices arise from **1-D Poisson** discretizations,
natural cubic splines, and many finite-difference schemes. The method uses
only $O(n)$ storage and arithmetic—far cheaper than general dense GE's
$O(n^3)$.

## Problem statement

In matrix form the system is

$$
\begin{bmatrix}
b_1 & c_1 & & & 0 \\
a_2 & b_2 & c_2 & & \\
 & a_3 & b_3 & \ddots & \\
 & & \ddots & \ddots & c_{n-1} \\
0 & & & a_n & b_n
\end{bmatrix}
\begin{bmatrix} x_1 \\ x_2 \\ x_3 \\ \vdots \\ x_n \end{bmatrix}
=
\begin{bmatrix} d_1 \\ d_2 \\ d_3 \\ \vdots \\ d_n \end{bmatrix}.
$$

## Method (this package)

**Forward sweep** (new coefficients denoted with primes):

$$
c'_i =
\begin{cases}
\dfrac{c_i}{b_i}, & i=1, \\
\dfrac{c_i}{b_i - a_i c'_{i-1}}, & i=2,3,\ldots,n-1,
\end{cases}
\qquad
d'_i =
\begin{cases}
\dfrac{d_i}{b_i}, & i=1, \\
\dfrac{d_i - a_i d'_{i-1}}{b_i - a_i c'_{i-1}}, & i=2,3,\ldots,n.
\end{cases}
$$

**Back substitution:**

$$
x_n = d'_n,\qquad
x_i = d'_i - c'_i x_{i+1},\quad i=n-1,n-2,\ldots,1.
$$

If any pivot denominator satisfies $|\mathrm{denom}|\le$ `Pivot_Tol`, the
solver returns status **`Degenerate`** (zero / tiny pivot).

## Stability

Thomas' algorithm is **not stable in general**, but is stable for several
important classes—notably when the matrix is **diagonally dominant** (by
rows or columns) or **symmetric positive definite**. This package exposes
`Is_Diagonally_Dominant` / `Is_Strictly_Diagonally_Dominant` as educational
screens. For general nonsingular tridiagonals, prefer Gaussian elimination
with partial pivoting (GEPP)—see the forthcoming Ada-Gaussian-Elimination
sibling.

Row diagonal dominance means

$$
|b_i| \ge |a_i| + |c_i|
\quad\text{for all } i
$$

(with $a_1=c_n=0$).

## API summary

| Symbol | Role |
| --- | --- |
| `Vector` | 1-based educational `Float` array |
| `Max_N` | Hard dimension cap ($256$) |
| `Status` | `Ok`, `Degenerate`, `Ill_Started`, `Size_Mismatch` |
| `Result` | `X`, `N`, `Stat`, `Success`, `Pivot` |
| `Thomas` / `Solve` | Non-mutating TDMA (alias pair) |
| `Thomas_In_Place` | Overwrites $C,D$ with $c',d'$; writes $X$ |
| `Make_Poisson_1D` | Diagonals $(-1,2,-1)$ |
| `Make_Poisson_1D_System` | Diagonals + RHS |
| `Make_Constant_Tridiagonal` | Constant $a,b,c$ with corner zeros |
| `Is_Diagonally_Dominant` | Row DD screen |
| `Residual` / `Residual_Norm` | $r=d-Tx$ and $\|r\|_2$ |
| `Near`, `Vec_Near`, `Norm2` | Numeric helpers |

Convention: callers should set $A(1)=0$ and $C(N)=0$; the residual helper
ignores wrap-around terms at the ends.

## Limits and caveats

- **$n\le 256$**, educational `Float` — not a production sparse / blocked /
  parallel tridiagonal solver; no cyclic (periodic) Thomas, no Sherman–Morrison
  correction, no block-tridiagonal variant.
- **Stability** requires diagonal dominance or SPD (or similar Higham
  conditions). Zero / tiny pivots yield `Degenerate`.
- Inputs to `Thomas` / `Solve` are **not** modified; `Thomas_In_Place`
  overwrites $C$ and $D$.
- Residual checks use the original $A,B,C,D$ against the computed $X$.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pthomas_algorithm.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `thomas_algorithm.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
thomas_algorithm.ads
thomas_algorithm.adb
thomas_algorithm.gpr
tests.adb
```

## References

1. [Wikipedia: Tridiagonal matrix algorithm](https://en.wikipedia.org/wiki/Tridiagonal_matrix_algorithm)
2. Higham, N. J. *Accuracy and Stability of Numerical Algorithms* (pivot /
   stability discussion for Thomas).
3. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
