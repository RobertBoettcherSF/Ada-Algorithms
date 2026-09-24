# Metropolis–Hastings — Ada 2023

Educational, self-contained Ada 2023 package implementing the
**Metropolis–Hastings** Markov chain Monte Carlo (MCMC) algorithm
(Metropolis et al. 1953; Hastings 1970). Given an unnormalized target density
$\pi$ (via $\log\pi$), the chain proposes candidates from a jumping distribution
$q$ and accepts them with probability

$$
\alpha=\min\bigl(1,\,e^{\log\pi(x')-\log\pi(x)}\cdot\tfrac{q(x\mid x')}{q(x'\mid x)}\bigr).
$$

Primary demo: **1D symmetric Gaussian random-walk Metropolis** (Hastings ratio
$=1$), with burn-in, acceptance-rate tracking, and Welford mean/variance.
Also: independent MH (asymmetric $q$), isotropic RW-MH in $D\le 4$, and tiny
discrete **Bernoulli** / **1D Ising** toys.

Based on [Wikipedia: Metropolis–Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (Monte Carlo survey series):

| Package | Role |
| --- | --- |
| [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER) | Recursive stratified Monte Carlo integration |
| [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau) | Flat-histogram density-of-states sampling |
| [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings) | This package (MCMC / Metropolis–Hastings) |
| [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling) | Forthcoming — Gibbs sampling |
| [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo) | Forthcoming — Hybrid / Hamiltonian MC |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | MCMC with accept/reject | Approximate $\pi$ by a Markov chain |
| **Target** | $\log\pi$ access-to-function | Unnormalized density OK |
| **Metropolis** | Symmetric $q$ (Gaussian RW) | Hastings ratio cancels |
| **Hastings** | General $q$-ratio | Independent MH demo |
| **Accept** | $\alpha=\min(1,\exp(\cdot))$ | Track acceptance rate |
| **Moments** | Welford online mean/var | Optional sample store |
| **Discrete** | Bernoulli flip / 1D Ising | Tiny educational toys |
| **API** | `Config` / `Result` / `Sample_1D` / `Run` | Seeded `Float_Random` |
| **Limits** | 1D primary; $D\le 4$ optional | Not production HMC/NUTS |

## Brief history

The **Metropolis algorithm** (Metropolis, Rosenbluth, Rosenbluth, Teller &
Teller, 1953) constructed a Markov chain with a prescribed Boltzmann
stationary distribution using a **symmetric** proposal. **Hastings** (1970)
extended the acceptance probability to **asymmetric** proposals via the
ratio $q(x\mid x')/q(x'\mid x)$. Together they are the workhorse of Bayesian
computation and statistical physics when direct i.i.d. sampling from $\pi$ is
intractable. The chain is autocorrelated; burn-in and effective sample size
matter in practice.

### Metropolis vs Metropolis–Hastings

- **Metropolis** (1953): proposal $q$ is **symmetric**,
  $q(x'\mid x)=q(x\mid x')$. Then
  $$
  \alpha=\min\bigl(1,\tfrac{\pi(x')}{\pi(x)}\bigr)
  =\min\bigl(1,\,e^{\log\pi(x')-\log\pi(x)}\bigr).
  $$
- **Metropolis–Hastings** (Hastings 1970): $q$ may be asymmetric; multiply by
  the Hastings correction $q(x\mid x')/q(x'\mid x)$.

This package’s `Sample_1D` is classical random-walk **Metropolis** (Gaussian
$q$). `Sample_1D_Independent` is full **Metropolis–Hastings** with an
independent proposal density supplied as $\log q$.

## Method

### Detailed balance

A sufficient condition for stationary distribution $\pi$ is **detailed
balance**:

$$
\pi(x)\,P(x\to x')=\pi(x')\,P(x'\to x).
$$

Factor the transition as proposal times acceptance,
$P(x\to x')=q(x'\mid x)\,A(x\to x')$. The Metropolis choice

$$
A(x\to x')=\min\Bigl(1,\,
\frac{\pi(x')\,q(x\mid x')}{\pi(x)\,q(x'\mid x)}\Bigr)
$$

satisfies detailed balance (when $\pi(x)q(x'\mid x)>0$). In log space this
package evaluates

$$
\log\alpha=\log\pi(x')-\log\pi(x)+\log q(x\mid x')-\log q(x'\mid x)
$$

and accepts if $u\sim\mathrm{Unif}(0,1)$ satisfies $u\le\min(1,e^{\log\alpha})$.

### Symmetric Gaussian random walk

Propose $x'=x+\sigma Z$ with $Z\sim\mathcal{N}(0,1)$. Then $q$ is symmetric and
the Hastings terms vanish. Tune $\sigma$ so the acceptance rate is moderate
(roughly $0.2$–$0.5$ in 1D Gaussian targets is a common heuristic).

### Independent Metropolis–Hastings

Propose $x'\sim q(\cdot)$ independent of the current state. Then
$\log q(x\mid x')-\log q(x'\mid x)=\log q(x)-\log q(x')$. The caller’s
`Log_Q` must match the actual proposal used (`Cfg.Start` = proposal mean,
`Cfg.Proposal_Sigma` = proposal std-dev when using the built-in Gaussian
drawer).

### Burn-in and moments

The first `Burn_In` steps are discarded. Remaining draws update Welford
mean/variance. Optionally (`Keep_Samples`) store up to `Max_Store` post-burn-in
values. Acceptance rate $=N_{\mathrm{accepted}}/N_{\mathrm{proposed}}$ over
**all** steps (including burn-in).

### Discrete toys

- **Bernoulli($p$)**: state $\{0,1\}$, flip proposal (symmetric Metropolis);
  chain mean $\approx p$.
- **1D Ising**: $N\le 8$ spins $\pm 1$, $E=-\sum_i s_i s_{i+1}$, single-spin
  flips with $\alpha=\min(1,e^{-\beta\Delta E})$.

## API summary

```ada
type Real is digits 15;
type Log_Target_1D is access function (X : Real) return Real;

type Config is record
   Steps          : Positive      := 10_000;
   Burn_In        : Natural       := 1_000;
   Proposal_Sigma : Positive_Real := 1.0;
   Seed           : Integer       := 42;
   Start          : Real          := 0.0;
   Keep_Samples   : Boolean       := False;
end record;

type Result is record
   Mean, Variance : Real;
   Accept_Rate    : Unit_Fraction;
   N_Kept, N_Accepted, N_Proposed : Natural;
   Stored         : Store_Count;
   Samples        : Sample_Array (1 .. Max_Store);
end record;

function Sample_1D (Log_Pi : Log_Target_1D; Cfg : Config := ...) return Result;
function Run       (Log_Pi : Log_Target_1D; Cfg : Config := ...) return Result;
--  Run renames Sample_1D

function Sample_1D_Independent
  (Log_Pi : Log_Target_1D; Log_Q : Log_Density_1D; Cfg : Config := ...)
  return Result;

function Sample_ND (Log_Pi : Log_Target_ND; Cfg : Config_ND) return Result_ND;
--  isotropic Gaussian RW-MH, D <= 4

function Sample_Bernoulli (P : Unit_Fraction; Cfg : Config := ...) return Result;
function Sample_Ising_1D (N : Positive; Beta : Non_Negative; ...) return Ising_Result;

function Accept_Probability (Log_Alpha : Real) return Unit_Fraction;
function Log_Hastings_Ratio
  (Log_Pi_Current, Log_Pi_Prop : Real; Log_Q_Ratio : Real := 0.0) return Real;

--  Educational targets: Target_Std_Normal, Target_Normal_Mu2,
--  Target_Normal_Wide, Target_Bimodal, Target_Iso_Normal_ND, ...
```

## Caveats / limits

- Educational only: 1D continuous primary; multi-D capped at $D\le 4$; Ising
  $N\le 8$. No adaptation, no NUTS/HMC, no parallel tempering.
- Samples are **autocorrelated**; reported variance is the marginal sample
  variance, not an MCMC standard-error estimate (no ESS / batch means).
- Independent MH requires `Log_Q` to match the proposal actually drawn
  (`Start`, `Proposal_Sigma` for the built-in Gaussian proposer).
- `Elementary_Functions` on `Float` underneath `Real` (digits 15) matches the
  sibling packages; not a high-precision numerics library.
- Not a drop-in replacement for Stan, PyMC, or production physics MCMC codes.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pmetropolis_hastings.gpr
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
| `metropolis_hastings.ads` | Package spec |
| `metropolis_hastings.adb` | Package body |
| `metropolis_hastings.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- Metropolis, N.; Rosenbluth, A. W.; Rosenbluth, M. N.; Teller, A. H.;
  Teller, E. (1953). “Equation of State Calculations by Fast Computing
  Machines.” *J. Chem. Phys.* **21** (6): 1087–1092.
- Hastings, W. K. (1970). “Monte Carlo Sampling Methods Using Markov Chains
  and Their Applications.” *Biometrika* **57** (1): 97–109.
- [Wikipedia: Metropolis–Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm)
- Siblings: [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER),
  [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau);
  forthcoming [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling),
  [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo).
