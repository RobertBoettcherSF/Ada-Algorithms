# Gibbs Sampling — Ada 2023

Educational, self-contained Ada 2023 package implementing **Gibbs sampling**
(Geman & Geman 1984), also known in statistical physics as the **heat bath**
algorithm. When a joint density $\pi(x_1,\ldots,x_d)$ is hard to sample
directly but each **full conditional** $\pi(x_i\mid x_{-i})$ is tractable,
Gibbs cycles through the coordinates, drawing each from its conditional given
the current values of the others. The resulting Markov chain has stationary
distribution $\pi$.

Gibbs is a special case of **Metropolis–Hastings** in which the proposal is
exactly the full conditional, so the acceptance probability is identically
$\alpha=1$ (every proposal is kept).

Primary demo: **bivariate standard Normal** with known correlation $\rho$,
sampling each coordinate from its exact Normal conditional. Optional:
**Beta–Bernoulli** conjugate Bayesian toy (draw $p$ from its Beta full
conditional given fixed Bernoulli counts).

Based on [Wikipedia: Gibbs sampling](https://en.wikipedia.org/wiki/Gibbs_sampling).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (Monte Carlo survey series):

| Package | Role |
| --- | --- |
| [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau) | Flat-histogram density-of-states sampling |
| [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings) | MCMC / Metropolis–Hastings (random-walk) |
| [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo) | Hybrid / Hamiltonian Monte Carlo |
| [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling) | This package (Gibbs / heat bath) |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | MCMC via full conditionals | Heat bath; $\alpha\equiv 1$ |
| **Primary** | Bivariate $\mathcal{N}(0,\Sigma)$ | Exact Normal conditionals |
| **Correlation** | Config `Rho` $=\rho$ | $\|\rho\|<1$ required |
| **Update** | Cycle $X\mid Y$, then $Y\mid X$ | One sweep per step |
| **Burn-in** | Discard first `Burn_In` sweeps | Then track moments |
| **Moments** | Online mean / var / cov / corr | Optional sample store |
| **Optional** | Beta–Bernoulli conjugate | Sample $p\sim\mathrm{Beta}(\alpha',\beta')$ |
| **API** | `Config` / `Result` / `Sample_Bivariate_Normal` / `Run` | Seeded `Float_Random` |
| **Limits** | Educational bivariate + conjugate toy | Not general MRF / NUTS |

## Brief history

**Gibbs sampling** is named after Josiah Willard Gibbs by analogy with
statistical physics. The algorithm was described by Stuart and Donald
**Geman** (1984) for image restoration / Markov random fields and later became
a workhorse of Bayesian computation whenever full conditionals are available
(often via conjugacy). In physics the same coordinate-wise resampling is the
**heat bath** algorithm. Casella & George (1992) popularized the pedagogical
“explain-and-illustrate” view used in this package.

### Gibbs as Metropolis–Hastings with $\alpha=1$

If the MH proposal for coordinate $i$ is exactly the full conditional
$q(x_i'\mid x_{-i})=\pi(x_i'\mid x_{-i})$, the Hastings ratio collapses and

$$
\alpha=\min\bigl(1,1\bigr)=1.
$$

Thus every draw is accepted. This package’s bivariate Normal sampler is that
special case: proposals are exact conditionals, so there is no accept/reject
bookkeeping (contrast
[Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings)).

## Method

### Full conditionals for standard bivariate Normal

Let $(X,Y)$ be standard bivariate Normal with $\mathrm{Corr}(X,Y)=\rho$ and
unit marginal variances. Then

$$
\begin{aligned}
X\mid Y=y &\sim \mathcal{N}(\rho\, y,\, 1-\rho^2),\\
Y\mid X=x &\sim \mathcal{N}(\rho\, x,\, 1-\rho^2).
\end{aligned}
$$

Helpers `Conditional_Mean`, `Conditional_Variance`, and `Conditional_Std_Dev`
expose $\rho\cdot(\cdot)$ and $1-\rho^2$.

### One Gibbs sweep

Starting from $(x_0,y_0)$ and seeded RNG:

1. Draw $x_{t}\sim\mathcal{N}(\rho\, y_{t-1},\, 1-\rho^2)$.
2. Draw $y_{t}\sim\mathcal{N}(\rho\, x_{t},\, 1-\rho^2)$.

Repeat for `Steps` sweeps; discard the first `Burn_In`. Remaining pairs update
online means, variances, covariance, and sample correlation
$\widehat{\rho}=\widehat{\mathrm{Cov}}/\sqrt{\widehat{\mathrm{Var}}_X\widehat{\mathrm{Var}}_Y}$.

### Beta–Bernoulli conjugate toy

Prior $p\sim\mathrm{Beta}(\alpha,\beta)$ and $s$ successes in $n$ Bernoulli
trials yield the full conditional (posterior)

$$
p\mid\mathrm{data}\sim\mathrm{Beta}(\alpha+s,\,\beta+n-s).
$$

With fixed data each “sweep” is an i.i.d. draw from that Beta (Gamma-ratio
sampler). The chain mean recovers $(\alpha+s)/(\alpha+\beta+n)$. This
illustrates conjugate full conditionals without needing a second free
parameter.

### Burn-in and autocorrelation

As with other MCMC methods, early samples may not represent the stationary
distribution and successive draws are dependent. This educational code reports
marginal sample moments only (no ESS / batch-means SE). Prefer longer
`Burn_In` and more `Steps` when $\|\rho\|$ is large (slower mixing).

## API summary

```ada
type Real is digits 15;

type Config is record
   Steps        : Positive              := 10_000;
   Burn_In      : Natural               := 1_000;
   Seed         : Integer               := 42;
   Rho          : Open_Unit_Correlation := 0.5;
   Start_X      : Real                  := 0.0;
   Start_Y      : Real                  := 0.0;
   Keep_Samples : Boolean               := False;
end record;

type Result is record
   Mean_X, Mean_Y : Real;
   Var_X, Var_Y   : Real;
   Cov_XY         : Real;
   Correlation    : Real;
   N_Kept         : Natural;
   Stored         : Store_Count;
   Samples_X, Samples_Y : Sample_Array (1 .. Max_Store);
end record;

function Conditional_Mean (Rho, Other : Real) return Real;
function Conditional_Variance (Rho : Real) return Non_Negative;
function Conditional_Std_Dev (Rho : Real) return Non_Negative;
function Valid_Correlation (Rho : Real) return Boolean;

function Sample_Bivariate_Normal (Cfg : Config := ...) return Result;
function Run (Cfg : Config := ...) return Result;  -- renames Sample_Bivariate_Normal

--  Optional conjugate toy:
function Posterior_Alpha (Alpha : Positive_Real; Successes : Natural)
  return Positive_Real;
function Posterior_Beta
  (Beta_P : Positive_Real; Successes, Trials : Natural) return Positive_Real;
function Posterior_Mean
  (Alpha, Beta_P : Positive_Real; Successes, Trials : Natural)
  return Unit_Fraction;
function Sample_Beta_Bernoulli (Cfg : Beta_Bernoulli_Config := ...)
  return Beta_Bernoulli_Result;
```

## Caveats / limits

- Educational only: primary target is **bivariate** Normal with known $\rho$;
  no general graphical models, blocked / collapsed Gibbs, or slice-within-Gibbs.
- Samples are **autocorrelated**; reported variances / correlation are sample
  moments, not MCMC standard errors (no ESS).
- Requires $\|\rho\|<1$ (`Valid_Correlation`); near-unit correlation mixes
  slowly — increase `Steps` / `Burn_In`.
- Beta sampler uses Marsaglia–Tsang Gamma + ratio; fine for demos, not a
  high-precision special-function library.
- `Elementary_Functions` on `Float` underneath `Real` (digits 15) matches the
  sibling packages.
- Not a drop-in replacement for Stan, PyMC, JAGS, or production MRF codes.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pgibbs_sampling.gpr
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
| `gibbs_sampling.ads` | Package spec |
| `gibbs_sampling.adb` | Package body |
| `gibbs_sampling.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- Geman, S.; Geman, D. (1984). “Stochastic Relaxation, Gibbs Distributions,
  and the Bayesian Restoration of Images.” *IEEE Trans. PAMI* **6** (6):
  721–741.
- Casella, G.; George, E. I. (1992). “Explaining the Gibbs Sampler.”
  *The American Statistician* **46** (3): 167–174.
- [Wikipedia: Gibbs sampling](https://en.wikipedia.org/wiki/Gibbs_sampling)
- Siblings:
  [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings),
  [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo),
  [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau).
