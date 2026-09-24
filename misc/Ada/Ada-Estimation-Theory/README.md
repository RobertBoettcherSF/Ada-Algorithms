# Estimation Theory — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Estimation theory](https://en.wikipedia.org/wiki/Estimation_theory):
point estimators (sample mean / variance), **method of moments**,
**maximum-likelihood** estimators for classic models, **bias / variance / MSE**,
and **Cramér–Rao lower bound** (CRLB) worked examples — including the Wikipedia
**AWGN constant-in-noise** derivation and the **Uniform[0,θ]** sample-maximum
classroom example (related to the German tank problem).

Estimation theory studies how to recover unknown parameters $\theta$ from
noisy measurements $x$ whose distribution $p(x\mid\theta)$ depends on
$\theta$. An *estimator* $\hat\theta(x)$ maps samples to parameter space;
quality is judged by bias, variance, mean squared error (MSE), and whether the
estimator attains the CRLB (efficiency).

This package is an **umbrella / survey** of closed-form textbook cases. For
iterative incomplete-data MLE see **Ada-Expectation-Maximization**; for
Fisher-scoring / Newton–Raphson MLE iterations see **Ada-Scoring-Algorithm**
(related siblings mentioned only — **not** dependencies of this repo).

Classic references: **Steven M. Kay**, *Fundamentals of Statistical Signal
Processing: Estimation Theory* (1993); Lehmann & Casella, *Theory of Point
Estimation*.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Sample stats** | Mean, Variance (1/N and 1/(N−1)) | Basics / Estimators |
| **MoM** | Exp rate; Uniform[0, θ] with 2x̄ | Match first moment |
| **MLE** | Gaussian μ / σ², Bernoulli p, Uniform max, AWGN | Closed forms |
| **Error metrics** | Bias, Var, MSE; MSE = Bias² + Var | Monte Carlo helpers |
| **CRLB** | Gaussian mean I = N/σ²; Bernoulli I = N / (p(1−p)) | Efficiency checks |
| **AWGN** | Â = x̄ attains σ² / N | Wikipedia worked example |
| **Uniform max** | θ̂_MLE = max xᵢ (biased low) | ≠ MoM; Bias: −θ / (N+1) |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_N`, `Sample` | Fixed educational limits |
| Helpers | `Near`, `Sample_Maximum`, `Sample_Minimum` | Numerics / order stats |
| Stats | `Mean`, `Variance` | Population & unbiased |
| Errors | `Bias`, `MSE`, `Variance_Of_Estimator`, `MSE_From_Bias_Var` | Bias²+Var identity |
| MoM | `MoM_Exponential_Rate`, `MoM_Uniform_Theta` | Moment matching |
| MLE | `MLE_Gaussian_Mean`, `MLE_Gaussian_Variance`, `MLE_Bernoulli_P`, `MLE_Uniform_Theta`, `MLE_AWGN_Constant`, `MLE_Exponential_Rate` | Classic MLEs |
| CRLB | `Fisher_Info_Gaussian_Mean`, `CRLB_Gaussian_Mean`, `Fisher_Info_Bernoulli`, `CRLB_Bernoulli`, analytic vars / Uniform bias | Bound examples |

Strong typing uses domain types (`Real` digits 12, `Sample`, …). Public
subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`.

## Formula summary

### Sample mean and variance

$$
\bar x=\frac1N\sum_{i=1}^N x_i,\qquad
\hat\sigma^2_{\mathrm{MLE}}=\frac1N\sum_i(x_i-\bar x)^2,\qquad
s^2=\frac1{N-1}\sum_i(x_i-\bar x)^2.
$$

### AWGN constant-in-noise (Wikipedia)

Model $x[n]=A+w[n]$, $w[n]\sim\mathcal N(0,\sigma^2)$ i.i.d. The MLE is
the sample mean $\hat A=\bar x$, with

$$
\mathrm{Var}(\hat A)=\frac{\sigma^2}{N},\qquad
\mathcal I(A)=\frac{N}{\sigma^2},\qquad
\mathrm{CRLB}=\frac1{\mathcal I}=\frac{\sigma^2}{N}.
$$

The sample mean **attains** the CRLB for all $N$ and $A$ (efficient / MVUE).

### Uniform$[0,\theta]$

$$
\hat\theta_{\mathrm{MoM}}=2\bar x,\qquad
\hat\theta_{\mathrm{MLE}}=\max_i x_i,\qquad
\mathbb E[\max]=\frac{N\theta}{N+1},\qquad
\mathrm{Bias}(\hat\theta_{\mathrm{MLE}})=-\frac{\theta}{N+1}.
$$

MLE ≠ MoM; the maximum is biased low (Wikipedia classroom example).

### Bernoulli / Gaussian CRLB

$$
\mathcal I(p)=\frac{N}{p(1-p)},\quad
\mathrm{Var}(\hat p)=\frac{p(1-p)}{N}
\quad\text{(attains bound)};
\qquad
\mathcal I(\mu)=\frac{N}{\sigma^2},\quad
\mathrm{Var}(\bar x)=\frac{\sigma^2}{N}.
$$

### MSE identity

$$
\mathrm{MSE}(\hat\theta)=\mathrm{Bias}^2(\hat\theta)+\mathrm{Var}(\hat\theta).
$$

## Usage

```ada
with Estimation_Theory; use Estimation_Theory;

procedure Demo is
   X : constant Sample := [1.0, 2.0, 3.0, 4.0];
   Mu : Real;
   Theta_Mle, Theta_Mom : Real;
   Bound : Real;
begin
   Mu := Mean (X);
   Theta_Mle := MLE_Uniform_Theta (X);   -- = 4.0
   Theta_Mom := MoM_Uniform_Theta (X);   -- = 5.0
   Bound := CRLB_Gaussian_Mean (N => 100, Sigma2 => 4.0);  -- 0.04
end Demo;
```

## Building

```bash
cd /workspace/ada-estimation-theory
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pestimation_theory.gpr`. Expect **zero**
errors and **zero** warnings.

## Testing

```bash
make test
```

Runs `bin/tests` (17 sections, 100+ assertions). Exit status 0 and
`Fail_Count = 0` (`pragma Assert`).

## Layout

```
ada-estimation-theory/
├── estimation_theory.ads   # public API
├── estimation_theory.adb   # implementation
├── estimation_theory.gpr
├── tests.adb               # main test program
├── Makefile
├── README.md
└── .gitignore
```

Root-only layout (no `src/`, no separate `main.adb`).

## References

1. [Wikipedia: Estimation theory](https://en.wikipedia.org/wiki/Estimation_theory)
   — Basics, Estimators, AWGN / MLE / CRLB, Uniform maximum.
2. Steven M. Kay, *Fundamentals of Statistical Signal Processing: Estimation
   Theory*, Prentice-Hall, 1993. ISBN 0-13-345711-7.
3. E. L. Lehmann & G. Casella, *Theory of Point Estimation*, Springer, 1998.
4. [Wikipedia: Cramér–Rao bound](https://en.wikipedia.org/wiki/Cram%C3%A9r%E2%80%93Rao_bound).
5. [Wikipedia: German tank problem](https://en.wikipedia.org/wiki/German_tank_problem)
   (Uniform maximum / UMVU).

## Related packages

- **Ada-Expectation-Maximization** — iterative EM for latent-variable MLE
  (Bernoulli mixture, univariate GMM).
- **Ada-Scoring-Algorithm** — Fisher scoring / iterative MLE updates.

These are deeper treatments of topics surveyed here; they are **not** build
dependencies of this repository.
