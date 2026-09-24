# Line Search — Ada 2023

Educational, self-contained Ada 2023 package implementing **line search**
methods that choose a step length $\alpha>0$ along a descent direction $p$
so that the restriction

$$
\varphi(\alpha)=f(x+\alpha p)
$$

decreases sufficiently. The package covers **Armijo backtracking**,
**(strong) Wolfe** approximate conditions, **golden-section** /
**Fibonacci** exact one-dimensional search for unimodal $\varphi$, a
**fixed step**, and an **exact quadratic** closed form.

Based on [Wikipedia: Line search](https://en.wikipedia.org/wiki/Line_search)
(Nocedal–Wright; Dennis–Schnabel).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-BFGS](../ada-bfgs/)**,
**[Ada-Newtons-Method-in-Optimization](../ada-newtons-method-in-optimization/)**
— quasi-Newton and Newton outer iterations that call a line search for
$\alpha$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Choose $\alpha$ along $p$ | Inner step of gradient / Newton / BFGS |
| **Armijo** | $\varphi(\alpha)\le\varphi(0)+c_1\alpha\varphi'(0)$ | Backtrack $\alpha\leftarrow\rho\alpha$ |
| **Wolfe** | Armijo + curvature on $\varphi'$ | Weak or strong ($c_2$) |
| **Exact 1-D** | Golden-section / Fibonacci | Unimodal $\varphi$ on $[a,b]$ |
| **Quadratic** | $\alpha^\*=-B/(2C)$ for $A+B\alpha+C\alpha^2$ | Closed form when $C>0$ |
| **Fixed** | Return given $\alpha$ | Baseline / learning-rate step |
| **Gradient** | Analytical `Grad_Fn` or FD | FD when `Grad` is null |
| **Result** | `Alpha`, `Success`, `Evals` | Evaluation counter included |

## Brief history

Line search is the classical companion to descent methods: once a direction
$p$ with $\varphi'(0)=\nabla f(x)^\top p<0$ is known, one selects how far to
move. Exact searches minimize $\varphi$ in one dimension; **inexact**
searches (Armijo, Wolfe, Goldstein) only enforce **sufficient decrease**
and optional **curvature**, which is enough for global convergence theorems
and usually far cheaper. Golden-section and Fibonacci search are optimal
zero-order schemes for unimodal restrictions.

## Problem statement

Given $x\in\mathbb{R}^n$, a descent direction $p$, and smooth
$f:\mathbb{R}^n\to\mathbb{R}$, define

$$
\varphi(\alpha)=f(x+\alpha p),\qquad
\varphi'(0)=\nabla f(x)^\top p.
$$

A line search returns $\alpha>0$ (approximately) minimizing $\varphi$ or
satisfying acceptance conditions, then the outer method sets
$x\leftarrow x+\alpha p$.

## Armijo backtracking

Start from $\alpha=\texttt{Alpha0}$ (default $1$). Accept the first trial
that satisfies the **Armijo / sufficient-decrease** condition

$$
\varphi(\alpha)\le\varphi(0)+c_1\,\alpha\,\varphi'(0),
$$

with default $c_1=10^{-4}$. On failure, set $\alpha\leftarrow\rho\alpha$
(default $\rho=1/2$) and retry up to `Max_Backtracks` times. If
$\varphi'(0)\ge 0$ (ascent or flat), the search reports `Success=False`.

## Wolfe / strong Wolfe

In addition to Armijo, require a **curvature** condition. With
$c_1<c_2<1$ (default $c_2=0.9$):

Weak Wolfe:

$$
\varphi'(\alpha)\ge c_2\,\varphi'(0)
$$

Strong Wolfe:

$$
\bigl|\varphi'(\alpha)\bigr|\le c_2\,\bigl|\varphi'(0)\bigr|
$$

`Config.Strong_Wolfe` selects the strong form (default). Trial derivatives
use the analytical `Grad_Fn` when provided, otherwise a central
finite-difference estimate of $\varphi'$.

## Exact one-dimensional search

For unimodal $\varphi$ on a bracket $[a,b]$:

- **Golden-section** places interior probes at the golden ratio
  $1/\varphi\approx 0.618$ and reuses one evaluation per iteration.
- **Fibonacci search** places probes from Fibonacci ratios and likewise
  needs one new evaluation per shrink (this package evaluates both
  interiors each round for clarity).

Both return the midpoint of the final bracket as `Alpha`.

## Fixed step and exact quadratic

`Fixed_Step(α)` returns the given positive step with `Evals=0`.

For a quadratic model $\varphi(\alpha)=A+B\alpha+C\alpha^2$ with $C>0$,

$$
\alpha^\*=-\frac{B}{2C}.
$$

`Exact_Quadratic` returns that closed form (`Success=False` when $C\le 0$).

## Built-in demo objectives

| Objective | Form | Role |
| --- | --- | --- |
| `Sphere` | $\sum x_i^2$ | Easy directional Armijo / Wolfe demos |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Nonlinear directional demos |
| `Quadratic_1D` | $(\alpha-2)^2$ | Golden / Fibonacci / exact quadratic |
| `Quartic_Unimodal` | $(\alpha-1.5)^4+0.1(\alpha-1.5)^2$ | Unimodal exact 1-D |

Each multi-D demo exposes a matching analytical `*_Grad` for tests against
`Directional_Derivative_FD`.

## API (`Line_Search`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Config`, `Result`, `Objective_Fn`, `Grad_Fn`, `Scalar_Fn` | Domain / callbacks |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale` | Linear algebra |
| Predicates | `Armijo_Accept`, `Wolfe_Curvature_Accept`, `Directional_Derivative`, `Directional_Derivative_FD` | Conditions / $\varphi'$ |
| Core | `Armijo_Backtrack`, `Wolfe_Line_Search`, `Golden_Section`, `Fibonacci_Search`, `Fixed_Step`, `Exact_Quadratic` | Algorithms |
| Demos | `Sphere`, `Rosenbrock`, `Quadratic_1D`, `Quartic_Unimodal` (+ grads) | Test objectives |

## Build and test

```bash
make clean && make
make test
```

Requires GNAT (`gnatmake`) with Ada 2022 mode (`-gnatwa -gnat2022`). The
test driver `tests.adb` is the project main; there is no separate
`main.adb`. Expect `Fail_Count=0` and `Pass_Count >= 100`.

## Caveats

- Educational dense $n\le 8$ vectors; not a production optimizer.
- Wolfe here is **backtracking with a curvature check**, not a full
  Moré–Thuente or Hager–Zhang bracketing zoom.
- Golden / Fibonacci assume **unimodal** $\varphi$ on the supplied
  interval; multimodal $\varphi$ may return a non-global point.
- Finite-difference $\varphi'$ is sensitive to `Fd_Eps` and scaling of $p$.
