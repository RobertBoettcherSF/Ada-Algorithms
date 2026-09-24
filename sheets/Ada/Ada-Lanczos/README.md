# Lanczos Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the **Lanczos
algorithm** for a real **symmetric** (Hermitian) matrix $A$: build an
orthonormal Krylov basis $V_m$ and a real symmetric **tridiagonal** $T_m$ by
the three-term recurrence, then read **Ritz values** as the eigenvalues of
$T_m$.

$$
\beta_{j+1} v_{j+1} = A v_j - \alpha_j v_j - \beta_j v_{j-1}.
$$

Equivalently $A V_m = V_m T_m + \beta_{m+1} v_{m+1} e_m^\top$. Cap $n\le 32$,
dense educational `Float`. **Full reorthogonalization** is recommended (and
the default) because plain Float Lanczos quickly loses orthogonality.

Based on [Wikipedia: Lanczos algorithm](https://en.wikipedia.org/wiki/Lanczos_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Power-Iteration](https://github.com/RobertBoettcherSF/Ada-Power-Iteration)** — dominant eigenpair (multiply-and-normalize)
- **[Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm)** — dense QR eigenvalue iteration
- **[Ada-Gram-Schmidt](https://github.com/RobertBoettcherSF/Ada-Gram-Schmidt)** — classical / modified orthonormalization
- **Ada-Arnoldi** — upcoming (nonsymmetric Krylov / Hessenberg)
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Orthonormal Krylov + tridiagonal $T_m$ | Three-term recurrence |
| **α, β** | $\alpha_j=v_j^\top A v_j$, $\beta_{j+1}=\|w\|$ | Stored in `Alphas` / `Betas` |
| **Reorth** | Full: $w\leftarrow w-\sum_i (w^\top v_i)v_i$ | Default `Reorthogonalize` |
| **Ritz** | Eigenvalues of $T_m$ (Jacobi sketch) | Sorted ascending |
| **Stop** | $m$ steps or $\beta_{j+1}\le$ `Tol` | `Breakdown` = invariant subspace |
| **Status** | `Ok` … `Not_Symmetric` | Incl. `Ill_Started` |
| **Builders** | Diagonal / Poisson / known spectrum | Teaching matrices |
| **Dim** | $n,m\le 32$ | `Max_N = 32` |

## Brief history

**Cornelius Lanczos** introduced the method in the early 1950s as a way to
tridiagonalize symmetric matrices via Krylov subspaces. Interest faded while
Householder reductions dominated dense eigenproblems, then returned with the
Kaniel–Paige theory and practical **reorthogonalization** (notably Ojalvo &
Newman, 1970) for large sparse engineering eigenproblems. Today Lanczos (and
its nonsymmetric cousin **Arnoldi**) underpins iterative eigensolvers and
related Krylov methods.

## Algorithm (this package)

Given symmetric $A\in\mathbb{R}^{n\times n}$, a nonzero start $v_0$, and
parameters `(M, Tol, Reorthogonalize, Max_QR_Iter)`:

1. Set $v_1\leftarrow v_0/\|v_0\|$, $\beta_1\leftarrow 0$, $v_0\leftarrow 0$.
2. For $j=1,2,\ldots$ up to $M$ (clipped to $n$):
   - $w\leftarrow A v_j$, $\alpha_j\leftarrow v_j^\top w$.
   - $w\leftarrow w-\alpha_j v_j-\beta_j v_{j-1}$.
   - Optionally **fully reorthogonalize** $w$ against $v_1,\ldots,v_j$.
   - $\beta_{j+1}\leftarrow\|w\|$. If $\beta_{j+1}\le$ `Tol`, return
     `Breakdown` (invariant Krylov subspace).
   - Else $v_{j+1}\leftarrow w/\beta_{j+1}$.
3. Form the $m\times m$ tridiagonal $T_m$ with diagonal $\alpha_j$ and
   subdiagonal $\beta_2,\ldots,\beta_m$ (`Betas(j)` stores $\beta_{j+1}$).
4. Diagonalize $T_m$ with an inlined **symmetric Jacobi** sketch (budget
   `Max_QR_Iter` sweeps). Eigenvalues are the **Ritz values**.
5. If the Lanczos basis $V$ is kept, ambient **Ritz vectors** are
   $Y=V Z$ where $T_m Z=Z\Theta$.

$$
T_m=\begin{pmatrix}
\alpha_1&\beta_2&&&\\
\beta_2&\alpha_2&\beta_3&&\\
&\ddots&\ddots&\ddots&\\
&&\beta_{m-1}&\alpha_{m-1}&\beta_m\\
&&&\beta_m&\alpha_m
\end{pmatrix}.
$$

## Loss of orthogonality

In exact arithmetic the three-term recurrence keeps the $v_j$ orthonormal. In
`Float`, roundoff makes new vectors drift into earlier directions; spurious
copies of extreme Ritz values are a classic symptom. This package therefore
defaults to **full reorthogonalization**. Turn it off only to demonstrate the
instability educationally — not for reliable spectra.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Parameters` | `M`, `Tol`, `Reorthogonalize`, `Max_QR_Iter`, `Keep_V` |
| `Status` | `Ok` / `Breakdown` / `Iteration_Limit` / `Ill_Started` / `Dimension_Error` / `Not_Symmetric` |
| `Result` | `Alphas`, `Betas`, `Ritz_Values`, `V`, `Ritz_Vectors`, `Steps`, `Stat`, `Success` |
| `Dot`, `Norm2`, `Mat_Vec`, `Near`, `Is_Symmetric` | Helpers |
| `Orthogonality_Residual` | $\max\|(V^\top V)_{ij}-\delta_{ij}\|$ |
| `Make_Tridiagonal` | Dense $T$ from $\alpha$/$\beta$ |
| `Make_Diagonal`, `Make_Poisson_1D`, `Make_Known_Spectrum_Symmetric` | Builders |
| `Build_Tridiagonal` | Three-term recurrence only |
| `Run` / `Iterate` | Recurrence + Jacobi Ritz extraction |
| `Ritz_Vector`, `Ritz_Residual_Norm` | Ambient Ritz helpers |

## Limits and caveats

- **Float instability without reorth** — prefer `Reorthogonalize => True`.
- **Educational dense** — every step uses a full matvec / dense $V$; fine for
  $n,m\le 32$, not a production sparse eigensolver.
- **Symmetric required** — nonsymmetric $A$ returns `Not_Symmetric` (see
  upcoming **Ada-Arnoldi** for Hessenberg Krylov).
- **Small $n,m$** — Jacobi on $T_m$ is $O(m^3)$ per solve; intended for
  teaching, not large-scale spectra.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Planczos.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `lanczos.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
lanczos.ads
lanczos.adb
lanczos.gpr
tests.adb
```

## References

1. [Wikipedia: Lanczos algorithm](https://en.wikipedia.org/wiki/Lanczos_algorithm)
2. Sibling READMEs: Ada-Power-Iteration, Ada-QR-Algorithm, Ada-Gram-Schmidt
   (linked above); Ada-Arnoldi and an eigenvalue survey upcoming.
3. Classical numerical linear algebra texts (Golub–Van Loan, Trefethen–Bau,
   Parlett) on Krylov methods and Lanczos reorthogonalization.
