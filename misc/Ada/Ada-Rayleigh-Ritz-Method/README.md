# Rayleigh–Ritz Method (Ada 2023)

Educational, self-contained Ada 2023 package implementing the classical
**matrix Rayleigh–Ritz procedure** (also called the **Ritz method**) from
[Wikipedia: Ritz method](https://en.wikipedia.org/wiki/Ritz_method)
(Rayleigh–Ritz method): Rayleigh quotient, modified Gram–Schmidt
orthonormalization, projected eigenproblem $T=Q^T A Q$, a small dense
symmetric Jacobi eigensolver, Ritz pairs, optional generalized
$A\mathbf{x}=\lambda B\mathbf{x}$, residuals, and a 1-D discrete Laplacian /
spring-mass trial-subspace demo.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Naming and history

The technique is attributed to **Lord Rayleigh** (*Theory of Sound*, 1877)
and **Walther Ritz** (1908–1909). Historians debate priority; Courant
emphasized that both independently used the equivalence between boundary-value
problems for PDEs and problems of the calculus of variations, replacing an
infinite-dimensional variational problem by a finite-parameter extremum.
Related names in applications: **Ritz–Galerkin** in the finite-element
method, trial-wavefunction / variational methods in quantum mechanics, and
modal approximation in structural vibration.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Rayleigh quotient** | $R(A,x)=(x^T A x)/(x^T x)$ | Exact on eigenvectors |
| **Orthonormalize** | Modified Gram–Schmidt | Rank detection |
| **Projection** | $T=Q^T A Q$ | Compression to trial space |
| **Small eigen** | Jacobi (+ analytic $2\times 2$) | $k\le 8$ |
| **Ritz pairs** | values $\Theta$, vectors $QY$ | Approximations to $(A,\lambda)$ |
| **Generalized** | $T y=\theta S y$, $S=Q^T B Q$ | Cholesky + standard eigen |
| **Demo** | Discrete 1-D Laplacian | Exact $\lambda_j=2-2\cos(\cdot)$ |

## Variational idea

For a self-adjoint operator (or Hermitian / real symmetric matrix) the
**Rayleigh quotient**

$$
R(A,x)=\frac{x^T A x}{x^T x}
$$

is stationary precisely at eigenvectors, and its value there is the
corresponding eigenvalue. Restricting $x$ to a trial subspace
$\mathrm{span}\{q_1,\ldots,q_k\}$ and enforcing orthonormality yields a
finite-dimensional eigenproblem for the **compression** of $A$ onto that
subspace — the Rayleigh–Ritz method.

## Matrix algorithm

Given symmetric $A\in\mathbb{R}^{n\times n}$ and a basis matrix
$Q\in\mathbb{R}^{n\times k}$ with orthonormal columns:

1. Form the projected matrix $T=Q^T A Q\in\mathbb{R}^{k\times k}$.
2. Solve the small dense eigenproblem $T Y = Y \Theta$ (diagonal $\Theta$).
3. **Ritz values** are the diagonal entries of $\Theta$; **Ritz vectors**
   are $\tilde{X}=Q Y$.

When $k=1$, $Q$ is a single unit vector $v$ and the method reduces to
evaluating $R(A,v)$. If the column space of $Q$ is invariant under $A$
(or contains exact eigenvectors), the corresponding Ritz pairs are exact.
The residual $\|A\tilde{x}_i-\tilde{\lambda}_i\tilde{x}_i\|$ is an easily
computed accuracy check.

### Wikipedia $3\times 3$ example

For

$$
A=\begin{bmatrix}2&0&0\\0&2&1\\0&1&2\end{bmatrix}
$$

with eigenvalues $1,2,3$, the trial basis spanning the last two coordinate
axes yields Ritz values $1$ and $3$ with exact eigenvectors — because that
subspace is $A$-invariant.

### Generalized problem

For $A\mathbf{x}=\lambda B\mathbf{x}$ with $B$ SPD, form
$T=Q^T A Q$ and $S=Q^T B Q$, then solve $T y=\theta S y$ (via Cholesky
$S=LL^T$ and a standard eigenproblem on $L^{-1}T L^{-T}$).

## Discrete Laplacian demo

The 1-D Dirichlet discrete Laplacian (spring-mass / finite-difference
stiffness) on $n$ interior nodes is the tridiagonal matrix with $2$ on the
diagonal and $-1$ on the off-diagonals. Exact eigenpairs:

$$
\lambda_j=2-2\cos\Bigl(\frac{\pi j}{n+1}\Bigr),\qquad
(v_j)_i=\sin\Bigl(\frac{\pi j i}{n+1}\Bigr).
$$

Fourier (discrete sine) trial columns recover exact modes; polynomial trial
subspaces approximate the lowest eigenvalues from above (Courant–Fischer /
monotonicity for SPD operators: enlarging the trial space cannot increase
the lowest Ritz value).

## Applications (brief)

- **Finite-element / Galerkin** methods (Ritz–Galerkin).
- **Quantum mechanics**: variational approximation of ground and excited
  states with trial wavefunctions.
- **Structural / mechanical vibration**: approximate eigenmodes and resonant
  frequencies.
- **Numerical linear algebra**: post-processing orthonormal bases from Krylov
  / LOBPCG / subspace iteration into Ritz pairs.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vector`, `Matrix`, `Basis`, `Small_*` | Dense 1-based arrays; `Max_N=32`, `Max_K=8` |
| Helpers | `Near`, `Dot`, `Norm`, `Norm2`, `Scale`, `Axpy`, `Mat_Vec` | Numerics |
| Residual | `Residual_Norm` | $\|Ax-\theta x\|_2$ |
| Quotient | `Rayleigh_Quotient` | $R(A,x)$ |
| MGS | `Orthonormalize`, `Is_Orthonormal` | Trial basis cleanup |
| Project | `Project_QtAQ`, `Project_QtBQ` | $Q^T A Q$, $Q^T B Q$ |
| Eigen | `Jacobi_Symmetric`, `Eigen_2x2` | Small symmetric solves |
| Ritz | `Ritz_Extract` | Standard Rayleigh–Ritz |
| Gen. Ritz | `Ritz_Extract_Generalized` | $A x=\lambda B x$ |
| Demo | `Discrete_Laplacian`, `Laplacian_Exact_*`, `*_Trial_Basis` | 1-D Laplacian |

Strong typing uses domain subtypes (`Non_Negative`, `Dim_N`, …). Public
subprograms carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Rank_Deficient`,
`Degenerate`.

## Build and test

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Prayleigh_ritz_method.gpr
make test                 # runs bin/tests; expect Fail_Count=0 and ≥100 PASS
```

Requirements: GNAT (GCC Ada) with Ada 2022/2023 support.

## Layout

Exactly seven root entries (no `main.adb`):

1. `rayleigh_ritz_method.ads`
2. `rayleigh_ritz_method.adb`
3. `rayleigh_ritz_method.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- [Wikipedia: Ritz method](https://en.wikipedia.org/wiki/Ritz_method)
  (Rayleigh–Ritz method)
- Trefethen & Bau, *Numerical Linear Algebra* (matrix RR formulation)
- Leissa, “The historical bases of the Rayleigh and Ritz methods,”
  *Journal of Sound and Vibration* (2005)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
