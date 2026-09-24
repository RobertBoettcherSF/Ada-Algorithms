# Euler method (Euler integration) — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Euler method](https://en.wikipedia.org/wiki/Euler_method)
([Euler integration](https://en.wikipedia.org/wiki/Euler_integration)):
the **explicit first-order** one-step method for the IVP $y'=f(t,y)$

$$
y_{n+1}=y_{n}+h f(t_{n},y_{n}).
$$

It is the simplest Runge–Kutta scheme and the baseline against which
higher-order and implicit methods are compared. Conditionally stable:
amplification $R(z)=1+z$ on the linear test equation; the region of
absolute stability is the closed disk $|1+z|\le 1$ in the complex plane.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).
Classroom `Long_Float`-class arithmetic (`Real` digits 15).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling: [Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE)
(implicit trapezoidal / Heun). Upcoming numerical DE / ODE track:
Runge–Kutta, Lax–Wendroff, FDM, Crank–Nicolson, Euler method row later,
**Backward Euler**, …

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **RHS** | `ODE_Fn` access-to-function | $f(t,y)$ pointer style |
| **Step** | `Step` | Forward Euler one step |
| **Interval** | `Integrate` | $N$ equal steps on $[t_0,t_1]$ |
| **Linear test** | `Amplification`, `Exact_Exponential` | $R(z)=1+z$, $e^{\lambda t}$ |
| **Mechanical sketch** | `Step_Semi_Implicit` | Symplectic Euler for $y''=G(y)$ |
| **Helpers** | `Near`, `Abs_Error` | Classroom utilities |
| **Domain error** | `Invalid_Argument` | $h\le 0$, bad interval |

## Method

Suppose we solve

$$
y'=f(t,y).
$$

The **forward Euler** method advances one step of size $h=t_{n+1}-t_{n}$ by

$$
y_{n+1}=y_{n}+h f(t_{n},y_{n}).
$$

Geometrically this follows the tangent line at $(t_{n},y_{n})$ for a
distance $h$. Algebraically it is the left Riemann (rectangle) quadrature
of $y'=f(t,y(t))$ over $[t_{n},t_{n+1}]$.

### Motivation (quadrature)

Integrating $y'=f(t,y(t))$ from $t_{n}$ to $t_{n+1}$ gives

$$
y(t_{n+1})-y(t_{n})=\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t.
$$

The left rectangular rule approximates the integrand by its value at the
left endpoint,

$$
\int_{t_{n}}^{t_{n+1}}f(t,y(t))\,\mathrm{d}t
\approx
h\,f(t_{n},y(t_{n})),
$$

which yields the Euler step with $y_{n}\approx y(t_{n})$.

### Error

Local truncation error is $O(h^{2})$; the method is **first-order**:
global error $O(h)$ as $h\to 0$ (halving $h$ roughly halves the error).

### Absolute stability

On the linear test equation $y'=\lambda y$, one step multiplies by the
stability function

$$
R(z)=1+z,\qquad z=h\lambda.
$$

Absolute stability requires $|R(z)|\le 1$, i.e. the closed disk of radius
$1$ centered at $-1$ in the complex $z$-plane. On the negative real axis
this is the interval $z\in[-2,0]$, or equivalently

$$
0<h\le\frac{2}{|\lambda|}\qquad(\lambda<0).
$$

Outside that disk the numerical solution grows even when the true solution
decays — classic explicit Euler limitation on stiff problems.
`Amplification(Z)` returns $R(Z)=1+Z$.

### Semi-implicit (symplectic) Euler sketch

For a mechanical second-order equation $y''=G(y)$, reduced to
$y'=v$, $v'=G(y)$, the **semi-implicit** (symplectic) Euler update

$$
\begin{aligned}
v_{n+1} &= v_{n}+h\,G(y_{n}),\\
y_{n+1} &= y_{n}+h\,v_{n+1}
\end{aligned}
$$

is exposed as `Step_Semi_Implicit` (sample force `G_Harmonic` for
$y''=-y$). It is a pedagogical contrast, not a full geometric-integration
library. **Backward Euler** is a separate upcoming sheet row.

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `ODE_Fn`, `Force_Fn` | Domain model |
| Step | `Step` | One forward Euler step |
| Interval | `Integrate` | Multi-step equal-$h$ |
| Linear test | `Amplification`, `Exact_Exponential` | $R(z)$, exact $e^{\lambda t}$ |
| Mechanical | `Step_Semi_Implicit`, `G_Harmonic` | Symplectic Euler sketch |
| Samples | `F_Decay`, `F_Growth`, `F_Decay_2`, `F_Stiff`, `F_Logistic` | $y'=\lambda y$, logistic |
| Helpers | `Near`, `Abs_Error` | Comparisons |
| Errors | `Invalid_Argument` | Bad $h$ / interval |

Strong typing uses `Positive_Real` / `Non_Negative` where helpful.
Public subprograms carry `Pre` / `Global` where meaningful
(`SPARK_Mode => Off`).

## Educational scope

In scope:

- Scalar IVP $y'=f(t,y)$ with access-to-subprogram RHS
- Forward Euler step and equal-step interval integration
- Linear test $y'=\lambda y$ vs $e^{\lambda t}$; stability helper $R(z)=1+z$
- Sample decay / growth / logistic RHS; refinement $\Rightarrow$ smaller error
- Optional semi-implicit Euler sketch for $y''=G(y)$

Out of scope:

- Systems / vector ODEs and full Butcher-tableau RK frameworks
- Adaptive step-size control and dense output
- Production stiff solvers (BDF, Radau, …); **Backward Euler** sibling later
- Full geometric / variational integrators beyond the one-step sketch

## Usage

```ada
with Euler_Integration; use Euler_Integration;

--  y' = -y, y(0)=1 → y(1)≈e^{-1}
declare
   Y : Real;
begin
   Y := Integrate (F_Decay'Access, 0.0, 1.0, 1.0, 100);
end;
```

## API summary

| Symbol | Role |
| --- | --- |
| `ODE_Fn` | $f(t,y)$ access-to-function |
| `Force_Fn` | $G(y)$ for $y''=G(y)$ sketch |
| `Step` | One forward Euler step |
| `Integrate` | Equal-step interval solver |
| `Amplification` | Stability function $R(z)=1+z$ |
| `Exact_Exponential` | $Y_0\,e^{\lambda t}$ |
| `Near` / `Abs_Error` | Comparison helpers |
| `Step_Semi_Implicit` | Symplectic Euler $(y,v)$ update |
| `F_Decay` / `F_Growth` / `F_Decay_2` / `F_Stiff` / `F_Logistic` | Sample RHS |
| `G_Harmonic` | $G(y)=-y$ for oscillator sketch |
| `Invalid_Argument` | Domain errors ($h\le 0$, bad interval) |

## Limitations / caveats

- Educational **Float / Long_Float-class** arithmetic (`Real` digits 15):
  not arbitrary precision.
- Scalar ODE only; first-order global accuracy $O(h)$.
- Conditionally stable: stiff decays need $h\le 2/|\lambda|$ (real $\lambda<0$).
- Semi-implicit Euler is a minimal mechanical sketch, not a general $N$-body
  or constrained integrator.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Peuler_integration.gpr
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
| `euler_integration.ads` | Package spec |
| `euler_integration.adb` | Package body |
| `euler_integration.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- [Wikipedia: Euler method](https://en.wikipedia.org/wiki/Euler_method)
- [Wikipedia: Euler integration](https://en.wikipedia.org/wiki/Euler_integration)
- [Ada-Trapezoidal-Rule-DE](https://github.com/RobertBoettcherSF/Ada-Trapezoidal-Rule-DE) (sibling)
- Hairer, E.; Nørsett, S. P.; Wanner, G. *Solving Ordinary Differential Equations I*.
- Iserles, A. (1996). *A First Course in the Numerical Analysis of Differential Equations*.
