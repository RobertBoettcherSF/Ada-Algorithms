# Hybrid / Hamiltonian Monte Carlo — Ada 2023

Educational, self-contained Ada 2023 package implementing **Hybrid Monte Carlo**
(**Hamiltonian Monte Carlo**, HMC; Duane et al. 1987; Neal 2011). Given a
differentiable potential $U$ with $\pi(q)\propto e^{-U(q)}$, the sampler
augments position $q$ with momentum $p$, proposes a trajectory under
Hamiltonian dynamics via the **leapfrog** integrator, and accepts or rejects
with a Metropolis step on the Hamiltonian $H=U+K$. Momentum is refreshed from
$\mathcal{N}(0,1)$ (unit mass) at every proposal.

Primary demo: **1D standard normal** $U(q)=q^2/2$. Also: shifted / wide
Gaussians and optional isotropic HMC in $D\le 4$.

Based on [Wikipedia: Hamiltonian Monte Carlo](https://en.wikipedia.org/wiki/Hamiltonian_Monte_Carlo).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (Monte Carlo survey series):

| Package | Role |
| --- | --- |
| [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER) | Recursive stratified Monte Carlo integration |
| [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau) | Flat-histogram density-of-states sampling |
| [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings) | MCMC / Metropolis–Hastings (random-walk) |
| [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo) | This package (Hybrid / Hamiltonian MC) |
| [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling) | Forthcoming — Gibbs sampling |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | MCMC with Hamiltonian proposals | Distant moves, high accept rate |
| **Target** | $U$, $\nabla U$ access-to-function | $\pi\propto e^{-U}$ |
| **Kinetic** | $K(p)=\|p\|^2/2$ | Unit mass |
| **Integrator** | Leapfrog, step $\varepsilon$, $L$ steps | Symplectic, reversible |
| **Accept** | $\alpha=\min(1,e^{-\Delta H})$ | Metropolis on $H=U+K$ |
| **Refresh** | $p\sim\mathcal{N}(0,I)$ each proposal | Gibbs step on momentum |
| **Moments** | Welford online mean/var | Optional sample store |
| **API** | `Config` / `Result` / `Sample_1D` / `Run` | Seeded `Float_Random` |
| **Limits** | 1D primary; $D\le 4$; modest $L$ | No NUTS (Forthcoming) |

## Brief history

**Hybrid Monte Carlo** (Duane, Kennedy, Pendleton & Roweth, 1987) introduced
Hamiltonian dynamics into MCMC for lattice field theory. **Neal** (2011) and
later Bayesian literature popularized the name **Hamiltonian Monte Carlo** and
the modern leapfrog + Metropolis presentation. Compared with random-walk
Metropolis, HMC reduces random-walk behaviour by proposing coherent moves along
approximately energy-conserving trajectories, often yielding lower
autocorrelation for a given computational budget when $\nabla U$ is available.

### HMC vs random-walk Metropolis

- **Random-walk Metropolis** (see
  [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings)):
  propose $q'=q+\sigma Z$, $Z\sim\mathcal{N}(0,1)$. Local, isotropic
  exploration; acceptance drops as dimension grows unless $\sigma$ shrinks.
- **HMC**: introduce $p$, simulate Hamilton’s equations for fictitious time
  $L\varepsilon$, then Metropolis-correct discretization error. Proposals can
  travel $O(L\varepsilon)$ while keeping $\Delta H$ small for symplectic
  integrators, so acceptance stays high.

**NUTS** (No-U-Turn Sampler) — automatic trajectory length — is **Forthcoming**
in this series and is **not** implemented here.

## Method

### Hamiltonian and target

With unit mass matrix $M=I$,

$$
H(q,p)=U(q)+K(p)=U(q)+\tfrac{1}{2}p\cdot p.
$$

The joint density $\propto e^{-H}$ has $q$-marginal $\pi(q)\propto e^{-U(q)}$.
Each iteration:

1. Draw fresh $p\sim\mathcal{N}(0,I)$.
2. Leapfrog $(q,p)$ for $L$ steps of size $\varepsilon$ to $(q',p')$.
3. Negate $p'$ (time-reversal; $K$ even) and accept with

$$
\alpha=\min\bigl(1,\,e^{-(H(q',p')-H(q,p))}\bigr).
$$

### Leapfrog integrator

One leapfrog step of size $\varepsilon$:

$$
\begin{aligned}
p &\leftarrow p-\tfrac{\varepsilon}{2}\nabla U(q),\\
q &\leftarrow q+\varepsilon\,p,\\
p &\leftarrow p-\tfrac{\varepsilon}{2}\nabla U(q).
\end{aligned}
$$

Repeated $L$ times. Leapfrog is volume-preserving and reversible; for smooth
$U$ the Hamiltonian error is $O(\varepsilon^2)$ over fixed fictitious time,
which the Metropolis step corrects exactly (up to floating-point).

### Burn-in and moments

The first `Burn_In` proposals are discarded. Remaining positions update Welford
mean/variance. Optionally (`Keep_Samples`) store up to `Max_Store` post-burn-in
values. Acceptance rate $=N_{\mathrm{accepted}}/N_{\mathrm{proposed}}$ over
**all** proposals (including burn-in).

### Tuning (educational)

Rough heuristics for Gaussian targets: start with $\varepsilon\approx 0.1$,
$L\approx 10$, aim for acceptance often $\gtrsim 0.6$. Too large $\varepsilon$
makes $\Delta H$ large and acceptance collapse; too small wastes gradient
evaluations. This package does **not** adapt $\varepsilon$ or $L$.

## API summary

```ada
type Real is digits 15;
type Potential_1D is access function (Q : Real) return Real;
type Gradient_1D  is access function (Q : Real) return Real;

type Config is record
   N_Samples    : Positive       := 10_000;
   Burn_In      : Natural        := 1_000;
   Epsilon      : Positive_Real  := 0.1;
   L_Steps      : Leapfrog_Steps := 10;
   Seed         : Integer        := 42;
   Start        : Real           := 0.0;
   Keep_Samples : Boolean        := False;
end record;

type Result is record
   Mean, Variance : Real;
   Accept_Rate    : Unit_Fraction;
   N_Kept, N_Accepted, N_Proposed : Natural;
   Stored         : Store_Count;
   Samples        : Sample_Array (1 .. Max_Store);
end record;

function Sample_1D
  (U : Potential_1D; Grad_U : Gradient_1D; Cfg : Config := ...)
  return Result;
function Run
  (U : Potential_1D; Grad_U : Gradient_1D; Cfg : Config := ...)
  return Result;
--  Run renames Sample_1D

function Sample_ND
  (U : Potential_ND; Grad_U : Gradient_ND; Cfg : Config_ND)
  return Result_ND;
--  unit-mass HMC, D <= 4

function Kinetic_1D (P : Real) return Non_Negative;
function Kinetic_ND (P : Point) return Non_Negative;
function Hamiltonian_1D (U_Q, P : Real) return Real;
function Hamiltonian_ND (U_Q : Real; P : Point) return Real;
function Accept_Probability (Delta_H : Real) return Unit_Fraction;

procedure Leapfrog_Step_1D (Q, P : in out Real; Grad_U : Gradient_1D;
                            Epsilon : Positive_Real);
procedure Leapfrog_1D (Q, P : in out Real; Grad_U : Gradient_1D;
                       Epsilon : Positive_Real; L : Leapfrog_Steps);
--  analogous Leapfrog_Step_ND / Leapfrog_ND

--  Educational potentials: U_Std_Normal, Grad_U_Std_Normal,
--  U_Normal_Mu2, Grad_U_Normal_Mu2, U_Normal_Wide, Grad_U_Normal_Wide,
--  U_Iso_Normal_ND, Grad_U_Iso_Normal_ND
```

## Caveats / limits

- Educational only: 1D continuous primary; multi-D capped at $D\le 4$;
  `L_Steps` $\le$ `Max_L_Steps` ($=100$). No mass-matrix tuning, no
  dual averaging, **no NUTS** (marked **Forthcoming**).
- Requires a user-supplied **gradient** $\nabla U$; finite-difference
  gradients are not provided.
- Samples are **autocorrelated**; reported variance is the marginal sample
  variance, not an MCMC standard-error estimate (no ESS / batch means).
- Leapfrog + Metropolis assumes reasonably smooth $U$; discontinuous or
  very stiff potentials need smaller $\varepsilon$ (or better integrators).
- `Elementary_Functions` on `Float` underneath `Real` (digits 15) matches the
  sibling packages; not a high-precision numerics library.
- Not a drop-in replacement for Stan, PyMC, or production physics HMC codes.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Phybrid_monte_carlo.gpr
make test     # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `hybrid_monte_carlo.ads` | Package spec |
| `hybrid_monte_carlo.adb` | Package body |
| `hybrid_monte_carlo.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- Duane, S.; Kennedy, A. D.; Pendleton, B. J.; Roweth, D. (1987).
  “Hybrid Monte Carlo.” *Phys. Lett. B* **195** (2): 216–222.
- Neal, R. M. (2011). “MCMC Using Hamiltonian Dynamics.” In Brooks et al.,
  *Handbook of Markov Chain Monte Carlo*. Chapman & Hall/CRC.
- Betancourt, M. (2018). “A Conceptual Introduction to Hamiltonian Monte
  Carlo.” arXiv:1701.02434.
- [Wikipedia: Hamiltonian Monte Carlo](https://en.wikipedia.org/wiki/Hamiltonian_Monte_Carlo)
- Siblings: [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau),
  [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings);
  forthcoming [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling).
