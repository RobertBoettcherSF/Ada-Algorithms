# Ground State (Ada 2023)

Educational, self-contained Ada 2023 package for the **quantum ground state**:
the stationary state of lowest energy, exact spectra for the 1-D infinite well
and harmonic oscillator, zero-point energy, discrete Hermitian Hamiltonians on
a grid with a Jacobi lowest-eigenpair solver, a one-parameter Gaussian
variational upper bound, degeneracy counting, and the 1-D nodeless property of
ground wavefunctions.

Based on [Wikipedia: Ground state](https://en.wikipedia.org/wiki/Ground_state).
Sibling surveys (documentation links only — no build dependency):
[`Ada-Variational-Method`](../ada-variational-method/),
[`Ada-Rayleigh-Ritz-Method`](../ada-rayleigh-ritz-method/).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Definition** | Lowest eigenvalue of Hermitian $H$ | Excited states above |
| **Zero-point energy** | $E_0$ of the ground level | Oscillator $E_0=\tfrac12\hbar\omega$ |
| **Degeneracy** | Multiplicity $>1$ | 2-D isotropic HO; equal diagonal |
| **Infinite well** | $E_n=n^2\pi^2\hbar^2/(2mL^2)$ | Ground $n=1$, nodeless $\sin$ |
| **Harmonic oscillator** | $E_n=(n+\tfrac12)\hbar\omega$ | Gaussian ground state |
| **Discrete $H$** | Tridiagonal kinetic + diagonal $V$ | Uniform grid |
| **Eigensolve** | Dense symmetric Jacobi ($N\le 64$) | Lowest eigenpair |
| **Variational** | Gaussian trial $E(\alpha)\ge E_0$ | Analytic optimum $\alpha^*=m\omega/\hbar$ |
| **Nodes** | Sign-change count on samples | Ground: zero interior nodes in 1-D |

## Definition

The **ground state** of a quantum-mechanical system is its stationary state of
lowest energy. Equivalently, if $H$ is a Hermitian Hamiltonian bounded below,
the ground energy is the lowest eigenvalue

$$
E_0=\min_{\|\psi\|=1}\langle\psi|H|\psi\rangle,
$$

and any corresponding eigenvector is a ground state. An **excited state** is
any eigenstate with energy strictly greater than $E_0$. In quantum field
theory the ground state is often called the vacuum.

## Zero-point energy

The energy of the ground state is the system's **zero-point energy**. Even in
the harmonic oscillator — classically at rest at the potential minimum — quantum
mechanics requires

$$
E_0=\frac12\hbar\omega>0
$$

(with $\hbar=m=1$ units available as package defaults). This package exposes
`Zero_Point_Energy` and verifies discrete / variational approximations against
it.

## Degeneracy and the third law

If more than one orthonormal ground state shares $E_0$, the level is
**degenerate**. Degeneracy arises when a nontrivial unitary that preserves $H$
acts nontrivially on the ground subspace. According to the **third law of
thermodynamics**, a system at absolute zero resides in its ground state, so its
entropy is fixed by the ground-state degeneracy (unique ground state $\Rightarrow$
zero residual entropy for an ideal crystal). This package reports multiplicities
via `Degeneracy_Of_Level`, a pedagogical $2\times 2$ equal-diagonal matrix, and
the closed-form degeneracy $n+1$ of the 2-D isotropic oscillator level with
total quanta $n=n_x+n_y$.

## Absence of nodes in one dimension

In one spatial dimension the ground-state wavefunction of the Schrödinger
equation can be proven to have **no nodes**. Sampling a discrete or analytic
wavefunction and counting sign changes (`Count_Sign_Changes`,
`Is_Nodeless_Interior`) makes this checkable: the infinite-well $\psi_1$ and
the discrete ground eigenvectors are nodeless, while excited $\psi_n$ exhibit
$n-1$ interior nodes.

## Exact models

### Infinite square well

For a particle in $[0,L]$ with infinite walls,

$$
E_n=\frac{n^2\pi^2\hbar^2}{2mL^2},\qquad
\psi_n(x)=\sqrt{\frac{2}{L}}\sin\Bigl(\frac{n\pi x}{L}\Bigr)\quad(n=1,2,\ldots).
$$

The ground state is $n=1$ (nodeless half-sine).

### Quantum harmonic oscillator

$$
E_n=\Bigl(n+\frac12\Bigr)\hbar\omega,\qquad
\psi_0(x)\propto\exp\Bigl(-\frac{m\omega x^2}{2\hbar}\Bigr).
$$

## Numerical eigensolve

On a uniform grid the kinetic operator $-\frac{\hbar^2}{2m}\frac{d^2}{dx^2}$
becomes a tridiagonal stencil and $V(x)$ a diagonal. The resulting real
symmetric matrix is diagonalized with a **Jacobi** sweep (reliable for
$N\le 64$ in this educational setting). `Lowest_Eigenpair` returns the ground
energy and a phase-normalized eigenvector; residuals
$\|H\psi-E\psi\|$ and the Rayleigh quotient provide accuracy checks. Discrete
well and oscillator grounds reproduce the analytic $E_0$ within discretization
error.

## Variational link

For any normalizable trial $\psi$,

$$
E[\psi]=\frac{\langle\psi|H|\psi\rangle}{\langle\psi|\psi\rangle}\ge E_0,
$$

with equality iff $\psi$ is a ground state. The Gaussian family
$\psi_\alpha\propto e^{-\alpha x^2/2}$ for the oscillator yields the analytic
upper bound

$$
E(\alpha)=\frac{\hbar^2\alpha}{4m}+\frac{m\omega^2}{4\alpha},
$$

minimized at $\alpha^*=m\omega/\hbar$ with $E=E_0$. See sibling
`Ada-Variational-Method` for the broader variational narrative and
`Ada-Rayleigh-Ritz-Method` for multi-parameter / subspace Ritz extraction.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Wave`, `Vector`, `Matrix` | Dense problems $\le$ `Max_N=64` |
| Helpers | `Near`, `Clamp`, `Pi_Value`, `Dot`, `Norm`, `Norm2` | Numerics |
| Well | `Infinite_Well_Energy`, `Infinite_Well_Ground_Energy`, `Infinite_Well_Psi` | Exact $E_n$, $\psi_n$ |
| Oscillator | `Harmonic_Energy`, `Zero_Point_Energy`, `Harmonic_Ground_Psi` | Exact $E_n$, $\psi_0$ |
| Discrete $H$ | `Make_Uniform_Grid`, `Grid_Spacing`, `Build_Discrete_Hamiltonian`, `Build_Infinite_Well_Hamiltonian`, `Build_Harmonic_Hamiltonian` | Grid operators |
| Eigen | `Jacobi_Symmetric`, `Lowest_Eigenpair`, `Rayleigh_Quotient`, `Residual_Norm`, `Normalize_In_Place` | Ground eigenpair |
| Nodes | `Count_Sign_Changes`, `Is_Nodeless_Interior` | 1-D node theorem checks |
| Degeneracy | `Degeneracy_Of_Level`, `Isotropic_2D_Oscillator_Degeneracy`, `Make_Equal_Diagonal_2x2` | Multiplicity demos |
| Variational | `Variational_Gaussian_Energy`, `Optimize_Gaussian_Trial`, `Optimal_Gaussian_Alpha` | Upper bound / $\alpha^*$ |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`, `Degenerate`.

Default units: $\hbar=1$, $m=1$ (`Default_Hbar`, `Default_Mass`), overridable
on each API that admits them.

## Build and test

```bash
make clean && make        # gnatmake -gnatwa -gnat2022 -Pground_state.gpr
make test                 # runs bin/tests; expect Fail_Count=0 and ≥100 PASS
```

Requirements: GNAT (GCC Ada) with Ada 2022/2023 support.

## Layout

Exactly seven root entries (no `main.adb`):

1. `ground_state.ads`
2. `ground_state.adb`
3. `ground_state.gpr`
4. `Makefile`
5. `tests.adb`
6. `README.md`
7. `.gitignore` (`obj/`, `bin/`)

## References

- [Wikipedia: Ground state](https://en.wikipedia.org/wiki/Ground_state)
- [Wikipedia: Zero-point energy](https://en.wikipedia.org/wiki/Zero-point_energy)
- [Wikipedia: Particle in a box](https://en.wikipedia.org/wiki/Particle_in_a_box)
- [Wikipedia: Quantum harmonic oscillator](https://en.wikipedia.org/wiki/Quantum_harmonic_oscillator)
- Sibling: [Ada-Variational-Method](../ada-variational-method/)
- Sibling: [Ada-Rayleigh-Ritz-Method](../ada-rayleigh-ritz-method/)
- Griffiths, *Introduction to Quantum Mechanics*; Cohen-Tannoudji et al., *Quantum Mechanics*

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
