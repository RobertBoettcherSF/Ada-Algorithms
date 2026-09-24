# Interior-Point Method — Ada 2023

Educational, self-contained Ada 2023 package implementing **interior-point
methods (IPMs)** for **small dense linear programs**: a working **primal
affine-scaling** path and a working **logarithmic-barrier** path-following
driver. Iterates stay in the **strict interior** $\{x:Ax=b,\,x>0\}$ rather
than walking vertices as in the simplex method.

Based on [Wikipedia: Interior-point method](https://en.wikipedia.org/wiki/Interior-point_method).

Siblings:

- **[Ada-Karmarkars-Algorithm](../ada-karmarkars-algorithm/)** — affine-scaling / Karmarkar spirit
- **[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)** — Dantzig tableau (exact vertices)
- **[Ada-Linear-Programming](../ada-linear-programming/)** — LP survey / Bland simplex umbrella

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Traverse the interior of the feasible region | vs simplex boundary / ellipsoid exterior |
| **Form** | $Ax=b$, $x>0$ (or $Ax\le b$ + slacks) | Strictly feasible $x_0$ required |
| **Affine scaling** | $D=\mathrm{diag}(x)$, $dx=\pm D^{2}(c-A^{\top}y)$ | Like Karmarkar sibling |
| **Barrier** | $\min\, c^{\top}x-\mu\sum\log x_i$ s.t. $Ax=b$ | Reduce $\mu\to 0$ |
| **Taxonomy** | Affine / logarithmic barrier / primal-dual | PD named; maps to barrier |
| **LA** | Dense GE on $m\times m$ normals | $n\le 12$, $m\le 8$ |
| **Contrast** | Approaches boundary asymptotically | Simplex hits exact BFS |

## Brief history

Soviet mathematician I. I. Dikin described an interior method in 1967. In 1984
Narendra Karmarkar’s polynomial-time LP algorithm sparked the modern IPM era
(affine scaling, path-following, primal-dual Newton systems). Fiacco &
McCormick studied barrier encodings in the 1960s; Nesterov & Nemirovski later
gave self-concordant barriers with polynomial iteration bounds. Production
solvers typically use **primal-dual path-following** (e.g. Mehrotra
predictor–corrector). This package teaches the **geometry** of interior steps
on tiny dense LPs — not production Mehrotra PD or bit-complexity claims.

## IPM taxonomy

| Kind | Meaning | This package |
| --- | --- | --- |
| **Affine_Scaling** | Diagonal scale by $x$; project reduced costs | `Solve_Affine` / default `Solve` |
| **Logarithmic_Barrier** | Centering path for $c^{\top}x-\mu\sum\log x_i$ | `Solve_Barrier` |
| **Primal_Dual** | Coupled $(x,y,s)$ Newton / Mehrotra family | Taxonomy + `Classify_Method`; `Solve` maps to barrier |

Helpers: `Method_Name`, `Classify_Method`.

## Problem statement

Given $A\in\mathbb{R}^{m\times n}$, $b\in\mathbb{R}^{m}$, $c\in\mathbb{R}^{n}$,
and a **strictly feasible** start $x_{0}>0$ with $Ax_{0}=b$, solve

$$
\min_{x}\; c^{\top}x
\quad\text{or}\quad
\max_{x}\; c^{\top}x
\quad\text{subject to}\quad
Ax=b,\quad x>0.
$$

Inequality form $Ax\le b$, $x>0$ is converted by nonnegative **slacks**
$s=b-Ax>0$:

$$
\begin{bmatrix} A & I \end{bmatrix}
\begin{bmatrix} x \\ s \end{bmatrix}
= b.
$$

## Affine-scaling iteration

1. Set $D=\mathrm{diag}(x)$.
2. Solve $(A D^{2} A^{\top})\,y = A D^{2} c$ by dense Gaussian elimination.
3. Reduced costs $r = c - A^{\top} y$. Stationarity $\|D r\|_{\infty}$.
4. Direction $dx = -D^{2} r$ (minimize) or $dx = +D^{2} r$ (maximize).
5. If $\|D r\|_{\infty}\le\texttt{Tol}$ → **Optimal**.
6. Step $\alpha=\gamma\cdot\min_{i:\,(dx)_{i}<0}\bigl(-x_{i}/(dx)_{i}\bigr)$
   with $\gamma=\texttt{Step\_Fraction}\in(0,1)$.
7. Unbounded ray / stall handling as in the Karmarkar sibling.
8. $x\leftarrow x+\alpha\,dx$ (stays positive; $Ax=b$ in exact arithmetic).

Helper `Project_Nullspace` exposes $(I-A^{\top}(AA^{\top})^{-1}A)$.

## Logarithmic-barrier path

For fixed $\mu>0$ minimize (or maximize via $-c$) the barrier objective

$$
\phi_{\mu}(x)=c^{\top}x-\mu\sum_{i=1}^{n}\log x_{i}
\quad\text{subject to}\quad Ax=b.
$$

Newton step uses Hessian $H=\mathrm{diag}(\mu/x_{i}^{2})$:

$$
(A H^{-1} A^{\top})\,\lambda = A H^{-1} g,\qquad
dx = -H^{-1}(g-A^{\top}\lambda),
$$

with $g=c-\mu X^{-1}e$ (minimize). After centering, set
$\mu\leftarrow\texttt{Mu\_Factor}\cdot\mu$ until $\mu\le\texttt{Mu\_Min}$.

## Versus Ada-Simplex-Algorithm

| | This package (IPM) | Simplex sibling |
| --- | --- | --- |
| Path | Interior of $\{x:Ax=b,\,x>0\}$ | Vertices of the polytope |
| Start | Strictly feasible $x_{0}>0$ | Basic feasible (Phase I if needed) |
| Linear algebra | Dense GE on $m\times m$ normals | Tableau pivots |
| Exact vertex | Approaches boundary asymptotically | Exact BFS optimum |
| History | Dikin / Karmarkar / barrier / PD era | Dantzig late 1940s |

Prefer **simplex** for tiny educational LPs when you want exact vertices.
Prefer **this package** (or the Karmarkar sibling) to illustrate interior-point
geometry, scaling, and barrier centering.

## Built-in textbook checks (in `tests.adb`)

| Case | Form | Expected |
| --- | --- | --- |
| Classic (simplex twin) | $\max 3x+5y$ s.t. $x\le 4$, $2y\le 12$, $3x+2y\le 18$ | near $(2,6)$, $z\approx 36$ |
| Equality min | $\min x_{1}$ s.t. $x_{1}+x_{2}=1$, $x>0$ | $x_{1}\to 0^{+}$, $x_{2}\to 1^{-}$ |
| Barrier path | same equality / classic | agrees loosely with affine |
| Unbounded | $\max x_{1}$ s.t. $x_{1}-x_{2}=0$, $x>0$ | `Unbounded` |
| Ill start | non-positive or $Ax\neq b$ | `Ill_Started` |

## API (`Interior_Point_Method`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Matrix`, `Square_Matrix`, `Vector`, `Config`, `Result`, `Status`, `Objective_Sense`, `Method_Kind` | Domain |
| Taxonomy | `Method_Name`, `Classify_Method` | Affine / barrier / PD |
| Helpers | `Near`, `Vec_Near`, `Dot`, `Norm_Inf`, `Norm2`, `Scale`, `Add`, `Sub` | Numerics |
| Linear algebra | `Mat_Vec`, `Mat_Vec_T`, `Solve_GE`, `Solve_SPD`, `Project_Nullspace` | Dense GE / project |
| IPM primitives | `Affine_Direction`, `Barrier_Value`, `Barrier_Direction`, `Interior_Step`, `Max_Feasible_Step`, `Expand_Inequalities` | Steps |
| Drivers | `Solve`, `Solve_Affine`, `Solve_Barrier`, `Minimize`, `Maximize`, `Maximize_Inequalities`, `Minimize_Inequalities` | LP solves |

Named exceptions: `Invalid_Argument`, `Singular_System`.

`Config` defaults: `Max_Iterations=200`, `Tol=1e-8`, `Step_Fraction=0.9`,
`Min_Step=1e-14`, `Method=Affine_Scaling`, `Mu_Init=1`, `Mu_Min=1e-10`,
`Mu_Factor=0.1`, `Centering_Iters=8`.

`Result` fields: `Stat`, `Objective`, `X`, `N_Vars`, `Iterations`,
`Mu_Final`, `Success` (`Success` is true iff `Stat=Optimal`).

Limits: `Max_Constraints=8`, `Max_Vars=12`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Interior-point method](https://en.wikipedia.org/wiki/Interior-point_method)
- [Wikipedia: Karmarkar's algorithm](https://en.wikipedia.org/wiki/Karmarkar%27s_algorithm)
- Karmarkar, N. “A new polynomial-time algorithm for linear programming,”
  *Combinatorica*, 4(4), 1984
- Nesterov, Y.; Nemirovski, A. *Interior-Point Polynomial Algorithms in
  Convex Programming*, SIAM, 1994
- Sibling: [Ada-Karmarkars-Algorithm](../ada-karmarkars-algorithm/)
- Sibling: [Ada-Simplex-Algorithm](../ada-simplex-algorithm/)
- Sibling: [Ada-Linear-Programming](../ada-linear-programming/)
