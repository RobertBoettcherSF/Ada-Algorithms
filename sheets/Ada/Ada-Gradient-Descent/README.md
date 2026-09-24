# Gradient Descent — Ada 2023

Educational, self-contained Ada 2023 package implementing **gradient
descent** (and **gradient ascent**) for **unconstrained** minimization of a
smooth objective $f:\mathbb{R}^n\to\mathbb{R}$. The basic update is

$$
x\leftarrow x-\eta\nabla f(x)
$$

with optional **Armijo backtracking** along $-\nabla f$ and optional
**heavy-ball / Polyak momentum**
$v\leftarrow\beta v-\eta g$, $x\leftarrow x+v$.

Based on [Wikipedia: Gradient descent](https://en.wikipedia.org/wiki/Gradient_descent)
(Cauchy, 1847; Hadamard; Curry).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Line-Search](../ada-line-search/)**,
**[Ada-BFGS](../ada-bfgs/)**,
**[Ada-Nonlinear-Optimization](../ada-nonlinear-optimization/)** — line
search primitives, quasi-Newton, and a broader NLP survey that also hosts a
GD driver.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Steepest descent / ascent | First-order; no Hessian |
| **Fixed step** | $x\leftarrow x-\eta g$ | `Config.Step` = $\eta$ |
| **Line search** | Armijo along $-\nabla f$ | When `Use_Line_Search` |
| **Momentum** | Heavy-ball $v\leftarrow\beta v-\eta g$ | `Minimize_Momentum` |
| **Ascent** | $x\leftarrow x+\eta g$ | `Maximize` |
| **Gradient** | Analytical `Grad_Fn` or central FD | FD when `Grad` is null |
| **Stop** | $\|\nabla f\|$, $\|\Delta x\|$, or max iters | Reports `Success` |
| **Dim** | $n\le 8$ | `Max_Dim = 8` |

## Brief history

Augustin-Louis Cauchy suggested the method in 1847; Jacques Hadamard proposed
a related idea in 1907. Convergence for nonlinear problems was studied by
Haskell Curry (1944). Modern machine-learning training often uses **stochastic**
variants; this package is the classical full-batch / deterministic form, with
a simple momentum extension (Polyak heavy ball).

## Problem statement

Minimize (or maximize) a continuously differentiable scalar objective

$$
\min_{x\in\mathbb{R}^n} f(x)
$$

with no constraints on $x$. At iterate $x_k$ let $g_k=\nabla f(x_k)$. The
negative gradient $-\,g_k$ is the direction of **steepest descent** of $f$;
$+g_k$ is the direction of **steepest ascent**.

## Fixed step size

With learning rate $\eta>0$ (`Config.Step`):

$$
x_{k+1}=x_k-\eta\,g_k.
$$

For ascent (`Maximize`):

$$
x_{k+1}=x_k+\eta\,g_k.
$$

Too large an $\eta$ can diverge; too small an $\eta$ converges slowly. For
the sphere $f(x)=\|x\|^2$ with $g=2x$, any fixed $\eta\in(0,1)$ is stable.

## Armijo backtracking line search

When `Use_Line_Search` is `True`, the search direction is $p=-\nabla f$
(descent) and the package starts from $\alpha=\eta$, accepting the first
trial that satisfies the **Armijo / sufficient-decrease** condition

$$
f(x+\alpha p)\le f(x)+c_1\,\alpha\,(g^\top p),
$$

with default $c_1=10^{-4}$. On failure, set $\alpha\leftarrow\rho\alpha$
(default $\rho=1/2$) and retry up to `Max_Line_Search` times. Ascent applies
the same test to $-f$ along $+g$.

## Momentum / heavy ball

`Minimize_Momentum` maintains a velocity $v$ (initially $0$) and updates

$$
v\leftarrow\beta v-\eta g,\qquad x\leftarrow x+v
$$

with $\beta=$ `Momentum_Beta` $\in[0,1)$. When $\beta=0$ this reduces to
plain fixed-step gradient descent. Line search is **not** used in the
momentum driver (fixed $\eta$ only).

## One iteration (sketch)

1. Evaluate $f(x)$ and $g=\nabla f(x)$ (analytical or central finite
   differences with step `Fd_Eps·(1+|x_i|)`).
2. If $\|g\|\le$ `Grad_Tol`, stop with `Success`.
3. **Fixed / Armijo:** form $p=-g$ (or $+g$ for ascent); choose $\alpha$
   fixed or by Armijo; set $x\leftarrow x+\alpha p$.
