# Backward Euler method — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Backward Euler method](https://en.wikipedia.org/wiki/Backward_Euler_method):
the **implicit first-order** one-step method (equivalently **BDF1**) for the
IVP $y'=f(t,y)$

$$
y_{n+1}=y_{n}+h\,f(t_{n+1},y_{n+1}).
$$

Unlike forward Euler, the derivative is evaluated at the *future* point, so
each step solves a (generally nonlinear) equation for $y_{n+1}$. The method
is **A-stable** and **L-stable**: amplification $R(z)=1/(1-z)$ on the linear
test equation satisfies $|R(z)|\le 1$ for all $\operatorname{Re}(z)\le 0$, and
$R(\infty)=0$ (stiff damping).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

Siblings:

- [Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration)
  (forward / explicit Euler)
- [Ada-Linear-Multistep-Methods](https://github.com/RobertBoettcherSF/Ada-Linear-Multistep-Methods)
  (includes BDF1 / BDF2 and Adams methods)
- [Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE)
  (implicit trapezoidal / AM2)
- [Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta)
  (single-step explicit RK)

Note-sheet row **“Euler method”** is skipped here as a duplicate of
Ada-Euler-Integration. Next sheet section: **Number theoretic algorithms**
(Sieve of Sundaram marked skip/x; then Eratosthenes).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **RHS** | `ODE_Fn` access-to-function | $f(t,y)$ pointer style |
| **Jacobian** | `Partial_Y_Fn` / `Config.DF_DY` | optional $\partial f/\partial y$ for Newton |
| **Step** | `Step` | One backward Euler step (Newton or fixed-point) |
| **Interval** | `Integrate` | $N$ equal steps on $[t_0,t_1]$ |
| **Linear test** | `Amplification`, `Exact_Exponential` | $R(z)=1/(1-z)$, $e^{\lambda t}$ |
| **A-/L-stability** | `Amplification_Bounded` | $|R|\le 1$; $R(\infty)=0$ |
| **Stiff contrast** | `Forward_Euler_*` | where FE needs tiny $h$ |
| **Helpers** | `Near`, `Abs_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | $h\le 0$, null $F$, failed solve, pole |

## Method

Suppose we solve

$$
y'=f(t,y).
$$

The **backward Euler** (implicit Euler / BDF1) method advances one step of
size $h=t_{n+1}-t_{n}$ by

$$
y_{n+1}=y_{n}+h\,f(t_{n+1},y_{n+1}).
$$

Geometrically this follows the tangent at the *unknown* future point.
Algebraically it is the right Riemann (rectangle) quadrature of
$y'=f(t,y(t))$ over $[t_{n},t_{n+1}]$. Equivalently it is the one-step BDF
formula.

### Motivation (quadrature)

Integrating $y'=f(t,y(t))$ from $t_{n}$ to $t_{n+1}$ gives

$$
y(t_{n+1})-y(t_{n})=\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t.
$$

The right rectangular rule approximates the integrand by its value at the
right endpoint,

$$
\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t
\approx
h\,f(t_{n+1},y(t_{n+1})),
$$

which yields the backward Euler step with $y_{n}\approx y(t_{n})$.

### Nonlinear solve

Each step requires solving the scalar equation

$$
g(y)=y-y_{n}-h\,f(t_{n}+h,y)=0
$$

for $y=y_{n+1}$. This package:

- uses **Newton** when `Config.DF_DY` supplies $\partial f/\partial y$
  (Jacobian of $g$: $g'=1-h\,\partial f/\partial y$);
- otherwise uses **fixed-point** iteration
  $y\leftarrow y_{n}+h\,f(t_{n}+h,y)$.

The initial guess is a forward Euler predictor. Failure to converge within
`Max_Iterations` raises `Invalid_Argument`.

### Error

Local truncation error is $O(h^{2})$; the method is **first-order**: global
error $O(h)$ as $h\to 0$ (halving $h$ roughly halves the error).

### Absolute stability

On the linear test equation $y'=\lambda y$, one step multiplies by the
stability function

$$
R(z)=\frac{1}{1-z},\qquad z=h\lambda.
$$

There is a pole at $z=1$ (`Amplification` raises `Invalid_Argument` there).
Absolute stability requires $|R(z)|\le 1$. Backward Euler is **A-stable**:
the entire left half-plane $\operatorname{Re}(z)\le 0$ lies in the stability
region. It is also **L-stable**: $R(\infty)=0$, so stiff modes are damped in
a single step. `Amplification(Z)` returns $R(Z)$; `Amplification_Bounded(Z)`
reports $|R(Z)|\le 1$.

On $y'=-y$, the closed form of one step from $y=1$ is

$$
y_{n+1}=\frac{1}{1+h}=R(-h).
$$

### Stiff contrast with forward Euler

Forward Euler has $R_{\mathrm{FE}}(z)=1+z$ and is only conditionally stable
(disk $|1+z|\le 1$). For $y'=-50\,y$, stability needs $h\le 2/50=0.04$; with
$h=0.1$ one has $|R_{\mathrm{FE}}(-5)|=4>1$ and the numerical solution blows
up, while backward Euler remains bounded ($|R(-5)|=1/6$). Helpers
`Forward_Euler_Step`, `Forward_Euler_Integrate`, and
`Forward_Euler_Amplification` document that regime.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `ODE_Fn`, `Partial_Y_Fn`, `Config` | Domain model |
| Step | `Step` | One backward Euler step |
| Interval | `Integrate` | Multi-step equal-$h$ |
| Linear test | `Amplification`, `Exact_Exponential` | $R(z)$, exact $e^{\lambda t}$ |
| Stability | `Amplification_Bounded` | A-/L-stability checks |
| Contrast | `Forward_Euler_*` | Explicit Euler stiff demo |
| Samples | `F_Decay`, `F_Growth`, `F_Decay_2`, `F_Stiff`, `F_Logistic`, `F_Square` | RHS + `DF_*` |
| Helpers | `Near`, `Abs_Error` | Comparisons |
| Errors | `Invalid_Argument` | Bad $h$ / interval / solve / pole |

Strong typing uses `Positive_Real` / `Non_Negative` where helpful.
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Scalar IVP $y'=f(t,y)$ with access-to-subprogram RHS
- Backward Euler step and equal-step interval integration
- Newton (analytic $\partial f/\partial y$) or fixed-point nonlinear solve
- Linear test $y'=\lambda y$ vs $e^{\lambda t}$; $R(z)=1/(1-z)$
- A-stability / L-stability demos; stiff decay vs forward Euler blow-up
- Nonlinear samples (logistic, $y'=y^{2}$); refinement $\Rightarrow$ $O(h)$ error

Out of scope:

- Systems / vector ODEs and full BDF/$k$-step frameworks (see LMM sibling)
- Adaptive step-size control and dense output
- Production stiff solvers (Radau, variable-order BDF, …)
- Higher-order implicit RK / trapezoidal (see Trapezoidal sibling)

## Usage

```ada
with Backward_Euler; use Backward_Euler;

--  y' = -y, y(0)=1 → y(1)≈e^{-1}
declare
   Cfg : constant Config :=
     (Max_Iterations => 50, Tol => 1.0E-12, DF_DY => DF_Decay'Access);
   Y   : Real;
begin
   Y := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, 100, Cfg);
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `ODE_Fn` | $f(t,y)$ access-to-function |
| `Partial_Y_Fn` | $\partial f/\partial y$ for Newton |
| `Config` | `Max_Iterations`, `Tol`, optional `DF_DY` |
| `Step` | One backward Euler step |
| `Integrate` | Equal-step interval solver |
| `Amplification` | Stability function $R(z)=1/(1-z)$ |
| `Amplification_Bounded` | $|R(z)|\le 1$ predicate |
| `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| `Forward_Euler_Step` / `Integrate` / `Amplification` | Stiff contrast |
| `Near` / `Abs_Error` | Comparison helpers |
| `F_*` / `DF_*` | Sample RHS and Jacobians |
| `Invalid_Argument` | Domain / convergence / pole errors |

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision.
- Scalar ODE only; first-order global accuracy $O(h)$.
- Fixed-point may fail for large $h$ or stiff nonlinearities — prefer Newton
  with `DF_DY`.
- `Amplification` is singular at $z=1$ (raises `Invalid_Argument`).

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pbackward_euler.gpr
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
| `backward_euler.ads` | Package spec |
| `backward_euler.adb` | Package body |
| `backward_euler.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Backward Euler method](https://en.wikipedia.org/wiki/Backward_Euler_method)
- [Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration) (sibling)
- [Ada-Linear-Multistep-Methods](https://github.com/RobertBoettcherSF/Ada-Linear-Multistep-Methods) (sibling; BDF1)
- [Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE) (sibling)
- [Ada-Runge-Kutta](https://github.com/RobertBoettcherSF/Ada-Runge-Kutta) (sibling)
- Hairer, E.; Nørsett, S. P.; Wanner, G. *Solving Ordinary Differential Equations I*.
- Hairer, E.; Wanner, G. *Solving Ordinary Differential Equations II* (stiff).
