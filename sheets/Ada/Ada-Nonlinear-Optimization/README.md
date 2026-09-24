# Nonlinear Optimization — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey / umbrella** package for
[Wikipedia: Nonlinear programming](https://en.wikipedia.org/wiki/Nonlinear_programming)
(*nonlinear optimization*): minimizing a smooth (typically nonlinear)
objective $f:\mathbb{R}^n\to\mathbb{R}$, optionally subject to simple
**box** constraints $x\in[L,U]$.

A nonlinear program (NLP) has the form

$$
\begin{aligned}
\underset{x}{\mathrm{minimize}}\quad & f(x) \\
\mathrm{subject\ to}\quad & g_i(x)\le 0,\quad i=1,\ldots,m, \\
& h_j(x)=0,\quad j=1,\ldots,p, \\
& x\in X\subseteq\mathbb{R}^n,
\end{aligned}
$$

where at least one of $f$, $g_i$, $h_j$ is nonlinear. This package focuses on
the **unconstrained** case ($m=p=0$, $X=\mathbb{R}^n$) plus a compact
**projected-gradient** sketch for bound constraints ($X$ a box) — the NLP
flavor without a full KKT / SQP / interior-point solver.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers are
**independent** — this repo does **not** depend on them; it implements
runnable **gradient descent**, **Newton**, **Armijo** line search,
**finite-difference** gradients/Hessians, and a **method taxonomy**. Full
BFGS / Gauss–Newton / LM / Nelder–Mead / SA live in the siblings linked below.

## Local vs global minima (caveat)

Stationarity $\|\nabla f(x)\|\approx 0$ is a **first-order necessary**
condition for an unconstrained local minimum. Without convexity, GD / Newton
may converge to a **local** minimizer (or saddle). Multimodal demos such as
**Himmelblau** have four global minima with $f=0$; the attractor depends on
the start point. Derivative-free global heuristics (simulated annealing,
stochastic tunneling, random search) are catalogued here and implemented in
siblings — not as large copies in this survey.

## Method family (Wikipedia numeric methods)

Wikipedia groups iterative NLP updates by derivative order:

| Order | Uses | Examples in this series |
| --- | --- | --- |
| **Zero-order** | $f$ values only | Nelder–Mead, Simulated Annealing, Random Search |
| **First-order** | $\nabla f$ | Gradient descent, BFGS (quasi-Newton), projected GD |
| **Second-order** | $\nabla^2 f$ | Newton; Gauss–Newton / LM approximate Hessians for NLS |

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Helpers** | `Point`/`Vector`, `Near`, `Norm2`, `Dot`, `Add`/`Sub`/`Scale`, `Mat_Vec`, `Identity` | Dense $n\le 8$ |
| **Objectives** | `Sphere`, `Rosenbrock`, `Quadratic_Bowl`, `Himmelblau` + grads (+ Hess where useful) | Analytical demos |
| **Line search** | `Armijo_Accept`, `Line_Search` | Backtracking Armijo |
| **FD** | `Finite_Difference_Gradient`, `Finite_Difference_Hessian` | Central differences |
| **Linear algebra** | `Solve_SPD`, `Newton_Direction` | GE with partial pivoting |
| **Optimality** | `Is_Stationary`, `Grad_Norm`, `Project_Box`, `Make_Box` | $\|\nabla f\|$ + box $\Pi$ |
| **Drivers** | `Minimize_GD`, `Minimize_Newton`, `Minimize_Projected_GD` | Full loops |
| **Taxonomy** | `Method_Kind`, `Classify_Method`, `Method_Name`, `Compare_Fixed_Step_GD` | Metadata + step study |

Caps: `Max_Dim = 8`. Exceptions: `Invalid_Argument`, `Line_Search_Failed`,
`Singular_System`. Public subprograms carry `Pre` / `Post` / `Global` where
meaningful (`SPARK_Mode => Off`).

## Formula summary

### Gradient descent

With step size $\alpha_k>0$ (fixed or Armijo),

$$
x_{k+1}=x_k-\alpha_k\nabla f(x_k).
$$

Armijo sufficient decrease ($c_1\in(0,1)$, direction $p$):

$$
f(x+\alpha p)\le f(x)+c_1\alpha\,\nabla f(x)^\top p.
$$

### Newton

$$
\nabla^2 f(x_k)\,p_k=-\nabla f(x_k),\qquad
x_{k+1}=x_k+\alpha_k p_k
$$

(with Armijo or unit step). For a positive-definite quadratic, one Newton
step reaches the minimizer.

### Projected gradient (box)

$$
x_{k+1}=\Pi_{[L,U]}\bigl(x_k-\alpha_k\nabla f(x_k)\bigr),
$$

where $\Pi$ is componentwise clipping — a minimal NLP bound-constraint sketch.

### Demo objectives

$$
\begin{aligned}
f_{\mathrm{sphere}}(x)&=\|x\|_2^2,\\
f_{\mathrm{bowl}}(x)&=\tfrac12\sum_{i=1}^n i\,x_i^2,\\
f_{\mathrm{rosen}}(x,y)&=(1-x)^2+100(y-x^2)^2,\\
f_{\mathrm{himmel}}(x,y)&=(x^2+y-11)^2+(x+y^2-7)^2.
\end{aligned}
$$

## Sibling solvers (README links only — no package deps)

| Sibling | Role |
| --- | --- |
| [Ada-BFGS](https://github.com/RobertBoettcherSF/Ada-BFGS) | Quasi-Newton inverse-Hessian BFGS |
| [Ada-Gauss-Newton](https://github.com/RobertBoettcherSF/Ada-Gauss-Newton) | Nonlinear least squares (Gauss–Newton) |
| [Ada-Levenberg-Marquardt](https://github.com/RobertBoettcherSF/Ada-Levenberg-Marquardt) | Damped NLS (LM) |
| [Ada-Nelder-Mead](https://github.com/RobertBoettcherSF/Ada-Nelder-Mead) | Derivative-free simplex |
| [Ada-Simulated-Annealing](https://github.com/RobertBoettcherSF/Ada-Simulated-Annealing) | Stochastic global search |
| [Ada-Stochastic-Tunneling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Tunneling) | Global heuristic |
| [Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search) | Zero-order random search |

## Public API (summary)

**Types:** `Real`, `Point`, `Vector`, `Matrix`, `Objective_Fn`, `Gradient_Fn`,
`Hessian_Fn`, `Config`, `Result`, `Box`, `Method_Kind`, `Method_Info`,
`Compare_Sample`, `Compare_Table`.

**Helpers:** `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale`,
`Mat_Vec`, `Identity`, `Solve_SPD`.

**Line search / FD:** `Armijo_Accept`, `Line_Search`,
`Finite_Difference_Gradient`, `Finite_Difference_Hessian`.

**Stationarity / box:** `Is_Stationary`, `Grad_Norm`, `Project_Box`,
`Make_Box`, `Gradient_Descent_Step`, `Projected_Gradient_Step`,
`Newton_Direction`.

**Objectives:** `Sphere`/`Sphere_Grad`/`Sphere_Hess`,
`Rosenbrock`/`Rosenbrock_Grad`/`Rosenbrock_Hess`,
`Quadratic_Bowl`/`Quadratic_Bowl_Grad`/`Quadratic_Bowl_Hess`,
`Himmelblau`/`Himmelblau_Grad`.

**Drivers:** `Minimize_GD`, `Minimize_Newton`, `Minimize_Projected_GD`.

**Catalog:** `Classify_Method`, `Method_Name`, `Method_Count`,
`Compare_Fixed_Step_GD`.

## Usage sketch

```ada
with Nonlinear_Optimization; use Nonlinear_Optimization;

procedure Demo is
   X0  : constant Point (1 .. 2) := [1.5, -1.0];
   Cfg : Config := Default_Config;
   R   : Result;
   Bx  : constant Box := Make_Box ([-1.0, -1.0], [2.0, 2.0]);
begin
   R := Minimize_GD (Sphere'Access, X0, Sphere_Grad'Access, Cfg);
   --  R.Final_Point ≈ (0,0), R.Final_Value ≈ 0

   R := Minimize_Newton
     (Quadratic_Bowl'Access, [2.0, -1.0],
      Quadratic_Bowl_Grad'Access, Quadratic_Bowl_Hess'Access, Cfg);

   R := Minimize_Projected_GD
     (Sphere'Access, [1.5, 1.5], Bx, Sphere_Grad'Access, Cfg);
end Demo;
```

## Building

```bash
cd /workspace/ada-nonlinear-optimization
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pnonlinear_optimization.gpr`. Expect
**zero** errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (14 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`). Plain GD on Rosenbrock is intentionally
slow — the suite documents that Newton (here) and BFGS (sibling) are the
practical choices for that valley.

## Layout

```
ada-nonlinear-optimization/
├── nonlinear_optimization.ads   # public API
├── nonlinear_optimization.adb   # implementation
├── nonlinear_optimization.gpr
├── tests.adb                    # main test program
├── Makefile
├── README.md
└── .gitignore
```

Root-only layout (no `src/`, no separate `main.adb`). Exactly **seven** root
files.

## References

1. [Wikipedia: Nonlinear programming](https://en.wikipedia.org/wiki/Nonlinear_programming)
   — definition, convex special cases, numeric 0th/1st/2nd-order methods, KKT.
2. Nocedal & Wright, *Numerical Optimization*, Springer.
3. [Wikipedia: Gradient descent](https://en.wikipedia.org/wiki/Gradient_descent).
4. [Wikipedia: Newton's method in optimization](https://en.wikipedia.org/wiki/Newton%27s_method_in_optimization).
5. [Wikipedia: Nonlinear conjugate gradient](https://en.wikipedia.org/wiki/Nonlinear_conjugate_gradient_method)
   (related first-order family; not implemented here).
