# Arnoldi Iteration — Ada 2023

Educational, self-contained Ada 2023 package implementing the **Arnoldi
iteration** for a general (possibly **nonsymmetric**) matrix $A$: build an
orthonormal Krylov basis $V_m$ and an **upper Hessenberg** $H_m$ by modified
Gram–Schmidt, optionally reading **Ritz values** as eigenvalues of $H_m$ when
$H_m$ is nearly symmetric (solid educational path on symmetric $A$).

$$
A V_m = V_m H_m + h_{m+1,m} v_{m+1} e_m^\top.
$$

Cap $n\le 16$, dense educational `Float`. When $A$ is Hermitian / symmetric,
Arnoldi **reduces to Lanczos**: $H_m$ becomes (real) symmetric tridiagonal.

Based on [Wikipedia: Arnoldi iteration](https://en.wikipedia.org/wiki/Arnoldi_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos)** — Hermitian three-term / tridiagonal Krylov
- **[Ada-Power-Iteration](https://github.com/RobertBoettcherSF/Ada-Power-Iteration)** — dominant eigenpair
- **[Ada-Inverse-Iteration](https://github.com/RobertBoettcherSF/Ada-Inverse-Iteration)** — shift-invert eigenpair
- **[Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm)** — dense QR eigenvalue iteration
- **[Ada-Jacobi-Eigenvalue](https://github.com/RobertBoettcherSF/Ada-Jacobi-Eigenvalue)** — symmetric Jacobi diagonalization
- **[Ada-Gram-Schmidt](https://github.com/RobertBoettcherSF/Ada-Gram-Schmidt)** — classical / modified orthonormalization
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Orthonormal Krylov + Hessenberg $H_m$ | Modified Gram–Schmidt |
| **$H$** | $h_{ij}=v_i^\top A v_j$ (MGS order) | Upper Hessenberg |
| **$h_{m+1,m}$** | Stored as `H_Extra` | Outside $m\times m$ block |
| **Ritz** | Jacobi on nearly-symmetric $H$ | Prefer symmetric $A$ |
| **Stop** | $m$ steps or $h_{j+1,j}\le$ `Tol` | `Breakdown` = invariant subspace |
| **Status** | `Ok` … `Dimension_Error` | Incl. `Ill_Started` |
| **Builders** | Diagonal / Poisson / known / nonsym DD | Teaching matrices |
| **Dim** | $n,m\le 16$ | `Max_N = 16` |

## Brief history

**W. E. Arnoldi** introduced the method in 1951 as a way to reduce a general
matrix to Hessenberg form via Krylov subspaces. It is the nonsymmetric cousin
of the **Lanczos** algorithm: the same idea (orthonormalize $\{v,Av,\ldots\}$)
with full MGS instead of a three-term recurrence. Arnoldi underpins GMRES and
many iterative eigensolvers for nonsymmetric / non-Hermitian spectra.

## Algorithm (this package)

Given $A\in\mathbb{R}^{n\times n}$, a nonzero start $x$, and parameters
`(M, Tol, Max_QR_Iter, Keep_V)`:

1. Set $v_1\leftarrow x/\|x\|$.
2. For $j=1,2,\ldots$ up to $M$ (clipped to $n$):
   - $w\leftarrow A v_j$.
   - For $i=1,\ldots,j$: $h_{ij}\leftarrow v_i^\top w$, then
     $w\leftarrow w-h_{ij} v_i$ (modified Gram–Schmidt).
   - $h_{j+1,j}\leftarrow\|w\|$. If $h_{j+1,j}\le$ `Tol`, return
     `Breakdown` (invariant Krylov subspace).
   - Else $v_{j+1}\leftarrow w/h_{j+1,j}$ (when $j<M$).
3. Form the $m\times m$ upper Hessenberg $H_m$; leftover $h_{m+1,m}$ is
   `H_Extra`.
4. If $H_m$ is **nearly symmetric**, diagonalize it with an inlined
   **symmetric Jacobi** sketch (budget `Max_QR_Iter`). Eigenvalues are the
   **Ritz values** (sorted ascending). This is the solid path for
   **symmetric** $A$, where $H_m\approx$ tridiagonal.
5. For clearly nonsymmetric $H_m$, expose $H$ and $V$ without forcing complex
   / Schur Ritz extraction (educational scope).

$$
H_m=\begin{pmatrix}
h_{11}&h_{12}&h_{13}&\cdots&h_{1m}\\
h_{21}&h_{22}&h_{23}&\cdots&h_{2m}\\
0&h_{32}&h_{33}&\cdots&h_{3m}\\
\vdots&\ddots&\ddots&\ddots&\vdots\\
0&\cdots&0&h_{m,m-1}&h_{mm}
\end{pmatrix}.
$$

## Reduction to Lanczos

When $A=A^\top$ (Hermitian in the complex case), exact arithmetic forces
$H_m$ to be **symmetric tridiagonal**, and the MGS loop collapses to the
Lanczos three-term recurrence. See sibling
**[Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos)**.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `M`, `Tol`, `Max_QR_Iter`, `Keep_V` |
| `Status` | `Ok` / `Breakdown` / `Iteration_Limit` / `Ill_Started` / `Dimension_Error` |
| `Result` | `H`, `V`, `Ritz_Values`, `Steps`, `H_Extra`, `Stat`, `Success` |
| `Dot`, `Norm2`, `Mat_Vec`, `Near`, `Is_Symmetric` | Helpers |
| `Is_Upper_Hessenberg` | Structure check for $H$ |
| `Orthogonality_Residual` | $\max\|(V^\top V)_{ij}-\delta_{ij}\|$ |
| `Arnoldi_Relation_Residual` | $\|A V-V H\|_F$ |
| `Make_Diagonal`, `Make_Poisson_1D`, `Make_Known_Spectrum_Symmetric`, `Make_Nonsymmetric_DD` | Builders |
| `Build_Hessenberg` | MGS recurrence only |
| `Run` / `Iterate` | Recurrence + optional Jacobi Ritz |
| `Ritz_Vector`, `Ritz_Residual_Norm` | Ambient Ritz helpers |

## Limits and caveats

- **Float / small $m$** — dense educational matvecs; fine for $n,m\le 16$, not
  a production sparse eigensolver.
- **Ritz for nonsymmetric $A$** — complex / nonnormal spectra need a real
  Schur or complex QR treatment; this package **exposes $H$ and $V$** and only
  extracts real Ritz when $H$ is nearly symmetric (prefer symmetric tests).
- **Loss of orthogonality** — MGS is used each step; still monitor
  `Orthogonality_Residual` in `Float`.
- **Breakdown** — $h_{j+1,j}\approx 0$ means an invariant Krylov subspace
  (often desirable convergence, not a hard error).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Parnoldi.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `arnoldi.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
arnoldi.ads
arnoldi.adb
arnoldi.gpr
tests.adb
```

## References

1. [Wikipedia: Arnoldi iteration](https://en.wikipedia.org/wiki/Arnoldi_iteration)
2. Sibling READMEs: Ada-Lanczos, Ada-Power-Iteration, Ada-Inverse-Iteration,
   Ada-QR-Algorithm, Ada-Jacobi-Eigenvalue, Ada-Gram-Schmidt (linked above);
   eigenvalue survey upcoming.
3. Classical numerical linear algebra texts (Golub–Van Loan, Trefethen–Bau,
   Saad) on Krylov methods, Arnoldi, and GMRES.
