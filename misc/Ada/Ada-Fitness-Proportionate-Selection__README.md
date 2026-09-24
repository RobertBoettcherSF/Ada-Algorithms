# Fitness Proportionate Selection — Ada 2023

Educational, self-contained Ada 2023 package implementing **fitness
proportionate selection (FPS)** — also called **roulette-wheel** or
**spinning-wheel** selection — for evolutionary algorithms. Each
individual $i$ is chosen with probability proportional to its
non-negative fitness $f_i$. Parents are drawn by spinning an independent
$\mathrm{Uniform}(0,F)$ pointer on the cumulative fitness wheel for every
selection.

Compared with [Baker’s stochastic universal sampling
(SUS)](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling),
classic FPS uses **independent** draws and therefore has **higher
sampling spread / variance**: one outstanding individual can dominate a
batch more often, and weaker members may be under- or over-represented
relative to their share.

Based on [Wikipedia: Fitness proportionate
selection](https://en.wikipedia.org/wiki/Fitness_proportionate_selection).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)** —
  Baker SUS (evenly spaced pointers; lower spread)
- **[Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)** —
  $K$-tournament (deterministic or soft)
- **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  rank / truncate / uniform sample from elite pool

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Fitness** | Non-negative proportionate | Or shift costs → fitness |
| **Probability** | $p_i=f_i/\sum_j f_j$ | `Selection_Probability` |
| **Wheel** | Cumulative $C_i=\sum_{j\le i}f_j$ | `Cumulative_Fitness` |
| **Draw** | Independent $U(0,F)$ | Higher variance than SUS |
| **Map** | RWS / smallest $I$ with $C_I \ge$ pointer | `Map_Pointer` |
| **Config** | Seed | `Make_Config` / `Valid_Config` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |
| **Validate** | $F>0$, fitness $\ge 0$ | `Invalid_Argument` |

## Brief history

Fitness-proportionate selection (roulette wheel) assigns each candidate a
sector of a wheel whose width is proportional to fitness, then “spins”
once per parent. It preserves a chance for weaker solutions to survive —
useful when they carry valuable genetic material — but independent spins
introduce stochastic noise. In practice, operators with lower spread such
as **SUS**, tournament selection, or truncation are often preferred.

## Algorithm

Given population size $M$ and non-negative fitnesses $f_i$ with total
$F=\sum_i f_i>0$:

1. **Require** $f_i\ge 0$ (or convert costs via
   $\mathrm{fitness}_i=\max_j c_j-c_i$; equal costs $\Rightarrow$ all $1$).
2. Selection probabilities
$$
p_i=\frac{f_i}{\sum_{j=1}^{M}f_j}=\frac{f_i}{F}.
$$
3. Build the cumulative wheel $C_i=\sum_{j=1}^{i}f_j$ (so $C_M=F$).
4. For each parent: draw $U\sim\mathrm{Uniform}[0,F)$ and select the
   smallest index $I$ with $C_I\ge U$.

Selecting $N$ parents is equivalent to $N$ independent spins. SUS instead
places $N$ evenly spaced pointers after one random offset, reducing
spread while remaining unbiased in expectation.

Example (Wikipedia): fitnesses $[1,2,3,4]$ give $F=10$ and probabilities
$[0.1,0.2,0.3,0.4]$ with cumulative thresholds
$[0.1,0.3,0.6,1.0]$.

## API (`Fitness_Proportionate_Selection`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Individual` (Fitness, Tag), `Population`, `Index_List`, `Fitness_Array` | Carriers / cumulants |
| Config | `Config`, `Default_Config`, `Make_Config`, `Valid_Config` | Seed / sanity |
| Helpers | `Near`, `All_Non_Negative`, `Total_Fitness` | Tolerance / sums |
| Prob | `Selection_Probability` | $p_i=f_i/F$ |
| Shift | `Shift_Costs_To_Fitness` | Costs → non-neg. fitness |
| Wheel | `Cumulative_Fitness`, `Map_Pointer` | RWS helper |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Real`, `Next_Natural` | Seeded LCG |
| Select | `Select_One`, `Select_Parents` | One spin / batch of spins |

Named exception: `Invalid_Argument` (empty population, negative fitness,
zero total fitness, bad index, empty cumulative, etc.).

## Usage

```ada
with Fitness_Proportionate_Selection; use Fitness_Proportionate_Selection;

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
   Kids := Select_Parents (Pop, 4, Cfg, State);
   --  four independent roulette spins on the cumulative wheel
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
| `fitness_proportionate_selection.ads` | Package spec |
| `fitness_proportionate_selection.adb` | Package body |
| `fitness_proportionate_selection.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## Caveats

- Fitness must be **non-negative** and total $F>0$; otherwise selection
  raises `Invalid_Argument`. Use `Shift_Costs_To_Fitness` for cost-like
  objectives.
- Independent spins ⇒ **higher spread** than SUS; a single elite can
  appear many times in one parent batch by chance.
- Zero-fitness individuals have $p_i=0$ and are never selected (unless
  every fitness is shifted to a constant positive value).
- The bundled LCG is for **reproducible education/tests**, not
  cryptographic randomness.

## References

- [Wikipedia: Fitness proportionate selection](https://en.wikipedia.org/wiki/Fitness_proportionate_selection)
- Sibling: [Ada-Stochastic-Universal-Sampling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Universal-Sampling)
- Sibling: [Ada-Tournament-Selection](https://github.com/RobertBoettcherSF/Ada-Tournament-Selection)
- Sibling: [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
