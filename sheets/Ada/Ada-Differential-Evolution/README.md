# Differential Evolution — Ada 2023

Educational, self-contained Ada 2023 package implementing **differential
evolution** (DE) — a population-based **metaheuristic** for continuous
box-constrained search. Agents create mutants by scaled vector differences,
mix them into the target with binomial crossover, and keep the better
candidate under greedy selection. Classic variant: **DE/rand/1/bin**.

Based on [Wikipedia: Differential evolution](https://en.wikipedia.org/wiki/Differential_evolution)
(Storn & Price, 1995).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Evolutionary-Computation](https://github.com/RobertBoettcherSF/Ada-Evolutionary-Computation)** —
  survey of EA loops / taxonomy
- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  bit-string GA (selection / crossover / mutation)
- **[Ada-Evolution-Strategy](https://github.com/RobertBoettcherSF/Ada-Evolution-Strategy)** —
  continuous ES with Gaussian mutation
- **[Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)** —
  inertia / personal / global best swarm
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  population search + local refinement

Educational limits: dimension $D\le 8$, population $NP\le 64$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Population** | $NP$ real vectors in box $[Lo,Hi]^D$ | $NP\ge 4$ |
| **Mutation** | DE/rand/1: $v = x_{r_1} + F(x_{r_2}-x_{r_3})$ | Then clamp to box |
| **Crossover** | Binomial with $CR$ and $j_{\mathrm{rand}}$ | ≥1 mutant coordinate |
| **Selection** | Greedy 1-to-1 vs target | Minimize by default |
| **Sense** | Optional maximize | `Maximize` / `Parameters.Maximize` |
| **Demos** | Sphere / Rosenbrock / Rastrigin / Shifted_Sphere | Continuous toys |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Storn and Price introduced differential evolution in 1995 as a simple
population method for continuous black-box optimization. New candidates
are built from differences of existing population members rather than
from gradient estimates. Like other metaheuristics, DE makes few
assumptions about $f$ (it need not be differentiable or even continuous)
and does **not** guarantee that a global optimum is ever found.

## Algorithm (DE/rand/1/bin)

Let $f:\mathbb{R}^D\to\mathbb{R}$ be minimized (maximization uses
$h:=-f$ or the package maximize flag). Maintain a population of $NP$
agents $x_i\in[Lo,Hi]^D$. Typical defaults: $NP\approx 10D$,
$F=0.8$, $CR=0.9$, with $F\in[0,2]$ and $CR\in[0,1]$.

Until a generation budget is exhausted, for each target index $i$:

1. Pick distinct $r_1,r_2,r_3$ different from $i$.
2. Form the mutant and clamp to the box:

$$
v = x_{r_1} + F\,(x_{r_2}-x_{r_3})
$$

3. Draw $j_{\mathrm{rand}}\in\{1,\ldots,D\}$ and build trial $u$ by
   binomial crossover:

$$
u_j =
\begin{cases}
v_j & \text{if } r_j < CR \text{ or } j = j_{\mathrm{rand}} \\
(x_i)_j & \text{otherwise}
\end{cases}
$$

   with $r_j\sim U(0,1)$. The $j_{\mathrm{rand}}$ rule ensures at least
   one coordinate comes from the mutant.
4. Replace $x_i$ by $u$ if $f(u)$ is strictly better (greedy selection).

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Rastrigin` | $10D+\sum_i(x_i^2-10\cos(2\pi x_i))$ | Multimodal; min $0$ at origin |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |
| `Neg_Sphere` | $-\sum_i x_i^2$ | Unique max $0$ at origin |

## API (`Differential_Evolution`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Vector`, `Bounds`, `Parameters`, `Result`, `Agent`, `Population` | $F$, $CR$, $NP$, `Max_Gen`, seed |
| Helpers | `Near`, `Clamp`, `Clamp_Vector`, `Default_Parameters` | Tolerance / box clamp |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Index` | Seeded LCG |
| Primitives | `Init_Population`, `Mutate_Rand1`, `Binomial_Crossover`, `Select_Greedy`, `Better`, `Step_Generation` | DE/rand/1/bin |
| Objectives | `Sphere`, `Rosenbrock`, `Rastrigin`, `Shifted_Sphere`, `Neg_Sphere` | Continuous tests |
| Drivers | `Minimize`, `Maximize`, `Optimize` | Box search |

Named exception: `Invalid_Argument` (inverted bounds, null objective,
Rosenbrock with $D<2$, undersized population).

Caps: $D\le 8$ (`Max_Dim`), $NP\le 64$ (`Max_NP`), $NP\ge 4$.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **80** PASS lines.

## References

- [Wikipedia: Differential evolution](https://en.wikipedia.org/wiki/Differential_evolution)
- R. Storn, K. Price, *Differential Evolution – A Simple and Efficient
  Heuristic for Global Optimization over Continuous Spaces*, Journal of
  Global Optimization 11:341–359 (1997)
- Sibling: [Ada-Evolutionary-Computation](https://github.com/RobertBoettcherSF/Ada-Evolutionary-Computation)
- Sibling: [Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)
- Sibling: [Ada-Evolution-Strategy](https://github.com/RobertBoettcherSF/Ada-Evolution-Strategy)
- Sibling: [Ada-Particle-Swarm](https://github.com/RobertBoettcherSF/Ada-Particle-Swarm)
- Sibling: [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
