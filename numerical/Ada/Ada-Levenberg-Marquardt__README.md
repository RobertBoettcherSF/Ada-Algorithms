# Levenberg–Marquardt Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Levenberg–Marquardt algorithm** (also **damped least squares**, LMA /
LM) — an iterative solver for **nonlinear least squares** that
interpolates between the **Gauss–Newton** method and **gradient descent**
via a damping factor $\lambda$.

Based on [Wikipedia: Levenberg–Marquardt algorithm](https://en.wikipedia.org/wiki/Levenberg–Marquardt_algorithm)
(Levenberg 1944; Marquardt 1963; independently Girard, Wynne, Morrison).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Nelder-Mead](../ada-nelder-mead/)**,
**[Ada-Simulated-Annealing](../ada-simulated-annealing/)**,
**[Ada-Partial-Least-Squares](../ada-partial-least-squares/)** — related
optimizers / least-squares tools.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Minimize $S(\beta)=\tfrac12\|r(\beta)\|^2$ | Residuals $r_i$ from a model |
| **Local model** | Linearize $r$ via Jacobian $J$ | Gauss–Newton normal eqs. |
| **Damping** | Marquardt: $J^\top J + \lambda\,\mathrm{diag}(J^\top J)$ | Scale-aware vs plain $\lambda I$ |
| **Update** | $\beta\leftarrow\beta+\delta$ when cost falls | Else increase $\lambda$ |
| **Jacobian** | Analytical callback or finite differences | FD used when `Jac` is null |
| **Stop** | $\|\delta\|$, relative cost drop, or max iters | Reports `Success` |
| **Dim** | $n\le 8$ params, $m\le 64$ residuals | Dense GE solver |

## Brief history

Kenneth Levenberg (1944, Frankford Army Arsenal) published the damped
update; Donald Marquardt (1963, DuPont) rediscovered and popularized it
with diagonal scaling for better parameter-scale invariance. The method
remains a workhorse for curve fitting in statistics, computer vision, and
scientific computing. Like other local iterative optimizers, LMA finds a
**local** minimum and depends on a reasonable start when multiple basins
exist.

## Problem statement

Given residuals $r(\beta)\in\mathbb{R}^m$ (often
$r_i(\beta)=y_i-f(x_i,\beta)$ for curve fitting), minimize

$$
S(\beta)=\frac12\sum_{i=1}^{m}r_i(\beta)^2=\frac12\|r(\beta)\|^2.
$$

Let $J$ be the Jacobian of residuals,
$J_{ij}=\partial r_i/\partial\beta_j$. Gauss–Newton solves
$(J^\top J)\,\delta=-J^\top r$. When $J^\top J$ is ill-conditioned or the
linear model is a poor local fit, damping stabilizes the step.

## Marquardt damped update (this package)

This implementation uses **Marquardt diagonal scaling** (preferred over
plain Levenberg $\lambda I$ for scale invariance):

$$
\bigl(J^\top J+\lambda\,\mathrm{diag}(J^\top J)\bigr)\,\delta=-J^\top r,
\qquad
\beta\leftarrow\beta+\delta\quad\text{if }S(\beta+\delta)<S(\beta).
$$

- Large $\lambda$: step resembles **scaled gradient descent** (robust far
  from the optimum).
- Small $\lambda$: step approaches **Gauss–Newton** (fast near a
  well-behaved minimum).

Tiny diagonal entries of $J^\top J$ are floored before damping so a zero
column does not collapse the regularizer.

## Choice of $\lambda$

Heuristic update (classic up/down factors; Wikipedia “delayed
gratification” discusses milder ratios such as $\times 2$ / $\div 3$):

| Event | Rule | Default in `Config` |
| --- | --- | --- |
| Start | $\lambda\leftarrow\lambda_0$ | `Lambda_Init = 1e-3` |
| Cost decreases | $\lambda\leftarrow\lambda/\texttt{Lambda_Down}$ | `Lambda_Down = 10` |
| Cost increases / singular | $\lambda\leftarrow\lambda\cdot\texttt{Lambda_Up}$ | `Lambda_Up = 10` |
| Clamp | $\lambda\in[10^{-16},10^{16}]$ | numeric hygiene |

