# Newton's Method in Optimization — Ada 2023

Educational, self-contained Ada 2023 package implementing **Newton's method
in optimization** for **unconstrained** minimization of a smooth objective
$f:\mathbb{R}^n\to\mathbb{R}$. At each iterate the package forms (or
approximates) the Hessian $H(x)=\nabla^2 f(x)$, solves the Newton system

$$
H(x)\,p=-\nabla f(x),
$$

and updates $x\leftarrow x+\alpha p$ with either a **pure** step $\alpha=1$
or **Armijo backtracking** (damped / relaxed Newton). Optional educational
**Hessian regularization** adds $\tau I$ when $H$ is not positive-definite.

Based on [Wikipedia: Newton's method in optimization](https://en.wikipedia.org/wiki/Newton%27s_method_in_optimization).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-BFGS](../ada-bfgs/)**,
**[Ada-Gauss-Newton](../ada-gauss-newton/)**,
**[Ada-Levenberg-Marquardt](../ada-levenberg-marquardt/)**,
**[Ada-Nonlinear-Optimization](../ada-nonlinear-optimization/)** — quasi-Newton,
NLS, and the broader NLP survey.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Critical points of $f$ via Newton on $\nabla f$ | Min / max / saddle |
| **Direction** | Solve $H p=-\nabla f$ | Dense GE, $n\le 8$ |
| **Update** | $x\leftarrow x+\alpha p$ | Pure $\alpha=1$ or Armijo |
| **Hessian** | Analytical `Hessian_Fn` or central FD | FD when `Hess` is null |
| **Gradient** | Analytical `Gradient_Fn` or central FD | FD when `Grad` is null |
| **Stabilization** | Optional $\tau I$ if $H$ not PD-ish | Documented educational |
| **Stop** | $\|\nabla f\|$, $\|\alpha p\|$, or max iters | Reports `Success` |
| **Dim** | $n\le 8$ | `Max_Dim = 8` |

## Brief history

Newton–Raphson root-finding applied to $f'=0$ yields the optimization form
of Newton's method. In several variables the scalar second derivative is
replaced by the **Hessian** $\nabla^2 f$, and the step solves a linear
system rather than dividing by $f''(x)$. Damped / relaxed variants choose
$\alpha\neq 1$ (e.g. Armijo) for global reliability; quasi-Newton methods
(BFGS) and Gauss–Newton / Levenberg–Marquardt approximate curvature without
a full analytic Hessian of a general $f$.

## Problem statement

Minimize a twice continuously differentiable scalar objective

$$
\min_{x\in\mathbb{R}^n} f(x)
$$

with no constraints on $x$. Stationary points satisfy $\nabla f(x)=0$.
Newton's method builds a local **quadratic model**

$$
f(x+p)\approx f(x)+\nabla f(x)^\top p+\tfrac12 p^\top H(x)\,p
$$

and chooses the minimizer of that model (when $H(x)$ is positive definite)
by solving $H(x)\,p=-\nabla f(x)$.

## Pure and damped Newton (this package)

**Pure Newton** uses the full step:

$$
x_{k+1}=x_k+p_k,\qquad H(x_k)\,p_k=-\nabla f(x_k).
$$

**Damped Newton** (`Config.Use_Line_Search=True`, default) starts from
$\alpha=1$ and accepts the first Armijo step size satisfying

$$
f(x+\alpha p)\le f(x)+c_1\,\alpha\,(\nabla f(x)^\top p),
$$

with default $c_1=10^{-4}$; otherwise $\alpha\leftarrow\rho\alpha$ (default
$\rho=1/2$).

For an exact **positive-definite quadratic**, pure Newton reaches the
minimizer in **one** iteration from any start (see `Quadratic_Bowl`).

## Hessian regularization (educational)

If $H$ is indefinite or singular, the Newton direction may fail to exist or
fail to be a descent direction. When `Config.Hessian_Regularization` is
`True` (default), the package uses an educational **Sylvester / leading-minor**
PD-ish check (`Is_Positive_Definite_Ish`). If it fails, it forms

$$
\tilde H = H + \tau I
$$

and grows $\tau$ from `Reg_Tau0` by `Reg_Tau_Grow` until $\tilde H$ is PD-ish
or $\tau$ hits `Reg_Tau_Max` — the Levenberg-style diagonal shift described
on Wikipedia. This is **not** a full modified-Cholesky or trust-region
method; it is documented so tests can exercise `Regularize_Hessian` /
`Make_PD_Hessian` directly. The driver also falls back to steepest descent
if the linear solve raises `Singular_System` or $p$ is not a descent
direction ($\nabla f^\top p\ge 0$).

## One iteration (sketch)

1. Evaluate $f(x)$ and $g=\nabla f(x)$ (analytical or central FD with step
   `Fd_Eps·(1+|x_i|)`).
2. Form $H=\nabla^2 f(x)$ (analytical or FD Hessian with `Fd_Hess_Eps`).
3. Optionally replace $H$ by $H+\tau I$ until PD-ish.
4. Solve $H p=-g$ (`Newton_Direction` / `Solve_Linear`).
5. Choose $\alpha=1$ or Armijo backtracking; set $x\leftarrow x+\alpha p$.
6. Stop when $\|g\|\le$ `Grad_Tol`, $\|\alpha p\|\le$ `Step_Tol`, or
   `Max_Iterations` is exhausted.

## Versus root-finding Newton / Gauss–Newton / BFGS / LM

| | Newton (this, optimization) | Root-finding Newton | Gauss–Newton / LM | BFGS |
| --- | --- | --- | --- | --- |
| Goal | $\min f$ via $\nabla f=0$ | Solve $F(x)=0$ | $\min\tfrac12\|r\|^2$ | $\min f$ |
| Uses | $f$, $\nabla f$, $\nabla^2 f$ | $F$, $F'$ / $J_F$ | residuals $r$, $J$ | $f$, $\nabla f$ |
| Curvature | Exact Hessian $H$ | Jacobian of $F$ | $J^\top J$ (+ $\lambda$) | Rank-2 inverse $H$ |
| Cost / iter | $O(n^3)$ factor / solve | Similar local solve | $O(mn^2)$ NLS | $O(n^2)$ update |
| Stabilization | Armijo $\alpha$; optional $\tau I$ | Damping / guarding | LM $\lambda$ | Armijo; skip bad $y^\top s$ |

- **Root-finding Newton** finds zeros of a vector map $F$; the optimization
  form is that method applied to $F=\nabla f$.
- Prefer **Gauss–Newton / LM** when $f$ is explicitly a sum of squares.
- Prefer **BFGS** when gradients are available but Hessians are expensive
  or noisy.
- Prefer **this Newton package** when an accurate Hessian is cheap and
  (locally) positive definite — e.g. exact quadratics, or well-scaled
  smooth demos.

## Built-in demo objectives

| Objective | Form | Global min | Notes |
| --- | --- | --- | --- |
| `Sphere` | $\sum x_i^2$ | $0$ at origin | Exact Newton: 1 step |
| `Quadratic_Bowl` | $\tfrac12\sum i\,x_i^2$ | $0$ at origin | Exact Newton: 1 step |
| `Shifted_Sphere` | $\sum(x_i-1)^2$ | $0$ at $(1,\ldots,1)$ | Exact Newton: 1 step |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | $0$ at $(1,1)$ | Needs damping |
| `Himmelblau` | $(x^2+y-11)^2+(x+y^2-7)^2$ | $0$ at four points | Multimodal |
| `Quartic_1D` | $(x-3)^4$ | $0$ at $x=3$ | $H=0$ at the min |

Each exposes matching analytical `*_Grad` / `*_Hess` for checks against
`Finite_Difference_Gradient` / `Finite_Difference_Hessian`.

## API (`Newtons_Method_Optimization`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point` / `Vector`, `Matrix`, `Config`, `Result`, `Objective_Fn`, `Gradient_Fn`, `Hessian_Fn` | Domain / callbacks |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale`, `Mat_Vec`, `Identity`, `Mat_Add`, `Mat_Scale`, `Quadratic_Form` | Linear algebra |
| Linear / PD | `Solve_Linear`, `Is_Symmetric`, `Is_Positive_Definite_Ish`, `Regularize_Hessian`, `Make_PD_Hessian` | GE solve / $\tau I$ |
| Core | `Finite_Difference_Gradient`, `Finite_Difference_Hessian`, `Newton_Direction`, `Line_Search`, `Armijo_Accept` | FD / Newton / Armijo |
| Demos | `Sphere`, `Quadratic_Bowl`, `Rosenbrock`, `Himmelblau`, `Quartic_1D`, `Shifted_Sphere` (+ `*_Grad` / `*_Hess`) | Test objectives |
| Driver | `Minimize` | Newton / damped Newton loop |

Named exceptions: `Invalid_Argument` (e.g. Rosenbrock / Himmelblau need
$\ge 2$ coordinates), `Line_Search_Failed` (no Armijo $\alpha$ within
budget), `Singular_System` (dense solve fails).

`Config` defaults: `Max_Iterations=100`, `Grad_Tol=1e-8`,
`Step_Tol=1e-12`, `Fd_Eps=1e-7`, `Fd_Hess_Eps=1e-5`, `Armijo_C=1e-4`,
`Line_Search_Rho=0.5`, `Max_Line_Search=30`, `Use_Line_Search=True`,
`Hessian_Regularization=True`, `Reg_Tau0=1e-6`, `Reg_Tau_Grow=10`,
`Reg_Tau_Max=1e8`.

`Result` fields: `Final_Point`, `Final_Value`, `Final_Grad_Norm`, `Dim`,
`Iterations`, `Success`, `Regularized`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Newton's method in optimization](https://en.wikipedia.org/wiki/Newton%27s_method_in_optimization)
- Nocedal, J. & Wright, S. *Numerical Optimization*, 2nd ed., Springer, 2006
  (Ch. 3, line search; Ch. 6–7, Newton / quasi-Newton)
- Sibling packages in this series: BFGS, Gauss–Newton, Levenberg–Marquardt,
  Nonlinear-Optimization
