# Lax–Wendroff method — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Lax–Wendroff method](https://en.wikipedia.org/wiki/Lax%E2%80%93Wendroff_method):
a **second-order** finite-difference scheme for hyperbolic PDEs.
Classroom focus is 1D **linear advection**

$$
u_t + a\, u_x = 0
$$

on a **periodic** uniform grid, with Long_Float-class (`Real` digits 15)
arrays, Gaussian / pulse initial data, and comparison against the exact
periodic shift.

The single-step update with Courant number $\nu = a\Delta t/\Delta x$ is

$$
u_j^{n+1}
  = u_j^n
  - \frac{\nu}{2}\bigl(u_{j+1}^n - u_{j-1}^n\bigr)
  + \frac{\nu^2}{2}\bigl(u_{j+1}^n - 2u_j^n + u_{j-1}^n\bigr).
$$

The package also exposes the **Richtmyer two-step** form (half-step
predictors at midpoints, then a full step). On linear advection the two
forms are algebraically equivalent.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling: [Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta)
(explicit ODE stages). Upcoming numerical DE / PDE track:
**FDM**, **Crank–Nicolson**, PDE sheets, **Multigrid**,
**Linear multistep**, Euler method row, **Backward Euler**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **PDE** | 1D linear advection $u_t+a u_x=0$ | Periodic grid |
| **Scheme** | `Step` / `Advance` | Single-step Lax–Wendroff |
| **Two-step** | `Step_Richtmyer` / `Advance_Richtmyer` | Richtmyer form |
| **CFL** | `CFL`, `CFL_OK` | $\nu=a\Delta t/\Delta x$; reject $\|\nu\|>1$ |
| **IC** | `Make_Gaussian`, `Make_Pulse`, `Make_Constant` | Smooth / discontinuous / steady |
| **Exact** | `Exact_Advection`, `Shift_Grid` | Periodic shift (+ interp) |
| **Errors** | `L2_Error`, `Max_Error`, `Mass` | Diagnostics |
| **Domain error** | `Invalid_Argument` | Bad $\Delta x$/$\Delta t$, $\|\nu\|>1$ |

## Method

### Single-step Lax–Wendroff

Taylor expansion in time plus centred replacements of $u_t$ and $u_{tt}$
(via the PDE $u_t=-a u_x$, $u_{tt}=a^2 u_{xx}$) yields the stencil above.
The scheme is **second-order** in space and time. For linear advection the
von Neumann stability restriction is

$$
|\nu| = \left|\frac{a\Delta t}{\Delta x}\right| \le 1.
$$

This package **rejects** $\|\nu\|>1$ with `Invalid_Argument` (educational
hard stop rather than a silent unstable run).

### Richtmyer two-step

An equivalent two-step form first builds midpoint predictors

$$
u_{j+1/2}^{n+1/2}
  = \frac{u_j^n+u_{j+1}^n}{2}
  - \frac{\nu}{2}\bigl(u_{j+1}^n-u_j^n\bigr)
$$

and then advances

$$
u_j^{n+1}
  = u_j^n
  - \nu\bigl(u_{j+1/2}^{n+1/2}-u_{j-1/2}^{n+1/2}\bigr).
$$

On $u_t+a u_x=0$ this coincides with the single-step stencil (verified in
the test suite).

### Exact solution

