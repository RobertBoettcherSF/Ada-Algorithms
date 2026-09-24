# Evolution Strategy — Ada 2023

Educational, self-contained Ada 2023 package implementing **evolution
strategies** (ES) — continuous **evolutionary algorithms** that mutate
with Gaussian noise, optionally recombine parents, and select the best
$\mu$ individuals under $(\mu,\lambda)$ or $(\mu+\lambda)$ replacement.
Includes the classical $(1+1)$-ES with Rechenberg’s **1/5 success rule**
for $\sigma$ adaptation and log-normal **self-adaptive** $\sigma$ for
multi-member ES. Search is **unbounded** (box-free) on $\mathbb{R}^n$.

Based on [Wikipedia: Evolution strategy](https://en.wikipedia.org/wiki/Evolution_strategy)
(Rechenberg 1971/1973; Schwefel 1974/1977; Beyer & Schwefel 2002).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  bit-string GA (selection / crossover / mutation)
- **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  keep the top fraction (breeder GA link)

Educational limit: dimension $n\le 8$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **$(1+1)$-ES** | Mutate parent; keep if not worse | 1/5 success-rule $\sigma$ |
| **$(\mu,\lambda)$** | Best $\mu$ from $\lambda$ offspring | Comma selection |
| **$(\mu+\lambda)$** | Best $\mu$ from parents $\cup$ offspring | Plus selection |
| **Mutation** | $x' = x + \sigma\,\mathcal{N}(0,I)$ | Isotropic Gaussian |
| **Self-adapt** | $\sigma' = \sigma\cdot e^{(1/\sqrt{n})\,Z}$ | Log-normal; $Z\sim\mathcal{N}(0,1)$ |
| **Recombine** | Optional intermediate $(\cdot+\cdot)/2$ | Then self-adaptive mutate |
| **Demos** | Sphere / Rosenbrock / Shifted_Sphere | Unbounded continuous |
| **RNG** | Seeded 32-bit LCG + Box–Muller | Reproducible tests |

## Brief history

Evolution strategies were created in the early 1960s and developed in the
1970s by Ingo Rechenberg, Hans-Paul Schwefel and co-workers for numerical
(engineering) optimization. Unlike classical genetic algorithms on bit
strings, ES works directly on real-valued decision vectors and co-evolves
mutation step sizes $\sigma$. Deterministic truncation of the best
$\mu$ candidates links ES to breeding / truncation selection. Related
methods include genetic algorithms, CMA-ES, and other derivative-free
metaheuristics; like them, ES does not guarantee a global optimum.

## Algorithm

### $(1+1)$-ES with 1/5 success rule

Maintain one parent $x$ with step size $\sigma$. Each generation:

$$
x' = x + \sigma\,\mathcal{N}(0,I).
$$

If $f(x')\le f(x)$ accept $x\leftarrow x'$ (success). Every
`Success_Window` trials, estimate the success rate $P_s$ and adapt:

- if $P_s > 1/5$: $\sigma \leftarrow \sigma / c$ (enlarge steps)
- if $P_s < 1/5$: $\sigma \leftarrow \sigma\cdot c$ (shrink steps)
- if $P_s = 1/5$: leave $\sigma$ unchanged

with educational factor $c\approx 0.82$.

### $(\mu,\lambda)$-ES and $(\mu+\lambda)$-ES

1. From $\mu$ parents, create $\lambda$ offspring. Mate selection is
   uniform (independent of fitness). Optional **intermediate
   recombination** averages two random parents’ $x$ and $\sigma$.
2. **Self-adapt** $\sigma$ (log-normal) then **mutate**:
   $$
   \sigma' = \sigma\cdot\exp\!\bigl((1/\sqrt{n})\,\mathcal{N}(0,1)\bigr),
   \qquad
   x' = x + \sigma'\,\mathcal{N}(0,I).
   $$
3. **Select** the best $\mu$ by fitness rank:
   - $(\mu,\lambda)$ (`Comma`): from the $\lambda$ offspring only
     (requires $\lambda\ge\mu$);
   - $(\mu+\lambda)$ (`Plus`): from the union of parents and offspring.

Selection is deterministic and rank-based (invariant to monotonic
transforms of $f$). Defaults for multi-member demos follow the common
heuristic $\lambda\approx 7\mu$ when convenient.

When `Mu = Lambda = 1` and `Plus_Or_Comma = Plus`, `Minimize` uses the
$(1+1)$ + 1/5 path; otherwise the multi-member path with log-normal
$\sigma$.

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |

All demos are **box-free** (unbounded). Initialization samples
$x\sim U(\mathrm{Init\_Lo},\mathrm{Init\_Hi})^n$ then evolves freely in
$\mathbb{R}^n$ with $n\le 8$.

## API (`Evolution_Strategy`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Config` ($\mu$, $\lambda$, `Plus_Or_Comma`, `Max_Gens`, `Seed`, `Init_Sigma`, …), `Individual` ($x$, $\sigma$, fitness), `Population`, `Result` | Carriers |
| Helpers | `Near`, `Default_Config`, `Config_Is_Valid` | Tolerance / validation |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Natural`, `Sample_Normal` | LCG + Box–Muller $\mathcal{N}(0,1)$ |
| Operators | `Mutate`, `Mutate_Self_Adaptive`, `Intermediate_Recombine`, `Rank_Ascending`, `Best_Index` | Core ES steps |
| Steps | `Init_Population`, `Step_One_Plus_One`, `Step_Mu_Lambda` | Generation primitives |
| Objectives | `Sphere`, `Rosenbrock`, `Shifted_Sphere` | Continuous tests |
| Drivers | `Minimize` | Unbounded continuous search |

Named exception: `Invalid_Argument` (invalid comma sizes, inverted init
range, null objective, Rosenbrock with $\mathrm{Dim}<2$).

## Usage

```ada
with Evolution_Strategy; use Evolution_Strategy;

declare
   Cfg : constant Config :=
     Default_Config
       (Mu => 5, Lambda => 35, Plus_Or_Comma => Comma,
        Max_Gens => 200, Seed => 1, Init_Sigma => 0.5,
        Recombine => True);
   R : Result;
begin
   R := Minimize (Sphere'Access, Dim => 3, Cfg => Cfg,
                  Init_Lo => -2.0, Init_Hi => 2.0);
   --  R.Best_Cost / R.Best_X / R.Best_Sigma
end;
```

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

Empty remote:
[Ada-Evolution-Strategy](https://github.com/RobertBoettcherSF/Ada-Evolution-Strategy)
(do not push from this workspace unless explicitly asked).

## References

- [Wikipedia: Evolution strategy](https://en.wikipedia.org/wiki/Evolution_strategy)
- I. Rechenberg, *Evolutionsstrategie*, Frommann-Holzboog (1973)
- H.-P. Schwefel, *Numerische Optimierung von Computer-Modellen* (1977);
  *Evolution and Optimum Seeking*, Wiley (1995)
- H.-G. Beyer, H.-P. Schwefel, *Evolution Strategies: A Comprehensive
  Introduction*, Natural Computing 1(1):3–52 (2002)
- Sibling: [Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)
- Sibling: [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)
  (breeder GA / truncation link)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
