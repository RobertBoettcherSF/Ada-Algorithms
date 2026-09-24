# Trapezoidal rule (differential equations) — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Trapezoidal rule (differential equations)](https://en.wikipedia.org/wiki/Trapezoidal_rule_(differential_equations)):
the **implicit second-order** one-step method obtained by applying the
trapezoidal quadrature rule to the IVP $y'=f(t,y)$. It is both a
Runge–Kutta method and a linear multistep method, and is **A-stable** on
the linear test equation. Closely related to the **Crank–Nicolson**
scheme in the PDE / method-of-lines setting.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

**Verlet skipped** (sheet Ada slot is [Ada-Velvet](https://github.com/RobertBoettcherSF/Ada-Velvet)).
Upcoming numerical DE / ODE track: Euler integration, Runge–Kutta,
Lax–Wendroff, FDM, Crank–Nicolson, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **RHS** | `ODE_Fn` access-to-function | $f(t,y)$ pointer style |
| **Implicit step** | `Step_Implicit` | Fixed-point or Newton |
| **Explicit contrast** | `Step_Heun` | Predictor-corrector trapezoidal |
| **Interval** | `Integrate` / `Integrate_Heun` | $N$ equal steps |
| **Linear test** | `Amplification`, `Exact_Exponential` | $R(z)$, $e^{\lambda t}$ |
| **Helpers** | `Near`, `Abs_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | $h\le 0$, failed convergence |

## Method

Suppose we solve

$$
y'=f(t,y).
$$

The **trapezoidal rule** (implicit) is

$$
y_{n+1}=y_{n}+\frac{h}{2}\bigl(f(t_{n},y_{n})+f(t_{n+1},y_{n+1})\bigr),
$$

where $h=t_{n+1}-t_{n}$. The unknown $y_{n+1}$ appears on both sides, so
each step solves a (usually nonlinear) scalar equation. This package
offers:

1. **Fixed-point** iteration of the right-hand side, and
2. **Newton** on $g(z)=z-y_{n}-\frac{h}{2}\bigl(f_{n}+f(t_{n}+h,z)\bigr)$,
   with optional analytic $\partial f/\partial y$ (else a finite-difference
   Jacobian).

The initial guess is **forward Euler**
$\hat y=y_{n}+h f(t_{n},y_{n})$. Stopping after that single predictor
(no corrector iterations) is exactly **Heun’s method** / improved Euler,
exposed here as `Step_Heun` for contrast:

$$
\begin{aligned}
\hat y &= y_{n}+h f(t_{n},y_{n}),\\
y_{n+1} &= y_{n}+\frac{h}{2}\bigl(f(t_{n},y_{n})+f(t_{n}+h,\hat y)\bigr).
\end{aligned}
$$

### Motivation (quadrature)

Integrating $y'=f(t,y(t))$ from $t_{n}$ to $t_{n+1}$ gives

$$
y(t_{n+1})-y(t_{n})=\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t.
$$

The trapezoidal quadrature rule approximates the integral by

$$
\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t
\approx
\frac{h}{2}\bigl(f(t_{n},y(t_{n}))+f(t_{n+1},y(t_{n+1}))\bigr),
$$

which yields the ODE step above with $y_{n}\approx y(t_{n})$.

### Error

Local truncation error satisfies

$$
|\tau_{n}|\le\frac{1}{12}h^{3}\max_{t}|y'''(t)|,
$$

so the method is **second-order**: global error $O(h^{2})$ as $h\to 0$.

### A-stability

On the linear test equation $y'=\lambda y$, one step multiplies by the
stability function

$$
R(z)=\frac{1+z/2}{1-z/2},\qquad z=h\lambda.
$$

The region of absolute stability is precisely the open left half-plane
$\{z\in\mathbb{C}:\operatorname{Re}(z)<0\}$, so the method is **A-stable**.
By the second Dahlquist barrier it is the most accurate A-stable linear
multistep method (order at most two; optimal error constant among those).

`Amplification(Z)` returns $R(Z)$ for real $Z$ (raises near the pole
$z=2$).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `ODE_Fn`, `Partial_Y_Fn`, `Config`, `Step_Result` | Domain model |
| Step | `Step_Implicit`, `Step_Heun` | One step |
| Interval | `Integrate`, `Integrate_Heun` | Multi-step |
| Linear test | `Amplification`, `Exact_Exponential` | $R(z)$, exact $e^{\lambda t}$ |
| Samples | `F_Decay`, `F_Growth`, `F_Decay_2`, `F_Stiff`, `F_Logistic` (+ `DF_*`) | $y'=\lambda y$, logistic |
| Helpers | `Near`, `Abs_Error` | Comparisons |
| Errors | `Invalid_Argument` | Bad $h$ / interval / convergence |

Strong typing uses `Positive_Real` / `Non_Negative` where helpful.
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Scalar IVP $y'=f(t,y)$ with access-to-subprogram RHS
- Implicit trapezoidal step (fixed-point / Newton)
- Explicit Heun predictor-corrector contrast
- Integration over $[t_0,t_1]$ with $N$ steps
- Linear test $y'=\lambda y$ vs $e^{\lambda t}$; A-stability helper $R(z)$

Out of scope:

- Systems / vector ODEs and full Butcher-tableau RK frameworks
- Adaptive step-size control and dense output
- Production DAE / stiff solvers (BDF, Radau, …)
- PDE Crank–Nicolson discretizations (forthcoming sibling)

## Usage

```ada
with Trapezoidal_Rule_DE; use Trapezoidal_Rule_DE;

--  y' = -y, y(0)=1 → y(1)=e^{-1}
declare
   Y : Real;
begin
   Y := Integrate
     (F_Decay'Access, 0.0, 1.0, 1.0, 100,
      Cfg => (Max_Iterations => 50, Tol => 1.0E-12, Solver => Newton),
      DF_DY => DF_Decay'Access);
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `ODE_Fn` / `Partial_Y_Fn` | $f(t,y)$ and $\partial f/\partial y$ |
| `Solver_Kind` / `Config` | Fixed-point or Newton; tol / budget |
| `Step_Result` | `Y_Next`, `Iterations`, `Converged` |
| `Step_Implicit` | One implicit trapezoidal step |
| `Step_Heun` | One explicit Heun step |
| `Integrate` / `Integrate_Heun` | Equal-step interval solvers |
| `Amplification` | Stability function $R(z)$ |
| `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| `Near` / `Abs_Error` | Comparison helpers |
| `F_Decay` / `F_Growth` / … | Sample RHS (+ `DF_*` Jacobians) |
| `Invalid_Argument` | Domain / convergence errors |

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision.
- Scalar ODE only; stiff nonlinear problems may need a better Newton
  strategy or smaller $h$ than production codes use.
- Fixed-point may diverge for large $h$ or stiff $f$; prefer Newton with
  analytic $\partial f/\partial y$ on stiff linear tests.
- For very large negative $z=h\lambda$, $R(z)\to -1$: the numerical
  solution decays but can oscillate (A-stable, not L-stable).

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Ptrapezoidal_rule_de.gpr
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
| `trapezoidal_rule_de.ads` | Package spec |
| `trapezoidal_rule_de.adb` | Package body |
| `trapezoidal_rule_de.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Trapezoidal rule (differential equations)](https://en.wikipedia.org/wiki/Trapezoidal_rule_(differential_equations))
- Iserles, A. (1996). *A First Course in the Numerical Analysis of Differential Equations*.
- Süli, E.; Mayers, D. (2003). *An Introduction to Numerical Analysis*.
