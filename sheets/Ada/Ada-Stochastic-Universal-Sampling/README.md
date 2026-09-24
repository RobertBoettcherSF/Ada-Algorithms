# Stochastic Universal Sampling — Ada 2023

Educational, self-contained Ada 2023 package implementing **stochastic
universal sampling (SUS)** — James Baker’s fitness-proportionate selection
operator for evolutionary algorithms. Unlike classic roulette-wheel FPS,
which draws $N$ independent samples, SUS places $N$ evenly spaced pointers
on the fitness wheel after a single random offset. This yields **no bias**
and **minimal spread**: weaker members keep a proportional chance, and a
single very fit individual cannot saturate the candidate set beyond its
share.

Also provides **classic FPS roulette** (`Select_Roulette`) for contrast
tests (higher sampling variance).

Based on [Wikipedia: Stochastic universal sampling](https://en.wikipedia.org/wiki/Stochastic_universal_sampling).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  rank / truncate / uniform sample from elite pool
- **[Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)** —
  $K$-tournament (deterministic or soft)
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  Lamarckian EA + local search

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Fitness** | Non-negative proportionate | Or shift costs → fitness |
| **SUS** | Baker: Start $+\,i\cdot P$ | $P=F/N$, Start $\sim U(0,P)$ |
| **Map** | RWS / cumulative wheel | `Map_Pointer` |
| **Roulette** | Independent $U(0,F)$ | Higher variance contrast |
| **Config** | Seed | `Make_Config` / `Valid_Config` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |
| **Validate** | $F>0$, fitness $\ge 0$ | `Invalid_Argument` |

## Brief history

Fitness-proportionate selection (FPS / roulette wheel) samples parents
with probability proportional to fitness. Repeated independent draws have
high variance and can let one outstanding individual dominate. Baker’s
**stochastic universal sampling** (1987) uses a comb of evenly spaced
pointers after one random start, guaranteeing low spread while remaining
unbiased. It is a standard parent-selection operator in genetic algorithms.

## Algorithm

Given population size $M$, offspring count $N\ge 1$, and non-negative
fitnesses $f_i$ with total $F=\sum_i f_i>0$:

1. **Require** $f_i\ge 0$ (or convert costs via
   $\mathrm{fitness}_i=\max_j c_j-c_i$; equal costs $\Rightarrow$ all $1$).
2. Build the cumulative wheel $C_i=\sum_{j=1}^{i}f_j$.
3. Pointer spacing $P=F/N$; draw Start $\sim\mathrm{Uniform}[0,P)$.
4. Pointers $\mathrm{Start}+i\cdot P$ for $i=0,\ldots,N-1$.
5. Map each pointer through RWS: smallest $I$ with $C_I\ge$ pointer.

In symbols:
$$
P=\frac{F}{N},\qquad
\mathrm{Pointers}=\{\mathrm{Start}+i\cdot P\mid i=0,\ldots,N-1\}.
$$

Classic roulette instead draws $N$ independent uniforms on $[0,F)$ and
maps each the same way — unbiased in expectation, but with larger
count variance.

When all $f_i$ are equal and $N=k\cdot M$, SUS selects each individual
exactly $k$ times.

## API (`Stochastic_Universal_Sampling`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Individual` (Fitness, Tag), `Population`, `Index_List`, `Fitness_Array` | Carriers / cumulants |
| Config | `Config`, `Default_Config`, `Make_Config`, `Valid_Config` | Seed / sanity |
| Helpers | `Near`, `All_Non_Negative`, `Total_Fitness` | Tolerance / sums |
| Shift | `Shift_Costs_To_Fitness` | Costs → non-neg. fitness |
| Wheel | `Cumulative_Fitness`, `Map_Pointer` | RWS helper |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Real`, `Next_Natural` | Seeded LCG |
| Select | `Select_SUS`, `Select_Roulette` | Baker SUS / classic FPS |

Named exception: `Invalid_Argument` (empty population, negative fitness,
zero total fitness, empty cumulative, etc.).

## Usage

```ada
with Stochastic_Universal_Sampling; use Stochastic_Universal_Sampling;

declare
   Pop : Population :=
     ((Fitness => 1.0, Tag => 1),
      (Fitness => 2.0, Tag => 2),
      (Fitness => 3.0, Tag => 3),
      (Fitness => 4.0, Tag => 4));
   Cfg   : constant Config := Make_Config (Seed => 42);
   State : RNG_State;
   Kids  : Index_List (1 .. 4);
begin
   Kids := Select_SUS (Pop, 4, Cfg, State);
   --  equal spacing on the wheel; low-spread proportionate sample
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
| `stochastic_universal_sampling.ads` | Package spec |
| `stochastic_universal_sampling.adb` | Package body |
| `stochastic_universal_sampling.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- [Wikipedia: Stochastic universal sampling](https://en.wikipedia.org/wiki/Stochastic_universal_sampling)
- Baker, J. E. (1987). Reducing bias and inefficiency in the selection algorithm.
- Sibling: [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)
- Sibling: [Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)
- Sibling: [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
