# Pareto Interpolation — Ada 2023

Educational, self-contained Ada 2023 package for **Pareto interpolation**:
estimating the **median** and other quantiles of a population that follows a
**Pareto distribution**, from a small random sample or from **grouped**
income-style data (economics). The family is parameterized by a positive
minimum $\kappa$ and a positive Pareto index $\theta$:

$$
\begin{aligned}
F(x)
&=
1-\Bigl(\frac{\kappa}{x}\Bigr)^{\theta},
\qquad x\ge\kappa,\\
f(x)
&=
\theta\,\kappa^{\theta}\,x^{-(\theta+1)},
\qquad x\ge\kappa,\\
Q(p)
&=
\kappa\,(1-p)^{-1/\theta},
\qquad 0<p<1,\\
\mathrm{median}
&=
\kappa\cdot 2^{1/\theta}.
\end{aligned}
$$

When only two cumulative proportions $P_a$, $P_b$ below bounds $a<b$ are
known, the Wikipedia estimators are

$$
\begin{aligned}
\widehat{\theta}
&=
\frac{\log(1-P_a)-\log(1-P_b)}{\log b-\log a},\\
\widehat{\kappa}
&=
\left(
\frac{P_b-P_a}{a^{-\widehat{\theta}}-b^{-\widehat{\theta}}}
\right)^{1/\widehat{\theta}},\\
\text{estimated median}
&=
\widehat{\kappa}\cdot 2^{1/\widehat{\theta}}.
\end{aligned}
$$

Educational `Float` throughout; powers and ratios use **logs** for numerical
care. Also provides classical **MLE** fit from positive iid samples
($\widehat{\kappa}=\min x_i$,
$\widehat{\theta}=n/\sum\log(x_i/\widehat{\kappa})$).

Based on [Wikipedia: Pareto interpolation](https://en.wikipedia.org/wiki/Pareto_interpolation).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Polynomial-Interpolation](https://github.com/RobertBoettcherSF/Ada-Polynomial-Interpolation)** — Lagrange / Newton / Neville survey
- **[Ada-Neville](https://github.com/RobertBoettcherSF/Ada-Neville)** — Neville tableau focus
- **[Ada-Spline-Interpolation](https://github.com/RobertBoettcherSF/Ada-Spline-Interpolation)** — natural / clamped cubics
- **Tricubic** — upcoming
- **Nearest-neighbor** — upcoming
- **Lanczos resampling** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Model** | Pareto$(\kappa,\theta)$ | $\kappa>0$ min, $\theta>0$ index |
| **Two-point fit** | Wiki $\widehat{\theta}$, $\widehat{\kappa}$ | From $(a,b,P_a,P_b)$ |
| **Sample fit** | MLE $\min$ + log-sum | Cap $n\le 512$ |
| **PDF / CDF / $Q$** | Log-safe Float | Reject bad $\kappa,\theta$ |
| **Median** | $\kappa\cdot 2^{1/\theta}$ | `Interpolate_Median` |
| **Class helper** | Fit then quantile | `Interpolate_In_Class` |
| **Status** | `Ok` … `Ill_Started` | Bad params / empty / proportions |

## Brief history

Vilfredo Pareto observed that upper tails of income and wealth often follow a
power law. Statistical agencies (e.g. U.S. Census Bureau income surveys) use
**Pareto interpolation** inside income classes when only grouped cumulative
counts are available: fit $\kappa$ and $\theta$ from the class endpoints and
the observed proportions, then read off the median or other quantiles from the
fitted Pareto. The closed-form two-point estimators above are the textbook
form presented on Wikipedia (with derivations also discussed by Stults).

## Algorithm (this package)

1. **Validate** $\kappa>0$, $\theta>0$; for two-point data require $a<b$,
   $0<P_a<P_b<1$, and positive bounds.
2. **Fit_From_Cumulative:** compute $\widehat{\theta}$ and $\widehat{\kappa}$
   with logarithms as in the display above.
3. **Fit_From_Sample:** MLE $\widehat{\kappa}=\min_i x_i$ and
   $\widehat{\theta}=n/\sum_i\log(x_i/\widehat{\kappa})$ (refuse non-positive
   or all-equal samples).
4. **PDF / CDF / Quantile / Median:** evaluate the Pareto$(\kappa,\theta)$
   formulas with `Exp`/`Log` (no fragile direct `**` on awkward scales).
5. **Interpolate_Median / Interpolate_In_Class:** fit from a cumulative pair
   (class endpoints), then return the median or a requested quantile.

## API summary

| Symbol | Role |
| --- | --- |
| `Parameters` | Fitted / prescribed $\kappa$, $\theta$ + `Status` |
| `Eval_Result` | Scalar `Value` + `Stat` + `Success` |
| `Observations`, `Sample` | Packed positive draws (cap $512$) |
| `Cumulative_Pair` | $(a,b,P_a,P_b)$ textbook setup |
| `Status` | `Ok` / `Bad_Parameters` / `Empty_Sample` / `Invalid_Proportions` / `Dimension_Error` / `Ill_Started` |
| `Near`, `Is_Positive` | Helpers |
| `Validate_Parameters`, `Validate_Cumulative` | Pre-checks |
| `PDF`, `CDF`, `Quantile` / `Inverse_CDF` | Pareto$(\kappa,\theta)$ |
| `Median`, `Interpolate_Median` | $\kappa\cdot 2^{1/\theta}$ |
| `Fit_From_Cumulative` | Wikipedia two-point estimator |
| `Fit_From_Sample` | Classical MLE |
| `Interpolate_Quantile`, `Interpolate_In_Class` | Class / quantile helpers |
| `Make_Cumulative`, `Make_Sample` | Builders |
| `Make_Pareto_Sample` | Synthetic inverse-CDF draws (LCG) |
| `Make_Example`, `Make_Wiki_Cumulative` | Demo presets |

## Limits and caveats

- **Educational `Float`** — ordinary single precision; not a production
  statistics library.
- **Economics / survey context** — meant for teaching income-style grouped
  estimation, not for arbitrary heavy-tail modelling in production.
- **Two-point assumption** — the Wikipedia estimator assumes the population
  is exactly Pareto between (and implicitly beyond) the two cumulative
  anchors; real income data may only be approximately Pareto in the upper
  tail.
- **MLE** — $\widehat{\kappa}=\min x_i$ is biased low for small $n$; synthetic
  tests allow generous relative tolerance.
- **Proportions** — $P_a$, $P_b$ and quantile probabilities must lie in the
  open interval $(0,1)$.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Ppareto_interpolation.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `pareto_interpolation.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
pareto_interpolation.ads
pareto_interpolation.adb
pareto_interpolation.gpr
tests.adb
```

## References

1. [Wikipedia: Pareto interpolation](https://en.wikipedia.org/wiki/Pareto_interpolation)
2. [Wikipedia: Pareto distribution](https://en.wikipedia.org/wiki/Pareto_distribution)
3. U.S. Census Bureau, Memorandum on statistical techniques used in 2001 income survey — Equation 10
4. Stults, Brian J., *Deriving median household income* — derivation of the Pareto interpolation equations
5. Sibling READMEs: Ada-Polynomial-Interpolation, Ada-Neville, Ada-Spline-Interpolation;
   upcoming Tricubic, Nearest-neighbor, Lanczos resampling
