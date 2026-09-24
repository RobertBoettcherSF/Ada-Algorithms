# Conjugate Gradient Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the classical
**Hestenes–Stiefel conjugate gradient (CG)** method for **symmetric
positive-definite (SPD)** linear systems $Ax=b$, equivalently minimizing the
quadratic

$$
\min_x\; \tfrac12 x^\top A x - b^\top x.
$$

Search directions $p_k$ are constructed to be **$A$-conjugate**
($p_i^\top A p_j=0$ for $i\neq j$), so that under exact arithmetic CG
terminates in at most $n$ steps. An optional **Fletcher–Reeves** nonlinear CG
sketch (Armijo line search + gradient oracle) is included for smooth
objectives such as Sphere and Rosenbrock.

Based on [Wikipedia: Conjugate gradient method](https://en.wikipedia.org/wiki/Conjugate_gradient_method)
(Magnus R. Hestenes and Eduard Stiefel, 1952).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Gradient-Descent](https://github.com/RobertBoettcherSF/Ada-Gradient-Descent)** — first-order steepest descent / ascent
- **[Ada-BFGS](https://github.com/RobertBoettcherSF/Ada-BFGS)** — quasi-Newton inverse-Hessian updates
- **[Ada-Gauss-Newton](https://github.com/RobertBoettcherSF/Ada-Gauss-Newton)** — nonlinear least squares
- **[Ada-Nonlinear-Optimization](https://github.com/RobertBoettcherSF/Ada-Nonlinear-Optimization)** — NLP survey / umbrella

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | $A$-conjugate search directions | Krylov / Gram–Schmidt flavour |
| **Linear CG** | Hestenes–Stiefel for SPD $Ax=b$ | Dense educational `Float` |
| **α step** | $\alpha_k=(r_k^\top r_k)/(p_k^\top A p_k)$ | Exact line min of quadratic |
| **β update** | $\beta_k=(r_{k+1}^\top r_{k+1})/(r_k^\top r_k)$ | Same formula as Fletcher–Reeves |
| **Stop** | $\|r\|_2\le$ `Tol` or `Max_Iter` | Default `Max_Iter=0` ⇒ $n$ |
| **SPD helpers** | `Is_Symmetric`, `Is_Diagonally_Dominant` | Light checks, not a proof |
| **Examples** | Hilbert / diag+ones / Poisson 1D | `Make_SPD_Example` |
| **Nonlinear** | Fletcher–Reeves + Armijo | Sphere / Rosenbrock demos |
| **Dim** | $n\le 16$ | `Max_N = 16` |

## Brief history

Magnus Hestenes and Eduard Stiefel introduced the method in 1952 (programmed
on the Z4). It sits between **steepest descent** (which ignores conjugacy)
and a full **orthogonalization** of the Krylov subspace. The same $\beta$
formula appears in the **Fletcher–Reeves** nonlinear CG method; Polak–Ribière
and Hestenes–Stiefel nonlinear variants change only how $\beta$ is formed.

## Problem statement

Solve the SPD linear system

$$
A x = b,\qquad A=A^\top\succ 0,
$$

or, equivalently, minimize the strictly convex quadratic
$f(x)=\tfrac12 x^\top A x - b^\top x$ whose gradient is
$\nabla f(x)=A x - b$. The residual $r=b-Ax$ is therefore $-\nabla f$.

Two vectors $u,v$ are **$A$-conjugate** when

$$
u^\top A v = 0.
$$

CG builds mutually $A$-conjugate directions so that successive exact line
searches do not spoil previous progress along earlier directions.

## Hestenes–Stiefel iteration (this package)

Starting from $x_0$:

$$
\begin{aligned}
r_0 &:= b - A x_0,\\
p_0 &:= r_0.
\end{aligned}
$$

Then for $k=0,1,2,\ldots$ until $\|r\|$ is small or $k$ reaches the iteration
budget:

$$
\begin{aligned}
\alpha_k &:= \frac{r_k^\top r_k}{p_k^\top A p_k},\\
x_{k+1} &:= x_k + \alpha_k p_k,\\
r_{k+1} &:= r_k - \alpha_k A p_k,\\
\beta_k &:= \frac{r_{k+1}^\top r_{k+1}}{r_k^\top r_k},\\
p_{k+1} &:= r_{k+1} + \beta_k p_k.
\end{aligned}
$$

Under **exact arithmetic**, residuals are mutually orthogonal and directions
are $A$-conjugate, so the method has the **finite-termination** property:
it reaches $x_*$ in at most $n$ steps. In floating point the directions
gradually lose conjugacy; a residual tolerance is the practical stopping
rule.

## Fletcher–Reeves nonlinear sketch (optional)

For a smooth $f$ with gradient oracle $g=\nabla f$, Fletcher–Reeves uses

$$
\beta_k^{\mathrm{FR}} = \frac{\|g_{k+1}\|^2}{\|g_k\|^2},\qquad
p_{k+1} = -g_{k+1} + \beta_k^{\mathrm{FR}} p_k,
$$

with Armijo backtracking along $p_k$ and a steepest-descent restart when
$g^\top p\ge 0$. Demo objectives: Sphere $f(x)=\tfrac12\|x\|^2$ and the
classic 2-D Rosenbrock function.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Iter` (`0` ⇒ use $n$) |
| `Mat_Vec`, `Dot`, `Norm2` | Dense BLAS-1/2 helpers |
| `Is_Symmetric`, `Is_Diagonally_Dominant` | Light SPD-related checks |
| `Residual`, `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Make_SPD_Example` | Hilbert tiny / diag+ones / Poisson 1D |
| `Conjugate_Gradient` | Classical Hestenes–Stiefel CG |
| `Solve_SPD` | Wrapper (empty start ⇒ zero $x_0$) |
| `Fletcher_Reeves` | Nonlinear CG sketch |
| `Sphere`, `Rosenbrock` (+ grads) | Demo oracles |

## Limits and caveats

- **Dense $n\le 16$**, educational `Float` — not a production sparse Krylov
  solver; no preconditioning (PCG), no BiCG / GMRES for nonsymmetric $A$.
- **SPD is assumed**. `Is_Symmetric` / `Is_Diagonally_Dominant` are helpful
  screens, not certificates of positive-definiteness. Ill-conditioned
  Hilbert examples need looser tolerances.
- Finite termination is **approximate** in floating point; expect small
  residuals rather than bitwise-exact $x_*$ after $n$ steps.
- Nonlinear FR is a teaching sketch (simple Armijo), not a Wolfe /
  Polak–Ribière production code.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pconjugate_gradient.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `conjugate_gradient.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
conjugate_gradient.ads
conjugate_gradient.adb
conjugate_gradient.gpr
tests.adb
```

## References

1. Hestenes, M. R. & Stiefel, E. (1952). Methods of conjugate gradients for
   solving linear systems. *Journal of Research of the NBS*.
2. [Wikipedia: Conjugate gradient method](https://en.wikipedia.org/wiki/Conjugate_gradient_method)
3. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
