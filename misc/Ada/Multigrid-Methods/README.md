# Multigrid methods — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Multigrid method](https://en.wikipedia.org/wiki/Multigrid_method):
**geometric multigrid** for the model elliptic problem $-u''=f$ on a
uniform 1D hierarchy ($H=2h$). Classroom focus:

- discrete **1D Poisson** operator $(-1,2,-1)/h^{2}$
- **weighted Jacobi** ($\omega=2/3$) and **Gauss–Seidel** smoothers
- **restriction** (injection / full-weighting $1$-$2$-$1$) and **linear prolongation**
- **two-grid** V-cycle and recursive geometric **V-cycle**
- coarsest solve via embedded **Thomas (TDMA)**

Multigrid accelerates iterative solvers for discrete elliptic PDEs by
damping high-frequency error cheaply with a few smoother sweeps on the
fine grid, then correcting the remaining smooth error on a coarser grid
where it is inexpensive to resolve.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15). Grid arrays
mirror the sibling **Ada-Finite-Difference-Method** /
**Ada-Partial-Differential-Equation** style (no `with` of those packages).

Part of the **RobertBoettcherSF** Ada algorithm series.

Siblings: [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method)
(FD stencils, Poisson, FTCS heat),
[Ada-Partial-Differential-Equation](https://github.com/RobertBoettcherSF/Ada-Partial-Differential-Equation)
(PDE taxonomy + 1D sketches),
[Ada-Crank-Nicolson](https://github.com/RobertBoettcherSF/Ada-Crank-Nicolson)
(implicit heat). Upcoming: **Linear Multistep**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Operator** | `Apply_Poisson_1D` | $(-u_{j-1}+2u_j-u_{j+1})/h^{2}$ |
| **Smooth** | `Smooth_Jacobi` / `Smooth_Gauss_Seidel` | $\nu$ sweeps; $\omega=2/3$ |
| **Restrict** | `Restrict_Injection` / `Restrict_Full_Weighting` | Fine $\to$ coarse |
| **Prolong** | `Prolong_Linear` | Coarse $\to$ fine |
| **Coarse** | `Solve_Coarse_Thomas` | Direct 1D Poisson |
| **Cycles** | `Two_Grid_V_Cycle` / `V_Cycle` | Geometric $H=2h$ |
| **Wrapper** | `Solve_Poisson_MG` | Several V-cycles from zero |
| **Metrics** | `Residual_L2`, `L2_Error`, `Max_Error` | Diagnostics |
| **Domain error** | `Invalid_Argument` | Bad $h$, sizes, $\omega$ |

## Method

### Why multigrid?

On a fine mesh the discrete Laplacian has eigenvalues spanning many
orders of magnitude. Stationary iterations (Jacobi / Gauss–Seidel)
damp **oscillatory** (high-frequency) error modes in a few sweeps, but
**smooth** (low-frequency) modes converge slowly — their effective
wavelength is resolved better on a coarser grid of spacing $H=2h$.

### Discrete 1D Poisson

On $[0,1]$ with Dirichlet ends, nodes $x_j=(j-1)h$ ($j=1,\ldots,N$,
$h=1/(N-1)$, $N=2^{L}+1$) the operator is

$$
(Au)_j=\frac{-u_{j-1}+2u_j-u_{j+1}}{h^{2}},\qquad j=2,\ldots,N-1,
$$

with residual $r=f-Au$ set to zero at the endpoints.

### Smoothers

Weighted Jacobi with the classic 1D damping $\omega=2/3$:

$$
u_j\leftarrow(1-\omega)u_j+\omega\cdot\frac{u_{j-1}+u_{j+1}+h^{2}f_j}{2}.
$$

Gauss–Seidel uses the newest left neighbour in the same stencil.

### Intergrid transfers

For nested grids with $N_c=(N_f-1)/2+1$:

- **Injection:** $u^H_j=u^h_{2j-1}$
- **Full weighting:** $u^H_j=\frac14 u^h_{2j-2}+\frac12 u^h_{2j-1}+\frac14 u^h_{2j}$ (ends copied)
- **Linear prolongation:** odd fine nodes copy coarse; even nodes average neighbours

Full weighting is (up to a constant factor) the $L^{2}$-adjoint of
linear prolongation — the combination used in the V-cycle residual
transfer here.

### V-cycle sketch

One geometric V-cycle with pre-/post-smoothing counts $\nu_1,\nu_2$:

1. **Pre-smooth:** $\nu_1$ sweeps of Jacobi / GS on $A_h u=f_h$
2. **Restrict residual:** $r_H=R(f_h-A_h u)$
3. **Coarse solve / recurse:** approximate $A_H e_H=r_H$ (Thomas on the coarsest grid with $\ge 3$ points; otherwise recurse with spacing $2h$)
4. **Correct:** $u\leftarrow u+P e_H$
5. **Post-smooth:** $\nu_2$ smoother sweeps

$$
\begin{aligned}
&\textbf{pre-smooth}\rightarrow
\textbf{restrict }r\rightarrow
\textbf{recurse / Thomas}\rightarrow
\textbf{prolong}+ \textbf{correct}\rightarrow
\textbf{post-smooth}.
\end{aligned}
$$

A **two-grid** cycle is the same with a single coarse Thomas solve
instead of recursion. Convergence for this model problem is typically
**mesh-independent**: a fixed number of V-cycles drives the residual
down by a roughly constant factor regardless of $h$.

### Full Multigrid (FMG) — README only

**Full Multigrid (FMG)** nested iteration (solve on the coarsest grid,
prolong as a first guess, then V-cycle on each finer level) often
reaches discretization accuracy in the cost of a small multiple of one
fine-grid residual evaluation. This package implements V-cycles and a
multi-cycle wrapper `Solve_Poisson_MG`; FMG / W-cycles / FAS
(nonlinear) are left as reading extensions.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Grid`, `Max_Points` ($=257$) | Domain model |
| Sample | `Sample`, `X_At`, `Coarse_Length` | Geometry |
| Operator | `Apply_Poisson_1D` | Discrete $-u''$ |
| Smooth | `Smooth_Jacobi`, `Smooth_Gauss_Seidel` | High-frequency damping |
| Transfer | `Restrict_*`, `Prolong_Linear` | $R$, $P$ |
| Coarse | `Solve_Coarse_Thomas` | Embedded TDMA |
| Cycles | `Two_Grid_V_Cycle`, `V_Cycle` | Geometric MG |
| Solve | `Solve_Poisson_MG` | Multi V-cycle wrapper |
| Metrics | `Residual_L2`, `L2_Error`, `Max_Error`, `Near`, … | Errors |
| Errors | `Invalid_Argument` | Bad $h$, sizes, $\omega$ |

Strong typing uses `Positive_Real` / `Non_Negative` / `Point_Count` where
helpful. Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Uniform 1D geometric hierarchy ($N=2^{k}+1$, $H=2h$)
- Weighted Jacobi / Gauss–Seidel for $-u''=f$ with Dirichlet BCs
- Injection, full-weighting, linear prolongation
- Two-grid and recursive V-cycle; embedded Thomas on the coarsest level
- Manufactured $u=\sin(\pi x)$ residual / accuracy tests vs pure Jacobi

Out of scope:

- Algebraic multigrid (AMG), unstructured / adaptive meshes
- 2D/3D geometric MG, anisotropic coarsening
- FAS for nonlinear problems, W-cycles, FMG implementation
- Production PETSc / hypre-style frameworks

## Usage

```ada
with Multigrid_Methods; use Multigrid_Methods;
with Ada.Numerics.Generic_Elementary_Functions;

declare
   package Elem is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use Elem;
   Pi : constant Real := Ada.Numerics.Pi;
   N  : constant Point_Count := 65;          -- 2^6 + 1
   H  : constant Real := 1.0 / Real (N - 1);

   function Rhs (X : Real) return Real is (Pi * Pi * Sin (Pi * X));
   function Sample_Rhs is new Sample (Rhs);

   F : constant Grid := Sample_Rhs (N, H);
   U : Grid (1 .. N) := [others => 0.0];
begin
   for Cycle in 1 .. 5 loop
      V_Cycle (U, F, H, Level => 4, Nu_1 => 2, Nu_2 => 2);
   end loop;
   --  U ≈ sin(π x) on [0,1]
end;
```

```ada
declare
   U : constant Grid :=
     Solve_Poisson_MG (F, H, N_Cycles => 6, Nu_1 => 2, Nu_2 => 2);
begin
   null;  -- multi V-cycle from zero guess
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `Grid` / `Real` / `Max_Points` | 1D samples / digits-15 Real / cap $257=2^{8}+1$ |
| `Sample` / `X_At` / `Coarse_Length` | Analytic $\to$ grid; geometry |
| `Apply_Poisson_1D` | Discrete $Au$ (ends $0$) |
| `Smooth_Jacobi` | Weighted Jacobi ($\omega=2/3$ default) |
| `Smooth_Gauss_Seidel` | Lexicographic GS |
| `Restrict_Injection` | Odd-index injection |
| `Restrict_Full_Weighting` | $1$-$2$-$1$ restriction |
| `Prolong_Linear` | Linear interpolation |
| `Solve_Coarse_Thomas` | Direct Poisson (embedded TDMA) |
| `Two_Grid_V_Cycle` | One two-grid cycle |
| `V_Cycle` | Recursive V-cycle (`Level`, $\nu_1$, $\nu_2$) |
| `Solve_Poisson_MG` | Several V-cycles from zero |
| `Residual_L2` / `L2_Error` / `Max_Error` | Diagnostics |
| `Near` / `Abs_Error` / `Vec_Near` | Comparison helpers |
| `Invalid_Argument` | Domain errors |

## Limitations / caveats

- Educational **Long_Float-class** arithmetic (`Real` digits 15): not
  arbitrary precision; `Max_Points = 257`.
- Geometric 1D only; fine grids must have odd length so that
  $N_c=(N_f-1)/2+1$ is an integer $\ge 2$ (coarsest Thomas needs
  $\ge 3$).
- Residual transfer uses **full weighting**; injection is exposed for
  teaching / mode checks.
- Thomas is embedded for the coarsest correction; for a full TDMA API
  see Ada-Thomas-Algorithm / Ada-Finite-Difference-Method siblings.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pmultigrid_methods.gpr
make test     # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `multigrid_methods.ads` | Package spec |
| `multigrid_methods.adb` | Package body |
| `multigrid_methods.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Multigrid method](https://en.wikipedia.org/wiki/Multigrid_method)
- [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method) (sibling FD / Poisson)
- [Ada-Partial-Differential-Equation](https://github.com/RobertBoettcherSF/Ada-Partial-Differential-Equation) (sibling PDE survey)
- [Ada-Crank-Nicolson](https://github.com/RobertBoettcherSF/Ada-Crank-Nicolson) (sibling implicit heat)
- Briggs, W. L., Henson, V. E., and McCormick, S. F. *A Multigrid Tutorial* (SIAM).
- Trottenberg, U., Oosterlee, C. W., and Schüller, A. *Multigrid*.
