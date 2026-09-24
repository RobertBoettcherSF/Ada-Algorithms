# Bees Algorithm — Ada 2023

Educational, self-contained Ada 2023 package implementing the **bees
algorithm** (BA) — a population-based **metaheuristic** that mimics
honey-bee foraging: scout bees sample the search box, the $m$ best
sites recruit foragers for neighbourhood search, and remaining scouts
explore globally at random.

Based on [Wikipedia: Bees algorithm](https://en.wikipedia.org/wiki/Bees_algorithm)
(Pham, Ghanbarzadeh et al., 2005).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Particle-Swarm](../ada-particle-swarm/)** — inertia / cognitive /
  social particle updates
- **[Ada-Harmony-Search](../ada-harmony-search/)** — harmony memory
  improvisation
- **[Ada-Simulated-Annealing](../ada-simulated-annealing/)** — Metropolis
  cooling on a single walk

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Scouts** | $n$ bees evaluate $f$ in the box | Ranked each iteration |
| **Sites** | $m$ best; $e$ elite among them | $1\le e\le m\le n$ |
| **Recruit** | $n_{ep}$ on elite, $n_{sp}$ on other best | Neighbourhood radius $ngh$ |
| **Global** | Remaining $n-m$ scouts re-sampled | Site abandon / re-scout |
| **Search** | Continuous box, $n_{\mathrm{dim}}\le 8$ | Sphere / Rosenbrock / Shifted_Sphere |
| **Track** | Best cost / best $x$ / iterations | Returned in `Result` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Pham, Ghanbarzadeh and co-authors (2005) introduced the bees algorithm
as a stylized model of honey-bee foraging. Scout bees explore randomly;
promising flower patches recruit more foragers via the waggle-dance
metaphor, so elite sites receive denser local search than ordinary best
sites, while a fraction of the colony continues global exploration. The
method needs no gradients and makes few assumptions about the objective,
but like other metaheuristics it does not guarantee a global optimum.

## Algorithm

Initialize $n$ scout bees uniformly in the box and evaluate $f$. Each
iteration:

1. Rank bees by cost (ascending).
2. For each of the $e$ elite sites, recruit $n_{ep}$ foragers and run
   neighbourhood search of radius $ngh$.
3. For each of the remaining $m-e$ best sites, recruit $n_{sp}$ foragers
   similarly.
4. Replace a site when a forager improves its cost.
5. Re-sample the remaining $n-m$ scouts uniformly in the box (global
   search / site abandonment of non-selected positions).

Neighbourhood sample for coordinate $d$ of center $c$:

$$
x'_d \sim U\bigl(\max(Lo_d,\, c_d-ngh),\, \min(Hi_d,\, c_d+ngh)\bigr)
$$

then clamp to the box. `Patch_Search` returns the best among the
foragers and the center. Defaults: $n=20$, $m=5$, $e=2$,
$n_{ep}=10$, $n_{sp}=5$, $ngh=0.5$.

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |

## API (`Bees_Algorithm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Bounds`, `Config`, `Result`, `Bee`, `Colony` | $n$, $m$, $e$, $n_{ep}$, $n_{sp}$, $ngh$, seed |
| Helpers | `Near`, `Clamp`, `Default_Config`, `Config_Is_Valid` | Tolerance / box clamp / $e\le m\le n$ |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform` | Seeded LCG |
| Colony core | `Init_Colony`, `Rank_Colony`, `Patch_Search`, `Step`, `Best_Index` | One Pham educational step |
| Objectives | `Sphere`, `Rosenbrock`, `Shifted_Sphere` | Continuous tests |
| Drivers | `Minimize_Box` | Box search |

Named exception: `Invalid_Argument` (inverted bounds, null objective,
invalid $e/m/n$, Rosenbrock with $\mathrm{Dim}<2$).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Bees algorithm](https://en.wikipedia.org/wiki/Bees_algorithm)
- D. T. Pham, A. Ghanbarzadeh, E. Koç, S. Otri, S. Rahim, M. Zaidi,
  *The Bees Algorithm — A Novel Tool for Complex Optimisation Problems*,
  Proc. 2nd Virtual International Conference on Intelligent Production
  Machines and Systems (IPROMS), 454–459 (2006)
- Sibling: [Ada-Particle-Swarm](../ada-particle-swarm/)
- Sibling: [Ada-Harmony-Search](../ada-harmony-search/)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
