# Evolutionary Computation — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Evolutionary computation](https://en.wikipedia.org/wiki/Evolutionary_computation):
a family of population-based trial-and-error solvers with a metaheuristic /
stochastic optimisation character, inspired by biological evolution
(selection, mutation, and optionally recombination). This survey ships
**shared EA-loop helpers** (population init, elitist merge, generation
counters), a compact **bit-string GA generation step**, and a
**(1+1)-ES** step with $1/5$-rule $\sigma$ adaptation. A **method taxonomy**
flags Genetic_Algorithm / Evolution_Strategy / Gene_Expression /
Differential_Evolution / Memetic / Genetic_Programming — DE and GP may be
forthcoming; full solvers live in sibling repos (README links only; **not**
build dependencies).

In evolutionary computation an initial set of candidate solutions is generated
and iteratively updated. Each new generation is produced by stochastically
removing less desired solutions and introducing small random changes as well
as, depending on the method, mixing parental information. Recombination and
mutation create diversity; selection increases quality.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers /
operators (links only — **not** build dependencies):

- [Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)
- [Ada-Evolution-Strategy](https://github.com/RobertBoettcherSF/Ada-Evolution-Strategy)
- [Ada-Gene-Expression-Programming](https://github.com/RobertBoettcherSF/Ada-Gene-Expression-Programming)
- [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)
- [Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)
- [Ada-Fitness-Proportionate-Selection](https://github.com/RobertBoettcherSF/Ada-Fitness-Proportionate-Selection)
- [Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)
- [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)

Style siblings: `ada-swarm-intelligence`, `ada-local-search`.

Educational limits: bit length $n\le 64$, population $P\le 64$, continuous
dimension $d\le 8$, generations $\le 500$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Taxonomy** | `Method_Kind` | GA / ES sketches; GEP / Memetic = siblings; DE / GP forthcoming |
| **EA helpers** | Init / elitist merge / generation | Shared loop scaffolding |
| **Bit GA** | Tournament + 1-point CX + bit-flip | OneMax maximise sketch |
| **(1+1)-ES** | Gaussian mutate + $1/5$ rule | Sphere minimise sketch |
| **Diversity** | Mean pairwise Hamming | Selection-pressure ratio |
| **Flags** | `Classify_Method` / `Uses_Recombination` | Metadata only |

## Formula summary

### Shared evolutionary loop

A population $P_t=\{x_1,\ldots,x_\mu\}$ is updated by variation and selection:

$$
P_{t+1} = \mathrm{select}\bigl(\mathrm{vary}(P_t)\bigr),
$$

where $\mathrm{vary}$ denotes mutation and (optionally) recombination, and
$\mathrm{select}$ retains higher-quality individuals under a fitness
$f$ (maximise) or cost $c$ (minimise).

### Bit GA (OneMax sketch)

Fitness $f(b)=\sum_{i=1}^{n} b_i$ on bit-strings $b\in\{0,1\}^n$. One
generation: tournament selection, one-point crossover with rate $p_c$,
independent bit-flip mutation with rate $p_m$, then elitist replacement of
the worst slots by the top elites.

### (1+1)-ES with $1/5$ success rule

Offspring $x'=x+\sigma\,\mathcal{N}(0,I)$. Accept if $c(x')\le c(x)$. Every
$W$ trials adapt

$$
\sigma \leftarrow
\begin{cases}
\sigma / c_{1/5} & \text{if success rate }>1/5,\\
\sigma \cdot c_{1/5} & \text{if success rate }<1/5,\\
\sigma & \text{otherwise,}
\end{cases}
$$

with classic factor $c_{1/5}\approx 0.817$. Demo objective:
$c(x)=\|x\|_2^2$ (Sphere).

### Selection pressure / diversity

Selection-pressure proxy (maximise): $f_{\max}/\bar f$. Diversity proxy:
mean pairwise Hamming distance, normalised by $n$ into $[0,1]$.

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Bits`, `Max_Pop`, `Max_Dim`, `Max_Gens` | Educational caps |
| Types | `Bit_String`, `Bit_Population`, `Cont_Individual`, `Generation_Count` | Shared state |
| Config | `GA_Config`, `ES_Config`, `Default_*`, `GA_Config_Is_Valid` | Controls |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Natural`, `Sample_Normal` | Reproducible draws |
| Bits | `Ones_Count`, `Hamming_Distance`, `Random_Bit_String`, `Flip_Bit` | Utilities |
| EA helpers | `Init_Bit_Population`, `Elitist_Merge_Max`, `Advance_Generation` | Loop scaffolding |
| Pressure | `Selection_Pressure_Ratio`, `Mean_Pairwise_Hamming`, `Normalised_Diversity` | Notes |
| Bit GA | `Tournament_Select`, `One_Point_Crossover`, `Bit_Flip_Mutate`, `Step_Bit_GA` | Sketch |
| Driver | `Maximize_OneMax` | Tiny OneMax run |
| (1+1)-ES | `Sphere`, `Mutate_Gaussian`, `Step_One_Plus_One_ES` | Sketch |
| Driver | `Minimize_Sphere_One_Plus_One` | Tiny Sphere run |
| Taxonomy | `Method_Kind`, `Classify_Method`, `Method_Name`, `Uses_Recombination` | Flags |

Strong typing uses `Real` (digits 15) and capacity subtypes. Public
subprograms carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exception: `Invalid_Argument`.

## Usage

```ada
with Evolutionary_Computation; use Evolutionary_Computation;

declare
   GA  : constant GA_Config := Default_GA_Config (Pop_Size => 20, Seed => 1);
   ES  : constant ES_Config := Default_ES_Config (Max_Gens => 200, Seed => 2);
   RG  : GA_Result;
   RE  : ES_Result;
   Info : Method_Info;
begin
   RG := Maximize_OneMax (N => 16, Cfg => GA);
   RE := Minimize_Sphere_One_Plus_One (Dim => 2, Cfg => ES);
   Info := Classify_Method (Genetic_Algorithm);
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pevolutionary_computation.gpr`. Main program
is `tests.adb` (no `main.adb`). Expect **zero** warnings and `Fail_Count = 0`
with `Pass_Count ≥ 100`.

## Layout

| File | Role |
| --- | --- |
| `evolutionary_computation.ads` | Package spec |
| `evolutionary_computation.adb` | Package body |
| `evolutionary_computation.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

Empty GitHub repo (do not push from this task):
[Ada-Evolutionary-Computation](https://github.com/RobertBoettcherSF/Ada-Evolutionary-Computation).

## References

- Wikipedia: [Evolutionary computation](https://en.wikipedia.org/wiki/Evolutionary_computation).
- Bäck, T., Fogel, D.B., and Michalewicz, Z. (eds.). *Handbook of Evolutionary Computation*, 1997.
- Eiben, A.E. and Smith, J.E. *Introduction to Evolutionary Computing*, Springer, 2015.
- Holland, J.H. *Adaptation in Natural and Artificial Systems*, 1975.
- Rechenberg, I. *Evolutionsstrategie*, 1973; Schwefel, H.-P. *Numerical Optimization of Computer Models*, 1981.
- Koza, J.R. *Genetic Programming*, MIT Press, 1992.

## Related packages

- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  full bit-string GA (link only).
- **[Ada-Evolution-Strategy](https://github.com/RobertBoettcherSF/Ada-Evolution-Strategy)** —
  $(\mu,\lambda)$ / $(\mu+\lambda)$ ES (link only).
- **[Ada-Gene-Expression-Programming](https://github.com/RobertBoettcherSF/Ada-Gene-Expression-Programming)** —
  GEP sketch (link only).
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  GA + local search (link only).
- **[Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)** /
  **[Ada-Fitness-Proportionate-Selection](https://github.com/RobertBoettcherSF/Ada-Fitness-Proportionate-Selection)** /
  **[Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)** /
  **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  selection operators (links only).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
