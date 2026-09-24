# GRASP — Ada 2023

Educational, self-contained Ada 2023 package implementing the **greedy
randomized adaptive search procedure** (**GRASP**) — a multi-start
metaheuristic that alternates a **greedy randomized construction** (via a
Restricted Candidate List controlled by $\alpha$) with **local search** to a
local optimum, keeping the best solution over $\textit{Max\_Iterations}$.

Based on [Wikipedia: Greedy randomized adaptive search procedure](https://en.wikipedia.org/wiki/Greedy_randomized_adaptive_search_procedure)
(Feo & Resende, 1989; surveys Feo & Resende 1995, Resende & Ribeiro 2003).
Semi-greedy construction goes back to Hart & Shogan (1987).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (links only — **not** build dependencies):

- **[Ada-Local-Search](https://github.com/RobertBoettcherSF/Ada-Local-Search)** —
  neighborhood / hill-climbing / 2-opt survey
- **[Ada-Min-Conflicts](https://github.com/RobertBoettcherSF/Ada-Min-Conflicts)** —
  CSP repair local search (N-queens)
- **[Ada-Tabu-Search](https://github.com/RobertBoettcherSF/Ada-Tabu-Search)** —
  short-term tabu memory with aspiration
- **[Ada-Combinatorial-Optimization](https://github.com/RobertBoettcherSF/Ada-Combinatorial-Optimization)** —
  combinatorial optimization survey / umbrella (**forthcoming**)
- Related series repos: https://github.com/RobertBoettcherSF/

Educational limits: knapsack items $n\le 32$ (tests focus $n\le 16$);
TSP cities $m\le 10$ (tests focus $m\le 4$). Documented iteration budgets
in tests are typically $5$–$40$.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Loop** | Construct → local search → keep best | Multi-start |
| **RCL** | Scores within $\alpha$ of best | $\alpha\in[0,1]$ |
| **$\alpha=0$** | Pure greedy | Only best-scoring candidates |
| **$\alpha=1$** | Pure random among feasible | Full candidate set |
| **Flagship** | 0-1 knapsack maximize value | Greedy $=$ value/weight |
| **Local search** | Add + 1-1 swap (knapsack); 2-opt (TSP) | First / steepest |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

**Feo and Resende** introduced GRASP in 1989 as a practical multi-start
framework for combinatorial optimization. Each iteration builds a feasible
solution with a **semi-greedy** heuristic (random among a Restricted
Candidate List), then applies local search. The method sits between pure
greedy construction and fully random multi-start; reactive and hybrid
variants (Reactive GRASP, path-relinking) followed in later surveys.

## Algorithm

Repeat for $i=1,\ldots,\textit{Max\_Iterations}$:

1. **Construction.** While the solution is incomplete, score feasible
   candidates with a greedy function $g$, form an RCL, and pick uniformly
   from the RCL (then adapt remaining capacity / unused set).
2. **Local search.** Improve to a local optimum (bit-flip / swap for
   knapsack; 2-opt for TSP).
3. **Incumbent.** Keep the best solution found.

### Restricted Candidate List (RCL)

For **maximisation** of greedy scores $g$ (knapsack value/weight):

$$
g_{\min}=\min_e g(e),\qquad g_{\max}=\max_e g(e)
$$

$$
\mathrm{threshold}=g_{\max}-\alpha\,(g_{\max}-g_{\min})
$$

$$
\mathrm{RCL}=\{e:g(e)\ge\mathrm{threshold}\}
$$

Thus $\alpha=0$ retains only the best score(s); $\alpha=1$ retains every
feasible candidate. For **minimisation** (TSP distance-to-unused) the
package uses the dual form
$\mathrm{threshold}=d_{\min}+\alpha(d_{\max}-d_{\min})$ and
$\mathrm{RCL}=\{e:d(e)\le\mathrm{threshold}\}$.

### 0-1 knapsack demo

Given weights $w_i$, values $v_i$, and capacity $C$, maximize
$\sum_i v_i x_i$ subject to $\sum_i w_i x_i\le C$ and $x_i\in\{0,1\}$.
Construction uses $g(i)=v_i/w_i$ (or $v_i$ when $w_i=0$). Local search
never decreases total value: insert any unused item that still fits, or
perform an improving 1-1 swap (drop one selected item, add one unused).

### Optional TSP demo

Nearest-neighbor RCL construction from city $1$, then steepest-descent
**2-opt** until a local minimum tour length. Tiny Euclidean squares are
used in tests ($m=4$ optimum length $4$).

## API (`Grasp`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Limits | `Max_Items`, `Max_Cities` | Caps $32$ / $10$ |
| Params | `Parameters` ($\alpha$, iters, seed), `Default_Parameters` | Config |
| Results | `Knapsack_Result`, `TSP_Result` | Best value/set or tour |
| RCL core | `Build_RCL`, `Build_RCL_Min`, `Pick_From_RCL`, `RCL` | Grasp_Generic threshold rule |
| Knapsack | `Greedy_Score`, `Build_RCL_Knapsack`, `Construct_Solution_Knapsack`, `Local_Search_Knapsack`, `Grasp_Knapsack` | End-to-end 0-1 KS |
| Utilities | `Total_Weight`, `Total_Value`, `Is_Feasible`, `Near` | Checks |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Natural` | Seeded LCG |
| TSP | `Construct_Tour_NN_RCL`, `Local_Search_2Opt`, `Grasp_TSP`, `Tour_Length`, `Apply_2Opt`, `Euclidean` | Optional demo |

Named exception: `Invalid_Argument`.

`Build_RCL` / `Build_RCL_Min` are the documented **Grasp_Generic**
specialization point: knapsack and TSP pack dense item/score buffers and
call the shared threshold rule.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pgrasp.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`;
`tests.adb` is the sole main unit listed in `grasp.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
grasp.ads
grasp.adb
grasp.gpr
tests.adb
```

## Caveats / limits

- Educational sizes only ($n\le 32$ items, $m\le 10$ cities); not a
  production solver.
- GRASP is stochastic (given $\alpha>0$); use `Seed` for reproducibility.
- Local search is first-improvement (knapsack) / steepest 2-opt (TSP);
  neighborhoods are intentionally small.
- Multiple optima: any optimal selection/tour may be returned; tests
  accept known optimum **values**.
- Reactive GRASP, path-relinking, and cost perturbation are **not**
  implemented (see Wikipedia / Resende–Ribeiro surveys).

## References

1. Feo, T. A., & Resende, M. G. C. (1989). A probabilistic heuristic for a
   computationally difficult set covering problem. *Operations Research
   Letters*.
2. Feo, T. A., & Resende, M. G. C. (1995). Greedy randomized adaptive
   search procedures. *Journal of Global Optimization*.
3. Resende, M. G. C., & Ribeiro, C. C. (2003). Greedy randomized adaptive
   search procedures. In *Handbook of Metaheuristics*.
4. Hart, J. P., & Shogan, A. W. (1987). Semi-greedy heuristics.
5. [Wikipedia: Greedy randomized adaptive search procedure](https://en.wikipedia.org/wiki/Greedy_randomized_adaptive_search_procedure)
6. Sibling READMEs in the RobertBoettcherSF Ada series (linked above).
