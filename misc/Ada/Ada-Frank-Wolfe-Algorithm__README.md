# Frank–Wolfe Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Frank–Wolfe algorithm** (also called the **conditional gradient** method)
for **constrained** minimization of a smooth convex objective
$f:\mathcal{D}\to\mathbb{R}$ over a compact convex set $\mathcal{D}$.
Each iteration solves a **linear minimization oracle** (LMO) and takes a
convex-combination step toward the oracle vertex — **projection-free**.

$$
s_k\in\arg\min_{s\in\mathcal{D}}\langle\nabla f(x_k),\,s\rangle,\qquad
x_{k+1}=(1-\gamma_k)\,x_k+\gamma_k\,s_k
$$

with step size $\gamma_k\in(0,1]$, e.g. the open-loop schedule
$\gamma_k=2/(k+2)$, exact line search on the segment, or Armijo
backtracking. Stopping uses the **duality gap**

$$
G(x)=\max_{s\in\mathcal{D}}\langle\nabla f(x),\,x-s\rangle
=\langle\nabla f(x),\,x-s^\star\rangle
$$

where $s^\star$ is an LMO solution at $\nabla f(x)$.

Based on [Wikipedia: Frank–Wolfe algorithm](https://en.wikipedia.org/wiki/Frank%E2%80%93Wolfe_algorithm)
(Frank & Wolfe, 1956).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Gradient-Descent](../ada-gradient-descent/)**,
**[Ada-Line-Search](../ada-line-search/)**,
**[Ada-Simplex-Algorithm](../ada-simplex-algorithm/)** — unconstrained
first-order steps, 1-D acceptance conditions, and LP pivots that motivate
polytope LMOs.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Conditional gradient | Linearize $f$, move toward LMO vertex |
| **LMO** | $\arg\min_{s\in D}\langle g,s\rangle$ | Simplex / box / $\ell_1$ ball |
| **Step** | $\gamma_k=2/(k+2)$ or segment search | `Open_Loop` / `Exact_Line_Search` / `Armijo` |
| **Update** | $x\leftarrow(1-\gamma)x+\gamma s$ | Stays in $\mathrm{conv}(D)$ |
| **Stop** | Duality gap $G(x)$ | Also $\|\Delta x\|$, max iters |
| **Gradient** | Analytical `Grad_Fn` or central FD | FD when `Grad` is null |
| **Dim** | $n\le 16$ | `Max_Dim = 16` |

## Brief history

Marguerite Frank and Philip Wolfe introduced the method in 1956 for quadratic
programs with linear constraints. It resurfaced in machine learning as a
**projection-free** first-order scheme whenever an LMO is cheaper than a
Euclidean projection (simplices, spectrahedra, flow polytopes). Worst-case
rate is typically $O(1/k)$ for smooth convex objectives; faster rates hold
under extra curvature / strong-convexity assumptions.

## Problem statement

$$
\min_{x\in\mathcal{D}} f(x)
$$

with $\mathcal{D}$ compact convex and $f$ convex and continuously
differentiable. Unlike projected gradient descent, Frank–Wolfe never
projects: feasibility is preserved by convex combination with an extreme
point returned by the LMO.

## One iteration (sketch)

1. Evaluate $g=\nabla f(x_k)$ (analytical or central finite differences with
   step `Fd_Eps·(1+|x_i|)`).
2. **LMO:** $s_k\in\arg\min_{s\in\mathcal{D}}\langle g,s\rangle$.
3. **Gap:** $G(x_k)=\langle g,\,x_k-s_k\rangle$. Stop if $G\le$ `Gap_Tol`.
4. Choose $\gamma_k\in(0,1]$:
   - **Open loop:** $\gamma_k=2/(k+2)$;
   - **Exact:** minimize $\varphi(\gamma)=f((1-\gamma)x_k+\gamma s_k)$ on
     $[0,1]$ (golden section);
   - **Armijo:** backtrack from $\gamma=1$ along $s_k-x_k$.
5. Set $x_{k+1}=(1-\gamma_k)x_k+\gamma_k s_k$.

## Linear minimization oracles

| Domain | Oracle | Implementation |
| --- | --- | --- |
| Probability simplex $\Delta^{n-1}$ | $s=e_{i^*}$, $i^*=\arg\min_i g_i$ | `LMO_Simplex` |
| Box $[L,U]^n$ | $s_i=L_i$ if $g_i>0$, else $U_i$ | `LMO_Box` |
| $\ell_1$ ball of radius $R$ | $s=-R\,\mathrm{sign}(g_{i^*})e_{i^*}$, $i^*=\arg\max_i\|g_i\|$ | `LMO_L1_Ball` |

