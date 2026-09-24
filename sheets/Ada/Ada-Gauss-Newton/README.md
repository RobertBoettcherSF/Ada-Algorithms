# Gauss–Newton Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Gauss–Newton algorithm** — an iterative solver for **nonlinear least
squares** that linearizes residuals with the Jacobian and solves the
**undamped** normal equations. Optional simple **backtracking line search**
can shrink the step when the full update raises the cost; there is **no**
$\lambda$ damping (contrast with the Levenberg–Marquardt sibling).

Based on [Wikipedia: Gauss–Newton algorithm](https://en.wikipedia.org/wiki/Gauss–Newton_algorithm)
(named for Carl Friedrich Gauss and Isaac Newton; appeared in Gauss’s
1809 *Theoria motus*).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Levenberg-Marquardt](../ada-levenberg-marquardt/)**,
**[Ada-Nelder-Mead](../ada-nelder-mead/)** — damped NLS and derivative-free
optimization.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Minimize $S(\beta)=\tfrac12\|r(\beta)\|^2$ | Residuals $r_i$ from a model |
| **Local model** | Linearize $r$ via Jacobian $J$ | First-order Taylor |
| **Normal eqs** | $(J^\top J)\,\delta=-J^\top r$ | **Undamped** (no $\lambda$) |
| **Update** | $\beta\leftarrow\beta+\alpha\delta$ | $\alpha=1$ or backtracking |
| **Jacobian** | Analytical callback or finite differences | FD used when `Jac` is null |
| **Stop** | $\|\delta\|$, relative cost drop, or max iters | Reports `Success` |
| **Dim** | $n\le 8$ params, $m\le 64$ residuals | Dense GE solver |

## Brief history

Gauss introduced least-squares methods for orbit determination; the
iterative linearization now called Gauss–Newton appears in that lineage
and is the undamped core that Levenberg (1944) and Marquardt (1963) later
stabilized with damping. The method avoids explicit second derivatives of
$S$ by approximating the Hessian of the sum-of-squares with $J^\top J$.

## Problem statement

Given residuals $r(\beta)\in\mathbb{R}^m$ (often
$r_i(\beta)=y_i-f(x_i,\beta)$ for curve fitting), minimize

$$
S(\beta)=\frac12\sum_{i=1}^{m}r_i(\beta)^2=\frac12\|r(\beta)\|^2.
$$

Let $J$ be the Jacobian of residuals,
$J_{ij}=\partial r_i/\partial\beta_j$. Starting from $\beta^{(0)}$, each
Gauss–Newton iteration solves for a step $\delta$ and updates the
parameters.

## Undamped update (this package)

$$
(J^\top J)\,\delta=-J^\top r,
\qquad
\beta\leftarrow\beta+\alpha\delta.
$$

- Core GN uses $\alpha=1$ (full Newton-like step in the linearized residual
  space).
- Optional **simple backtracking**: if $S(\beta+\alpha\delta)$ does not
  decrease, set $\alpha\leftarrow\rho\alpha$ (default $\rho=0.5$) and retry
  up to `Max_Line_Search` times. This keeps the normal equations undamped
  while guarding against cost increases far from the optimum.
- There is **no** Marquardt term $\lambda\,\mathrm{diag}(J^\top J)$ and no
  plain Levenberg $\lambda I$.

If $J^\top J$ is singular (rank-deficient columns of $J$), the dense solver
raises `Singular_System` and the driver stops.

## One iteration (sketch)

1. Evaluate residuals $r(\beta)$ and cost $S$.
2. Form Jacobian $J$ (analytical `Jacobian_Fn`, or finite differences with
   step `Fd_Eps·(1+|\beta_j|)`).
3. Build $A=J^\top J$ and $g=J^\top r$.
4. Solve $A\,\delta=-g$ (Gaussian elimination with partial pivoting,
   $n\le 8$) — **undamped**.
5. Try $\alpha=1$, then optionally backtrack with factor
   `Line_Search_Rho` until $S$ falls (or give up).