For constant $a$ the exact solution is a pure translation
$u(x,t)=u_0(x-a t)$ with periodic wrap on the domain. `Exact_Advection`
samples that shift with linear interpolation between cell centres;
`Shift_Grid` covers the grid-aligned integer-cell case (e.g. $\nu=1$).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Grid`, `Grid_State`, `Max_Cells` | Domain model (cap 512) |
| Geometry | `Domain_Length`, `X_At`, `CFL`, `CFL_OK` | Mesh / Courant |
| Builders | `Make_Grid`, `Make_Gaussian`, `Make_Pulse`, `Make_Constant` | ICs |
| Steps | `Step`, `Advance` | Single-step LW |
| Richtmyer | `Step_Richtmyer`, `Advance_Richtmyer` | Two-step form |
| Exact | `Exact_Advection`, `Shift_Grid`, `Wrap_Periodic` | Comparison |
| Metrics | `L2_Error`, `Max_Error`, `Mass`, `Max_Abs` | Errors / conservation |
| Helpers | `Near`, `Abs_Error`, `Vec_Near` | Comparisons |
| Errors | `Invalid_Argument` | Bad $\Delta x$/$\Delta t$, $\|\nu\|>1$ |

Strong typing uses `Positive_Real` / `Non_Negative` / `Cell_Count` where
helpful. Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- 1D linear advection on a periodic uniform grid (arrays, $\le 512$ cells)
- Single-step Lax–Wendroff and Richtmyer two-step (linear equivalence)
- Gaussian, rectangular pulse, and constant initial data
- Exact periodic shift for error measurement; mass conservation checks
- CFL computation and hard reject when $\|\nu\|>1$

Out of scope:

- Nonlinear conservation laws / systems (Euler, shallow water, …)
- Limiters, TVD / WENO / discontinuous Galerkin variants
- Multi-dimensional LW, unstructured meshes, adaptive $\Delta t$
- Production PDE frameworks (deferred to upcoming FDM / Multigrid rows)

## Usage

```ada
with Lax_Wendroff; use Lax_Wendroff;

declare
   N  : constant Cell_Count := 128;
   Dx : constant Real := 1.0 / Real (N);
   Dt : constant Real := 0.4 * Dx;  -- nu = 0.4
   S  : Grid_State :=
     Make_Gaussian (N, Dx, Dt, A => 1.0, Centre => 0.5, Width => 0.08);
   U0 : constant Grid := S.U (1 .. N);
   Exact : Grid (1 .. N);
begin
   Advance (S, 50);
   Exact := Exact_Advection (U0, N, Dx, 0.0, 1.0 * 50.0 * Dt);
   --  compare L2_Error (S, Exact), Mass (S), ...
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `Grid` / `Grid_State` | 1D samples / packed periodic state |
| `Max_Cells` | Hard cap ($512$) |
| `CFL` / `CFL_OK` | $\nu=a\Delta t/\Delta x$; stability check |
| `Make_Grid` | Zero field with geometry |
| `Make_Gaussian` | Smooth Gaussian pulse IC |
| `Make_Pulse` | Rectangular pulse IC |
| `Make_Constant` | Constant field (exact steady state) |
| `Step` / `Advance` | Single-step Lax–Wendroff |
| `Step_Richtmyer` / `Advance_Richtmyer` | Two-step Richtmyer form |
| `Exact_Advection` | Periodic exact shift (interpolated) |
| `Shift_Grid` | Integer-cell periodic rotation |
| `L2_Error` / `Max_Error` | Discrete errors vs exact |
| `Mass` / `Max_Abs` | Conservation / amplitude diagnostics |
| `Near` / `Abs_Error` / `Vec_Near` | Comparison helpers |
| `Invalid_Argument` | Domain errors (bad $\Delta x$/$\Delta t$, $\|\nu\|>1$) |

## Limitations / caveats

- Educational **Long_Float-class** arithmetic (`Real` digits 15): not
  arbitrary precision; `Max_Cells = 512`.
- Linear scalar advection only; discontinuous data (pulses) will show
  dispersive oscillations (no limiter).
- $\|\nu\|>1$ is rejected rather than run unstably.
- Exact comparison uses linear interpolation of the shifted profile;
  grid-aligned $\nu=1$ shifts are exact via `Shift_Grid`.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Plax_wendroff.gpr
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
| `lax_wendroff.ads` | Package spec |
| `lax_wendroff.adb` | Package body |
| `lax_wendroff.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Lax–Wendroff method](https://en.wikipedia.org/wiki/Lax%E2%80%93Wendroff_method)
- [Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta) (sibling)
- Lax, P. D.; Wendroff, B. (1960). Systems of conservation laws.
- LeVeque, R. J. *Finite Volume Methods for Hyperbolic Problems*.
- Richtmyer, R. D.; Morton, K. W. *Difference Methods for Initial-Value Problems*.
