# Crank–Nicolson method — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Crank–Nicolson method](https://en.wikipedia.org/wiki/Crank%E2%80%93Nicolson_method):
the classic **implicit** finite-difference scheme for the 1D heat equation
$u_t=\alpha u_{xx}$, averaging forward and backward Euler in time with a
central second-difference in space. Classroom focus:

- one **Crank–Nicolson** time step (tridiagonal + embedded Thomas)
- multi-step **advance** with fixed Dirichlet BCs
- $r$-parameter and **Fourier amplification** (unconditional stability)

On a uniform mesh with spacing $h=\Delta x$ and time step $\Delta t$, the
scheme at interior node $j$ is

$$
\frac{u^{n+1}_{j}-u^{n}_{j}}{\Delta t}
=\frac{\alpha}{2}\cdot\frac{\delta^{2}u^{n+1}_{j}+\delta^{2}u^{n}_{j}}{h^{2}},
\qquad
\delta^{2}u_{j}=u_{j-1}-2u_{j}+u_{j+1}.
$$

Letting $r=\alpha\Delta t/(2h^{2})$ this rearranges to the tridiagonal system

$$
-r\,u^{n+1}_{j-1}+(1+2r)\,u^{n+1}_{j}-r\,u^{n+1}_{j+1}
=r\,u^{n}_{j-1}+(1-2r)\,u^{n}_{j}+r\,u^{n}_{j+1},
$$

with Dirichlet boundary values folded into the right-hand side and solved
by an embedded **Thomas (TDMA)** sweep.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15). Grid arrays
mirror the sibling **Ada-Finite-Difference-Method** / **Ada-Lax-Wendroff**
style (no `with` of those packages).

Part of the **RobertBoettcherSF** Ada algorithm series.

Siblings: [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method)
(FD stencils, Poisson, FTCS heat),
[Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff)
(hyperbolic LW step). Upcoming: **PDE survey**, **Multigrid**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **CN step** | `Heat_CN_Step` | One implicit step; Dirichlet ends |
| **Advance** | `Heat_CN_Advance` | $N$ steps, fixed BCs |
| **$r$** | `R_Param` | $r=\alpha\Delta t/(2h^{2})$ |
| **Stability** | `Amplification_Factor`, `Unconditionally_Stable` | $\|A\|\le 1$ for all $r\ge 0$ |
| **Order** | Manufactured $e^{-\pi^{2}\alpha t}\sin(\pi x)$ | $O(\Delta t^{2}+\Delta x^{2})$ |
| **Errors** | `Near`, `Abs_Error`, `L2_Error`, `Max_Error` | Diagnostics |
| **Domain error** | `Invalid_Argument` | Bad $h$, $\Delta t$, $\alpha$, short grids |

## Method

### Averaging explicit and implicit Euler

Forward Euler (FTCS) is explicit but only conditionally stable
($r_{\mathrm{FTCS}}=\alpha\Delta t/h^{2}\le 1/2$). Backward Euler is
unconditionally stable but only first-order in time. Crank–Nicolson
takes the arithmetic mean of the two spatial operators, yielding a
scheme that is **second-order in time and space** and
**unconditionally stable** for the linear heat equation.

### Fourier amplification

For a mode $e^{i\kappa x}$ with phase $\Theta=\kappa h$, the
amplification factor is

$$
A(r,\Theta)=\frac{1-4r\sin^{2}(\Theta/2)}{1+4r\sin^{2}(\Theta/2)}.
$$

For all $r\ge 0$ and all $\Theta$, $|A|\le 1$. (Contrast with FTCS, which
requires $r_{\mathrm{FTCS}}\le 1/2$.) For oscillatory / hyperbolic
problems CN can still produce non-physical ringing; damping or other
schemes may be preferred there.

### Embedded Thomas solve

