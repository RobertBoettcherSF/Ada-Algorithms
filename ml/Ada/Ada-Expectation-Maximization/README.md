# Expectation–Maximization (EM) Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Expectation–maximization algorithm](https://en.wikipedia.org/wiki/Expectation%E2%80%93maximization_algorithm)
(**EM**) — an iterative method for (local) **maximum likelihood** (or MAP)
estimation in statistical models that depend on unobserved **latent
variables**.

The classic reference is **Dempster, Laird & Rubin (1977)**:

> A. P. Dempster, N. M. Laird, and D. B. Rubin, “Maximum Likelihood from
> Incomplete Data via the EM Algorithm,” *Journal of the Royal Statistical
> Society, Series B*, vol. 39, no. 1, pp. 1–38, 1977.
> doi:[10.1111/j.2517-6161.1977.tb01600.x](https://doi.org/10.1111/j.2517-6161.1977.tb01600.x)

Each iteration alternates:

1. **E-step** — compute responsibilities / expected complete-data sufficient
   statistics given current parameters $\theta^{(t)}$ (i.e. form
   $Q(\theta\mid\theta^{(t)})$).
2. **M-step** — maximize $Q$ to obtain $\theta^{(t+1)}$.

Iterate until $|\ell(\theta^{(t+1)})-\ell(\theta^{(t)})| < \mathrm{Tol}$.
The observed-data log-likelihood is **monotone nondecreasing**.

This package provides the generic EM structure plus two concrete educational
examples: a **Bernoulli / two-coin latent mixture** and a **univariate
Gaussian mixture model (GMM)** (the Wikipedia Gaussian-mixture worked
example, specialized to $d=1$).

Related specialized EM siblings (mentioned only; **not** dependencies of this
repo): **Ada-Baum-Welch** (HMM forward–backward EM) and
**Ada-Ordered-Subset-EM** (Hudson–Larkin OSEM for emission tomography).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **E-step** | Responsibilities $\gamma_{ik}$ via Bayes | Log-domain / log-sum-exp |
| **M-step** | Closed-form weighted MLEs | Mixture exponential families |
| **Bernoulli mix** | Latent coin / Bern($p_k$) mixture | Classic textbook two-coin |
| **Univariate GMM** | $\theta=\{\pi_k,\mu_k,\sigma^2_k\}$ | Wikipedia GMM, $d=1$ |
| **Stopping** | $\|\Delta\ell\|<\mathrm{Tol}$ | Optional `Did_Not_Converge` |
| **Stability** | Log-sum-exp; $\sigma^2\ge\varepsilon$ | Avoid singular components |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_N`, `Max_K` | Fixed educational limits |
| Helpers | `Near`, `Log`, `Exp`, `Gaussian_Pdf`, `Log_Sum_Exp`, `Clamp_Prob`, `Normalize_Weights` | Numerics |
| Bernoulli | `Bernoulli_Mixture`, `Bernoulli_E_Step`, `Bernoulli_M_Step`, `Bernoulli_EM_Fit`, `Bernoulli_Log_Likelihood` | Two-coin / Bern mix |
| GMM | `GMM_Params`, `GMM_E_Step`, `GMM_M_Step`, `GMM_EM_Fit`, `GMM_Log_Likelihood` | Univariate mixture |
| Init | `Random_Init_GMM`, `Make_Equal_Bernoulli`, `Make_GMM` | Starts / constructors |
| Result | `Fit_Result` (Params, Iterations, Log_Likelihood, Converged) | Discriminated by model |

Strong typing uses domain types (`Real` digits 12, `Sample`,
`Responsibility_Matrix`, …). Public subprograms carry `Pre` / `Post` /
`Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Degenerate_Geometry`,
`Capacity_Exceeded`, `Did_Not_Converge`.

## Formula summary

### Generic EM (Dempster–Laird–Rubin)

$$
Q(\theta\mid\theta^{(t)})
=
\mathbb{E}_{Z\sim p(\cdot\mid X,\theta^{(t)})}
\bigl[\log p(X,Z\mid\theta)\bigr],
\qquad
\theta^{(t+1)}
=
\arg\max_\theta Q(\theta\mid\theta^{(t)}).
$$

### Bernoulli mixture

Observations $x_i\in\{0,1\}$, latent component $Z_i\in\{1..K\}$,
$P(Z_i=k)=\pi_k$, $X_i\mid Z_i=k\sim\mathrm{Bern}(p_k)$:

$$
\gamma_{ik}
\propto
\pi_k\, p_k^{x_i}(1-p_k)^{1-x_i},
\quad
\pi_k\leftarrow\frac{N_k}{N},
\quad
p_k\leftarrow\frac{\sum_i\gamma_{ik}x_i}{N_k},
\quad
N_k=\sum_i\gamma_{ik}.
$$

### Univariate GMM

$$
\gamma_{ik}
=
\frac{\pi_k\,\mathcal{N}(x_i\mid\mu_k,\sigma_k^2)}
{\sum_j\pi_j\,\mathcal{N}(x_i\mid\mu_j,\sigma_j^2)},
$$

$$
N_k=\sum_i\gamma_{ik},
\quad
\pi_k=\frac{N_k}{N},
\quad
\mu_k=\frac{\sum_i\gamma_{ik}x_i}{N_k},
\quad
\sigma_k^2
=
\frac{\sum_i\gamma_{ik}(x_i-\mu_k)^2}{N_k}
\;(\ge\varepsilon).
$$

Log-sum-exp is used for stable evaluation of $\log\sum_k\exp(\cdot)$.

## Properties

- Each full EM iteration does **not decrease** the observed-data
  log-likelihood $\ell(\theta)=\log p(X\mid\theta)$.
- Convergence is typically to a **local** maximum (or saddle); multiple
  random restarts help.
- Singularities (e.g. a GMM component collapsing onto one point with
  $\sigma^2\to 0$) are mitigated by clamping $\sigma^2\ge\varepsilon$.

## Usage

```ada
with Expectation_Maximization; use Expectation_Maximization;

--  Univariate GMM
declare
   Data : constant Sample := [-2.0, -1.5, 4.0, 4.5, 5.0];
   Init : constant GMM_Params := Random_Init_GMM (Data, K => 2, Seed => 1);
   Fit  : constant Fit_Result :=
     GMM_EM_Fit (Data, Init, Max_Iter => 100, Tol => 1.0E-8);
begin
   pragma Assert (Fit.Kind = GMM_Model);
   --  Fit.GMM.Mu (k), Fit.GMM.Sigma2 (k), Fit.Converged, ...
end;

--  Bernoulli / two-coin mixture
declare
   Heads : constant Sample := [2.0, 8.0, 1.0, 9.0, 3.0];  -- out of 10 flips
   Init  : constant Bernoulli_Mixture :=
     Make_Equal_Bernoulli (2, 0.4, 0.6);
   Fit   : constant Fit_Result :=
     Bernoulli_EM_Fit (Heads, Init, Trials => 10);
begin
   pragma Assert (Fit.Kind = Bernoulli_Model);
end;
```

## Building

```bash
cd /workspace/ada-expectation-maximization
make clean && make
```

Uses `gnatmake -gnatwa -gnat2022 -Pexpectation_maximization.gpr`.
Object files go to `obj/`, the test binary to `bin/tests`.

## Testing

```bash
make test
```

The standalone `tests.adb` suite covers Gaussian pdf sanity, Bernoulli
recovery of known biases, GMM recovery of well-separated means,
monotone log-likelihood, responsibility / $\pi$ normalization,
$\sigma^2>0$, invalid $K$ / empty data, Tol convergence flags,
single-component GMM mean/variance, and seeded `Random_Init_GMM`.

## Related siblings

| Package | Role vs this EM core |
| --- | --- |
| **Ada-Baum-Welch** | EM for HMM transition/emission parameters (forward–backward) |
| **Ada-Ordered-Subset-EM** | Subset-accelerated Poisson MLEM (medical image reconstruction) |

No build or runtime dependency on those repos — they are conceptual siblings
in the same educational Ada algorithm collection.

## Layout

Root-only sources (no `src/`, no `main.adb`):

- `expectation_maximization.ads` / `.adb` / `.gpr`
- `Makefile`, `tests.adb`, `README.md`, `.gitignore`
