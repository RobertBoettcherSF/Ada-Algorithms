# Runge–Kutta methods — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Runge–Kutta methods](https://en.wikipedia.org/wiki/Runge%E2%80%93Kutta_methods):
**explicit one-step** ODE schemes with intermediate stages for the IVP
$y'=f(t,y)$.

Classic **RK4** advances one step of size $h$ by four stages

$$
\begin{aligned}
k_{1} &= f(t_{n}, y_{n}), \\
k_{2} &= f\!\left(t_{n}+\tfrac{h}{2},\, y_{n}+\tfrac{h}{2}k_{1}\right), \\
k_{3} &= f\!\left(t_{n}+\tfrac{h}{2},\, y_{n}+\tfrac{h}{2}k_{2}\right), \\
k_{4} &= f(t_{n}+h,\, y_{n}+h\,k_{3}), \\
y_{n+1} &= y_{n}+\tfrac{h}{6}(k_{1}+2k_{2}+2k_{3}+k_{4}).
\end{aligned}
$$

In Butcher-tableau form the classical RK4 coefficients are
$c=(0,\tfrac12,\tfrac12,1)$, $b=(\tfrac16,\tfrac13,\tfrac13,\tfrac16)$,
and the usual lower-triangular $A$ with mid-stage half-weights. The
package also exposes the **midpoint** method (explicit RK2), **Heun** /
improved Euler (explicit RK2), and a tiny **forward Euler** (RK1)
catalogue contrast so classroom comparisons of order and error are
immediate.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling: [Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration)
(forward Euler baseline). Upcoming numerical DE / ODE / PDE track:
**Lax–Wendroff**, **FDM**, **Crank–Nicolson**, PDE sheets, **Multigrid**,
**Linear multistep**, Euler method row, **Backward Euler**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **RHS** | `ODE_Fn` access-to-function | $f(t,y)$ pointer style |
| **RK4** | `Step_RK4` / `Integrate_RK4` | Classic 4-stage, order 4 |
| **Midpoint** | `Step_Midpoint` / `Integrate_Midpoint` | Explicit RK2 |
| **Heun** | `Step_Heun` / `Integrate_Heun` | Improved Euler RK2 |
| **Euler contrast** | `Step_Euler` / `Integrate_Euler` | RK1 catalogue baseline |
| **Exact** | `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| **Helpers** | `Near`, `Abs_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | $h\le 0$, bad interval |

## Method

Suppose we solve

$$
y'=f(t,y).
$$

A general $s$-stage explicit Runge–Kutta method evaluates intermediate
slopes $k_{i}$ and combines them with weights $b_{i}$:

$$
y_{n+1}=y_{n}+h\sum_{i=1}^{s} b_{i}\,k_{i}.
$$

### Classic RK4 (Butcher tableau)

The classical fourth-order method uses four stages with the tableau
sketched above. Local truncation error is $O(h^{5})$; global error is
**fourth-order** $O(h^{4})$ as $h\to 0$.

### Midpoint (explicit RK2)

$$
\begin{aligned}
k_{1} &= f(t_{n},y_{n}), \\
k_{2} &= f\!\left(t_{n}+\tfrac{h}{2},\, y_{n}+\tfrac{h}{2}k_{1}\right), \\
y_{n+1} &= y_{n}+h\,k_{2}.
\end{aligned}
$$

Order 2; evaluates the slope at the predicted midpoint.

### Heun / improved Euler (explicit RK2)

$$
\begin{aligned}
k_{1} &= f(t_{n},y_{n}), \\
k_{2} &= f(t_{n}+h,\, y_{n}+h\,k_{1}), \\
y_{n+1} &= y_{n}+\tfrac{h}{2}(k_{1}+k_{2}).
\end{aligned}
$$

Order 2; averages the left and predicted-right slopes (trapezoidal
predictor–corrector flavour). On linear autonomous $y'=\lambda y$,
Heun and midpoint produce the same one-step map.

### Forward Euler (RK1 contrast)

$$
y_{n+1}=y_{n}+h\,f(t_{n},y_{n})
$$

