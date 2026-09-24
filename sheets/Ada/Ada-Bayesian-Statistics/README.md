# Bayesian Statistics — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Bayesian statistics](https://en.wikipedia.org/wiki/Bayesian_statistics):
probability as a **degree of belief**, **Bayes' theorem** event updates,
**conjugate priors** (Beta–Bernoulli / Binomial and Normal with known
variance), **MAP** / posterior mean estimators, equal-tailed **credible
intervals**, and simple discrete **evidence** / **Bayes factors**.

Bayesian analysis encodes prior knowledge as a prior distribution over
parameters, then updates that belief with data via Bayes' theorem to obtain
a **posterior**. Point summaries include the posterior mean and the
**maximum a posteriori** (MAP) mode; uncertainty is reported with credible
intervals (probability statements about parameters given the data), which
differ philosophically from frequentist confidence intervals.

This package is an **umbrella / survey** of closed-form textbook cases.
For numerical approximation of the marginal likelihood (evidence) in
higher dimensions see sibling **Ada-Nested-Sampling** (Skilling nested
sampling); related estimation / filtering siblings include
**Ada-Estimation-Theory** and **Ada-Kalman-Filter**. Those repos are
mentioned only — **not** dependencies of this repository.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Bayesian vs frequentist (brief)

| | Bayesian | Frequentist |
| --- | --- | --- |
| Probability | Degree of belief (may use priors) | Long-run relative frequency |
| Parameters | Random (with prior / posterior) | Fixed unknowns |
| Interval | Credible: $P(\theta\in I\mid D)$ | Confidence: coverage over repeated samples |
| Evidence | Marginal $Z=P(D)$; Bayes factors | $p$-values, likelihood ratios (different meaning) |

Thomas **Bayes** (c. 1763) and Pierre-Simon **Laplace** developed the
inversion of conditional probability that underpins modern Bayesian
inference. Wikipedia and standard texts (Gelman *et al.*, *Bayesian Data
Analysis*; Lee, *Bayesian Statistics*) survey the paradigm, conjugates,
and computational methods (MCMC, nested sampling, variational inference).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Events** | $P(A\mid B)=P(B\mid A)P(A)/P(B)$ | Complement form for disease tests |
| **Beta–Bernoulli** | $\mathrm{Beta}(\alpha+s,\beta+n-s)$ | Mean, MAP, variance, PDF |
| **Credible interval** | Equal-tailed Beta quantiles | Inverse regularized incomplete beta |
| **Normal conjugate** | Known $\sigma^2$; precision add | Posterior mean shrinks toward prior |
| **Evidence** | $Z=\sum P(D\mid H_i)P(H_i)$ | Discrete hypotheses |
| **Bayes factor** | $\mathrm{BF}_{12}=P(D\mid H_1)/P(D\mid H_2)$ | Model comparison |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Helpers | `Near`, `Safe_Log`, `Log_Sum` | Numerics |
| RNG | `Seed_RNG`, `Next_Unit` | Seeded LCG (optional MC) |
| Events | `Posterior_Prob`, `Posterior_Prob_Complement`, `Evidence_From_Complement` | Bayes' theorem |
| Beta | `Beta_Params`, `Beta_Update`, `Beta_Mean`, `Beta_Mode`, `Beta_Variance`, `Beta_PDF`, `Beta_Log_PDF` | Conjugate Bernoulli / Binomial |
| Incomplete beta | `Regularized_Incomplete_Beta`, `Beta_Quantile` | CDF / inverse CDF |
| Intervals | `Equal_Tailed_Credible_Interval`, `Contains` | Credible intervals |
| Normal | `Normal_Params`, `Normal_Conjugate_Update`, `Normal_PDF` | Known-variance conjugate |
| Evidence | `Discrete_Evidence`, `Bayes_Factor`, `Posterior_Odds` | Model comparison |

