# Partial differential equation — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Partial differential equation](https://en.wikipedia.org/wiki/Partial_differential_equation):
classify second-order linear PDEs in two variables and run **thin 1D sketches**
of one prototype per class (elliptic / parabolic / hyperbolic).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages are
**independent** — this repo does **not** `with` them; it re-implements short
educational sketches. Full packages live in the siblings linked below.

## Caveats

- **Sketches only** — not a production PDE framework (no FEM / FVM / AMR).
- Uniform **1D** grids only (`Max_Points = 512`).
- FTCS heat **rejects** $r>1/2$; upwind / leapfrog **reject** CFL $>1$.
- Thomas (TDMA) for Poisson is **embedded** for teaching; see siblings for
  full FD / CN / LW APIs.

## Classification (discriminant)

For a second-order linear PDE in two variables

$$
A\,u_{xx}+2B\,u_{xy}+C\,u_{yy}+\text{(lower-order terms)}=0,
$$

the **discriminant** $\Delta=B^{2}-A\cdot C$ decides the type:

| $\Delta$ | Class | Prototype (this survey) |
| --- | --- | --- |
| $\Delta<0$ | **Elliptic** | Poisson $-u''=g$ (Dirichlet + Thomas) |
| $\Delta=0$ (incl. near-zero tol) | **Parabolic** | Heat $u_t=\alpha u_{xx}$ (FTCS) |
| $\Delta>0$ | **Hyperbolic** | Advection $u_t+c u_x=0$ / wave $u_{tt}=c^{2}u_{xx}$ |
| $A=B=C=0$ | **Degenerate** | Principal part vanishes |

Examples encoded in tests: Laplace $(A,B,C)=(1,0,1)$ elliptic; heat
$(1,0,0)$ parabolic; wave $(1,0,-1)$ hyperbolic; zeros degenerate.

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Taxonomy** | `PDE_Class`, `Classify_2nd_Order`, `Class_Name` | Survey glue |
| **Domain** | `Real`, `Grid`, `Max_Points`, `Sample`, `X_At` | Mirror FDM style |
| **Metrics** | `Near`, `Abs_Error`, `Vec_Near`, `L2_Error`, `Max_Error` | Diagnostics |
| **Elliptic** | `Solve_Poisson_1D` | $-u''=g$, Dirichlet, embedded Thomas |
| **Parabolic** | `Heat_FTCS_Step`, `Heat_FTCS_Stable` | $r=\alpha\Delta t/H^{2}\le 1/2$ |
| **Hyperbolic** | `Advection_Upwind_Step`, `Wave_Leapfrog_Step` | Upwind $c\ge 0$; leapfrog wave |
| **CFL** | `CFL_Advection`, `CFL_Wave` | Courant helpers |
| **Errors** | `Invalid_Argument` | Bad $H$, $\Delta t$, CFL / $r$, lengths |

## Formula summary

### Elliptic — 1D Poisson

On $[0,1]$ with $u(0)=u_L$, $u(1)=u_R$, interior nodes with spacing $H$:

$$
\frac{-u_{j-1}+2u_j-u_{j+1}}{H^{2}}=g(x_j),
$$

solved by an embedded **Thomas (TDMA)** sweep.

### Parabolic — FTCS heat

$$
u_j^{n+1}=u_j^{n}+r\bigl(u_{j-1}^{n}-2u_j^{n}+u_{j+1}^{n}\bigr),
\qquad r=\frac{\alpha\Delta t}{H^{2}},\quad r\le\tfrac12.
$$

### Hyperbolic — upwind advection ($c\ge 0$)

$$
u_j^{n+1}=u_j^{n}-\nu\bigl(u_j^{n}-u_{j-1}^{n}\bigr),
\qquad \nu=\frac{c\Delta t}{H}\le 1.
$$

### Hyperbolic — leapfrog wave

$$
u_j^{n+1}=2u_j^{n}-u_j^{n-1}+\lambda^{2}\bigl(u_{j-1}^{n}-2u_j^{n}+u_{j+1}^{n}\bigr),
\qquad \lambda=\frac{c\Delta t}{H},\quad |\lambda|\le 1.
$$

## Sibling packages (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method) | FD stencils, Poisson, FTCS helpers |
| [Ada-Crank-Nicolson](https://github.com/RobertBoettcherSF/Ada-Crank-Nicolson) | Implicit CN heat (unconditionally stable) |
| [Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff) | Second-order hyperbolic LW advection |

## Upcoming (series)

- **Ada-Multigrid-Methods** (elliptic multilevel)

## Public API (summary)

**Types:** `PDE_Class`, `Real`, `Grid`, `Point_Count`, `Invalid_Argument`.

**Taxonomy:** `Classify_2nd_Order`, `Class_Name`.

**Helpers:** `Near`, `Abs_Error`, `Vec_Near`, `L2_Error`, `Max_Error`,
`X_At`, generic `Sample`.

**Sketches:** `Solve_Poisson_1D`, `Heat_FTCS_Step`, `Heat_FTCS_Stable`,
`Advection_Upwind_Step`, `Wave_Leapfrog_Step`, `CFL_Advection`, `CFL_Wave`.

## Usage

```ada
with Partial_Differential_Equation; use Partial_Differential_Equation;

declare
   Kind : constant PDE_Class := Classify_2nd_Order (1.0, 0.0, 1.0);
   H    : constant Real := 1.0 / 32.0;
   G    : Grid (1 .. 31) := [others => 2.0];
   U    : Grid (1 .. 33);
begin
   pragma Assert (Kind = Elliptic);
   U := Solve_Poisson_1D (G, 0.0, 0.0, H);
end;
```

```ada
declare
   U : Grid := [...];  -- includes Dirichlet ends
begin
   if Heat_FTCS_Stable (Alpha => 1.0, H => 0.1, Dt => 0.004) then
      U := Heat_FTCS_Step (U, 1.0, 0.1, 0.004, 0.0, 0.0);
   end if;
end;
```

## Educational scope

In scope:

- Discriminant classification with near-zero tolerance and Degenerate case
- One thin sketch per class on uniform 1D grids
- Stability / CFL guards that raise `Invalid_Argument`
- Manufactured-solution checks (Poisson $\sin(\pi x)$, heat damping, wave mode)

Out of scope:

- Multi-D / nonlinear / systems of PDEs
- Full sibling APIs (CN multi-step, LW Richtmyer, multigrid V-cycles)
- Adaptive meshes, production solvers

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Ppartial_differential_equation.gpr
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
| `partial_differential_equation.ads` | Package spec |
| `partial_differential_equation.adb` | Package body |
| `partial_differential_equation.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Partial differential equation](https://en.wikipedia.org/wiki/Partial_differential_equation)
- [Ada-Finite-Difference-Method](https://github.com/RobertBoettcherSF/Ada-Finite-Difference-Method)
- [Ada-Crank-Nicolson](https://github.com/RobertBoettcherSF/Ada-Crank-Nicolson)
- [Ada-Lax-Wendroff](https://github.com/RobertBoettcherSF/Ada-Lax-Wendroff)
- Evans, L. C. *Partial Differential Equations*.
- LeVeque, R. J. *Finite Difference Methods for Ordinary and Partial Differential Equations*.
