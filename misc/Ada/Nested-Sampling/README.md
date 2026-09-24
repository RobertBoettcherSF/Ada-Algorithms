# Nested Sampling Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Nested sampling algorithm](https://en.wikipedia.org/wiki/Nested_sampling_algorithm)
introduced by **John Skilling** (2004; refined 2006). Nested sampling
approximates the Bayesian **evidence** (marginal likelihood)

$$Z = P(D\mid M) = \int L(\theta)\,\pi(\theta)\,d\theta$$

and simultaneously produces **posterior-weighted** discarded samples for
posterior inference and **Bayes-factor** model comparison.

Part of the **RobertBoettcherSF** Ada algorithm series.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Evidence** | Shell sum $Z \leftarrow Z + L_i w_i$ | Skilling / Wikipedia |
| **Prior mass** | $X_0=1$, $X_i=\exp(-i/N)$ | Optional debiased $(1-1/N)^i$ |
| **Shell weight** | $w_i = X_{i-1}-X_i$ | Lebesgue-style bins in $L$ |
| **Constrained prior** | MCMC random walk, reject $L\le L_i$ | Plus rejection fallback |
| **Remainder** | $Z \mathrel{+}= X_j\cdot\mathrm{mean}(L_{\mathrm{live}})$ | Optional |
| **Toys** | Flat $Z=1$, Exp $Z=1-e^{-1}$, Gaussian bump | Analytic / numeric refs |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Helpers | `Near`, `Safe_Log`, `Log_Sum` | Numerics |
| Schedule | `Prior_Volume`, `Shell_Weight` | $X_i$, $w_i$ |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Real` | Seeded LCG |
| Models | `Built_In_Model`, `Analytic_Evidence`, … | Flat / Exp / Gauss |
| Live set | `Init_Live_From_Prior`, `Min_Likelihood_Index` | $N$ live points |
| Replace | `Replace_Lowest_MCMC` | Constrained sampling |
| Driver | `Run_Nested_Sampling`, `Run_Built_In` | Full loop + result |

Strong typing uses domain types (`Real` digits 12, `Param_Vector`,
`Live_Set`, `Parameters`, `Result`, …). Bounded capacities:
`Max_Dims=4`, `Max_Live=256`, `Max_Samples=4096`.

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Algorithm (Skilling / Wikipedia)

1. Sample $N$ **live points** $\theta$ from the prior $\pi$.
2. For iteration $i=1,\ldots,j$:
   - $L_i := \min$ likelihood among live points
   - $X_i := \exp(-i/N)$ (or $(1-1/N)^i$)
   - $w_i := X_{i-1}-X_i$
   - $Z := Z + L_i\cdot w_i$
   - Save the discarded point with weight $w_i$
   - Replace the lowest-$L$ point by sampling the prior **restricted to**
     $L(\theta)>L_i$ (MCMC under the prior; reject if $L\le L_i$)
3. Return $Z$, optionally adding the remainder
   $X_j\cdot\mathrm{mean}(L)$ over remaining live points.

The schedule $X_i$ estimates remaining prior mass above the current
likelihood contour. Stopping when $L_i X_i$ is small relative to $Z$
(controlled by `Tol`) avoids useless late iterations.

## Built-in test models

| Model | Prior | Likelihood | Evidence |
| --- | --- | --- | --- |
| `Flat_Unit` | $U[0,1]$ | $L=1$ | $Z=1$ |
| `Exponential_Unit` | $U[0,1]$ | $L=e^{-\theta}$ | $Z=1-e^{-1}\approx0.63212$ |
| `Gaussian_Bump` | $U[-5,5]$ | $L=e^{-\theta^2/2}$ | $Z\approx\sqrt{2\pi}/10\approx0.25066$ |
| `Theta_Unit` | $U[0,1]$ | $L=\theta$ | $Z=1/2$ |

Custom models use a `Likelihood_Fn` access procedure with box bounds in
`Parameters`.

## Related work (not implemented)

Practical high-dimensional samplers such as **MultiNest** (ellipsoidal
decomposition) and **PolyChord** (slice sampling) build on the same
nested-sampling identity but replace the simple random-walk replacement
used here for clarity.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pnested_sampling.gpr`. Main program:
`tests.adb` (no `main.adb`).

## Public API (summary)

```ada
type Real is digits 12;
type Param_Vector is array (Dim_Index) of Real;
type Live_Point, Live_Set, Parameters, Result, Built_In_Model, ...

function Prior_Volume (Iteration, N_Live, Schedule) return Unit_Interval;
function Shell_Weight (X_Prev, X_Curr) return Non_Negative;

procedure Init_Live_From_Prior (Live, Params, Likely, State);
function  Min_Likelihood_Index (Live) return Live_Index;
procedure Replace_Lowest_MCMC (Live, L_Star, Params, Likely, State, Accepted);

function Run_Nested_Sampling (Params, Likely) return Result;
function Run_Built_In (Model, Params) return Result;
```

`Result` carries `Evidence` ($Z$), `Log_Evidence`, discarded `Samples` with
`Weight`s, `Iters`, `Final_X`, and `Remainder`.

## References

- Skilling, J. (2004). *Nested Sampling*. AIP Conf. Proc. 735, 395–405.
- Skilling, J. (2006). *Nested sampling for general Bayesian computation*.
  Bayesian Analysis 1(4), 833–860.
- [Nested sampling algorithm — Wikipedia](https://en.wikipedia.org/wiki/Nested_sampling_algorithm)

## License

Educational reference implementation for the RobertBoettcherSF Ada series.