On a failed trial step the package retries with larger $\lambda$ within
the same outer iteration (up to 20 inner attempts) before giving up.

## One iteration (sketch)

1. Evaluate residuals $r(\beta)$ and cost $S$.
2. Form Jacobian $J$ (analytical `Jacobian_Fn`, or finite differences with
   step `Fd_Eps·(1+|\beta_j|)`).
3. Build $A=J^\top J$ and $g=J^\top r$.
4. Solve $(A+\lambda\,\mathrm{diag}(A))\,\delta=-g$ (Gaussian elimination
   with partial pivoting, $n\le 8$).
5. If $S(\beta+\delta)<S(\beta)$, accept, decrease $\lambda$; else reject,
   increase $\lambda$ and retry.
6. Stop when $\|\delta\|\le$ `Step_Tol`, relative cost improvement
   $\le$ `Cost_Tol`, or `Max_Iterations` is exhausted.

## Versus related methods

| | Levenberg–Marquardt | Gauss–Newton | Nelder–Mead |
| --- | --- | --- | --- |
| Needs $J$ | Yes (or FD) | Yes | No (values only) |
| Objective | Nonlinear least squares | Same | General $f$ |
| Robustness | High (damping) | Lower far away | Heuristic DFO |
| Near minimum | Often near-quadratic | Same if full rank | Slower |

Prefer LM for smooth curve fitting with $m\ge n$. Prefer Nelder–Mead when
only black-box comparisons are available. Prefer plain Gauss–Newton only
when the start is already good and $J$ is well conditioned.

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

## API (`Levenberg_Marquardt`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Parameter_Vector`, `Residual_Vector`, `Jacobian`, `Square_Matrix`, `Config`, `Result`, `Model_Fn`, `Jacobian_Fn` | Domain / callbacks |
| Helpers | `Near`, `Params_Near`, `Residuals_Near`, `Norm2`, `Residual_Norm2`, `Dot`, `Residual_Dot`, `Add`, `Sub`, `Scale`, `Cost` | Geometry / cost |
| LA | `JTJ`, `JTr`, `Mat_Vec`, `Solve_SPD`, `Damped_Normal_Matrix`, `Finite_Difference_Jacobian`, `Adjust_Lambda` | Normal eqs / damping |
| Models | `Linear_*`, `Quadratic_*`, `Exp_Decay_*`, `Rosenbrock_*`, `Sphere_Residuals` | Demos + analytical $J$ |
| Driver | `Fit` / `Minimize` | LM nonlinear least squares |

Named exceptions: `Invalid_Argument` (e.g. too few parameters for a demo
model), `Singular_System` (from `Solve_SPD` when pivoting fails).

`Config` defaults: $\lambda_0=10^{-3}$, `Lambda_Up=10`, `Lambda_Down=10`,
`Max_Iterations=200`, `Step_Tol=1e-10`, `Cost_Tol=1e-12`, `Fd_Eps=1e-7`.

`Result` fields: `Final_Params`, `Final_Cost`, `N_Params`, `N_Residuals`,
`Iterations`, `Success`, `Final_Lambda`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Levenberg–Marquardt algorithm](https://en.wikipedia.org/wiki/Levenberg–Marquardt_algorithm)
- K. Levenberg, *A method for the solution of certain non-linear problems
  in least squares*, Quart. Appl. Math. **2**, 164–168 (1944)
- D. W. Marquardt, *An algorithm for least-squares estimation of nonlinear
  parameters*, SIAM J. Appl. Math. **11**, 431–441 (1963)
- W. H. Press et al., *Numerical Recipes*, §15.5 Nonlinear Models
- H. P. Gavin, *The Levenberg-Marquardt method for nonlinear least-squares
  curve-fitting problems* (tutorial notes)
- Siblings: [Ada-Nelder-Mead](../ada-nelder-mead/),
  [Ada-Simulated-Annealing](../ada-simulated-annealing/),
  [Ada-Partial-Least-Squares](../ada-partial-least-squares/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
