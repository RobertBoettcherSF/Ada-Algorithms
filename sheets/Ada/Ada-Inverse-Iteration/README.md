# Inverse Iteration — Ada 2023

Educational, self-contained Ada 2023 package implementing **inverse iteration**
(the **inverse power method**) for an eigenpair nearest a fixed shift $\mu$.
It is power iteration applied to $(A-\mu I)^{-1}$: each step solves a dense
shifted linear system and renormalizes.

$$
\begin{aligned}
(A-\mu I)\,y &= x_k,\\
x_{k+1} &= \frac{y}{\|y\|},\\
\lambda_k &\approx R(A,x_{k+1})=\frac{x_{k+1}^\top A x_{k+1}}{x_{k+1}^\top x_{k+1}}
\end{aligned}
$$

(alternatively $\lambda\approx\mu+1/(x_k^\top y)$). Cap $n\le 16$, dense
educational `Float`, self-contained GEPP for $(A-\mu I)y=x$.

**Sibling note:** [Rayleigh quotient iteration](https://en.wikipedia.org/wiki/Rayleigh_quotient_iteration)
updates $\mu$ every step ($\mu_k=R(A,x_k)$) for cubic local convergence;
**this package keeps $\mu$ fixed**.

Based on [Wikipedia: Inverse iteration](https://en.wikipedia.org/wiki/Inverse_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Power-Iteration](https://github.com/RobertBoettcherSF/Ada-Power-Iteration)** — dominant eigenpair (multiply-and-normalize)
- **[Ada-Rayleigh-Quotient-Iteration](https://github.com/RobertBoettcherSF/Ada-Rayleigh-Quotient-Iteration)** — cubic local eigenpair iteration (updates $\mu$)
- **[Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm)** — dense QR eigenvalue iteration
- **[Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos)** — Krylov / tridiagonal Ritz values
- **[Ada-Jacobi-Eigenvalue](https://github.com/RobertBoettcherSF/Ada-Jacobi-Eigenvalue)** — Jacobi diagonalization
- **Arnoldi iteration** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Power method on $(A-\mu I)^{-1}$ | Eigenpair nearest fixed $\mu$ |
| **Step** | Solve $(A-\mu I)y=x$, normalize | Dense GEPP; $\mu$ **fixed** |
| **λ estimate** | Rayleigh $R(A,x)$ or $\mu+1/(x^\top y)$ | `Rayleigh_Quotient` |
| **Stop** | $\|Ax-\lambda x\|_2\le$ `Tol` | Or `Max_Iter` / singular shift |
| **Status** | `Converged` … `Dimension_Error` | Incl. `Singular_Shift` |
| **Builders** | Diagonal / Poisson / known spectrum | Known $\lambda$ for tests |
| **Dim** | $n\le 16$ | `Max_N = 16` |

## Brief history

Inverse iteration (inverse power method) was developed to compute resonance
frequencies in structural mechanics when an approximate eigenvalue is already
known. Conceptually it is the power method applied to $(A-\mu I)^{-1}$, so
components along eigenvectors with $\lambda$ near $\mu$ are amplified most.
When $\mu$ is close to a simple eigenvalue the method converges rapidly;
updating $\mu$ with the Rayleigh quotient each step yields **Rayleigh quotient
iteration** (sibling package).

## Algorithm (this package)

Given a square $A$, a shift $\mu$ near a desired eigenvalue, a nonzero start
$x_0$, and parameters `(Tol, Max_Iter, Mu)`:

1. Normalize $x_0$.
2. For $k=1,2,\ldots$ until the residual is small or the budget is spent:
   - Solve $(A-\mu I)y=x$ (dense GEPP) with the **same** $\mu$.
   - If the shift makes the system singular: accept as converged when
     $\|Ax-\lambda x\|$ is already small, otherwise try a tiny solve-only
     perturbation or return `Singular_Shift`.
   - Set $x\leftarrow y/\|y\|$ and estimate $\lambda$ (Rayleigh, or
     $\mu+1/(x^\top y)$).
   - Stop when $\|Ax-\lambda x\|_2\le$ `Tol`.
3. Report the approximate eigenpair $(\lambda,x)$, fixed $\mu$, iteration
   count, and residual.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Iter`, fixed `Mu` |
| `Status` | `Converged` / `Iteration_Limit` / `Singular_Shift` / `Breakdown` / `Ill_Started` / `Dimension_Error` |
| `Result` | `Eigenvalue`, `Eigenvector`, `Iterations`, `Residual`, `Mu`, `Stat`, `Success` |
| `Dot`, `Norm2`, `Mat_Vec` | Basic linear-algebra helpers |
| `Rayleigh_Quotient` | $R(A,x)=(x^\top A x)/(x^\top x)$ |
| `Eigen_Residual`, `Eigen_Residual_Norm` | $Ax-\lambda x$ and its $2$-norm |
| `Solve_Shifted` | Educational GEPP for $(A-\mu I)y=x$ |
| `Make_Diagonal`, `Make_Poisson_1D` | Teaching matrices |
| `Make_Known_Spectrum_Symmetric` | $Q\,D\,Q^\top$ with known spectrum |
| `Iterate` / `Eigenpair_Near` | Inverse iteration (optional default $x_0=$ ones) |

## Limits and caveats

- **Needs a good $\mu$** — the method targets the eigenvalue nearest the
  shift; a poor guess may converge to the wrong eigenpair or stall.
- **Dense GEPP every step** — $O(n^3)$ per iteration; fine for $n\le 16$, not
  a production sparse eigensolver (no shift-invert Arnoldi / Lanczos).
- **Educational `Float`** — no extended precision; residuals and spectra are
  accurate only to ordinary single-precision expectations.
- When $\mu$ is already an exact eigenvalue, $A-\mu I$ is singular; the
  package treats a tiny residual as success and otherwise reports
  `Singular_Shift` (after a tiny solve-only perturbation attempt).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pinverse_iteration.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `inverse_iteration.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
inverse_iteration.ads
inverse_iteration.adb
inverse_iteration.gpr
tests.adb
```

## References

1. [Wikipedia: Inverse iteration](https://en.wikipedia.org/wiki/Inverse_iteration)
2. Sibling READMEs: Ada-Power-Iteration, Ada-Rayleigh-Quotient-Iteration,
   Ada-QR-Algorithm, Ada-Lanczos, Ada-Jacobi-Eigenvalue (linked above).
3. Classical numerical linear algebra texts (Golub–Van Loan, Trefethen–Bau) on
   the inverse power method and Rayleigh quotient iteration.