Pass an `LMO_Fn` to `Minimize`: `LMO_Simplex'Access`, or
`Active_Box_LMO'Access` / `Active_L1_LMO'Access` after
`Set_Box_Bounds` / `Set_L1_Radius`.

## Duality gap

Convexity implies $f(y)\ge f(x)+\langle\nabla f(x),\,y-x\rangle$, so

$$
f(x)-f(x^\star)\le\max_{s\in\mathcal{D}}\langle\nabla f(x),\,x-s\rangle=G(x).
$$

Thus $G(x)=0$ certifies optimality. The gap is cheap once the LMO call is
available and is the package's primary stopping criterion (`Config.Gap_Tol`).

## Versus Gradient descent / Line search / Simplex

| | Frank–Wolfe (this) | Gradient descent | Line search | Simplex algorithm |
| --- | --- | --- | --- | --- |
| Feasible set | Compact convex $D$ | Unconstrained $\mathbb{R}^n$ | 1-D along $p$ | Polyhedron / LP |
| Subproblem | Linear min over $D$ | (optional) Armijo on $-\nabla f$ | Choose $\alpha$ | Pivots / bases |
| Projection | None (convex combo) | N/A | N/A | Implicit in tableau |
| Role | Constrained 1st-order | Unconstrained 1st-order | Inner $\alpha$ | Exact LP |

Prefer **this package** when an LMO is natural (simplex, box, $\ell_1$).
Prefer **Gradient-Descent** for unconstrained smooth problems. Prefer
**Line-Search** to study Armijo / Wolfe in isolation. Prefer **Simplex**
when the model is a linear program rather than a smooth nonlinear $f$.

## Built-in demo objectives

| Objective | Form | Typical domain |
| --- | --- | --- |
| `Sphere` | $\sum x_i^2$ | Box / $\ell_1$ (optimum at $0$ if feasible) |
| `Shifted_Quadratic` | $\tfrac12\sum(x_i-1/n)^2$ | Simplex (optimum at uniform barycenter) |
| `Weighted_Quadratic` | $\tfrac12\sum i\,x_i^2$ | Simplex (mass on small indices) |
| `Linear_Ones` | $\sum x_i$ | Box / $\ell_1$ (vertex optimum) |

Each exposes a matching analytical `*_Grad` for tests against
`Finite_Difference_Gradient`.

## API (`Frank_Wolfe_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point` / `Vector`, `Config`, `Result`, `Objective_Fn`, `Grad_Fn`, `LMO_Fn`, `Step_Mode_Kind` | Domain / callbacks |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale`, `Convex_Combination` | Linear algebra |
| Core | `Finite_Difference_Gradient`, `Open_Loop_Step`, `Duality_Gap`, `Armijo_Accept`, `Exact_Line_Search`, `Armijo_Line_Search` | Gap / steps |
| Oracles | `LMO_Simplex`, `LMO_Box`, `LMO_L1_Ball` | Concrete LMOs |
| Active LMO | `Set_Box_Bounds` / `Active_Box_LMO`, `Set_L1_Radius` / `Active_L1_LMO` | `LMO_Fn` adapters |
| Demos | `Sphere`, `Shifted_Quadratic`, `Weighted_Quadratic`, `Linear_Ones` (+ `*_Grad`) | Test objectives |
| Driver | `Minimize` | Frank–Wolfe loop |

Named exceptions: `Invalid_Argument`, `Line_Search_Failed` (no Armijo
$\gamma$ within budget; the driver then stops and reports current progress).

`Config` defaults: `Max_Iterations=500`, `Gap_Tol=1e-6`, `Step_Tol=1e-12`,
`Step_Mode=Open_Loop`, `Armijo_C=1e-4`, `Line_Search_Rho=0.5`,
`Max_Line_Search=40`, `Exact_Tol=1e-10`, `Fd_Eps=1e-7`.

`Result` fields: `Final_Point`, `Final_Value`, `Final_Gap`, `Dim`,
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

- [Wikipedia: Frank–Wolfe algorithm](https://en.wikipedia.org/wiki/Frank%E2%80%93Wolfe_algorithm)
- Frank, M. & Wolfe, P. An algorithm for quadratic programming.
  *Naval Research Logistics Quarterly*, 1956
- Jaggi, M. Revisiting Frank–Wolfe: Projection-Free Sparse Convex
  Optimization. *ICML*, 2013
- Sibling packages in this series: Gradient-Descent, Line-Search,
  Simplex-Algorithm