4. **Momentum:** $v\leftarrow\beta v-\eta g$; $x\leftarrow x+v$.
5. Stop when $\|\Delta x\|\le$ `Step_Tol` or `Max_Iterations` is exhausted.

## Versus Line search / BFGS / Nonlinear optimization

| | Gradient descent (this) | Line search | BFGS | Nonlinear opt. survey |
| --- | --- | --- | --- | --- |
| Uses | $f$, $\nabla f$ | $f$, $\varphi(\alpha)$ along $p$ | $f$, $\nabla f$, rank-2 $H$ | GD / Newton / projected |
| Curvature | None (optional momentum) | N/A (inner $\alpha$) | Inverse Hessian $H$ | Optional Hessian |
| Step | Fixed $\eta$ or Armijo | Armijo / Wolfe / exact 1-D | Armijo on $p=-Hg$ | Configurable |
| Role | Outer first-order loop | Choose $\alpha$ given $p$ | Quasi-Newton outer | Taxonomy + drivers |

Prefer **this package** for a clear first-order baseline. Prefer the
**Line-Search** sibling when studying acceptance conditions in isolation.
Prefer **BFGS** when a cheap inverse-Hessian approximation is worthwhile.
See **Nonlinear-Optimization** for a side-by-side GD / Newton survey.

## Built-in demo objectives

| Objective | Form | Global min |
| --- | --- | --- |
| `Sphere` | $\sum x_i^2$ | $0$ at origin |
| `Quadratic_Bowl` | $\tfrac12\sum i\,x_i^2$ | $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | $0$ at $(1,1)$ |
| `Himmelblau` | $(x^2+y-11)^2+(x+y^2-7)^2$ | $0$ at four points |
| `Negated_Sphere` | $-\sum x_i^2$ | max $0$ at origin (ascent) |

Each exposes a matching analytical `*_Grad` for tests against
`Finite_Difference_Gradient`.

## API (`Gradient_Descent`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point` / `Vector`, `Config`, `Result`, `Objective_Fn`, `Grad_Fn` | Domain / callbacks |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale` | Linear algebra |
| Core | `Finite_Difference_Gradient`, `Armijo_Accept`, `Line_Search`, `Descent_Step`, `Ascent_Step`, `Momentum_Step` | FD / Armijo / steps |
| Demos | `Sphere`, `Quadratic_Bowl`, `Rosenbrock`, `Himmelblau`, `Negated_Sphere` (+ `*_Grad`) | Test objectives |
| Drivers | `Minimize`, `Maximize`, `Minimize_Momentum` | GD / ascent / heavy-ball |

Named exceptions: `Invalid_Argument` (Rosenbrock / Himmelblau need
$\ge 2$ coordinates), `Line_Search_Failed` (no Armijo $\alpha$ within
budget; the driver then stops and reports current progress).

`Config` defaults: `Max_Iterations=500`, `Step=0.1`, `Grad_Tol=1e-8`,
`Step_Tol=1e-12`, `Use_Line_Search=False`, `Momentum_Beta=0`,
`Armijo_C=1e-4`, `Line_Search_Rho=0.5`, `Max_Line_Search=40`,
`Fd_Eps=1e-7`.

`Result` fields: `Final_Point`, `Final_Value`, `Final_Grad_Norm`, `Dim`,
`Iterations`, `Success`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Gradient descent](https://en.wikipedia.org/wiki/Gradient_descent)
- Nocedal, J. & Wright, S. *Numerical Optimization*, 2nd ed., Springer, 2006
  (Ch. 3, line search methods)
- Polyak, B. T. Some methods of speeding up the convergence of iteration
  methods. *USSR Computational Mathematics and Mathematical Physics*, 1964
- Sibling packages in this series: Line-Search, BFGS, Nonlinear-Optimization


## SPARK / GNATprove (Level 2)

Parent package stays `SPARK_Mode => Off` (access-to-subprogram objectives and
`Generic_Elementary_Functions`). Standalone package `Gradient_Descent_Spark` is
`SPARK_Mode => On` and holds the flow-safe helpers (Near/Dot/Add/Scale/steps/
Sphere/Quadratic_Bowl/Negated_Sphere).

```bash
make prove
```

**Bar:** Level 2 on `Gradient_Descent_Spark`; all analyzed checks proved. `make test` green.