6. Stop when $\|\alpha\delta\|\le$ `Step_Tol`, relative cost improvement
   $\le$ `Cost_Tol`, cost $\le$ `Cost_Tol`, or `Max_Iterations` is
   exhausted.

## Versus Levenberg–Marquardt (sibling)

| | Gauss–Newton (this package) | Levenberg–Marquardt |
| --- | --- | --- |
| Normal matrix | $J^\top J$ | $J^\top J+\lambda\,\mathrm{diag}(J^\top J)$ |
| Stabilization | Optional line search on $\alpha$ | Adaptive $\lambda$ up/down |
| Far from optimum | Can diverge / stall if $J$ ill-conditioned | More robust |
| Near well-behaved min | Often fast (near-quadratic) | Approaches GN as $\lambda\to 0$ |
| Config knobs | `Use_Line_Search`, $\rho$ | `Lambda_Init/Up/Down` |

Prefer **LM** when starts are poor or $J^\top J$ is nearly singular. Prefer
**plain GN** when the start is already good, the model is mildly nonlinear,
and you want the textbook undamped iteration. Prefer **Nelder–Mead** when
only black-box function values are available.

## Built-in demo models

| Model | Form | Truth / min |
| --- | --- | --- |
| `Linear_Residuals` | $y=a+bx$ on 8 samples | $(a,b)=(2,3)$ |
| `Quadratic_Residuals` | $y=a+bx+cx^2$ | $(1,-2,0.5)$ |
| `Exp_Decay_Residuals` | $y=a\,e^{-bx}$ | $(5,0.4)$ |
| `Rosenbrock_Residuals` | $r=(1-x,\,10(y-x^2))$ | $(1,1)$, $S=0$ |
| `Sphere_Residuals` | $r_i=\beta_i$ | origin |

Linear, quadratic, exponential, and Rosenbrock expose matching analytical
`*_Jacobian` functions; tests also exercise the finite-difference path.

## API (`Gauss_Newton`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Parameter_Vector`, `Residual_Vector`, `Jacobian`, `Square_Matrix`, `Config`, `Result`, `Model_Fn`, `Jacobian_Fn` | Domain / callbacks |
| Helpers | `Near`, `Params_Near`, `Residuals_Near`, `Norm2`, `Residual_Norm2`, `Dot`, `Residual_Dot`, `Add`, `Sub`, `Scale`, `Cost` | Geometry / cost |
| LA | `JTJ`, `JTr`, `Mat_Vec`, `Solve_SPD`, `Finite_Difference_Jacobian`, `Backtrack_Alpha` | Normal eqs / line search |
| Models | `Linear_*`, `Quadratic_*`, `Exp_Decay_*`, `Rosenbrock_*`, `Sphere_Residuals` | Demos + analytical $J$ |
| Driver | `Fit` / `Minimize` | Undamped Gauss–Newton NLS |

Named exceptions: `Invalid_Argument` (e.g. too few parameters for a demo
model), `Singular_System` (from `Solve_SPD` when pivoting fails).

`Config` defaults: `Max_Iterations=200`, `Step_Tol=1e-10`,
`Cost_Tol=1e-12`, `Fd_Eps=1e-7`, `Use_Line_Search=True`,
`Line_Search_Rho=0.5`, `Max_Line_Search=20`.

`Result` fields: `Final_Params`, `Final_Cost`, `N_Params`, `N_Residuals`,
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

- [Wikipedia: Gauss–Newton algorithm](https://en.wikipedia.org/wiki/Gauss–Newton_algorithm)
- C. F. Gauss, *Theoria motus corporum coelestium…* (1809)
- W. H. Press et al., *Numerical Recipes*, §15.5 Nonlinear Models
- Sibling (damped GN): [Ada-Levenberg-Marquardt](../ada-levenberg-marquardt/)
- Sibling (DFO): [Ada-Nelder-Mead](../ada-nelder-mead/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
