# Rayleigh Quotient Iteration — Ada 2023

Educational, self-contained Ada 2023 package implementing **Rayleigh quotient
iteration (RQI)** for Hermitian / symmetric matrices: inverse iteration with
the Rayleigh quotient as a dynamically updated shift. Near an eigenpair the
method converges **cubically** for symmetric $A$.

The Rayleigh quotient is

$$
R(A,x)=\frac{x^\top A x}{x^\top x}.
$$

Each iteration solves a dense shifted system and renormalizes:

$$
\begin{aligned}
(A-\mu_k I)\,y &= x_k,\\
x_{k+1} &= \frac{y}{\|y\|},\\
\mu_{k+1} &= R(A,x_{k+1}).
\end{aligned}
$$

Cap $n\le 16$, dense educational `Float`, self-contained GEPP for
$(A-\mu I)y=x$.

Based on [Wikipedia: Rayleigh quotient iteration](https://en.wikipedia.org/wiki/Rayleigh_quotient_iteration).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gram-Schmidt](https://github.com/RobertBoettcherSF/Ada-Gram-Schmidt)** — classical / modified orthonormalization
- **Power method** — upcoming
- **Inverse iteration** — upcoming
- **QR algorithm** — upcoming
- **Lanczos algorithm** — upcoming
- **Arnoldi iteration** — upcoming
- **Eigenvalue methods survey** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Inverse iteration + Rayleigh shift | Local cubic rate (symmetric) |
| **Quotient** | $R(A,x)=(x^\top A x)/(x^\top x)$ | `Rayleigh_Quotient` |
| **Step** | Solve $(A-\mu I)y=x$, normalize | Dense GEPP each step |
| **Stop** | $\|Ax-\mu x\|_2\le$ `Tol` | Or `Max_Iter` / singular shift |
| **Status** | `Converged` … `Dimension_Error` | Incl. `Singular_Shift` |
| **Builders** | Diagonal / Poisson / Hilbert / randomish | Known spectra for tests |
| **Dim** | $n\le 16$ | `Max_N = 16` |

## Brief history

Rayleigh quotient iteration extends **inverse iteration** by replacing a fixed
shift with the Rayleigh quotient of the current vector. For Hermitian
matrices Ostrowski and others established the **cubic** local convergence;
Wikipedia emphasizes that a good initial guess is essential to land in the
attraction basin of a desired eigenpair. In practice only a few iterations
are needed once the iterate is close.

## Algorithm (this package)

Given a symmetric (or Hermitian) $A$, a nonzero start $x_0$, and optional
$\mu_0$:

1. Normalize $x_0$; set $\mu_0:=R(A,x_0)$ unless the caller supplies a shift.
2. For $k=0,1,2,\ldots$ until the residual is small or the budget is spent:
   - Solve $(A-\mu_k I)y=x_k$ (dense GEPP).
   - If the shift makes the system singular: accept as converged when
     $\|Ax-\mu x\|$ is already small, otherwise return `Singular_Shift`.
   - Set $x_{k+1}=y/\|y\|$ and $\mu_{k+1}=R(A,x_{k+1})$.
3. Report the approximate eigenpair $(\mu,x)$ and residual
   $\|Ax-\mu x\|_2$.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Iter`, optional `Initial_Mu` |
| `Status` | `Converged` / `Iteration_Limit` / `Singular_Shift` / `Breakdown` / `Ill_Started` / `Dimension_Error` |
| `Rayleigh_Quotient` | $R(A,x)$ |
| `Eigen_Residual`, `Eigen_Residual_Norm` | $Ax-\mu x$ and its $2$-norm |
| `Solve_Shifted` | Educational GEPP for $(A-\mu I)y=x$ |
| `Make_Diagonal`, `Make_Symmetric_Example` | Teaching matrices |
| `Iterate` / `Solve` | Rayleigh quotient iteration |

## Limits and caveats

- **Dense GEPP every step** — $O(n^3)$ per iteration; fine for $n\le 16$, not
  a production sparse eigensolver (no shift-invert Arnoldi / Lanczos).
- **Educational `Float`** — no extended precision; ill-conditioned Hilbert
  examples need looser tolerances.
- **Needs a good initial guess** for the cubic local rate; a poor start may
  converge to a different eigenpair or hit `Iteration_Limit`.
- When $\mu$ is already an exact eigenvalue, $A-\mu I$ is singular; the
  package treats a tiny residual as success and otherwise reports
  `Singular_Shift`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Prayleigh_quotient_iteration.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `rayleigh_quotient_iteration.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
rayleigh_quotient_iteration.ads
rayleigh_quotient_iteration.adb
rayleigh_quotient_iteration.gpr
tests.adb
```

## References

1. [Wikipedia: Rayleigh quotient iteration](https://en.wikipedia.org/wiki/Rayleigh_quotient_iteration)
2. Ostrowski, A. M. — classical analysis of the cubic rate for Hermitian RQI.
3. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
