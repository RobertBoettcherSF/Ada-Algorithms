# Jacobi Eigenvalue Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the **Jacobi
eigenvalue algorithm** (Jacobi diagonalization) for a real **symmetric**
matrix $S$. Repeated plane rotations $G(i,j,\theta)$ (Givens / Jacobi
rotations) drive $S$ toward diagonal form while accumulating eigenvectors:

$$
S \leftarrow G^\top S G,\qquad V \leftarrow V G.
$$

When the off-diagonal Frobenius mass is small, the eigenvalues are the
diagonal entries of the final $S$ and the eigenvectors are the columns of
$V$. Cap $n\le 16$, dense educational `Float`.

**This is not** the Jacobi iterative method for linear systems $Ax=b$ (that
belongs to the Gauss–Seidel / SOR family). See
**[Ada-System-of-Linear-Equations](https://github.com/RobertBoettcherSF/Ada-System-of-Linear-Equations)**
and sibling iterative solvers.

Based on [Wikipedia: Jacobi eigenvalue algorithm](https://en.wikipedia.org/wiki/Jacobi_eigenvalue_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm)** — dense QR eigenvalue iteration
- **[Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos)** — Krylov / tridiagonal Ritz values
- **[Ada-Power-Iteration](https://github.com/RobertBoettcherSF/Ada-Power-Iteration)** — dominant eigenpair
- **[Ada-Rayleigh-Quotient-Iteration](https://github.com/RobertBoettcherSF/Ada-Rayleigh-Quotient-Iteration)** — cubic local eigenpair iteration
- **Inverse iteration** — upcoming
- **Arnoldi iteration** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Plane rotations $G(i,j,\theta)$ | Zero one off-diagonal at a time |
| **Update** | $S\leftarrow G^\top S G$, $V\leftarrow VG$ | Similarity; accumulate evecs |
| **Stop** | $\mathrm{OffDiag}(S)\le$ `Tol` | Frobenius off-diagonal norm |
| **Modes** | `Cyclic` / `Classical` | Sweep all pairs vs largest $\|s_{ij}\|$ |
| **Status** | `Converged` … `Not_Symmetric` | Incl. `Iteration_Limit` |
| **Builders** | Diagonal / Poisson / Hilbert / known | Known spectra for tests |
| **Dim** | $n\le 16$ | `Max_N = 16`; **dense** — destroys sparsity |

## Brief history

Carl Gustav Jacob Jacobi proposed the method in **1846**. It saw wide use in
the 1950s with early computers and remains attractive for moderate dense
symmetric eigenproblems and for parallel / hardware implementations (disjoint
index pairs commute). Production dense eigensolvers usually prefer
tridiagonal reduction plus QR / divide-and-conquer, but Jacobi's conceptual
clarity and quadratic convergence of sweeps make it an excellent teaching
algorithm.

## Algorithm (this package)

Given a real symmetric $n\times n$ matrix $S$:

1. Set $V:=I$ and work on a copy of $S$.
2. While $\mathrm{OffDiag}(S)>$ `Tol` and the sweep budget remains:
   - **Cyclic** (default): for every pair $1\le i<j\le n$, choose $\theta$ so
     that the $(i,j)$ entry of $G^\top S G$ vanishes, then apply the update.
   - **Classical**: repeatedly find the largest $|s_{ij}|$ and rotate that
     pivot.
3. Read $\lambda_k\approx s_{kk}$ and eigenvector columns from $V$.
4. Optionally sort eigenvalues ascending and permute $V$ (`Sort_Eigs`).

Angle choice (educational stable form via $\tau=\tan\theta$):

$$
\tan(2\theta)=\frac{2s_{ij}}{s_{jj}-s_{ii}}
\quad\text{(or }\theta=\pi/4\text{ if }s_{ii}=s_{jj}\text{)}.
$$

**Dense method.** Jacobi draws little or no advantage from sparsity and
**destroys** banding / sparsity by fill-in. Prefer Krylov methods (Lanczos /
Arnoldi) for large sparse problems.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Sweeps`, `Mode`, `Sort_Eigs` |
| `Status` | `Converged` / `Iteration_Limit` / `Not_Symmetric` / `Ill_Started` / `Dimension_Error` |
| `Diagonalize` / `Eigenpairs` | Full symmetric eigenpairs |
| `Apply_Rotation` | One educational $G(p,q,\theta)$ on $(S,V)$ |
| `Off_Diag_Norm`, `Mat_Mul`, `Near`, `Is_Symmetric` | Helpers |
| `Eigen_Residual`, `Mat_Eigen_Residual` | $Ax-\lambda x$ and $\|AV-V\Lambda\|_F$ |
| `Make_Diagonal`, `Make_Symmetric_Known`, … | Teaching matrices |

## Limits and caveats

- **Symmetric only** — nonsymmetric input returns `Not_Symmetric`.
- **Educational `Float`** — no extended precision; ill-conditioned Hilbert
  examples need careful tolerances for larger $n$.
- **Dense only** — $O(n^3)$ work per sweep; fine for $n\le 16$, not a sparse
  production eigensolver.
- **Not $Ax=b$ Jacobi** — do not confuse with the Jacobi iterative linear
  solver (row-wise fixed-point for diagonally dominant systems).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pjacobi_eigenvalue.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `jacobi_eigenvalue.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
jacobi_eigenvalue.ads
jacobi_eigenvalue.adb
jacobi_eigenvalue.gpr
tests.adb
```

## References

1. [Wikipedia: Jacobi eigenvalue algorithm](https://en.wikipedia.org/wiki/Jacobi_eigenvalue_algorithm)
2. Jacobi, C. G. J. — Über ein leichtes Verfahren die in der Theorie der
   Säkularstörungen vorkommenden Gleichungen numerisch aufzulösen, 1846.
3. Golub & Van Loan — *Matrix Computations* (Jacobi methods chapter).
4. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
