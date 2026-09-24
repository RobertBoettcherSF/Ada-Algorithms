# Truncation Selection — Ada 2023

Educational, self-contained Ada 2023 package implementing **truncation
selection** — a selection operator for evolutionary algorithms and a
classical method in animal / plant breeding. Individuals are ranked by
fitness; a top fraction $T$ (or top $K$) forms a breeding pool; parents
are then sampled **uniformly with replacement** from that truncated pool.

Based on [Wikipedia: Truncation selection](https://en.wikipedia.org/wiki/Truncation_selection)
(used e.g. in Mühlenbein’s breeder genetic algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **Tournament selection** — forthcoming
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  Lamarckian EA + local search (uses $k$-tournament today)
- **Stochastic universal sampling** — forthcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Rank** | Stable insertion sort by fitness | Best first |
| **Sense** | `Maximize` or `Minimize` | Higher better / lower cost |
| **Truncate** | Keep top $K=\lceil T\cdot N\rceil$ | Or explicit $K$ |
| **Sample** | Uniform with replacement | From truncated pool only |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |
| **Validate** | $T\in(0,1]$, non-empty pop | `Invalid_Argument` |

## Brief history

In animal and plant breeding, truncation selection ranks individuals by a
phenotypic trait and reproduces the top percentage. In evolutionary
computation the same idea selects candidate solutions for recombination:
order by fitness, keep proportion $T$ of the fittest, and reproduce from
that set at random. It is simple and strong selection pressure; diversity
can collapse quickly when $T$ is small.

## Algorithm

Given population size $N$, truncation threshold $T\in(0,1]$, and a fitness
sense (maximize or minimize):

1. **Rank** the population so the best individual is first.
2. **Truncate:** keep the top
   $$
   K=\lceil T\cdot N\rceil
   $$
   individuals (clamped to $[1,N]$) as the breeding pool. Equivalently,
   keep an explicit top-$K$ set.
3. **Sample** each parent independently and uniformly from the $K$ elites
   (with replacement).

For maximize, individual $a$ beats $b$ when $f(a)>f(b)$; for minimize,
when $f(a)<f(b)$. Ties keep their relative order (stable sort).

## API (`Truncation_Selection`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Individual` (Fitness, Tag), `Population`, `Index_List`, `Fitness_Sense` | Carriers / maximize–minimize |
| Helpers | `Near`, `Valid_T`, `Better`, `Better_Or_Equal` | Tolerance / comparison |
| Size | `Truncation_Count(N,T)` | $K=\lceil T\cdot N\rceil$ |
| Rank | `Sort_By_Fitness` (proc + fn) | Best-first ordering |
| Pool | `Select_Pool` (by $T$ or by $K$) | Truncated breeding set |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Natural` | Seeded LCG |
| Sample | `Select_Parent_Index`, `Select_Parents` | Uniform with replacement |

Named exception: `Invalid_Argument` (empty population, $T\notin(0,1]$, etc.).

## Usage

```ada
with Truncation_Selection; use Truncation_Selection;

declare
   Pop  : Population :=
     ((Fitness => 1.0, Tag => 1),
      (Fitness => 5.0, Tag => 2),
      (Fitness => 3.0, Tag => 3),
      (Fitness => 4.0, Tag => 4));
   Pool : Population := Select_Pool (Pop, 0.5, Maximize);
   --  K = ceil(0.5*4) = 2  →  elites Tag 2 then 4
   State : RNG_State;
   Idx   : Positive;
begin
   Seed_RNG (State, 1);
   Idx := Select_Parent_Index (Pool, State);
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
| `truncation_selection.ads` | Package spec |
| `truncation_selection.adb` | Package body |
| `truncation_selection.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- [Wikipedia: Truncation selection](https://en.wikipedia.org/wiki/Truncation_selection)
- Mühlenbein, H.; Schlierkamp-Voosen, D. Predictive Models for the Breeder
  Genetic Algorithm. *Evolutionary Computation* 1(1):25–49 (1993).
- Sibling: Tournament selection (forthcoming)
- Sibling: [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)
- Sibling: Stochastic universal sampling (forthcoming)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
