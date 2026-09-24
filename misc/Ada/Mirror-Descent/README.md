# Mirror descent — Ada 2023

Educational, self-contained Ada 2023 package for **mirror descent**: an
iterative first-order method that finds a local minimum of a differentiable
(or convex) objective by taking gradient steps in a dual space induced by a
strongly convex regularizer $\psi$, then mapping back with the Bregman
divergence $D_\psi$. It generalizes **gradient descent** and
**multiplicative weights / Hedge**. See
[Wikipedia: Mirror descent](https://en.wikipedia.org/wiki/Mirror_descent).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT
(`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project overview

Nemirovski and Yudin (1983) introduced mirror descent. Given convex $f$
over a convex set $K$ and an $\alpha$-strongly convex distance-generating
function $\psi$, each iteration maps the current point $x_t$ to the dual
space, takes a gradient step, maps back, and Bregman-projects onto $K$:

$$
\nabla\psi(y_{t+1})=\nabla\psi(x_t)-\eta_t g_t,\qquad
x_{t+1}=\arg\min_{x\in K} D_\psi(x,y_{t+1}),
$$

where $g_t\in\partial f(x_t)$ (or $\nabla f(x_t)$ when smooth) and

$$
D_\psi(x,y)=\psi(x)-\psi(y)-\langle\nabla\psi(y),x-y\rangle.
$$

This package is a classroom implementation with an opaque `State` /
`Iterate`, dimension $D\le 64$, step size $\eta$, and two concrete
geometries.

## Two classroom geometries

| Geometry | Regularizer $\psi$ | Update | Feasible set |
| --- | --- | --- | --- |
| `Euclidean` | $\psi(x)=\tfrac12\|x\|^2$ | $x\leftarrow x-\eta g$ | $\mathbb{R}^D$ (optional Euclidean simplex projection) |
| `Entropic` | $\psi(x)=\sum_i x_i\ln x_i$ | $x_i\leftarrow x_i\exp(-\eta g_i)/Z$ | probability simplex |

Euclidean mirror descent recovers (projected) **gradient descent**.
Entropic mirror descent on the simplex recovers **Hedge / multiplicative
weights**.

Helpers expose $D_\psi$ for both geometries: `Bregman_Euclidean` is
$\tfrac12\|x-y\|^2$; `Bregman_Entropy` is the KL form
$\sum_i x_i\ln(x_i/y_i)$.

## MWU / regret siblings (README only)

Entropic mirror descent **is** Hedge on the simplex. Contrast —
documentation only, **do not** `with` —

- Ada-Multiplicative-Weight-Update-Method (MWU / Hedge as a first-class
  online learner)
- Ada regret-minimization siblings (external / internal regret)

This package stays self-contained so it can be studied as the geometric
template behind those algorithms.

## API summary

| Symbol | Role |
| --- | --- |
| `State` / `Iterate` | Opaque iterate: $D$, $\eta$, geometry, point $x$, rounds |
| `Create` | Origin (Euclidean) or uniform $1/D$ (Entropic); or custom $x_0$ |
| `Reset` | Restore default / custom start; clear rounds |
| `Step` | One mirror step with gradient / subgradient $g$ |
| `Point` / `Get` | Current primal $x$ |
| `Enable_Simplex_Projection` | Euclidean: project onto simplex after each `Step` |
| `Dot` / `Norm2` / `Scale` / `Add` / `Sub` | Vector helpers |
| `Normalize_Simplex` | $x/\sum x_i$ (entropic Bregman projection of a positive vector) |
| `Project_Simplex` | Euclidean projection onto $\{x\ge 0,\sum x_i=1\}$ |
| `Is_Simplex` | Non-negativity + sum-to-one check |
| `Bregman_Euclidean` | $\tfrac12\|x-y\|^2$ |
| `Bregman_Entropy` | $\sum_i x_i\ln(x_i/y_i)$ |
| `Suggested_Eta_Entropic` | $\sqrt{(\ln D)/T}$ Hedge schedule |
| `Invalid_Argument` | Bad $D$, $\eta\le 0$, lengths, non-simplex, … |

Bounds: $1\le D\le\texttt{Max\_Dim}=64$. Arrays are $1$-based.

## Build and test

```bash
make
make test
```

Uses `gnatmake -gnatwa -gnat2022` via `mirror_descent.gpr`. Expect a green
suite with zero warnings.

## Classroom walk-through

### Euclidean: minimize $\|x-x^\star\|^2$

1. `S := Create (2, 0.25, Euclidean);`
2. Target $x^\star=(1, -1)$; gradient of $\tfrac12\|x-x^\star\|^2$ is
   $g=x-x^\star$.
3. Each round `Step (S, Sub (Point (S), Star));`.
4. After enough steps `Point (S)` approaches $x^\star$.

### Entropic: linear loss on the simplex

1. `S := Create (3, 0.5, Entropic);` — uniform start.
2. Constant loss / gradient $g=(1,0,0)$: expert 1 always loses.
3. `Step (S, G);` shrinks mass on coordinate 1 (Hedge).
4. `Is_Simplex (Point (S))` stays true; mass concentrates on the best
   coordinates.

### Pseudocode (general)

```text
x ← x0 in K
for t = 1 .. T:
    g ← gradient / subgradient of f at x
    θ ← ∇ψ(x) − η · g          -- dual step
    y ← (∇ψ)^{-1}(θ)           -- map back
    x ← argmin_{z in K} D_ψ(z, y)
```

## References

- [Mirror descent (Wikipedia)](https://en.wikipedia.org/wiki/Mirror_descent)
- Nemirovski & Yudin — *Problem Complexity and Method Efficiency in
  Optimization* (1983)
- Beck & Teboulle — *Mirror descent and nonlinear projected subgradient
  methods for convex optimization* (Operations Research Letters, 2003)
- Bubeck — *Convex Optimization: Algorithms and Complexity* (FnT ML,
  2015) — mirror descent chapter

## License

Educational example for the RobertBoettcherSF Ada algorithm series.
