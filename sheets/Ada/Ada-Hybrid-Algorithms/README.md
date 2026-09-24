# Hybrid Algorithms — Ada 2023 (Educational Survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Hybrid algorithm](https://en.wikipedia.org/wiki/Hybrid_algorithm):
algorithms that combine two or more methods that solve the **same** problem,
either **switching by a data characteristic** (e.g. size) or **switching over
the course of the run**, so the hybrid inherits desirable traits of each
component (average speed, worst-case guarantees, small-$n$ efficiency,
exploration vs exploitation).

This is **not** “glue any subroutines together”: Wikipedia reserves the term
for combining alternative solvers of one problem that differ in performance
characteristics.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling packages
(links only — **not** build dependencies):

- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  population EA + individual local search (Lamarckian MA)
- **[Ada-GRASP](https://github.com/RobertBoettcherSF/Ada-GRASP)** —
  greedy randomized construction + local search multi-start
- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  population selection / crossover / mutation survey
- **[Ada-Local-Search](https://github.com/RobertBoettcherSF/Ada-Local-Search)** —
  steepest / first-improvement hill climbing, ILS, 2-opt

Educational limits: sort $n\le 256$; knapsack $n\le 20$ (exhaustive $n\le 16$);
bits $n\le 32$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Definition** | Same-problem algorithm combination | Wikipedia hybrid |
| **Switch_By_Size** | Introsort-like sort | Quick + heap + insertion cutoff |
| **Exact_Then_Heuristic** | Size-switch knapsack | Exhaustive if $n\le N_0$ else greedy |
| **Memetic_GA_Local** | One-step MA sketch | Random candidate + hill climb |
| **Grasp_Construct_LS** | Mini construct+LS | RCL density + flip LS |
| **Portfolio_Select** | Run two, keep best | Greedy vs construct+LS |
| **Taxonomy** | `Hybrid_Kind` | Implemented vs Forthcoming tags |
| **RNG** | Seeded 32-bit LCG | Reproducible stochastic sketches |

## Definition

A **hybrid algorithm** combines algorithms $A_1,\ldots,A_k$ that each solve the
same problem $P$, choosing among them by a predicate on the instance (or on
progress) so that the composite $H$ is “better” on the relevant metric than
any single $A_i$ alone. Classic performance hybrids include:

- **Size short-circuit:** use algorithm $A_{\mathrm{small}}$ when the remaining
  subproblem size is below a threshold $T$, else $A_{\mathrm{large}}$
  (insertion sort under merge/quick; Timsort; arm’s-length recursion).
- **Introspection:** start with a fast average-case method (quicksort /
  quickselect) and fall back to a worst-case optimal method (heapsort /
  median-of-medians) when progress is poor (**introsort** / **introselect**).
- **Metaheuristic hybrids:** evolutionary global search plus local
  improvement (**memetic**); greedy randomized construction plus local
  search (**GRASP**); solver **portfolios** that pick the best of several runs.

### Taxonomy (`Hybrid_Kind`)

| Kind | Role | Status here |
| --- | --- | --- |
| `Switch_By_Size` | Cutoff / introsort-style | **Implemented** (`Hybrid_Sort`) |
| `Exact_Then_Heuristic` | Exact tiny $n$, else heuristic | **Implemented** (`Size_Switch_Knapsack`) |
| `Memetic_GA_Local` | Candidate + individual LS | **Implemented** (one-step sketches) |
| `Grasp_Construct_LS` | Construct then LS | **Implemented** (mini multi-start) |
| `Portfolio_Select` | Several solvers → best | **Implemented** (`Portfolio_Knapsack`) |

`Classify` / `Implemented` / `Forthcoming` expose the tags for demos and tests.

## Implemented sketches

### 1. Introsort-like `Hybrid_Sort` (`Switch_By_Size`)

On array $a[1..n]$ with insertion threshold $T$ (default $16$):

1. If $n\le T$, **insertion sort** the slice (efficient on tiny data).
2. Else **quicksort** with median-of-three pivot, recursion depth budget
   $2\lfloor\log_2 n\rfloor$.
3. If the depth budget is exhausted, **heapsort** that slice (worst-case
   $O(n\log n)$ insurance — the introsort idea).

`Sort_Stats` records `Insertion_Segments`, `Heap_Fallbacks`,
`Quick_Partitions`, and `Max_Recursion_Depth` so tests can assert that
insertion runs below the threshold.

Asymptotically, well-tuned hybrids aim for average-case speed close to
quicksort with heapsort’s $O(n\log n)$ worst-case ceiling:

$$
T_{\mathrm{intro}}(n)=O(n\log n)\quad\text{(worst case)}.
$$

### 2. Size-switch knapsack (`Exact_Then_Heuristic`)

0-1 knapsack: maximize $\sum_i v_i x_i$ subject to $\sum_i w_i x_i\le C$,
$x_i\in\{0,1\}$.

$$
\texttt{Size\_Switch}(n)=
\begin{cases}
\text{exhaustive }2^{n} & \text{if }n\le N_0,\\
\text{greedy by }v_i/w_i & \text{otherwise.}
\end{cases}
$$

Default $N_0=12$. **Quality tradeoff:** greedy density is $O(n\log n)$ after
sorting but can miss the optimum (classic counter-example in tests: capacity
$10$, items $(7,9),(5,5),(5,5)$ → greedy value $9$, exhaustive $10$).
Document `Exact` / `Used_Greedy` flags on `Knapsack_Result`.

### 3. Memetic one-step (`Memetic_GA_Local`)

Educational **one-step** Lamarckian sketch (not a full population MA — see
sibling Ada-Memetic-Algorithm):

1. Sample a random bit-string (OneMax) or random feasible knapsack packing.
2. **Steepest hill-climb** in the bit-flip / item-flip neighborhood for up to
   `Local_Search_Steps` improving moves.

OneMax cost (minimize zeros):

$$
f(x)=n-\sum_{i=1}^{n}x_i,\qquad
N(x)=\{x\oplus e_i:1\le i\le n\}.
$$

### 4. Construct + local search (`Grasp_Construct_LS`)

Mini multi-start without a package dependency on Ada-GRASP: each iteration
builds a feasible packing via a density **RCL** with parameter
$\alpha\in[0,1]$ ($\alpha=0$ pure greedy, $\alpha=1$ uniform among feasible),
then hill-climbs; keep the best over `Max_Iterations`.

RCL threshold (maximize density):

$$
\tau=\mathrm{max}-\alpha\,(\mathrm{max}-\mathrm{min}).
$$

### 5. Portfolio (`Portfolio_Select`)

Run **greedy density** and **one** construct+LS start; return the better
value (ties broken by lighter weight). Illustrates algorithm portfolios at
toy scale.

## API (`Hybrid_Algorithms`)

| Symbol | Role |
| --- | --- |
| `Hybrid_Kind` / `Classify` / `Hybrid_Name` | Taxonomy + Implemented/Forthcoming |
| `Config` / `Default_Config` | Thresholds, $\alpha$, seeds, budgets |
| `RNG_State` / `Seed_RNG` / `Next_Unit` / `Next_Natural` | Seeded LCG |
| `Hybrid_Sort` / `Hybrid_Sort_Copy` / `Sort_Stats` | Introsort-like hybrid |
| `Insertion_Sort_Range` / `Heap_Sort_Range` / `Is_Sorted` | Building blocks |
| `Knapsack_Exhaustive` / `Knapsack_Greedy_Density` | Exact vs density heuristic |
| `Size_Switch_Knapsack` | Exact-then-heuristic by $n$ |
| `Hill_Climb_OneMax` / `Memetic_One_Step_OneMax` | Bit memetic one-step |
| `Hill_Climb_Knapsack` / `Memetic_One_Step_Knapsack` | Knapsack memetic one-step |
| `Construct_Local_Search_Knapsack` | Mini GRASP-style hybrid |
| `Portfolio_Knapsack` | Two-solver portfolio |
| `Near` / bit & knapsack helpers | Utilities |

## Build / test

```bash
make        # gnatmake -gnatwa -gnat2022 -Phybrid_algorithms.gpr
make test   # runs bin/tests — expect ALL PASSED, Fail_Count=0, Pass_Count 80+
make clean
```

Root layout (exactly **7** files; no `main.adb`, no `src/`):

| File | Role |
| --- | --- |
| `hybrid_algorithms.ads` | Package spec |
| `hybrid_algorithms.adb` | Package body |
| `hybrid_algorithms.gpr` | GNAT project (`Main` = `tests.adb`) |
| `Makefile` | `all` / `test` / `clean` |
| `tests.adb` | Custom `Check` suite |
| `README.md` | This document |
| `.gitignore` | `obj/`, `bin/` |

## Limits / caveats

- **Educational caps** only — not production introsort/Timsort, not a full MA
  or GRASP library (see siblings).
- Exhaustive knapsack is $O(2^n)$; keep $n\le 16$.
- Greedy density and construct+LS are **incomplete**; `Exact=False` means the
  returned value may be suboptimal.
- Stochastic sketches use a tiny LCG; always pass an explicit `Seed` in tests.
- LaTeX in this README uses `$...$` / `$$...$$` only (raw strings / doubled
  backslashes if you regenerate math from a string processor).

## References

- Wikipedia: [Hybrid algorithm](https://en.wikipedia.org/wiki/Hybrid_algorithm).
- Wikipedia: [Introsort](https://en.wikipedia.org/wiki/Introsort).
- Wikipedia: [Memetic algorithm](https://en.wikipedia.org/wiki/Memetic_algorithm).
- Wikipedia: [GRASP](https://en.wikipedia.org/wiki/Greedy_randomized_adaptive_search_procedure).
- Musser, D.R. (1997). Introspective sorting and selection algorithms.
  *Software: Practice and Experience*.

## Related packages

- **[Ada-Memetic-Algorithm](https://github.com/RobertBoettcherSF/Ada-Memetic-Algorithm)** —
  full educational MA (link only).
- **[Ada-GRASP](https://github.com/RobertBoettcherSF/Ada-GRASP)** —
  RCL multi-start metaheuristic (link only).
- **[Ada-Genetic-Algorithms](https://github.com/RobertBoettcherSF/Ada-Genetic-Algorithms)** —
  population EA survey (link only).
- **[Ada-Local-Search](https://github.com/RobertBoettcherSF/Ada-Local-Search)** —
  hill climbing / ILS / 2-opt survey (link only).

## License

Educational reference implementation for the RobertBoettcherSF Ada algorithm
series. Use and adapt freely for learning and research.