is the one-stage Runge–Kutta method of order 1 — the sibling
[Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration)
baseline, included here only for catalogue comparison.

### Error comparison

On a smooth problem (e.g. $y'=-y$) with the **same** step size $h$,
classic RK4 typically yields errors orders of magnitude smaller than
forward Euler:

$$
\text{error}_{\mathrm{RK4}}\ll\text{error}_{\mathrm{Euler}}.
$$

Halving $h$ cuts RK4 global error by roughly $16$ (order 4) versus
roughly $2$ for Euler (order 1).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `ODE_Fn` | Domain model |
| Steps | `Step_RK4`, `Step_Midpoint`, `Step_Heun`, `Step_Euler` | One-step updates |
| Interval | `Integrate_RK4`, `Integrate_Midpoint`, `Integrate_Heun`, `Integrate_Euler` | Equal-$h$ solvers |
| Exact | `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| Samples | `F_Decay`, `F_Growth`, `F_Decay_2`, `F_Stiff`, `F_Logistic` | $y'=\lambda y$, logistic |
| Helpers | `Near`, `Abs_Error` | Comparisons |
| Errors | `Invalid_Argument` | Bad $h$ / interval |

Strong typing uses `Positive_Real` / `Non_Negative` where helpful.
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Scalar IVP $y'=f(t,y)$ with access-to-subprogram RHS
- Classic RK4, midpoint RK2, Heun RK2, Euler RK1 contrast
- Equal-step interval integration for each method
- Linear test $y'=\lambda y$ vs $e^{\lambda t}$; order / refinement studies
- Classroom demonstration that $\mathrm{RK4}\ll\mathrm{Euler}$ error for fixed $h$

Out of scope:

- Systems / vector ODEs and a full general Butcher-tableau framework
- Adaptive step-size control, embedded pairs (RK45), dense output
- Implicit / stiff RK (Radau, Lobatto, …); **Backward Euler** sibling later
- Production multistep / multigrid / PDE discretizations (upcoming rows)

## Usage

```ada
with Runge_Kutta; use Runge_Kutta;

--  y' = -y, y(0)=1 → y(1)≈e^{-1}
declare
   Y : Real;
begin
   Y := Integrate_RK4 (F_Decay'Access, 0.0, 1.0, 1.0, 100);
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `ODE_Fn` | $f(t,y)$ access-to-function |
| `Step_RK4` | Classic 4-stage RK4 step |
| `Step_Midpoint` | Explicit midpoint (RK2) step |
| `Step_Heun` | Heun / improved Euler (RK2) step |
| `Step_Euler` | Forward Euler (RK1) contrast step |
| `Integrate_RK4` | Equal-step RK4 interval solver |
| `Integrate_Midpoint` | Equal-step midpoint solver |
| `Integrate_Heun` | Equal-step Heun solver |
| `Integrate_Euler` | Equal-step Euler contrast solver |
| `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| `Near` / `Abs_Error` | Comparison helpers |
| `F_Decay` / `F_Growth` / `F_Decay_2` / `F_Stiff` / `F_Logistic` | Sample RHS |
| `Invalid_Argument` | Domain errors ($h\le 0$, bad interval) |

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision.
- Scalar ODE only; classical RK4 is conditionally stable (not A-stable).
- No adaptive $h$, no embedded error estimate, no general tableau interpreter.
- Stiff problems still need small $h$ with these explicit methods;
  implicit / BDF material is deferred to sibling sheets.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Prunge_kutta.gpr
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
| `runge_kutta.ads` | Package spec |
| `runge_kutta.adb` | Package body |
| `runge_kutta.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Runge–Kutta methods](https://en.wikipedia.org/wiki/Runge%E2%80%93Kutta_methods)
- [Ada-Euler-Integration](https://github.com/RobertBoettcherSF/Ada-Euler-Integration) (sibling)
- Hairer, E.; Nørsett, S. P.; Wanner, G. *Solving Ordinary Differential Equations I*.
- Butcher, J. C. *Numerical Methods for Ordinary Differential Equations*.
- Iserles, A. (1996). *A First Course in the Numerical Analysis of Differential Equations*.
