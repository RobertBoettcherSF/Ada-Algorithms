# BFGS Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Broyden–Fletcher–Goldfarb–Shanno (BFGS)** quasi-Newton method for
**unconstrained** minimization of a smooth objective
$f:\mathbb{R}^n\to\mathbb{R}$. The package maintains an approximate
**inverse Hessian** $H$ and takes search directions $p=-Hg$, updating $H$
from successive displacement / gradient-change pairs $(s,y)$ without
forming second derivatives.

Based on [Wikipedia: Broyden–Fletcher–Goldfarb–Shanno algorithm](https://en.wikipedia.org/wiki/Broyden–Fletcher–Goldfarb–Shanno_algorithm)
(Broyden, Fletcher, Goldfarb, and Shanno, 1970).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Gauss-Newton](../ada-gauss-newton/)**,
**[Ada-Levenberg-Marquardt](../ada-levenberg-marquardt/)**,
**[Ada-Nelder-Mead](../ada-nelder-mead/)** — nonlinear least squares and
derivative-free search.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Quasi-Newton with inverse Hessian $H$ | No explicit $\nabla^2 f$ |
| **Direction** | $p=-H g$, $g=\nabla f$ | $O(n^2)$ mat-vec |
| **Line search** | Armijo backtracking on $\alpha$ | Geometric shrink $\rho$ |
| **Update** | BFGS formula with $\rho=1/(y^\top s)$ | Skip if $y^\top s\le 0$ |
| **Init** | $H_0=I$; optional scaled $I$ after step 1 | $(s^\top y/y^\top y)\,I$ |
| **Gradient** | Analytical `Gradient_Fn` or central FD | FD when `Grad` is null |
| **Stop** | $\|\nabla f\|$, $\|\alpha p\|$, or max iters | Reports `Success` |
| **Dim** | $n\le 8$ | `Max_Dim = 8` |

## Brief history

Charles G. Broyden, Roger Fletcher, Donald Goldfarb, and David F. Shanno
independently proposed related rank-two updates around 1970. BFGS became the
most widely used member of the **DFP / BFGS** quasi-Newton family for smooth
unconstrained problems. Limited-memory **L-BFGS** and bound-constrained
**BFGS-B** variants extend the idea to large $n$ and simple constraints;
this package is the dense, unconstrained textbook form.

## Problem statement

Minimize a twice continuously differentiable scalar objective

$$
\min_{x\in\mathbb{R}^n} f(x)
$$

with no constraints on $x$. At iterate $x_k$ let $g_k=\nabla f(x_k)$. A
Newton step would solve $\nabla^2 f(x_k)\,p_k=-g_k$; BFGS replaces the true
Hessian by a positive-definite approximation $B_k$ (or, equivalently, works
with $H_k\approx B_k^{-1}$).

## Inverse-Hessian form (this package)

This implementation stores $H_k\approx(\nabla^2 f)^{-1}$ and forms

$$
p_k=-H_k g_k.
$$

A **line search** then chooses $\alpha_k>0$ and sets

$$
x_{k+1}=x_k+\alpha_k p_k,\qquad
s_k=x_{k+1}-x_k,\qquad
y_k=g_{k+1}-g_k.
$$

With $\rho_k=1/(y_k^\top s_k)$ (when the **curvature condition**
$y_k^\top s_k>0$ holds), the BFGS inverse update is

$$
H_{k+1}=(I-\rho_k s_k y_k^\top)\,H_k\,(I-\rho_k y_k s_k^\top)
+\rho_k s_k s_k^\top.
$$

If $y_k^\top s_k\le 0$, the update is **skipped** (safeguard) and $H$ is left
unchanged. After the first successful step the package may replace $H$ by the
scaled identity $(s^\top y/y^\top y)\,I$ before applying the first BFGS update
(`Config.Scale_Initial_H`, default `True`).

## Line search (Armijo backtracking)

Starting from $\alpha=1$, accept the first step size that satisfies the
**Armijo / sufficient-decrease** condition

$$
f(x+\alpha p)\le f(x)+c_1\,\alpha\,(g^\top p),
$$

with default $c_1=10^{-4}$. On failure, set $\alpha\leftarrow\rho\alpha$
(default $\rho=1/2$) and retry up to `Max_Line_Search` times. This is a
simple geometric shrink — not a full Wolfe line search — documented so tests
can exercise `Armijo_Accept` and `Line_Search` directly.

