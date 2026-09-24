# Cross-Entropy Method — Ada 2023

Educational, self-contained Ada 2023 package implementing the **cross-entropy
(CE) method** of Rubinstein — a Monte Carlo technique for **importance
sampling** and **optimization**. For continuous minimization over
$\mathbb{R}^D$ this package uses an **independent (diagonal) Gaussian**
sampling model: draw $N$ candidates, keep the elite $\rho$-quantile, and
update $(\mu,\sigma)$ toward elite sample means/stds (optional smoothing
$\alpha$ and $\sigma$ floor). A tiny **Bernoulli** sketch supports
combinatorial toys such as a 0–1 knapsack score.

Based on [Wikipedia: Cross-entropy method](https://en.wikipedia.org/wiki/Cross-entropy_method)
(Rubinstein; De Boer, Kroese, Mannor & Rubinstein tutorial).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Differential-Evolution](https://github.com/RobertBoettcherSF/Ada-Differential-Evolution)** —
  DE/rand/1/bin continuous metaheuristic
- **[Ada-Evolutionary-Computation](https://github.com/RobertBoettcherSF/Ada-Evolutionary-Computation)** —
  survey of EA loops / taxonomy
- **[Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)** —
  inertia / personal / global best swarm
- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  bit-string GA (selection / crossover / mutation)

Educational limits: dimension $D\le 8$, sample size $N\le 256$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Model** | Diagonal Gaussian $x_d\sim\mathcal{N}(\mu_d,\sigma_d^2)$ | Independent dims |
| **Sample** | $N$ i.i.d. draws per iteration | Box–Muller + seeded LCG |
| **Elite** | Top $\rho$-quantile (lowest $f$ for minimize) | $N_e=\max(1,\lfloor\rho N\rfloor)$ |
| **Update** | Elite mean / std → smoothed $(\mu,\sigma)$ | $\alpha\in[0,1]$ |
| **Floor** | $\sigma_d \leftarrow \max(\sigma_d,\sigma_{\min})$ | Avoids collapse |
| **Demos** | Sphere / Rosenbrock / Rastrigin / Shifted_Sphere | Continuous toys |
| **Discrete** | Bernoulli probs + tiny knapsack score | Optional sketch |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Reuven Rubinstein developed CE for **rare-event simulation**, where tiny
probabilities must be estimated (network reliability, queues,
telecommunication performance). The same adaptive importance-sampling
idea became a black-box **optimizer**: treat “good” objective levels as
rare events and tilt the sampling distribution toward them by minimizing
Kullback–Leibler (cross-entropy) divergence to an ideal indicator
distribution. Continuous Gaussian CE coincides with a simple
estimation-of-distribution (EMNA-style) update on elite samples.

## Importance-sampling intuition

Estimating $\ell=\mathbb{E}_{\mathbf{u}}[H(\mathbf{X})]$ under a nominal
density $f(\cdot;\mathbf{u})$ is hard when $H$ is rarely nonzero. Importance
sampling draws from another density $g$ and reweights. The CE method
adaptively chooses a parametric $f(\cdot;\mathbf{v})$ closest in KL sense to
the (unknown) optimal importance density, by maximizing a sample average of
$\log f$ on elite / weighted draws.

For optimization of $S$ (here we **minimize** $f$), one tracks a level
$\gamma$ and elites $\{x:f(x)\le\gamma\}$ (or the best $\rho$ fraction), then
refits the parametric family to those elites.

## Continuous CE update (diagonal Gaussian)

Maintain $\mu\in\mathbb{R}^D$ and $\sigma\in\mathbb{R}_+^D$. Each iteration:

1. Sample $X^{(1)},\ldots,X^{(N)}$ with independent coordinates
   $X_d\sim\mathcal{N}(\mu_d,\sigma_d^2)$.
2. Evaluate $f(X^{(i)})$; let $\mathcal{E}$ be the elite index set of size
   $N_e=\max\bigl(1,\lfloor\rho N\rfloor\bigr)$ (best = lowest $f$).
3. Elite moments (MLE / population form):

$$
\mu_{e,d}=\frac{1}{N_e}\sum_{i\in\mathcal{E}}X_d^{(i)},\qquad
\sigma_{e,d}=\sqrt{\frac{1}{N_e}\sum_{i\in\mathcal{E}}\bigl(X_d^{(i)}-\mu_{e,d}\bigr)^2}
$$

4. Smooth and floor:

$$
\mu_d\leftarrow(1-\alpha)\mu_d+\alpha\mu_{e,d},\qquad
\sigma_d\leftarrow\max\bigl((1-\alpha)\sigma_d+\alpha\sigma_{e,d},\;\sigma_{\min}\bigr)
$$

5. Stop at `Max_Iter` or when $\max_d\sigma_d$ is near $\sigma_{\min}$.

Return the best evaluated point seen (not only the final mean).

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Rastrigin` | $10D+\sum_i(x_i^2-10\cos(2\pi x_i))$ | Multimodal; min $0$ at origin |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |
| `Tiny_Knapsack_Value` | sum values if weight $\le C$ else penalty | Bernoulli sketch helper |

## API (`Cross_Entropy_Method`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vector`, `Gaussian_Params`, `Parameters`, `Result`, `Sample_Buffer` | $N$, $\rho$, $\alpha$, seed, $\sigma_{\min}$ |
| Helpers | `Near`, `Clamp`, `Elite_Count`, `Default_Parameters` | Quantile size / tolerance |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Index`, `Next_Gaussian`, `Next_Bernoulli` | LCG + Box–Muller |
| Primitives | `Init_Isotropic`, `Sample_Gaussian`, `Evaluate_Samples`, `Elite_Indices`, `Update_From_Elite`, `Step` | One CE iteration |
| Discrete | `Init_Bernoulli`, `Sample_Bernoulli_Bits`, `Update_Bernoulli_From_Elite`, `Tiny_Knapsack_Value` | Optional sketch |
| Objectives | `Sphere`, `Rosenbrock`, `Rastrigin`, `Shifted_Sphere` | Continuous tests |
| Drivers | `Minimize`, `Minimize_Isotropic` | Continuous CE search |

Named exception: `Invalid_Argument` (inverted clamp bounds, null objective,
Rosenbrock with $D<2$, bad elite packing).

Caps: $D\le 8$ (`Max_Dim`), $N\le 256$ (`Max_N`), $N\ge 2$.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Cross-entropy method](https://en.wikipedia.org/wiki/Cross-entropy_method)
- R.Y. Rubinstein, *Optimization of Computer Simulation Models with Rare Events*,
  European Journal of Operational Research 99:89–112 (1997)
- P.-T. De Boer, D.P. Kroese, S. Mannor, R.Y. Rubinstein,
  *A Tutorial on the Cross-Entropy Method*, Annals of Operations Research
  134:19–67 (2005)
- Sibling: [Ada-Differential-Evolution](https://github.com/RobertBoettcherSF/Ada-Differential-Evolution)
- Sibling: [Ada-Evolutionary-Computation](https://github.com/RobertBoettcherSF/Ada-Evolutionary-Computation)
- Sibling: [Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)
- Sibling: [Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
