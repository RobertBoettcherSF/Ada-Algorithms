# Tournament Selection — Ada 2023

Educational, self-contained Ada 2023 package implementing **tournament
selection** — a selection operator for evolutionary algorithms. Draw
$K$ contestants from the population (with or without replacement), then
return the fittest (**deterministic** tournament, $P = 1$) or a
**soft-tournament** pick: the contestant of rank $r$ (best $= 0$) is
chosen with probability $P\cdot(1-P)^{r}$, the last rank absorbing the
residual mass.

Selection pressure is controlled by $K$: **$K = 1$ is equivalent to
uniform random selection**; larger $K$ raises the chance that a strong
individual wins the bout.

Based on [Wikipedia: Tournament selection](https://en.wikipedia.org/wiki/Tournament_selection).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)** —
  rank / truncate / uniform sample from elite pool
- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  Lamarckian EA + local search (uses $k$-tournament today)
- **Stochastic universal sampling** — forthcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Draw** | $K$ contestants | With or without replacement |
| **Winner** | Best of bout, or soft ranks | $P=1$ deterministic |
| **Pressure** | Larger $K$ $\Rightarrow$ higher | $K=1\equiv$ random |
| **Sense** | `Maximize` or `Minimize` | Higher better / lower cost |
| **Config** | $K$, $P$, replacement, sense, seed | `Valid_Config` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |
| **Validate** | Non-empty pop; $K\le N$ w/o repl. | `Invalid_Argument` |

## Brief history

Tournament selection runs many small “tournaments” among randomly chosen
individuals; the winner of each bout is selected for recombination.
Unlike fitness-proportionate selection it needs no fitness scaling, is
easy to parallelize, and lets practitioners dial selection pressure by
changing the tournament size $K$. Soft tournaments ($P < 1$) occasionally
promote runners-up, easing premature convergence.

## Algorithm

Given population size $N$, tournament size $K\ge 1$, soft probability
$P\in[0,1]$, a replacement flag, and a fitness sense:

1. **Draw** $K$ contestants from the population:
   - **with replacement** — independent uniform indices (duplicates OK);
   - **without replacement** — $K$ distinct indices (requires $K\le N$).
2. **Rank** the contestants so rank $r=0$ is the best under the sense.
3. **Pick** the winner:
   - if $P = 1$ (deterministic), return the best contestant;
   - otherwise (soft), choose rank $r$ with
     $$
     \Pr(r)=P\cdot(1-P)^{r}
     \qquad\text{for }r=0,\ldots,K-2,
     $$
     and assign the residual probability $(1-P)^{K-1}$ to rank $K-1$.

For maximize, individual $a$ beats $b$ when $f(a)>f(b)$; for minimize,
when $f(a)<f(b)$. When $K=1$ the single drawn individual always wins
(random selection). As $K$ grows, weak individuals are less likely to
survive a bout that also contains a stronger peer.

## API (`Tournament_Selection`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Individual` (Fitness, Tag), `Population`, `Index_List`, `Fitness_Sense` | Carriers / maximize–minimize |
| Config | `Config`, `Default_Config`, `Make_Config`, `Valid_Config` | $K$, $P$, replacement, sense, seed |
| Helpers | `Near`, `Better`, `Better_Or_Equal` | Tolerance / comparison |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Natural` | Seeded LCG |
| Draw | `Draw_Contestants` | $K$ indices w/ or w/o replacement |
| Soft | `Soft_Pick` | Ranked soft / deterministic pick |
| Select | `Tournament_Winner`, `Select_One`, `Select_Parents` | Bout → index / individual / batch |

Named exception: `Invalid_Argument` (empty population, $K>N$ without
replacement, out-of-range contestant indices, etc.).

## Usage

```ada
with Tournament_Selection; use Tournament_Selection;

declare
   Pop : Population :=
     ((Fitness => 1.0, Tag => 1),
      (Fitness => 5.0, Tag => 2),
      (Fitness => 3.0, Tag => 3),
      (Fitness => 4.0, Tag => 4));
   Cfg   : constant Config :=
     Make_Config (K => 3, P => 1.0, With_Replacement => True,
                  Sense => Maximize, Seed => 42);
   State : RNG_State;
   Win   : Individual;
begin
   Seed_RNG (State, Cfg);
   Win := Select_One (Pop, Cfg, State);
   --  deterministic 3-tournament; larger K biases toward Tag 2
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
| `tournament_selection.ads` | Package spec |
| `tournament_selection.adb` | Package body |
| `tournament_selection.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- [Wikipedia: Tournament selection](https://en.wikipedia.org/wiki/Tournament_selection)
- Sibling: [Ada-Truncation-Selection](https://github.com/RobertBoettcherSF/Ada-Truncation-Selection)
- Sibling: [Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)
- Sibling: Stochastic universal sampling (forthcoming)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
