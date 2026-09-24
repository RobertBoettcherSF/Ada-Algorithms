# Biconjugate Gradient Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the classical
**biconjugate gradient (BiCG)** method for **nonsymmetric** (or indefinite)
linear systems $Ax=b$. Unlike conjugate gradient, BiCG does **not** require
$A$ to be symmetric positive-definite; it maintains a pair of residual /
search-direction sequences and needs matrix–vector products with both $A$
and the real transpose $A^\top$.

Based on [Wikipedia: Biconjugate gradient method](https://en.wikipedia.org/wiki/Biconjugate_gradient_method)
(R. Fletcher, 1976). This package implements **classic BiCG only** — the more
stable **BiCGSTAB** (biconjugate gradient stabilized) method is a natural
sibling topic, not included here.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient)** — Hestenes–Stiefel CG for SPD $Ax=b$
- **[Ada-Gauss-Seidel](https://github.com/RobertBoettcherSF/Ada-Gauss-Seidel)** — stationary iterative smoother
- **[Ada-Gaussian-Elimination](https://github.com/RobertBoettcherSF/Ada-Gaussian-Elimination)** — direct dense LU-style solve
- **[Ada-Stones-Method](https://github.com/RobertBoettcherSF/Ada-Stones-Method)** — Stone’s strongly implicit procedure

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Biorthogonal residuals / $A$-biconjugate directions | Krylov; nonsymmetric OK |
| **Matvecs** | $Ap$ and $A^\top\tilde{p}$ | Real transpose; dense educational `Float` |
| **α step** | $\alpha_k=(\tilde{r}_k^\top r_k)/(\tilde{p}_k^\top A p_k)$ | Breakdown if denom vanishes |
| **β update** | $\beta_k=(\tilde{r}_{k+1}^\top r_{k+1})/(\tilde{r}_k^\top r_k)$ | Breakdown if $\rho$ vanishes |
| **Stop** | $\|r\|_2\le$ `Tol` or `Max_Iter` | Default `Max_Iter=0` ⇒ $2n$ |
| **Examples** | Nonsym DD / conv–diff / SPD Poisson / fixed | `Make_Example` |
| **Dim** | $n\le 16$ | `Max_N = 16` |

## Brief history

Fletcher (1976) extended the conjugate-gradient idea to nonsymmetric systems
by running a second, “shadow” recurrence involving $A^*$ (here the real
transpose $A^\top$). When $A=A^\top$ and the shadow residual is chosen equal
to the primary residual, BiCG reduces to classical CG at half the matvec
cost. Numerically BiCG can **break down** or oscillate; **BiCGSTAB** was
later designed for greater stability.

## Problem statement

Solve the square linear system

$$
A x = b
$$

with $A\in\mathbb{R}^{n\times n}$ **not necessarily** symmetric or definite.
BiCG builds two Krylov sequences so that residuals $r_k=b-Ax_k$ and shadow
residuals $\tilde{r}_k$ stay biorthogonal, while search directions $p_k$ and
$\tilde{p}_k$ are $A$-biconjugate:

$$
\tilde{p}_i^\top A p_j = 0\quad(i\neq j),\qquad
\tilde{r}_i^\top r_j = 0\quad(i\neq j).
$$

## Unpreconditioned BiCG (this package)

Starting from $x_0$, set

$$
\begin{aligned}
r_0 &:= b - A x_0,\\
\tilde{r}_0 &:= r_0,\\
p_0 &:= r_0,\\
\tilde{p}_0 &:= \tilde{r}_0.
\end{aligned}
$$

(The choice $\tilde{r}_0=r_0$ is the usual default whenever
$\tilde{r}_0^\top r_0\neq 0$.) Then for $k=0,1,2,\ldots$ until $\|r\|$ is small
or $k$ reaches the iteration budget:

$$
\begin{aligned}
\alpha_k &:= \frac{\tilde{r}_k^\top r_k}{\tilde{p}_k^\top A p_k},\\
x_{k+1} &:= x_k + \alpha_k p_k,\\
r_{k+1} &:= r_k - \alpha_k A p_k,\\
\tilde{r}_{k+1} &:= \tilde{r}_k - \alpha_k A^\top \tilde{p}_k,\\
\beta_k &:= \frac{\tilde{r}_{k+1}^\top r_{k+1}}{\tilde{r}_k^\top r_k},\\
p_{k+1} &:= r_{k+1} + \beta_k p_k,\\
\tilde{p}_{k+1} &:= \tilde{r}_{k+1} + \beta_k \tilde{p}_k.
\end{aligned}
$$

**Breakdown** is reported when a denominator
$\rho_k=\tilde{r}_k^\top r_k$ or $\tilde{p}_k^\top A p_k$ vanishes (to
educational tolerance). On SPD problems with $\tilde{r}_0=r_0$, the
recurrence mirrors CG.

## API summary

| Symbol | Role |
| --- | --- |
| `Vector`, `Matrix` | Dense 1-based educational `Float` arrays |
| `Max_N` | Hard dimension cap ($16$) |
| `Parameters` | `Tol`, `Max_Iter` (`0` ⇒ use $2n$) |
| `Status` | `Converged` / `Iteration_Limit` / `Breakdown` / `Ill_Started` / `Dimension_Error` |
| `Result` | `X`, `N`, `Iterations`, `Residual`, `Stat`, `Success` |
| `Mat_Vec`, `Mat_Vec_T`, `Transpose` | Dense matvecs with $A$ and $A^\top$ |
| `Dot`, `Norm2`, `Near`, `Vec_Near` | BLAS-1 / comparison helpers |
| `Residual`, `Residual_Norm` | $r=b-Ax$ and $\|r\|_2$ |
| `Make_Example` | Nonsym DD / conv–diff / SPD Poisson / fixed $2\times2$, $3\times3$ |
| `Biconjugate_Gradient` | Classical unpreconditioned BiCG |
| `Solve` | Wrapper (empty start ⇒ zero $x_0$) |

## Limits and caveats

- **Dense $n\le 16$**, educational `Float` — not a production sparse Krylov
  solver; **no preconditioning**.
- BiCG can **break down** even on nonsingular $A$; residuals may oscillate.
  Prefer **BiCGSTAB** (or GMRES) in practice for nonsymmetric systems — that
  method is intentionally **not** implemented in this package.
- SPD examples still work (BiCG reduces toward CG), but for SPD-only work
  prefer [Ada-Conjugate-Gradient](https://github.com/RobertBoettcherSF/Ada-Conjugate-Gradient).
- Default `Max_Iter=0` uses a $2n$ budget (nonsymmetric Krylov often needs
  more than the SPD CG $n$-step bound).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pbiconjugate_gradient.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `biconjugate_gradient.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
biconjugate_gradient.ads
biconjugate_gradient.adb
biconjugate_gradient.gpr
tests.adb
```

## References

1. Fletcher, R. (1976). Conjugate gradient methods for indefinite systems.
   In *Numerical Analysis* (Dundee), Lecture Notes in Mathematics 506.
2. [Wikipedia: Biconjugate gradient method](https://en.wikipedia.org/wiki/Biconjugate_gradient_method)
3. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
