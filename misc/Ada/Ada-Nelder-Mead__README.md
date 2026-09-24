# Nelder–Mead Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Nelder–Mead method** (also **downhill simplex**, **amoeba**, or
**polytope** method) — a derivative-free **direct search** heuristic that
minimizes a smooth objective $f:\mathbb{R}^n\to\mathbb{R}$ by maintaining
an $n{+}1$-vertex simplex and replacing the worst vertex via reflection,
expansion, contraction, or shrink.

Based on [Wikipedia: Nelder–Mead method](https://en.wikipedia.org/wiki/Nelder–Mead_method)
(Nelder & Mead, *Computer Journal* **7**, 308–313, 1965; development of
Spendley, Hext & Himsworth, 1962).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages: **[Ada-Simulated-Annealing](../ada-simulated-annealing/)**,
**[Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/)**,
**[Ada-Random-Search](../ada-random-search/)** — other derivative-free /
metaheuristic optimizers on continuous landscapes.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Compare $f$ at simplex vertices | No gradients / Hessians |
| **Geometry** | $n{+}1$ points in $\mathbb{R}^n$ | Segment / triangle / tetrahedron / … |
| **Steps** | Reflect, expand, contract, shrink | Standard $\alpha,\gamma,\rho,\sigma$ |
| **Init** | $x_1=x_0$, axis offsets of size $s$ | Sensitive to variable scaling |
| **Stop** | Size or $f$-spread tol, or max iters | Programs terminate; iters may converge |
| **Dim** | $1\ldots 8$ | `Max_Dim = 8` |

## Brief history

John A. Nelder and Roger Mead (1965) proposed the method as a development of
the simplex designs of Spendley, Hext, and Himsworth (1962). It remains a
popular **pattern search** / **derivative-free** baseline when derivatives
are unavailable or expensive (e.g. simulation-based objectives). Like other
heuristics, it can converge to non-stationary points on some problems unless
stronger conditions hold (Powell 1973; McKinnon 1999).

## Simplex and coefficients

A **simplex** in $n$ dimensions is a polytope with $n{+}1$ vertices
$x_1,\ldots,x_{n+1}$. After ordering by ascending objective value

$$
f(x_1)\le f(x_2)\le\cdots\le f(x_{n+1}),
$$

let $x_o$ be the **centroid** of all vertices except the worst $x_{n+1}$:

$$
x_o=\frac{1}{n}\sum_{i=1}^{n}x_i.
$$

Standard coefficients (Wikipedia / Nelder–Mead defaults):

$$
\alpha=1\quad\text{(reflection)},\quad
\gamma=2\quad\text{(expansion)},\quad
\rho=\tfrac12\quad\text{(contraction)},\quad
\sigma=\tfrac12\quad\text{(shrink)}.
$$

## One iteration (Wikipedia variation)

1. **Order** vertices by $f$; optionally terminate (see below).
2. Compute centroid $x_o$ of the best $n$ vertices.
3. **Reflection:** $x_r=x_o+\alpha(x_o-x_{n+1})$.
   - If $f(x_1)\le f(x_r)<f(x_n)$, replace $x_{n+1}$ by $x_r$ and restart.
4. **Expansion:** if $f(x_r)<f(x_1)$, try
   $x_e=x_o+\gamma(x_r-x_o)$; take the better of $x_e$ and $x_r$.
5. **Contraction:** if $f(x_r)\ge f(x_n)$:
   - **Outside** when $f(x_r)<f(x_{n+1})$:
     $x_c=x_o+\rho(x_r-x_o)$; accept if $f(x_c)<f(x_r)$.
   - **Inside** when $f(x_r)\ge f(x_{n+1})$:
     $x_c=x_o+\rho(x_{n+1}-x_o)$; accept if $f(x_c)<f(x_{n+1})$.
6. **Shrink:** otherwise replace every non-best vertex by
   $x_i\leftarrow x_1+\sigma(x_i-x_1)$.

Intuitively: reflect the highest point through the opposite face; stretch
when the landscape improves; contract or shrink when the simplex straddles a
valley or must pass through a narrow region (cf. *Numerical Recipes*).

## Initial simplex and termination

Given a start $x_0$ and step $s>0$, this package builds

$$
x_1=x_0,\qquad
x_{1+i}=x_0+s\,e_i\quad(i=1\ldots n),
$$

the classic axis-aligned construction (sensitive to coordinate scaling).

Stopping criteria here (both geometric and value tolerances, in the spirit
of MATLAB `fminsearch` / Nash's size check):

- **Size:** maximum Euclidean distance from the best vertex to any other
  $\le$ `Size_Tol`;
- **$f$-spread:** $f(x_{n+1})-f(x_1)\le$ `F_Tol`;
- **Converged** only when **both** size and $f$-spread are met (avoids
  stopping on equal $f$ at symmetric wrong points);
- **Budget:** `Max_Iters` iterations otherwise.

(Nelder & Mead originally used the sample standard deviation of the vertex
function values; Nash also checks that shrink actually reduces size.)

## Versus gradient-based methods

| | Nelder–Mead | Gradient / quasi-Newton (e.g. BFGS) |
| --- | --- | --- |
| Derivatives | None (function values only) | $\nabla f$ (and often approx. Hessian) |
| Cost / iter | Typically $1$–$2$ evals (more on shrink) | Line search + gradient work |
| Smoothness | Heuristic; may stall at non-stationary points | Locally fast on smooth well-scaled problems |
| Nonsmooth / noisy $f$ | Often usable as a direct search | Gradients may be undefined / unstable |
| Scaling | Sensitive to variable units / initial $s$ | Also benefits from good scaling |

For unconstrained smooth problems with cheap gradients, BFGS / nonlinear CG /
Levenberg–Marquardt usually outperform Nelder–Mead. Prefer Nelder–Mead when
only black-box comparisons are available, or as a robust first try in low
dimension ($n\lesssim 10$).

## Built-in test objectives

| Function | Form (sketch) | Global structure |
| --- | --- | --- |
| `Sphere` | $\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana valley; min $0$ at $(1,1)$ |
| `Himmelblau` | $(x^2+y-11)^2+(x+y^2-7)^2$ | Four minima with $f=0$ |
| `Quadratic_1D` | $(x_1-2)^2$ | 1-D / 2-vertex simplex demo |
| `Shifted_Sphere` | $\sum_i(x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |

## API (`Nelder_Mead`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Vertex`, `Simplex`, `Config`, `Result`, `Objective_Fn` | Domain, coeffs, output |
| Helpers | `Near`, `Point_Near`, `Norm2`, `Dot`, `Add`, `Sub`, `Scale` | Geometry / tolerance |
| Ops | `Reflect`, `Expand`, `Contract_Outside`, `Contract_Inside`, `Shrink_Toward_Best` | Wikipedia steps |
| Simplex | `Centroid_Excluding_Worst`, `Simplex_Size`, `F_Spread`, `Order_Vertices`, `Initial_Simplex` | Setup / diagnostics |
| Objectives | `Sphere`, `Rosenbrock`, `Himmelblau`, `Quadratic_1D`, `Shifted_Sphere` | Test landscapes |
| Driver | `Minimize` | Downhill simplex from $x_0$ + step |

Named exception: `Invalid_Argument` (e.g. Rosenbrock / Himmelblau with
dimension $<2$).

`Config` defaults: $\alpha=1$, $\gamma=2$, $\rho=1/2$, $\sigma=1/2$,
`Step=1`, `Max_Iters=5000`, `Size_Tol=1e-10`, `F_Tol=1e-12`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Nelder–Mead method](https://en.wikipedia.org/wiki/Nelder–Mead_method)
- J. A. Nelder, R. Mead, *A simplex method for function minimization*,
  Computer Journal **7** (4), 308–313 (1965)
- W. Spendley, G. R. Hext, F. R. Himsworth, *Sequential Application of
  Simplex Designs in Optimisation and Evolutionary Operation*,
  Technometrics **4**, 441–461 (1962)
- W. H. Press et al., *Numerical Recipes*, §10.5 Downhill Simplex Method
- K. I. M. McKinnon, *Convergence of the Nelder–Mead simplex method to a
  non-stationary point*, SIAM J. Optim. **9**, 148–158 (1999)
- Siblings: [Ada-Simulated-Annealing](../ada-simulated-annealing/),
  [Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/),
  [Ada-Random-Search](../ada-random-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
