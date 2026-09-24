# Genetic Algorithms — Ada 2023

Educational, self-contained Ada 2023 package implementing a classical
**genetic algorithm** (GA) on **bit-string** chromosomes: population
initialization, fitness evaluation, selection, crossover, mutation, and
generational replacement with optional **elitism**.

Based on [Wikipedia: Genetic algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm)
(Holland 1975; evolutionary algorithms / metaheuristics).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  hybrid EA + local search (Lamarckian)
- **[Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)** —
  $k$-tournament parent selection
- **[Ada-Fitness-Proportionate-Selection](https://github.com/RobertBoettcherSF/Ada-Fitness-Proportionate-Selection)** —
  roulette-wheel / FPS
- **[Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)** —
  low-spread fitness sampling
- **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  keep the top fraction

Educational limits: bits $n\le 64$, population $\le 128$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Population** | Random bit-strings | Size `Pop_Size` |
| **Fitness** | OneMax / Hamming | Maximize ones or $n-d_H$ |
| **Selection** | $k$-tournament and/or FPS | Config `Selection` |
| **Crossover** | One-point / two-point | Rate $p_c$ |
| **Mutation** | Independent bit-flip | Rate $p_m$ per locus |
| **Replace** | Generational + elitism | `Elite_Count` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Genetic algorithms became popular through John Holland’s work in the early
1970s and *Adaptation in Natural and Artificial Systems* (1975). A GA
evolves a population of candidate genotypes by **selection**,
**crossover** (recombination), and **mutation**. Binary encodings are the
classical representation; the educational drivers here use fixed-length
bit strings. Related evolutionary methods include evolution strategies,
evolutionary programming, genetic programming, and **memetic algorithms**
(EA + local search). Like other metaheuristics, a GA does not guarantee a
global optimum.

## Algorithm

Initialize a population of size $P$, evaluate fitness (or cost). For each
generation $g=1..G$:

1. **Copy** the best `Elite_Count` individuals unchanged into the next
   population (elitism).
2. Until the next population is full: **select** two parents
   ($k$-tournament on fitness, or fitness-proportionate / roulette),
   apply **crossover** with probability $p_c$, then **mutate** each locus
   independently with probability $p_m$.
3. Evaluate the new population; track the globally best individual.
4. Terminate after $G$ generations (or $G=0$ for an init-only result).

`Result.History_Length` equals `Generations_Run` ($=G$ when $G>0$).

### OneMax

Maximize the number of ones (dual: minimize zero-count):

$$
f(x)=\sum_{i=1}^{n} x_i,\qquad x\in\{0,1\}^n.
$$

Optimum $f(x^\star)=n$ at the all-ones string. Cost form:
$c(x)=n-f(x)$.

### Hamming to target

Minimize Hamming distance to a fixed target $t\in\{0,1\}^n$:

$$
c(x)=d_H(x,t)=\lvert\{i:x_i\neq t_i\}\rvert,
$$

or maximize fitness $f(x)=n-d_H(x,t)$. Optimum cost $0$ when $x=t$.

### Operators

**Tournament** (maximization): sample $k$ indices with replacement; return
the one with highest fitness. Minimization uses lowest cost.

**Fitness-proportionate selection** (FPS / roulette): draw
$U\sim\mathrm{Uniform}(0,F)$ on the cumulative fitness wheel with
$F=\sum_i \max(f_i,0)$. If $F=0$, pick uniformly. For minimization
drivers, costs are shifted to fitness via $f_i=\max_j c_j-c_i$ (flat
populations get $f_i=1$).

**One-point crossover** with cut $c\in\{0,\ldots,n\}$:

$$
\mathrm{child}=x^{(A)}_{1..c}\,\Vert\,x^{(B)}_{c+1..n}.
$$

**Two-point crossover** with $1\le L\le H\le n$ copies parent B on
$[L..H]$ and parent A elsewhere.

**Bit-flip mutation**: for each locus $i$, flip $x_i$ with probability
$p_m$.

Defaults: $P=30$, $G=80$, $p_c=0.8$, $p_m=0.02$, $k=3$,
$\mathrm{Elite\_Count}=1$, tournament + one-point.

## Built-in demos

| Driver | Sense | Notes |
| --- | --- | --- |
| `Maximize_OneMax` | maximize ones | Classic OneMax |
| `Minimize_Zero_Count` | minimize zeros | Dual of OneMax |
| `Minimize_Hamming` | minimize $d_H$ | Match a target pattern |
| `Maximize_Hamming_Fitness` | maximize $n-d_H$ | Same search, fitness view |

## API (`Genetic_Algorithms`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Bit_String`, `Config`, `Result`, `Selection_Kind`, `Crossover_Kind` | $P$, $G$, $p_c$, $p_m$, $k$, elites, seed |
| Helpers | `Near`, `Default_Config`, `Config_Is_Valid` | Tolerance / validation |
| RNG (LCG) | `Seed_RNG`, `Next_Unit`, `Next_Natural` | Reproducible draws |
| Bits | `Hamming_Distance`, `Zero_Count` / `Ones_Count`, `Flip_Bit`, `Equal_Bits` | Utilities |
| Fitness | `Fitness_OneMax`, `Cost_Zero_Count`, `Cost_Hamming`, `Fitness_Hamming` | Objectives |
| Selection | `Tournament_Select`, `Tournament_Select_Min`, `Fitness_Proportionate_Select` | Parent pick |
| Variation | `One_Point_Crossover`, `Two_Point_Crossover`, `Crossover`, `Mutate_Bits` | Operators |
| Elitism | `Elite_Indices_Max`, `Elite_Indices_Min` | Top-$E$ indices |
| Drivers | `Maximize_OneMax`, `Minimize_Hamming`, `Maximize_Hamming_Fitness`, `Minimize_Zero_Count` | Full runs |

Named exception: `Invalid_Argument` (bad config, empty FPS population,
length mismatch, etc.).

`Result` fields: `Best_Bits` (prefix `N`), `Best_Fitness`, `Best_Cost`,
`Generations_Run`, `Evaluations`, `History_Length` ($=$ generations run).

## Usage

```ada
with Genetic_Algorithms; use Genetic_Algorithms;

declare
   Cfg : constant Config :=
     Default_Config (Pop_Size => 20, Generations => 40, Seed => 1);
   R   : Result;
   T   : constant Bit_String := [True, False, True, True];
begin
   R := Maximize_OneMax (12, Cfg);
   R := Minimize_Hamming (T, Cfg);
end;
```

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **zero** warnings,
**Fail_Count = 0**, and at least **100** PASS lines.

## Layout

| File | Role |
| --- | --- |
| `genetic_algorithms.ads` | Package spec |
| `genetic_algorithms.adb` | Package body |
| `genetic_algorithms.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- [Wikipedia: Genetic algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm)
- Holland, J. H. (1975). *Adaptation in Natural and Artificial Systems*.
  University of Michigan Press.
- Goldberg, D. E. (1989). *Genetic Algorithms in Search, Optimization and
  Machine Learning*. Addison-Wesley.
- Sibling: [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)
- Sibling: [Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)
- Sibling: [Ada-Fitness-Proportionate-Selection](https://github.com/RobertBoettcherSF/Ada-Fitness-Proportionate-Selection)
- Sibling: [Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)
- Sibling: [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
