# Local Search (Optimization) — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Local search (optimization)](https://en.wikipedia.org/wiki/Local_search_(optimization)):
candidate solutions, **neighborhoods**, **steepest** and **first-improvement**
hill climbing on bit-flip OneMax / Hamming, a **random-restart** wrapper, an
**iterated local search** sketch (climb → perturb → climb → accept if better),
and **2-opt** local search for tiny TSP. A **method taxonomy** flags
Hill_Climbing / Random_Restart / Iterated_Local_Search (implemented) and
Tabu / Simulated_Annealing / Random_Search (metadata only — see sibling
solver repos).

Local search moves from solution to solution in a discrete search space by
applying local changes until a local optimum (or time bound) is reached. When
the neighbor is chosen greedily to maximize (or minimize) the criterion, the
method is **hill climbing**. Restarts, randomization, and iterated schemes
address the local-optima problem.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling solvers (links
only — **not** build dependencies):

- [Ada-Tabu-Search](https://github.com/RobertBoettcherSF/Ada-Tabu-Search)
- [Ada-Random-Restart-Hill-Climbing](https://github.com/RobertBoettcherSF/Ada-Random-Restart-Hill-Climbing)
- [Ada-Simulated-Annealing](https://github.com/RobertBoettcherSF/Ada-Simulated-Annealing)
- [Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search)
- [Ada-Stochastic-Tunneling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Tunneling)

Style siblings: `ada-nonlinear-optimization`, `ada-nearest-neighbor-search`.

Educational limits: bits $n\le 32$, cities $m\le 10$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **States** | Bit-strings / TSP tours | Helpers + `Near` / `Config` / `Result` |
| **Steepest HC** | Full neighborhood, best flip | OneMax / Hamming |
| **First-improve HC** | First improving flip | Scan order $1..n$ |
| **Random restart** | Few random starts | Keep globally best local opt |
| **ILS sketch** | Climb → perturb → climb | Accept if strictly better |
| **2-opt TSP** | Steepest edge exchange | Tiny $m\le 10$ |
| **Taxonomy** | `Method_Kind` | Tabu / SA / RS = flags only |

## Formula summary

### Neighborhoods

For a bit-string $x\in\{0,1\}^n$, the **bit-flip** neighborhood is

$$
N(x)=\{x\oplus e_i:1\le i\le n\},
$$

where $e_i$ flips bit $i$. Cost for **OneMax** (minimization of zeros) is
$f(x)=n-\sum_i x_i$; for **Hamming** to a target $t$, $f(x)=d_H(x,t)$.

For a tour $\pi$ on $m$ cities, a **2-opt** move with indices $i<j$ reverses
the segment $\pi(i+1..j)$. Tour length is

$$
L(\pi)=\sum_{k=1}^{m-1} d(\pi_k,\pi_{k+1})+d(\pi_m,\pi_1).
$$

### Hill climbing

**Steepest descent**: at each step move to $\arg\min_{y\in N(x)} f(y)$ if it
strictly improves; stop at a local optimum ($N(x)$ has no improving neighbor)
or after a step budget. **First-improvement**: take the first improving
neighbor in scan order.

### Random restart / ILS

Random-restart runs independent climbs from random starts and keeps the best
local optimum. Iterated local search (sketch here): from a local optimum,
**perturb** $k$ bits, climb again, and **accept** the new local optimum only
if $f$ is strictly better.

Local search is typically incomplete: termination at a local optimum does not
imply global optimality.

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Bits`, `Max_Cities` | Caps |
| Types | `Config`, `Result`, `Bit_String`, `Tour`, `Bit_Result`, `TSP_Result` | Domain |
| Helpers | `Near`, `Default_Config`, `Hamming_Distance`, `Zero_Count` / `Ones_Count` | Utilities |
| Neighborhood | `Flip_Bit`, `Apply_2Opt`, `Is_Local_Optimum_*` | Moves / tests |
| Steepest | `Steepest_Climb_OneMax` / `_Hamming` | Full-neighborhood HC |
| First-improve | `First_Improve_OneMax` / `_Hamming` | First improving flip |
| Restarts | `Random_Restart_OneMax` / `_Hamming` / `_TSP` | Multi-start wrapper |
| ILS | `Perturb_Bits`, `Iterated_Local_Search_*` | Climb–perturb–climb |
| TSP | `Tour_Length`, `Two_Opt_Local_Search`, `Identity_Tour` / `Random_Tour` | 2-opt LS |
| Taxonomy | `Method_Kind`, `Classify_Method`, `Method_Name` | Metadata flags |
| Pack | `To_Result` | Shared `Result` view |

Strong typing uses `Real` (digits 15) and capacity subtypes. Public
subprograms carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exception: `Invalid_Argument`.

## Usage

```ada
with Local_Search; use Local_Search;

declare
   Cfg : constant Config := Default_Config (Max_Restarts => 5, Seed => 1);
   R   : Bit_Result;
   T   : TSP_Result;
   D   : Dist_Matrix (1 .. 4, 1 .. 4);
begin
   R := Steepest_Climb_OneMax (All_Zeros (8), Cfg);
   R := First_Improve_Hamming (All_Zeros (6), All_Ones (6), Cfg);
   R := Random_Restart_OneMax (10, Cfg);
   R := Iterated_Local_Search_OneMax (All_Zeros (8), Cfg);
   -- fill D ...
   T := Two_Opt_Local_Search (D, Identity_Tour (4), Cfg);
end;
```

## Build / test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Plocal_search.gpr`. Main program is
`tests.adb` (no `main.adb`). Expect **zero** warnings and `Fail_Count = 0`
with `Pass_Count ≥ 100`.

## Layout

| File | Role |
| --- | --- |
| `local_search.ads` | Package spec |
| `local_search.adb` | Package body |
| `local_search.gpr` | GNAT project (main = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom Check suite (`Fail_Count`, no Ada.Assertions API) |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

Root-only layout (exactly 7 files; no `src/`, no separate `main.adb`).

## References

- Wikipedia: [Local search (optimization)](https://en.wikipedia.org/wiki/Local_search_(optimization)).
- Wikipedia: [Hill climbing](https://en.wikipedia.org/wiki/Hill_climbing).
- Wikipedia: [2-opt](https://en.wikipedia.org/wiki/2-opt).
- Hoos, H.H. and Stützle, T. (2005). *Stochastic Local Search: Foundations and Applications*. Morgan Kaufmann.
- Lourenço, H.R.; Martin, O.; Stützle, T. Iterated Local Search.

## Related packages

- **[Ada-Tabu-Search](https://github.com/RobertBoettcherSF/Ada-Tabu-Search)** —
  memory-based escape from local optima (link only).
- **[Ada-Random-Restart-Hill-Climbing](https://github.com/RobertBoettcherSF/Ada-Random-Restart-Hill-Climbing)** —
  shotgun / multi-start HC (link only).
- **[Ada-Simulated-Annealing](https://github.com/RobertBoettcherSF/Ada-Simulated-Annealing)** —
  temperature schedule acceptance (link only).
- **[Ada-Random-Search](https://github.com/RobertBoettcherSF/Ada-Random-Search)** —
  pure random sampling baseline (link only).
- **[Ada-Stochastic-Tunneling](https://github.com/RobertBoettcherSF/Ada-Stochastic-Tunneling)** —
  nonlinear cost transform for tunneling (link only).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