Strong typing uses domain types (`Real` digits 12, `Unit_Interval`,
`Beta_Params`, `Normal_Params`, …). Public subprograms carry `Pre` /
`Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Formula summary

### Bayes' theorem (events)

$$
P(A\mid B)=\frac{P(B\mid A)\,P(A)}{P(B)}
=\frac{P(B\mid A)\,P(A)}{P(B\mid A)\,P(A)+P(B\mid\neg A)\,P(\neg A)}
$$

Classroom **disease / false-positive** numbers used in tests:
$P(D)=0.001$, $P(+|D)=0.99$, $P(+|\neg D)=0.05$ give
$P(D|+)\approx 0.0194$ — a base-rate reminder that a positive test need
not imply high posterior disease probability.

### Beta–Bernoulli conjugate

Prior $\theta\sim\mathrm{Beta}(\alpha,\beta)$; observe $s$ successes in
$n$ Bernoulli trials:

$$
\theta\mid D\sim\mathrm{Beta}(\alpha+s,\,\beta+n-s)
$$

Posterior mean $\alpha'/(\alpha'+\beta')$; MAP (mode)
$(\alpha'-1)/(\alpha'+\beta'-2)$ when $\alpha',\beta'>1$.

Equal-tailed level-$L$ credible interval: Beta quantiles at
$(1-L)/2$ and $1-(1-L)/2$, obtained by bisection on the regularized
incomplete beta $I_x(\alpha,\beta)$.

### Normal conjugate (known variance)

Prior $\mu\sim\mathcal{N}(\mu_0,\tau_0^2)$, observations with known
$\sigma^2$ and sample mean $\bar x$ of size $n$:

$$
\frac{1}{\tau_n^2}=\frac{1}{\tau_0^2}+\frac{n}{\sigma^2},\qquad
\mu_n=\tau_n^2\Bigl(\frac{\mu_0}{\tau_0^2}+\frac{n\bar x}{\sigma^2}\Bigr)
$$

The posterior mean **shrinks** $\bar x$ toward $\mu_0$.

### Evidence and Bayes factors

For discrete hypotheses,

$$
Z=P(D)=\sum_i P(D\mid H_i)\,P(H_i),\qquad
\mathrm{BF}_{12}=\frac{P(D\mid H_1)}{P(D\mid H_2)}
$$

Posterior odds $=$ prior odds $\times\mathrm{BF}_{12}$. Continuous-model
evidence integrals are the domain of MCMC / **nested sampling** (see
Ada-Nested-Sampling).

## Credible intervals vs confidence intervals

A Bayesian **credible interval** $I$ satisfies $P(\theta\in I\mid D)=L$
under the posterior. A frequentist **confidence interval** procedure
guarantees long-run coverage over repeated samples; it is not, in
general, a posterior probability statement about $\theta$ given the
observed data. Both are useful; they answer different questions.

## Approximation siblings (not dependencies)

Closed conjugates cover many textbook models. When the posterior or
evidence lacks a closed form, standard approximations include Markov
chain Monte Carlo (MCMC), Laplace approximations, variational inference,
and **nested sampling** for $Z=P(D)$. This survey stays analytic /
numerical-special-function based and does **not** depend on
Ada-Nested-Sampling.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pbayesian_statistics.gpr`. Main
program is `tests.adb` (no `main.adb`). Artifacts land in `obj/` and
`bin/` (ignored by git).

## Public API (package `Bayesian_Statistics`)

- **Events:** `Is_Valid_Probability`, `Posterior_Prob`,
  `Posterior_Prob_Complement`, `Evidence_From_Complement`
- **Beta–Bernoulli:** `Beta_Params`, `Beta_Update`, `Beta_Mean`,
  `Beta_Mode`, `Beta_Variance`, `Beta_PDF`, `Beta_Log_PDF`,
  `Regularized_Incomplete_Beta`, `Beta_Quantile`,
  `Equal_Tailed_Credible_Interval`, `Contains`
- **Normal:** `Normal_Params`, `Normal_Conjugate_Update`, `Normal_PDF`
- **Evidence:** `Discrete_Evidence`, `Bayes_Factor`, `Posterior_Odds`
- **Utilities:** `Near`, `Safe_Log`, `Log_Sum`, `Seed_RNG`, `Next_Unit`

## Layout

| File | Role |
| --- | --- |
| `bayesian_statistics.ads` | Package specification |
| `bayesian_statistics.adb` | Package body |
| `bayesian_statistics.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom `Check` suite (no `Ada.Assertions`) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## References

- [Wikipedia: Bayesian statistics](https://en.wikipedia.org/wiki/Bayesian_statistics)
- [Wikipedia: Bayes' theorem](https://en.wikipedia.org/wiki/Bayes%27_theorem)
- [Wikipedia: Conjugate prior](https://en.wikipedia.org/wiki/Conjugate_prior)
- [Wikipedia: Credible interval](https://en.wikipedia.org/wiki/Credible_interval)
- [Wikipedia: Bayes factor](https://en.wikipedia.org/wiki/Bayes_factor)
- Gelman, Carlin, Stern, Dunson, Vehtari, Rubin — *Bayesian Data Analysis*
- Nested sampling sibling: Ada-Nested-Sampling (RobertBoettcherSF series)
