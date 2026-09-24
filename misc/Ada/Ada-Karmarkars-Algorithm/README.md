# Karmarkar's Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing an **affine-scaling /
simplified Karmarkar-style interior-point** method for **small dense linear
programs**. Iterates move through the **strict interior** of the feasible
region (after diagonal scaling by the current $x$), rather than along vertices
as in the simplex method.

**Honest scope:** this is an **educational affine-scaling interior-point method
in the spirit of Karmarkar (1984)**, **not** a bit-exact reproduction of the
original **projective** potential-reduction algorithm (no projective
transformation, no exact potential function, no bit-complexity analysis). The
classical Karmarkar method was the first **practically efficient polynomial-time**
LP algorithm; the ellipsoid method is also polynomial-time but was inefficient
in practice. Later interior-point codes evolved into primal-dual
path-following methods used in production solvers.

Based on [Wikipedia: Karmarkar's algorithm](https://en.wikipedia.org/wiki/Karmarkar%27s_algorithm)
(Narendra Karmarkar, 1984).

Sibling (vertex / tableau LP):
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)**.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Walk the strict interior toward improving directions | Not vertex pivots |
| **Form** | $Ax=b$, $x>0$ (or $Ax\le b$ + slacks) | Strictly feasible $x_0$ required |
| **Scale** | $D=\mathrm{diag}(x)$ | Affine scaling |
| **Direction** | $dx=\pm D^{2}(c-A^{\top}y)$, $(AD^{2}A^{\top})y=AD^{2}c$ | Dense GE |
| **Step** | Fraction $\gamma$ of distance to $\partial\{x>0\}$ | Keeps $x>0$ |
| **Status** | `Optimal` / `Iteration_Limit` / `Ill_Started` / `Unbounded` | Plus $x$, $z$ |
| **Contrast** | Interior-point vs simplex sibling | Same LPs, different geometry |
| **Limits** | $n\le 12$, $m\le 8$ | Educational dense |

## Brief history

In 1984 Narendra Karmarkar published a **polynomial-time** interior-point
algorithm for linear programming that was far more practical than the earlier
ellipsoid method. It sparked the modern interior-point era (affine scaling,
path-following, primal-dual Newton systems). AT&T patented related technology
(U.S. patent 4,744,028; expired 2006). This package teaches the **geometry**
of interior steps on tiny dense LPs; it does **not** claim the original
projective potential analysis or production robustness.

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

## One affine-scaling iteration

1. Set $D=\mathrm{diag}(x)$.
2. Solve the normal equations $(A D^{2} A^{\top})\,y = A D^{2} c$ by dense
   Gaussian elimination.
3. Reduced costs $r = c - A^{\top} y$. Stationarity measure $\|D r\|_{\infty}$.
4. Direction: $dx = -D^{2} r$ (minimize) or $dx = +D^{2} r$ (maximize).
5. If $\|D r\|_{\infty}\le\texttt{Tol}$ → **Optimal**.
6. Step length $\alpha=\gamma\cdot\min_{i:\,(dx)_{i}<0}\bigl(-x_{i}/(dx)_{i}\bigr)$
   with $\gamma=\texttt{Step\_Fraction}\in(0,1)$ (default $0.9$).
7. If no blocking index and $\|dx\|$ is large → **Unbounded**; if the step
   collapses → treat as **Optimal** numerically.
8. $x\leftarrow x+\alpha\,dx$ (stays positive and, in exact arithmetic,
   feasible).

Equivalently, the direction is a diagonally scaled projection of $\pm c$ onto
the nullspace of $A D$. Helper `Project_Nullspace` exposes the unweighted
projector $(I-A^{\top}(AA^{\top})^{-1}A)$ for tests.

## Versus Ada-Simplex-Algorithm

| | This package (affine scaling) | Simplex sibling |
| --- | --- | --- |
| Path | Interior of $\{x:Ax=b,\,x>0\}$ | Vertices of the polytope |
| Start | Strictly feasible $x_{0}>0$ | Basic feasible (Phase I if needed) |
| Linear algebra | Dense GE on $m\times m$ normal equations | Tableau pivots |
| Exact vertex | Approaches boundary asymptotically | Exact BFS optimum |
| History | Karmarkar 1984 spirit (poly-time IPM) | Dantzig late 1940s |

Prefer **simplex** for tiny educational LPs when you want exact vertices and
Phase-I infeasibility certificates. Prefer **this package** to illustrate
interior-point geometry and scaling.

## Built-in textbook checks (in `tests.adb`)

| Case | Form | Expected |
| --- | --- | --- |
| Classic (simplex twin) | $\max 3x+5y$ s.t. $x\le 4$, $2y\le 12$, $3x+2y\le 18$ | near $(2,6)$, $z\approx 36$ |
| Equality min | $\min x_{1}$ s.t. $x_{1}+x_{2}=1$, $x>0$ | $x_{1}\to 0^{+}$, $x_{2}\to 1^{-}$ |
| Unbounded | $\max x_{1}$ s.t. $x_{1}-x_{2}=0$, $x>0$ | `Unbounded` |
| Ill start | non-positive or $Ax\neq b$ | `Ill_Started` |

## API (`Karmarkars_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Matrix`, `Square_Matrix`, `Vector`, `Config`, `Result`, `Status`, `Objective_Sense` | Domain |
| Helpers | `Near`, `Vec_Near`, `Dot`, `Norm_Inf`, `Norm2`, `Scale`, `Add`, `Sub` | Numerics |
| Linear algebra | `Mat_Vec`, `Mat_Vec_T`, `Solve_GE`, `Solve_SPD`, `Project_Nullspace` | Dense GE / project |
| IPM primitives | `Affine_Direction`, `Interior_Step`, `Max_Feasible_Step`, `Expand_Inequalities` | Scaling step |
| Drivers | `Solve`, `Minimize`, `Maximize`, `Maximize_Inequalities`, `Minimize_Inequalities` | LP solves |

Named exceptions: `Invalid_Argument`, `Singular_System`.

`Config` defaults: `Max_Iterations=200`, `Tol=1e-8`, `Step_Fraction=0.9`,
`Min_Step=1e-14`.

`Result` fields: `Stat`, `Objective`, `X`, `N_Vars`, `Iterations`, `Success`
(`Success` is true iff `Stat=Optimal`).

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

- [Wikipedia: Karmarkar's algorithm](https://en.wikipedia.org/wiki/Karmarkar%27s_algorithm)
- Karmarkar, N. “A new polynomial-time algorithm for linear programming,”
  *Combinatorica*, 4(4), 1984
- Adler, I.; Karmarkar, N.; Resende, M.; Veiga, G. “An implementation of
  Karmarkar's algorithm for linear programming,” *Mathematical Programming*,
  44, 1989
- Sibling: [Ada-Simplex-Algorithm](../ada-simplex-algorithm/) (Dantzig tableau)
