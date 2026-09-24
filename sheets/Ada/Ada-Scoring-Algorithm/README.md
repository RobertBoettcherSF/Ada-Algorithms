# Scoring Algorithm / Fisher Scoring (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Scoring algorithm](https://en.wikipedia.org/wiki/Scoring_algorithm)
(also known as **Fisher's scoring**) — a Newton-like iteration for
**maximum likelihood** estimation that updates the parameter with the
**score** $V(\theta)=\nabla\log L$ and either the **observed information**
$\mathcal{J}$ or the **expected Fisher information** $\mathcal{I}=\mathrm{E}[\mathcal{J}]$.

Named after [Ronald Fisher](https://en.wikipedia.org/wiki/Ronald_Fisher);
see also Longford (1987) for a classical scoring algorithm in mixed models.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Observed Newton** | $\theta\leftarrow\theta+\mathcal{J}^{-1}V$ | Hessian-based |
| **Fisher scoring** | $\theta\leftarrow\theta+\mathcal{I}^{-1}V$ | Expected information |
| **Scalar engine** | `Fisher_Step`, `Run_Scalar_Scoring` | Callback `Score_Fn` / `Info_Fn` |
| **Bernoulli $p$** | Closed-form $V,I,J$; MLE $k/n$ | Interior clamp |
| **Poisson $\lambda$** | Closed-form; MLE = sample mean | Positive rate |
| **Normal mean $\mu$** | Known $\sigma^2$; $I=J=n/\sigma^2$ | One-step MLE |
| **Exponential $\lambda$** | Rate pdf; $I=J=n/\lambda^2$ | MLE $1/\bar x$ |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms | Role |
| --- | --- | --- |
| Helpers | `Near`, `Clamp_Unit_Interval`, `Sample_Mean`, `Sample_Sum`, `Count_Successes` | Numerics / data |
| Engine | `Fisher_Step`, `Run_Scalar_Scoring` | Generic scalar iteration |
| Bernoulli | `Bernoulli_Score`, `*_Fisher_Info`, `*_Observed_Info`, `Bernoulli_MLE`, `Fit_Bernoulli` | Proportion $p$ |
| Poisson | `Poisson_Score`, infos, `Poisson_MLE`, `Fit_Poisson` | Rate $\lambda$ |
| Normal | `Normal_Mean_Score`, infos, `Normal_Mean_MLE`, `Fit_Normal_Mean` | Mean $\mu$ |
| Exponential | `Exponential_Score`, infos, `Exponential_MLE`, `Fit_Exponential` | Rate $\lambda$ |
| Result | `Scoring_Result`, `Scoring_Kind` | Estimate, iters, flags |

Strong typing uses domain types (`Real` digits 12, `Sample`,
`Scoring_Result`, …). Public subprograms carry `Pre` / `Post` / `Global`
where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Singular_Information` (also
`Degenerate_Geometry`), `Capacity_Exceeded`, `Did_Not_Converge`,
`Empty_Sample`.

## Formula summary

Taylor expansion of the score about $\theta_0$ and $V(\theta^*)=0$ yield
the observed-information Newton update:

$$
\theta_{m+1}
=
\theta_m + \mathcal{J}(\theta_m)^{-1} V(\theta_m)
$$

Fisher scoring replaces $\mathcal{J}$ by its expectation:

$$
\theta_{m+1}
=
\theta_m + \mathcal{I}(\theta_m)^{-1} V(\theta_m),
\qquad
\mathcal{I}(\theta)=\mathrm{E}[\mathcal{J}(\theta)].
$$

**Bernoulli** ( $n$ trials, $k$ successes, $\theta=p\in(0,1)$ ):

$$
V(p)=\frac{k}{p}-\frac{n-k}{1-p},\quad
\mathcal{I}(p)=\frac{n}{p(1-p)},\quad
\mathcal{J}(p)=\frac{k}{p^2}+\frac{n-k}{(1-p)^2},\quad
\hat p=\frac{k}{n}.
$$

**Poisson** ( $\theta=\lambda>0$ ): $V(\lambda)=-n+(\sum x_i)/\lambda$,
$\mathcal{I}=n/\lambda$, $\mathcal{J}=(\sum x_i)/\lambda^2$,
$\hat\lambda=\bar x$.

**Normal mean** ( known $\sigma^2$ ): $V(\mu)=\sum(x_i-\mu)/\sigma^2$,
$\mathcal{I}=\mathcal{J}=n/\sigma^2$, $\hat\mu=\bar x$.

**Exponential rate**: $V(\lambda)=n/\lambda-\sum x_i$,
$\mathcal{I}=\mathcal{J}=n/\lambda^2$, $\hat\lambda=1/\bar x$.

For one-parameter exponential families in mean parameterization, a single
Fisher step often lands on the MLE (Bernoulli, Poisson, Normal mean).

## Usage

```ada
with Scoring_Algorithm; use Scoring_Algorithm;

--  Bernoulli proportion from a 0/1 sample
Data : constant Sample := [1.0, 1.0, 0.0, 1.0];
R    : constant Scoring_Result :=
  Fit_Bernoulli (Data, Start => 0.5, Kind => Fisher_Expected);
--  R.Estimate ≈ 0.75, R.Converged = True
```

```bash
cd /workspace/ada-scoring-algorithm
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone harness (local `Check` + `Text_IO`; no
`Ada.Assertions`). It covers helpers, one-step formulas, Bernoulli /
Poisson / Normal / Exponential fits vs analytic MLEs, Fisher vs Observed
agreement where $I=J$, bad starts, empty/singular edges, tolerance and
iteration bounds (≥15 sections, 80+ assertions). Exit status is nonzero
if any check fails (`pragma Assert (Fail_Count = 0)`).

## Building

Requires GNAT with Ada 2022 support (`gnatmake -gnatwa -gnat2022`).
The GPR file `scoring_algorithm.gpr` places objects in `obj/` and the
test executable in `bin/`.

```text
scoring_algorithm.ads / .adb   — package
scoring_algorithm.gpr          — project
Makefile                       — all / test / clean
tests.adb                      — test main
README.md                      — this file
.gitignore                     — obj/ bin/
```

## References

1. Wikipedia contributors. *[Scoring algorithm](https://en.wikipedia.org/wiki/Scoring_algorithm)*.
2. Wikipedia. *[Score (statistics)](https://en.wikipedia.org/wiki/Score_(statistics))*;
   *[Fisher information](https://en.wikipedia.org/wiki/Fisher_information)*;
   *[Observed information](https://en.wikipedia.org/wiki/Observed_information)*.
3. Longford, N. T. (1987). A fast scoring algorithm for maximum likelihood
   estimation in unbalanced mixed models with nested random effects.
   *Biometrika* 74 (4): 817–827. doi:10.1093/biomet/74.4.817.
4. Fisher, R. A. — foundational work on maximum likelihood and information.
5. Jennrich, R. I. & Sampson, P. F. (1976). Newton–Raphson and related
   algorithms for maximum likelihood variance component estimation.
   *Technometrics* 18 (1): 11–17.
