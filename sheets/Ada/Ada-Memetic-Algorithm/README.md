# Memetic Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing a **memetic
algorithm** (MA) — a hybrid of a population-based **evolutionary algorithm**
(EA) with **individual local search** (Lamarckian learning: the improved
chromosome replaces the offspring).

Based on [Wikipedia: Memetic algorithm](https://en.wikipedia.org/wiki/Memetic_algorithm)
(Moscato 1989; also known as genetic local search / Lamarckian EA).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Local-Search](../ada-local-search/)** — steepest / first-improvement
  hill climbing, ILS sketch, 2-opt
- **[Ada-Tabu-Search](../ada-tabu-search/)** — tabu list + aspiration
- **[Ada-Random-Restart-Hill-Climbing](../ada-random-restart-hill-climbing/)** —
  multi-start shotgun HC

Educational limits: bits $n\le 32$, cities $m\le 10$, population $\le 64$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Population** | Random bit-strings / TSP tours | Size `Pop_Size` |
| **Selection** | $k$-tournament (minimization) | Default $k=3$ |
| **Crossover** | One-point (bits) / order OX (TSP) | Variation |
| **Mutation** | Bernoulli bit-flip / swap | Rate $p_m$ |
| **Local search** | Steepest or first-improvement | Lamarckian update |
| **Replace** | Generational | Track global best |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Pablo Moscato (1989) introduced memetic algorithms as a marriage of
population-based global search with heuristic local refinement performed by
individuals — inspired by Darwinian evolution and Dawkins’ *meme*. Lamarckian
learning writes the improved solution back into the genotype; Baldwinian
learning would keep the genotype and only use the improved fitness. This
package implements the Lamarckian educational variant. MAs balance EA
exploration with local exploitation; like other metaheuristics they do not
guarantee a global optimum.

## Algorithm

Initialize a population of size $P$, evaluate costs, optionally locally
improve each individual. For each generation $g=1..G$:

1. **Select** two parents by $k$-tournament on cost (lower is better).
2. **Crossover** → **mutate** to form an offspring.
3. **Locally improve** the offspring (all offspring, or elites-only half)
   for up to $t_{\mathrm{il}}$ improving steps (steepest or first-improvement).
4. Place offspring into the next population (generational replacement).
5. Track the globally best cost / individual.

### OneMax / Hamming (bits)

Cost for OneMax as minimization of zeros:

$$
f(x)=n-\sum_{i=1}^{n} x_i,\qquad x\in\{0,1\}^n.
$$

Hamming cost to a target $t$ is $f(x)=d_H(x,t)$. Neighborhood for local
search is single bit-flip:

$$
N(x)=\{x\oplus e_i:1\le i\le n\}.
$$

One-point crossover with cut $c\in\{0,\ldots,n\}$ copies $x_{1..c}$ from
parent A and $x_{c+1..n}$ from parent B. Mutation flips each bit
independently with probability $p_m$.

### Tiny TSP

Tour length on $m$ cities:

$$
L(\pi)=\sum_{k=1}^{m-1} d(\pi_k,\pi_{k+1})+d(\pi_m,\pi_1).
$$

Variation uses **order crossover** (OX) and swap mutation. Local search is
**2-opt** (reverse segment $\pi(i+1..j)$), steepest or first-improvement.

Defaults: $P=20$, $G=50$, $p_m=0.05$, $t_{\mathrm{il}}=10$, $k=3$.

## Built-in demos

| Driver | Domain | Notes |
| --- | --- | --- |
| `Minimize_OneMax` | Bit-strings | Maximize ones ≡ minimize zeros |
| `Minimize_Hamming` | Bit-strings | Match a target pattern |
| `Minimize_TSP` | Tours $m\le 10$ | OX + swap + 2-opt LS |

## API (`Memetic_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Config`, `Result`, `Bit_String`, `Tour`, `Bit_Result`, `TSP_Result` | $P$, $G$, $p_m$, $t_{\mathrm{il}}$, seed |
| Helpers | `Near`, `Default_Config`, `Config_Is_Valid` | Tolerance / validation |
| RNG (LCG) | `Seed_RNG`, `Next_Unit`, `Next_Natural` | Reproducible draws |
| Bits | `Hamming_Distance`, `Zero_Count` / `Ones_Count`, `Flip_Bit` | Utilities |
| EA ops | `Tournament_Pick`, `One_Point_Crossover`, `Mutate_Bits` | Variation |
| Local improve | `Local_Improve`, `Local_Improve_Bits`, `Local_Improve_TSP` | Lamarckian LS |
| TSP | `Tour_Length`, `Apply_2Opt`, `Order_Crossover`, `Mutate_Tour` | Permutation MA |
| Drivers | `Minimize_OneMax`, `Minimize_Hamming`, `Minimize_TSP` | Full runs |
| Pack | `To_Result` | Shared `Result` view |

Named exception: `Invalid_Argument` (bad config, length mismatch, etc.).

## Usage

```ada
with Memetic_Algorithm; use Memetic_Algorithm;

declare
   Cfg : constant Config :=
     Default_Config (Pop_Size => 16, Generations => 30, Seed => 1);
   R   : Bit_Result;
   T   : TSP_Result;
   D   : Dist_Matrix (1 .. 4, 1 .. 4);
begin
   R := Minimize_OneMax (12, Cfg);
   -- fill D ...
   T := Minimize_TSP (D, Cfg);
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
| `memetic_algorithm.ads` | Package spec |
| `memetic_algorithm.adb` | Package body |
| `memetic_algorithm.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- [Wikipedia: Memetic algorithm](https://en.wikipedia.org/wiki/Memetic_algorithm)
- Moscato, P. (1989). *On Evolution, Search, Optimization, Genetic Algorithms
  and Martial Arts: Towards Memetic Algorithms*. Caltech Concurrent
  Computation Program, Report 826.
- Krasnogor, N.; Smith, J. A tutorial for competent memetic algorithms.
- Sibling: [Ada-Local-Search](../ada-local-search/)
- Sibling: [Ada-Tabu-Search](../ada-tabu-search/)
- Sibling: [Ada-Random-Restart-Hill-Climbing](../ada-random-restart-hill-climbing/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
