# Finite difference method — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Finite difference method](https://en.wikipedia.org/wiki/Finite_difference_method):
approximate derivatives on a **uniform grid** and discretize simple 1D
boundary-value / parabolic problems. Classroom focus:

- forward / backward / central **first** derivatives
- central **second** derivative
- **1D Poisson** $-u''=g$ with Dirichlet BCs (tridiagonal + Thomas)
- optional **FTCS heat** step with stability $r\le 1/2$

On a uniform mesh with spacing $h$, the basic stencils are

$$
f'(x)\approx\frac{f(x+h)-f(x)}{h}
\quad\text{(forward)},\qquad
f'(x)\approx\frac{f(x)-f(x-h)}{h}
\quad\text{(backward)},
$$

$$
f'(x)\approx\frac{f(x+h)-f(x-h)}{2h}
\quad\text{(central)},\qquad
f''(x)\approx\frac{f(x+h)-2f(x)+f(x-h)}{h^{2}}.
$$

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15). Grid arrays
mirror the sibling **Ada-Lax-Wendroff** style (no `with` of that package).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling: [Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff)
(hyperbolic LW step). Upcoming numerical DE / PDE track:
**Crank–Nicolson**, PDE sheets, **Multigrid**,
**Linear multistep**, Euler method row, **Backward Euler**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **1st deriv.** | `Diff_Forward` / `Diff_Backward` / `Diff_Central` | Sampled arrays |
| **2nd deriv.** | `Diff2_Central` | Interior stencil |
| **Poisson** | `Solve_Poisson_1D` | $-u''=g$, Dirichlet, Thomas |
| **Heat** | `Heat_FTCS_Step` | One FTCS step; $r\le 1/2$ |
| **Order** | Tests on smooth $f$ | Forward $O(h)$, central $O(h^{2})$ |
| **Errors** | `Near`, `Abs_Error`, `L2_Error`, `Max_Error` | Diagnostics |
| **Domain error** | `Invalid_Argument` | Bad $h$, short grids, $r>1/2$ |

## Method

### Difference quotients from Taylor

Truncating Taylor's expansion yields the forward quotient above with local
truncation error $O(h)$. Centring cancels the leading odd term and gives
$O(h^{2})$ for the first-derivative central stencil and for the standard
three-point second-derivative stencil.

### 1D Poisson

On $[0,1]$ with $u(0)=u_L$, $u(1)=u_R$, interior nodes $x_j=j h$
($h=1/(N+1)$, $j=1,\ldots,N$) the central second-difference of $-u''=g$
produces the tridiagonal system

$$
\frac{-u_{j-1}+2u_j-u_{j+1}}{h^{2}}=g(x_j),
$$

with boundary values folded into the right-hand side. This package solves
that system with an embedded **Thomas (TDMA)** sweep (self-contained; does
not `with` Ada-Thomas-Algorithm).

### FTCS heat

For $u_t=\kappa u_{xx}$, one Forward-Time Central-Space step is

$$
u_j^{n+1}=u_j^{n}+r\bigl(u_{j-1}^{n}-2u_j^{n}+u_{j+1}^{n}\bigr),
\qquad r=\frac{\kappa\Delta t}{h^{2}}.
$$

Von Neumann analysis requires $r\le 1/2$ for stability; this package
**rejects** $r>1/2$ with `Invalid_Argument`. Dirichlet endpoints are
copied unchanged.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Grid`, `Max_Points`, generic `Sample` | Domain model (cap 512) |
| Sample | `Sample`, `X_At` | Analytic $\to$ grid |
| 1st FD | `Diff_Forward`, `Diff_Backward`, `Diff_Central` | Difference quotients |
| 2nd FD | `Diff2_Central` | Laplacian building block |
| BVP | `Solve_Poisson_1D` | $-u''=g$ + Thomas |
| Parabolic | `Heat_FTCS_Step`, `FTCS_Stable` | Explicit heat step |
| Metrics | `L2_Error`, `Max_Error`, `Near`, `Abs_Error`, `Vec_Near` | Errors |
| Errors | `Invalid_Argument` | Bad $h$, $r$, lengths |

Strong typing uses `Positive_Real` / `Non_Negative` / `Point_Count` where
helpful. Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Uniform 1D grids (arrays, $\le 512$ points)
- Forward / backward / central first derivatives; central second
- 1D Poisson with Dirichlet BCs via Thomas
- One FTCS heat step with hard stability reject
- Order-of-accuracy checks on known smooth $f$ (sin, cos, exp, polynomials)

Out of scope:

- Multi-dimensional Laplacians / irregular meshes
- Implicit / Crank–Nicolson time stepping (upcoming sibling)
- Nonlinear PDEs, adaptive $h$, production FEM / FVM frameworks
- Multigrid and linear multistep methods (upcoming rows)

## Usage

```ada
with Finite_Difference_Method; use Finite_Difference_Method;

declare
   H  : constant Real := 1.0 / 32.0;
   N  : constant Point_Count := 31;   -- interior
   G  : Grid (1 .. N) := [others => 2.0];  -- −u'' = 2
   U  : Grid (1 .. N + 2);
begin
   U := Solve_Poisson_1D (G, H, 0.0, 0.0);
   --  U ≈ x(1−x) on [0,1]
end;
```

```ada
declare
   function F_Sin (X : Real) return Real is (Sin (X));
   function Sample_Sin is new Sample (F_Sin);
   F  : constant Grid := Sample_Sin (65, Ada.Numerics.Pi / 64.0);
   DF : constant Grid := Diff_Central (F, Ada.Numerics.Pi / 64.0);
begin
   null;  -- DF ≈ cos at interior nodes
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `Grid` / `Real` / `Max_Points` | 1D samples / digits-15 Real / cap 512 |
| `Sample` / `X_At` | Sample analytic $f$; abscissa helper |
| `Diff_Forward` | Forward first difference ($O(h)$) |
| `Diff_Backward` | Backward first difference ($O(h)$) |
| `Diff_Central` | Central first difference ($O(h^{2})$) |
| `Diff2_Central` | Central second difference ($O(h^{2})$) |
| `Solve_Poisson_1D` | $-u''=g$ Dirichlet + Thomas |
| `Heat_FTCS_Step` | One FTCS heat step |
| `FTCS_Stable` | $0\le r\le 1/2$ predicate |
| `L2_Error` / `Max_Error` | Discrete errors vs exact |
| `Near` / `Abs_Error` / `Vec_Near` | Comparison helpers |
| `Invalid_Argument` | Domain errors (bad $h$, $r>1/2$, …) |

## Limitations / caveats

- Educational **Long_Float-class** arithmetic (`Real` digits 15): not
  arbitrary precision; `Max_Points = 512`.
- Uniform 1D only; no ghost-cell / Neumann helpers beyond Dirichlet ends
  on Poisson / heat.
- $r>1/2$ is rejected rather than run unstably.
- Thomas is embedded for teaching the Poisson path; for a full TDMA API
  see the Ada-Thomas-Algorithm sibling.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pfinite_difference_method.gpr
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
| `finite_difference_method.ads` | Package spec |
| `finite_difference_method.adb` | Package body |
| `finite_difference_method.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Finite difference method](https://en.wikipedia.org/wiki/Finite_difference_method)
- [Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff) (sibling grid style)
- [Ada-Thomas-Algorithm](https://github.com/RobertBoettcherSF/Ada-Thomas-Algorithm) (standalone TDMA)
- LeVeque, R. J. *Finite Difference Methods for Ordinary and Partial Differential Equations*.
- Smith, G. D. *Numerical Solution of Partial Differential Equations: Finite Difference Methods*.
