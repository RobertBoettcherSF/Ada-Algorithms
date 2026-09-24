# N-Body Problems — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for the classical
gravitational
[Wikipedia: n-body problem](https://en.wikipedia.org/wiki/N-body_problem):
Newtonian forces with softening, **two-body** circular-orbit helpers,
**direct** $O(N^2)$ summation, **Euler** and symplectic **leapfrog /
velocity Verlet** integrators, kinetic / potential / total energy, linear
momentum, and center of mass — plus a trivial far-cluster **monopole**
note.

This package is an **umbrella / survey** of small, testable representatives
in **2-D** (the 3-D equations are identical with $\mathbf{r}\in\mathbb{R}^3$).
Full hierarchical solvers live in sibling repositories **Ada-Barnes-Hut**
(monopole tree / MAC) and **Ada-Fast-Multipole-Method** (higher-order
multipoles). Those repos are linked here only — **not** dependencies of
this repository.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## History (brief)

Isaac **Newton** showed that mutual gravitation among many bodies makes
exact planetary orbits far harder than the one-body / central-force case.
In the late 19th century King **Oscar II** of Sweden offered a prize for a
convergent series solution; **Poincaré**’s prize memoir did not solve the
stated problem but seeded **chaos theory**. **Sundman** later gave a series
solution for $n=3$; generalizations for $n>3$ followed (Babadzanjanz,
Wang). Today the practical route for $n\gg 1$ is numerical simulation:
direct summation for small $n$, tree codes and FMM for large $n$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Formulation** | Softened Newtonian gravity in 2-D | Mass, position, velocity |
| **Two-body** | Reduced mass $\mu$; Kepler circular helpers | Period, speed, energy |
| **Direct sum** | `Forces_Direct` / `Accelerations_Direct` | $O(N^2)$ |
| **Integrators** | Leapfrog (velocity Verlet) and Euler | Energy vs drift |
| **Conserved** | Energy (approx.), $\mathbf{P}$, COM motion | Softened PE |
| **Many-body note** | Trivial monopole cluster force | See BH / FMM siblings |

## Newtonian formulation

For point masses $m_i$ with positions $\mathbf{r}_i$, Newton’s law of
gravitation and the second law give

$$
\ddot{\mathbf{r}}_i = -G\sum_{j\neq i}
\frac{m_j(\mathbf{r}_i-\mathbf{r}_j)}{|\mathbf{r}_i-\mathbf{r}_j|^3}.
$$

Equivalently, the force on body $i$ due to $j$ is along $\mathbf{r}_j-\mathbf{r}_i$
with magnitude $G m_i m_j / r_{ij}^2$. This survey uses a **softened**
kernel (Plummer-style) with softening length $\varepsilon$ to avoid
singularities at $r\to 0$:

$$
\mathbf{F}_{ij}=G\,m_i m_j\,
\frac{\mathbf{r}_j-\mathbf{r}_i}{\bigl(|\mathbf{r}_j-\mathbf{r}_i|^2+\varepsilon^2\bigr)^{3/2}}.
$$

Softened pair potential:

$$
\Phi_{ij}=-\frac{G m_i m_j}{\sqrt{r_{ij}^2+\varepsilon^2}}.
$$

Kinetic energy $T=\sum_i\tfrac12 m_i|\mathbf{v}_i|^2$, potential
$V=\sum_{i<j}\Phi_{ij}$, total $E=T+V$. Linear momentum
$\mathbf{P}=\sum_i m_i\mathbf{v}_i$ is conserved in the absence of external
forces (pairwise forces cancel by Newton’s third law).

## Two-body problem

With reduced mass $\mu=m_1 m_2/(m_1+m_2)$ the relative motion is a
Kepler problem. For a **circular** relative orbit of separation $a$:

$$
v=\sqrt{\frac{G(m_1+m_2)}{a}},\qquad
T=2\pi\sqrt{\frac{a^3}{G(m_1+m_2)}},\qquad
E=-\frac{G m_1 m_2}{2a}.
$$

`Make_Circular_Binary` places both bodies in the COM frame with matching
tangential speeds so centripetal demand balances mutual gravity.

## Three-body and chaos

The **three-body problem** is not solvable in elementary closed form in
general; it exhibits sensitive dependence on initial conditions (chaos).
Special solutions include Lagrange equilateral configurations and
collinear Euler solutions. This package only checks soft numerical
sanity (net force $\approx 0$, COM) for an equal-mass triangle and a
symmetric collinear triple — not a full 3-body integrator study.

## Direct summation vs tree / FMM

| Method | Typical cost | Role here |
| --- | --- | --- |
| Direct (`Forces_Direct`) | $O(N^2)$ | Exact softened pairs (survey default) |
| Barnes–Hut tree | $O(N\log N)$ | Sibling **Ada-Barnes-Hut** |
| Fast Multipole Method | $O(N)$ (full FMM) | Sibling **Ada-Fast-Multipole-Method** |

`Force_Approx_Monopole_Cluster` and `Accept_Monopole` ($s/d<\theta$) are
tiny educational stand-ins for the far-field idea; they do **not**
duplicate a full quadtree or multipole pipeline.

## Integrators

**Explicit Euler** updates positions with the old velocity, then velocities
with the current acceleration. It is simple but drifts in energy.

**Leapfrog / velocity Verlet** (kick–drift–kick) is a second-order
**symplectic** method widely used in $n$-body work:

1. $\mathbf{v}\leftarrow\mathbf{v}+\tfrac12\mathbf{a}\,\Delta t$
2. $\mathbf{r}\leftarrow\mathbf{r}+\mathbf{v}\,\Delta t$
3. Recompute $\mathbf{a}$ from forces
4. $\mathbf{v}\leftarrow\mathbf{v}+\tfrac12\mathbf{a}\,\Delta t$

On a circular two-body orbit over several periods, leapfrog keeps
$|E-E_0|$ much smaller than Euler at the same step size (demonstrated in
`tests.adb`).

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vec2`, `Body_State`, `Body_Array`, `Force_Array`, `Accel_Array`, `NB_Config` | Domain model ($G$, $\varepsilon$) |
| Helpers | `Near`, `Hypot`, `Soft_Denom`, `Vec_Add` / `Sub` / `Scale` / `Norm`, `Dot` | Numerics |
| Force | `Pair_Force`, `Pair_Potential`, `Forces_Direct`, `Accelerations_Direct` | Softened gravity |
| Conserved | `Kinetic_Energy`, `Potential_Energy`, `Total_Energy`, `Linear_Momentum`, `Center_Of_Mass`, `Angular_Momentum_Z`, `Total_Mass` | Diagnostics |
| Two-body | `Reduced_Mass`, `Circular_Orbit_Speed`, `Circular_Orbit_Period`, `Circular_Orbit_Energy`, `Make_Circular_Binary` | Kepler circular |
| Integrators | `Leapfrog_Step`, `Euler_Step` | Time stepping |
| Many-body note | `Force_Approx_Monopole_Cluster`, `Accept_Monopole`, `Force_Sum` | Far cluster / MAC |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Empty_System`.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022` with project `n_body_problems.gpr`
(`Main = tests.adb`). Expect exit status 0 and `Fail_Count = 0`.

## Layout

Exactly seven root entries (no `main.adb`):

1. `n_body_problems.ads`
2. `n_body_problems.adb`
3. `n_body_problems.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## Related siblings

- [Ada-Barnes-Hut](https://github.com/RobertBoettcherSF/ada-barnes-hut) — monopole quadtree / MAC
- [Ada-Fast-Multipole-Method](https://github.com/RobertBoettcherSF/ada-fast-multipole-method) — hierarchical multipoles

## References

- Wikipedia: [n-body problem](https://en.wikipedia.org/wiki/N-body_problem)
- Wikipedia: [Barnes–Hut simulation](https://en.wikipedia.org/wiki/Barnes–Hut_simulation)
- Wikipedia: [Fast multipole method](https://en.wikipedia.org/wiki/Fast_multipole_method)
- Newton, *Philosophiæ Naturalis Principia Mathematica*
- Poincaré; Sundman (series solutions / three-body)
