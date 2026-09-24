# Power Iteration — Ada 2023

Educational, self-contained Ada 2023 package implementing the **power method**
(von Mises iteration) for the **dominant eigenpair** of a diagonalizable
matrix $A$: the eigenvalue of largest absolute value and a corresponding
eigenvector.

Starting from a nonzero $x_0$, each step multiplies by $A$ and renormalizes:

$$
\begin{aligned}
y &= A x_k,\\
x_{k+1} &= \frac{y}{\|y\|},\\
\lambda_k &= R(A,x_{k+1})=\frac{x_{k+1}^\top A x_{k+1}}{x_{k+1}^\top x_{k+1}}.
\end{aligned}
$$

This package estimates $\lambda$ with the **Rayleigh quotient** (preferred over
a single-component ratio). Cap $n\le 32$, dense educational `Float`.

Based on [Wikipedia: Power iteration](https://en.wikipedia.org/wiki/Power_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Rayleigh-Quotient-Iteration](https://github.com/RobertBoettcherSF/Ada-Rayleigh-Quotient-Iteration)** — cubic local eigenpair iteration
- **[Ada-QR-Algorithm](https://github.com/RobertBoettcherSF/Ada-QR-Algorithm)** — dense QR eigenvalue iteration
- **Inverse iteration** — upcoming (power method on $(A-\mu I)^{-1}$)
- **Lanczos algorithm** — upcoming
- **Arnoldi iteration** — upcoming
- **Jacobi eigenvalue algorithm** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Multiply-and-normalize | Dominant $|\lambda|$ eigenpair |
| **λ estimate** | Rayleigh quotient $R(A,x)$ | `Rayleigh_Quotient` |
| **Stop** | $\|Ax-\lambda x\|_2\le$ `Tol` | Or `Max_Iter` / breakdown |
| **Status** | `Converged` … `Dimension_Error` | Incl. `Iteration_Limit` |
| **Builders** | Diagonal / scaled $I$ / Poisson / known | Clear spectral gaps for tests |
| **Dim** | $n\le 32$ | `Max_N = 32` |

## Brief history

Power iteration (also called the **von Mises iteration**) is among the oldest
numerical eigenvalue methods. Convergence is geometric with ratio
$|\lambda_2/\lambda_1|$, so a clear gap between the largest and second-largest
absolute eigenvalues is essential. The method remains attractive for huge
sparse matrices (only matvecs are required) and appears in applications such
as PageRank. Richer cousins — inverse iteration, Rayleigh quotient iteration,
Lanczos / Arnoldi, and the QR algorithm — can be viewed as refinements of the
same multiply-and-normalize idea.

## Algorithm (this package)

Given a square diagonalizable $A$, a nonzero start $x_0$, and parameters
`(Tol, Max_Iter)`:

1. Normalize $x_0$.
2. For $k=1,2,\ldots$ until the residual is small or the budget is spent:
   - Compute $y=A x$; if $\|y\|\approx 0$, return `Breakdown`.
   - Set $x\leftarrow y/\|y\|$ and $\lambda\leftarrow R(A,x)$.
   - Stop when $\|Ax-\lambda x\|_2\le$ `Tol`.
3. Report the approximate eigenpair $(\lambda,x)$, iteration count, and residual.

**Inverse power method** (mentioned only here): applying the same loop to
$(A-\mu I)^{-1}$ targets the eigenvalue nearest a shift $\mu$. That solver is
planned as the sibling **Inverse iteration** package; this repository stays
with plain power iteration.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($32$) |
| `Parameters` | `Tol`, `Max_Iter` |
| `Status` | `Converged` / `Iteration_Limit` / `Breakdown` / `Ill_Started` / `Dimension_Error` |
| `Result` | `Eigenvalue`, `Eigenvector`, `Iterations`, `Residual`, `Stat`, `Success` |
| `Dot`, `Norm2`, `Mat_Vec` | Basic linear-algebra helpers |
| `Rayleigh_Quotient` | $R(A,x)=(x^\top A x)/(x^\top x)$ |
| `Eigen_Residual`, `Eigen_Residual_Norm` | $Ax-\lambda x$ and its $2$-norm |
| `Make_Diagonal`, `Make_Scaled_Identity` | Teaching matrices |
| `Make_Poisson_1D`, `Make_Known_Spectrum_Symmetric` | SPD / known-spectrum builders |
| `Iterate` / `Dominant_Eigenpair` | Power iteration (optional default $x_0=$ ones) |

## Limits and caveats

- **Needs a dominant $|\lambda|$ gap** — if $|\lambda_2/\lambda_1|\approx 1$,
  convergence is slow or stalls at `Iteration_Limit`.
- **Educational `Float`** — no extended precision; residuals and spectra are
  accurate only to ordinary single-precision expectations.
- **Eigenvectors up to sign** — if $Av=\lambda v$ then so does $-v$; tests
  accept either orientation.
- **Dense matvec only** — fine for $n\le 32$; not a production sparse
  eigensolver (no Lanczos / Arnoldi / shift-invert here).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Ppower_iteration.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `power_iteration.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
power_iteration.ads
power_iteration.adb
power_iteration.gpr
tests.adb
```

## References

1. [Wikipedia: Power iteration](https://en.wikipedia.org/wiki/Power_iteration)
2. Sibling READMEs: Ada-Rayleigh-Quotient-Iteration, Ada-QR-Algorithm (linked above).
3. Classical numerical linear algebra texts (Golub–Van Loan, Trefethen–Bau) on
   the power method and its relatives.