## One iteration (sketch)

1. Evaluate $f(x)$ and $g=\nabla f(x)$ (analytical or central finite
   differences with step `Fd_Eps·(1+|x_i|)`).
2. Form search direction $p=-Hg$. If $g^\top p\ge 0$, reset $H\leftarrow I$
   and use $p=-g$.
3. Armijo backtracking for $\alpha$; set $x\leftarrow x+\alpha p$.
4. Form $s=\alpha p$, $y=g_{\mathrm{new}}-g_{\mathrm{old}}$.
5. Optionally scale $H$ on the first step; then apply `BFGS_Update` (or skip
   when $y^\top s\le 0$).
6. Stop when $\|g\|\le$ `Grad_Tol`, $\|\alpha p\|\le$ `Step_Tol`, or
   `Max_Iterations` is exhausted.

## Versus Newton / Gauss–Newton / Levenberg–Marquardt / Nelder–Mead

| | BFGS (this) | Newton | Gauss–Newton / LM | Nelder–Mead |
| --- | --- | --- | --- | --- |
| Uses | $f$, $\nabla f$ | $f$, $\nabla f$, $\nabla^2 f$ | residuals $r$, $J$ | $f$ only |
| Curvature | Rank-2 $H$ from $(s,y)$ | Exact Hessian | $J^\top J$ (+ $\lambda$) | None |
| Cost / iter | $O(n^2)$ | $O(n^3)$ factor / solve | $O(mn^2)$ NLS | Simplex ops |
| Problem class | General smooth min | General smooth min | Nonlinear least squares | Derivative-free |
| Stabilization | Armijo $\alpha$; skip bad $y^\top s$ | Line search / trust | LM damping | Reflect/contract |

Prefer **BFGS** for general smooth unconstrained $f$ when gradients are
available (or cheap to difference) but Hessians are not. Prefer **GN/LM**
when the objective is explicitly a sum of squares. Prefer **Nelder–Mead**
when only black-box values exist. Prefer **Newton** when an accurate
Hessian is cheap and well-conditioned.

## Built-in demo objectives

| Objective | Form | Global min |
| --- | --- | --- |
| `Sphere` | $\sum x_i^2$ | $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | $0$ at $(1,1)$ |
| `Quadratic_Bowl` | $\tfrac12\sum i\,x_i^2$ | $0$ at origin |
| `Himmelblau` | $(x^2+y-11)^2+(x+y^2-7)^2$ | $0$ at four points |
| `Shifted_Sphere` | $\sum(x_i-1)^2$ | $0$ at $(1,\ldots,1)$ |

Each exposes a matching analytical `*_Grad` for tests against
`Finite_Difference_Gradient`.

## API (`BFGS`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point` / `Vector`, `Matrix`, `Config`, `Result`, `Objective_Fn`, `Gradient_Fn` | Domain / callbacks |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale`, `Mat_Vec`, `Identity`, `Outer`, `Mat_Add`, `Mat_Scale` | Linear algebra |
| Core | `BFGS_Update`, `Finite_Difference_Gradient`, `Line_Search`, `Armijo_Accept` | Update / FD / Armijo |
| Demos | `Sphere`, `Rosenbrock`, `Quadratic_Bowl`, `Himmelblau`, `Shifted_Sphere` (+ `*_Grad`) | Test objectives |
| Driver | `Minimize` | BFGS loop |

Named exceptions: `Invalid_Argument` (e.g. Rosenbrock / Himmelblau need
$\ge 2$ coordinates), `Line_Search_Failed` (no Armijo $\alpha$ within
budget; the driver then stops and reports current progress).

`Config` defaults: `Max_Iterations=200`, `Grad_Tol=1e-8`,
`Step_Tol=1e-10`, `Fd_Eps=1e-7`, `Armijo_C=1e-4`,
`Line_Search_Rho=0.5`, `Max_Line_Search=30`, `Scale_Initial_H=True`.

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

- [Wikipedia: Broyden–Fletcher–Goldfarb–Shanno algorithm](https://en.wikipedia.org/wiki/Broyden–Fletcher–Goldfarb–Shanno_algorithm)
- Nocedal, J. & Wright, S. *Numerical Optimization*, 2nd ed., Springer, 2006
  (Ch. 6, quasi-Newton methods)
- Sibling packages in this series: Gauss–Newton, Levenberg–Marquardt,
  Nelder–Mead
