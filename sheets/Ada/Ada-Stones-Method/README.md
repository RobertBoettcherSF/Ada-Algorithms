# Stone's Method (SIP) — Ada 2023

Educational, self-contained Ada 2023 package implementing **Stone's method**,
also known as the **Strongly Implicit Procedure (SIP)**, of **Harold S. Stone**
(1968). SIP builds an **incomplete LU** factorization of $A$ that keeps the
same five-point sparsity pattern as a 2D discrete Laplacian, then iterates a
residual correction $x\leftarrow x+M^{-1}r$ with $M=LU$. A parameter $\alpha$
approximately cancels neglected fill into the diagonal (Stone's compensation).

Based on [Wikipedia: Stone's method](https://en.wikipedia.org/wiki/Stone%27s_method).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Successive-Over-Relaxation](https://github.com/RobertBoettcherSF/Ada-Successive-Over-Relaxation)** — Young/Frankel SOR
- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — iterative SPD Krylov solver
- **[Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm)** — $O(n)$ tridiagonal TDMA
- **[Ada-Sparse-Matrix](https://github.com/RobertBoettcherSF/Ada-Sparse-Matrix)** — sparse matrix primitives

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Incomplete $LU\approx A$ as $M$ | Stone (1968) SIP |
| **Fill** | Keep five-point pattern | $\alpha$ compensates neglected terms |
| **Iterate** | $r=b-Ax$, $z=M^{-1}r$, $x\leftarrow x+z$ | Equiv. $Mx^{k+1}=Nx^{k}+b$ |
| **$\alpha$** | $[0,1]$; classic CFD $\approx 0.92$ | $\alpha=0$ ≈ plain ILU(0)-like |
| **Stop** | $\|r\|_2\le$ `Tol` or `Max_Iter` | Default budget $5\,000$ |
| **Builders** | Poisson 2D / 1D / DD | `Make_Poisson_2D`, `Make_Example` |
| **Compare** | Jacobi / Gauss–Seidel | Optional dense helpers |
| **Cap** | $n\le 64$ | `Max_N = 64` ($N_{\mathrm{grid}}\le 8$) |

## Brief history

Exact **LU** is an excellent general solver, but the factors of a sparse matrix
are usually dense, so memory and work explode for large grids. Stone (1968)
proposed an **incomplete** factorization whose $L$ and $U$ keep the same
pentadiagonal structure as the five-point stencil arising from elliptic PDEs
in 2D, then used $M=LU$ inside a stationary iteration. The distinctive SIP
ingredient is an approximate cancellation of the two neglected fill diagonals
via a scalar $\alpha$.

Full SIP details vary by textbook and CFD code (Ferziger & Perić, Patankar,
etc.); this package documents the formulae it implements explicitly below.

## Problem statement

Solve

$$
A x = b,\qquad A\in\mathbb{R}^{n\times n},\quad x,b\in\mathbb{R}^{n}.
$$

Write $A=M-N$ with $\|M\|\gg\|N\|$ and $M=LU$ incomplete. The Wikipedia
stationary form is

$$
M x^{(k+1)} = N x^{(k)} + b,
$$

which is algebraically equivalent to the residual correction used here:

$$
r^{(k)}=b-A x^{(k)},\qquad
z^{(k)}=M^{-1} r^{(k)},\qquad
x^{(k+1)}=x^{(k)}+z^{(k)}.
$$

## Five-point SIP factorization (Option A)

For an $N\times N$ interior grid ($n=N^{2}$) with coefficients
$A_W,A_E,A_S,A_N,A_P$ (west/east/south/north/center), this package builds

$$
L:\ (L_W,\ L_S,\ L_P),\qquad
U:\ (1,\ U_E,\ U_N)
$$

row by row ($i=1,\ldots,n$) with Stone compensation parameter $\alpha\in[0,1]$:

$$
\begin{aligned}
L_{W,i}
&=
\frac{A_{W,i}}{1+\alpha\,U_{N,i-1}},
\\
L_{S,i}
&=
\frac{A_{S,i}}{1+\alpha\,U_{E,i-N}},
\\
P_1
&=
\alpha\,L_{W,i}\,U_{N,i-1},
\qquad
P_2
&=
\alpha\,L_{S,i}\,U_{E,i-N},
\\
L_{P,i}
&=
A_{P,i}+P_1+P_2
- L_{W,i}\,U_{E,i-1}
- L_{S,i}\,U_{N,i-N},
\\
U_{E,i}
&=
\frac{A_{E,i}-P_1}{L_{P,i}},
\qquad
U_{N,i}
&=
\frac{A_{N,i}-P_2}{L_{P,i}}.
\end{aligned}
$$

(Missing neighbours are treated as zero.) Forward substitution on $L$ then
back substitution on $U$ applies $M^{-1}$.

## Dense ILU(0) + Stone tweak (Option B)

`Factor_ILU0` / `Solve_SIP_Dense` perform a Doolittle-style **ILU(0)**
(no fill beyond the sparsity of $A$). When $\alpha>0$, a fraction of each
neglected fill product is added into the pivot row — a dense teaching
analogue of Stone's diagonal compensation. Prefer Option A for structured
Poisson grids.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Pentadiagonal` | Five-point stencil storage ($A_W,A_E,A_S,A_N,A_P$) |
| `SIP_Factors` | Incomplete $L$/$U$ for Option A |
| `Dense_ILU` | Incomplete dense $L$/$U$ for Option B |
| `Max_N` | Hard dimension cap ($64$) |
| `Parameters` | `Alpha`, `Tol`, `Max_Iter` (`0` ⇒ default budget) |
| `Result` | `X`, `Iterations`, `Success`, `Residual` (+ `N`, `Stat`) |
| `Make_Poisson_2D` | Structured five-point discrete Laplacian |
| `Factor_SIP`, `Solve_SIP` | Stone SIP (preferred Option A) |
| `Factor_ILU0`, `Solve_SIP_Dense` | Dense ILU(0)/Stone iteration |
| `Solve_Jacobi`, `Solve_Gauss_Seidel` | Comparison smoothers |
| `Residual`, `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ (dense / penta) |

## Limits and caveats

- **Educational** $n\le 64$, `Float` arithmetic — not a production CFD
  multigrid / SIP3D code. No red–black ordering, no modified Strongly
  Implicit Procedure variants beyond the $\alpha$ compensation above.
- **Published SIP formulae differ** slightly across references; treat the
  displayed equations as the contract of *this* package.
- Convergence is **not guaranteed** for arbitrary $A$. Prefer SPD /
  diagonally dominant Poisson-type systems (the builders).
- $\alpha\notin[0,1]$ returns `Bad_Alpha`. A vanishing incomplete pivot
  returns `Factorization_Failed`.
- Finite-precision residuals may stall above machine epsilon; choose `Tol`
  accordingly (defaults are teaching-oriented). With educational `Float`,
  $\alpha\approx 0.92$ can leave a residual floor near $10^{-5}$ on larger
  grids; values closer to $1$ (e.g. $0.99$) often restore full convergence.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pstones_method.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `stones_method.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
stones_method.ads
stones_method.adb
stones_method.gpr
tests.adb
```

## References

1. Stone, H. L. (1968). Iterative Solution of Implicit Approximations of
   Multidimensional Partial Differential Equations. *SIAM Journal on
   Numerical Analysis*, 5(3), 530–538.
2. Ferziger, J. H. and Perić, M. (2001). *Computational Methods for Fluid
   Dynamics*. Springer.
3. [Wikipedia: Stone's method](https://en.wikipedia.org/wiki/Stone%27s_method)
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