Each step builds a diagonally dominant tridiagonal system of size
$N-2$ (interior nodes) and solves it with a self-contained Thomas
sweep — no `with` of Ada-Thomas-Algorithm or Ada-Finite-Difference-Method.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Grid`, `Max_Points`, generic `Sample` | Domain model (cap 512) |
| Sample | `Sample`, `X_At` | Analytic $\to$ grid |
| Parameter | `R_Param` | $r=\alpha\Delta t/(2h^{2})$ |
| Stability | `Amplification_Factor`, `Amplification_Bounded`, `Unconditionally_Stable` | Von Neumann checks |
| Parabolic | `Heat_CN_Step`, `Heat_CN_Advance` | Implicit heat stepping |
| Metrics | `L2_Error`, `Max_Error`, `Near`, `Abs_Error`, `Vec_Near` | Errors |
| Errors | `Invalid_Argument` | Bad $h$, $\Delta t$, $\alpha$, lengths |

Strong typing uses `Positive_Real` / `Non_Negative` / `Point_Count` where
helpful. Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Uniform 1D grids (arrays, $\le 512$ points) with Dirichlet ends
- One CN heat step and multi-step advance
- $r$-parameter and Fourier amplification helpers
- Manufactured-solution / order / large-$r$ stability checks

Out of scope:

- Multi-dimensional heat / irregular meshes
- Neumann / Robin BCs, nonlinear diffusivity
- Hyperbolic / oscillatory CN variants
- Multigrid and full PDE survey (upcoming rows)

## Usage

```ada
with Crank_Nicolson; use Crank_Nicolson;

declare
   N     : constant Point_Count := 33;
   H     : constant Real := 1.0 / Real (N - 1);
   Dt    : constant Real := 1.0E-3;
   Alpha : constant Real := 1.0;
   U0, U : Grid (1 .. N);
begin
   for J in 1 .. N loop
      U0 (J) := Sin (Ada.Numerics.Pi * X_At (0.0, H, J));
   end loop;
   U := Heat_CN_Advance (U0, H, Dt, Alpha, 50, 0.0, 0.0);
   --  U ≈ exp(−π² α t) sin(π x) at t = 50·Dt
end;
```

```ada
declare
   R : constant Real := R_Param (Alpha => 1.0, Dt => 0.01, H => 0.1);
   --  R = 0.5; |A| ≤ 1 for every phase
begin
   pragma Assert (Unconditionally_Stable (R));
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `Grid` / `Real` / `Max_Points` | 1D samples / digits-15 Real / cap 512 |
| `Sample` / `X_At` | Sample analytic $f$; abscissa helper |
| `R_Param` | $r=\alpha\Delta t/(2h^{2})$ |
| `Amplification_Factor` | Fourier $A(r,\Theta)$ |
| `Amplification_Bounded` | $\|A\|\le 1$ predicate |
| `Unconditionally_Stable` | Educational multi-$\Theta$ check |
| `Heat_CN_Step` | One Crank–Nicolson heat step |
| `Heat_CN_Advance` | $N$ CN steps, fixed Dirichlet BCs |
| `L2_Error` / `Max_Error` | Discrete errors vs exact |
| `Near` / `Abs_Error` / `Vec_Near` | Comparison helpers |
| `Invalid_Argument` | Domain errors (bad $h$, $\Delta t$, $\alpha$, …) |

## Limitations / caveats

- Educational **Long_Float-class** arithmetic (`Real` digits 15): not
  arbitrary precision; `Max_Points = 512`.
- Uniform 1D Dirichlet only; no Neumann helpers.
- Unconditional stability is for the **linear** heat equation; large $r$
  can still show oscillatory approach to steady state.
- Thomas is embedded for teaching the CN path; for a full TDMA API see
  the Ada-Thomas-Algorithm sibling.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pcrank_nicolson.gpr
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
| `crank_nicolson.ads` | Package spec |
| `crank_nicolson.adb` | Package body |
| `crank_nicolson.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Crank–Nicolson method](https://en.wikipedia.org/wiki/Crank%E2%80%93Nicolson_method)
- [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method) (sibling; FTCS heat)
- [Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff) (sibling grid style)
- Crank, J. and Nicolson, P. (1947). A practical method for numerical evaluation of solutions of partial differential equations of the heat-conduction type.
- LeVeque, R. J. *Finite Difference Methods for Ordinary and Partial Differential Equations*.
