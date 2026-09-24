# Variational Method (Ada 2023)

Educational, self-contained Ada 2023 survey package for the **calculus of
variations** — discrete paths, numerical evaluation of functionals
$J[y]=\int_a^b L(x,y,y')\,dx$, Euler–Lagrange stationarity, shortest-path and
Dirichlet-energy examples — plus a small **quantum variational principle**
application (Gaussian trial for the harmonic oscillator; energy upper bound).

Wikipedia’s page title **Variational method**
[redirects to Calculus of variations](https://en.wikipedia.org/wiki/Calculus_of_variations);
the hatnote points to the QM article
[Variational method (quantum mechanics)](https://en.wikipedia.org/wiki/Variational_method_(quantum_mechanics)).
Neighbor spreadsheet rows include **Rayleigh–Ritz** and **Ground state**; see
sibling package [`Ada-Rayleigh-Ritz-Method`](../ada-rayleigh-ritz-method/)
(documentation link only — no build dependency).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Discrete path** | Polyline $(x_i,y_i)$ | Fixed endpoints |
| **Arc-length functional** | $L=\sqrt{1+(y')^2}$ | Minimizer = straight line |
| **Dirichlet energy** | $L=(y')^2$ | EL $\Rightarrow y''=0$ (linear) |
| **Quadrature** | Trapezoid / Simpson on polyline | Exact on segments for arc length |
| **Stationarity** | Finite-difference $\partial J/\partial y_i$ | Gradient ≈ 0 at minimizer |
| **Path improvement** | Gradient / coordinate descent | Bowed $\to$ straighter |
| **QM trial** | $\psi\propto e^{-\alpha x^2/2}$ | $E[\psi]\ge E_0$ |
| **Harmonic $H$** | $-d^2/dx^2+x^2$ | Exact $E_0=1$ |

## Calculus of variations

Elementary calculus studies how a function’s value changes with its argument.
The **calculus of variations** studies how a **functional**
$J$ — a map from functions to scalars — changes when the function itself is
varied. Typical functionals are definite integrals of a **Lagrangian**
$L(x,y,y')$:

$$
J[y]=\int_a^b L\bigl(x,y(x),y'(x)\bigr)\,dx.
$$

A necessary condition for $y$ to extremize $J$ (with fixed endpoints) is the
**Euler–Lagrange equation**

$$
\frac{\partial L}{\partial y}-\frac{d}{dx}\frac{\partial L}{\partial y'}=0.
$$

### Shortest path

For arc length, $L=\sqrt{1+(y')^2}$. The Euler–Lagrange equation implies
$y'=\mathrm{const}$, so the extremal is a **straight line**. This package
builds discrete polylines, evaluates $J$ as the sum of Euclidean segment
lengths, and verifies that sine-bowed competitors are strictly longer.
Finite-difference gradients of discrete $J$ w.r.t. interior nodes vanish on
the line and drive gradient / coordinate descent from a bowed path toward it.

### Dirichlet energy

For $L=(y')^2$ (prototype of Dirichlet’s principle / Laplace problems),
Euler–Lagrange reduces to $y''=0$: the minimizer with fixed boundary values
is again the **linear interpolant**. The discrete energy
$\sum_i(\Delta y_i)^2/|\Delta x_i|$ and the mean absolute second difference
of interior nodes make this checkable on grids.

Classical named problems such as the **brachistochrone** (curve of fastest
descent) and the **catenary** (hanging chain) are mentioned here for context
only; this survey implements the clean arc-length and Dirichlet cases plus
path improvement, not a full brachistochrone solver.

## Quantum variational principle (application)

In quantum mechanics the same variational idea yields an **upper bound** on
the ground-state energy. For a Hamiltonian $H$ bounded below and any
normalizable trial $\psi$,

$$
E[\psi]=\frac{\langle\psi|H|\psi\rangle}{\langle\psi|\psi\rangle}\ge E_0,
$$

with equality iff $\psi$ is the ground state. Choosing a parameterized ansatz
and minimizing $E$ approximates both $E_0$ and the ground wavefunction.

This package uses the 1-D harmonic oscillator
$H=-\dfrac{d^2}{dx^2}+x^2$ (units $\hbar=m=\omega$ scaled so the exact
ground energy is $E_0=1$) and the Gaussian trial
$\psi_\alpha(x)\propto\exp(-\alpha x^2/2)$. Analytically,

$$
E(\alpha)=\frac{\alpha}{2}+\frac{1}{2\alpha},
$$

minimized at $\alpha^*=1$ with $E=1=E_0$. Discrete Rayleigh quotients on a
uniform grid recover the same upper-bound story and improve when $\alpha$ is
optimized.

Linear combinations of trial functions recover the **Rayleigh–Ritz** /
Ritz method (see sibling `Ada-Rayleigh-Ritz-Method`). The present package
stays with a simple nonlinear one-parameter trial so the CoV narrative remains
primary.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Path`, `Wave` | Paths ≤ `Max_Points=64`; grids ≤ `Max_Grid=64` |
| Helpers | `Near`, `Clamp`, `Linear_Interpolation_Y` | Numerics |
| Paths | `Straight_Line_Path`, `Bowed_Path` | Construction |
| Functionals | `Path_Length`, `Dirichlet_Energy`, `Functional_Trapezoid_*`, `Functional_Simpson_Arc` | $J[y]$ |
| EL / stationarity | `Euler_Lagrange_Residual_Dirichlet`, `Mean_Abs_Second_Difference`, `Max_Abs_Length_Gradient` | Residuals / $\nabla J$ |
| Descent | `Improve_Path_Gradient`, `Improve_Path_Coordinate` | Bowed → minimizer |
| QM | `Harmonic_Ground_Exact`, `Gaussian_Trial_Energy_Analytic`, `Quantum_Trial_Energy`, `Rayleigh_Energy`, `Normalize`, `Optimize_Gaussian_Alpha`, `Make_*` | Upper bound / trial |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Degenerate`.

## Build and test

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pvariational_method.gpr
make test                 # runs bin/tests; expect Fail_Count=0 and ≥100 PASS
```

Requirements: GNAT (GCC Ada) with Ada 2022/2023 support.

## Layout

Exactly seven root entries (no `main.adb`):

1. `variational_method.ads`
2. `variational_method.adb`
3. `variational_method.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- [Wikipedia: Calculus of variations](https://en.wikipedia.org/wiki/Calculus_of_variations)
  (target of the **Variational method** redirect)
- [Wikipedia: Variational method (quantum mechanics)](https://en.wikipedia.org/wiki/Variational_method_(quantum_mechanics))
  (hatnote companion)
- [Wikipedia: Euler–Lagrange equation](https://en.wikipedia.org/wiki/Euler%E2%80%93Lagrange_equation)
- Sibling: [Ada-Rayleigh-Ritz-Method](../ada-rayleigh-ritz-method/)
- Gelfand & Fomin, *Calculus of Variations*; Griffiths, *Introduction to Quantum Mechanics*

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
