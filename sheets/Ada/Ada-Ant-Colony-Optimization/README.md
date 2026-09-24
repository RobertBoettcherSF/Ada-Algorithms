# Ant Colony Optimization — Ada 2023

Educational, self-contained Ada 2023 package implementing **ant colony
optimization** (ACO) — specifically classical **Ant System** (AS) for the
travelling salesman problem. Artificial ants construct tours on a complete
graph using pheromone $\tau$ and heuristic $\eta=1/d$; trails evaporate and
receive deposits $\Delta\tau=Q/L$.

Based on [Wikipedia: Ant colony optimization algorithms](https://en.wikipedia.org/wiki/Ant_colony_optimization_algorithms)
(Marco Dorigo, 1992; Ant System — Dorigo, Maniezzo & Colorni, 1996).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Bees-Algorithm](../ada-bees-algorithm/)** — scout / elite / site
  recruitment on continuous boxes
- **[Ada-Particle-Swarm](../ada-particle-swarm/)** — inertia / cognitive /
  social particle updates
- **[Ada-Tabu-Search](../ada-tabu-search/)** — short-term tabu memory with
  2-opt TSP demos ($n\le 12$)

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Problem** | Symmetric TSP, $n\le 12$ | Distance matrix $D$; closed tours |
| **Heuristic** | $\eta_{ij}=1/d_{ij}$ | Large $\eta$ on zero / diagonal |
| **Choice** | $p_{ij}\propto \tau_{ij}^{\alpha}\eta_{ij}^{\beta}$ | Unused cities only |
| **Update** | $\tau\leftarrow(1-\rho)\tau$; $\Delta\tau=Q/L$ | All ants or best-only |
| **Config** | $\alpha,\beta,\rho,Q,m$, iters, seed | Seeded 32-bit LCG |
| **Result** | Best tour + length | `Solve_TSP` |

## Brief history

Dorigo introduced ant colony methods in his 1992 PhD thesis; the seminal
**Ant System** paper (Dorigo, Maniezzo & Colorni, 1996) applied cooperating
ants to TSP. Ants prefer short, highly pheromoned edges; evaporation prevents
early stagnation. Later variants (ACS, MMAS, rank-based AS) refine deposit
and selection rules. This package teaches the original AS loop on tiny
Euclidean instances.

## Algorithm (Ant System)

Initialize $\tau_{ij}\leftarrow\tau_0$ (diagonal 0) and
$\eta_{ij}=1/d_{ij}$. Each iteration, every ant builds a tour:

1. Start at a random city.
2. From city $i$, choose unused $j$ with

$$
p_{ij}^{k}=\frac{\tau_{ij}^{\alpha}\,\eta_{ij}^{\beta}}
{\sum_{z\in\mathrm{allowed}} \tau_{iz}^{\alpha}\,\eta_{iz}^{\beta}}.
$$

3. After all ants finish, evaporate and deposit:

$$
\tau_{ij}\leftarrow(1-\rho)\,\tau_{ij}+\sum_{k=1}^{m}\Delta\tau_{ij}^{k},
\qquad
\Delta\tau_{ij}^{k}=\begin{cases}
Q/L_{k} & \text{if ant }k\text{ used edge }ij,\\
0 & \text{otherwise.}
\end{cases}
$$

With `Best_Only => True`, only the iteration-best ant deposits (elitist
educational option). Defaults: $\alpha=1$, $\beta=2$, $\rho=0.5$,
$Q=100$, $m=10$, $\tau_0=1$.

## Built-in demos

| Driver / helper | Form (sketch) | Notes |
| --- | --- | --- |
| `Euclidean_Matrix` | $d_{ij}=\|x_i-x_j\|_2$ | Square / pentagon instances |
| `Solve_TSP` | full AS loop | Improves / finds known optima on $n=4,5$ |
| `Construct_Tour` | one probabilistic tour | Valid permutation |
| `Update_Pheromone` | evaporate + single deposit | $\tau$ shrinks when $Q=0$ |

## API (`Ant_Colony_Optimization`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Tour`, `Dist_Matrix`, `Pheromone_Matrix`, `Heuristic_Matrix`, `Config`, `Result` | $\alpha,\beta,\rho,Q,m$, seed |
| Helpers | `Near`, `Default_Config`, `Tour_Length`, `Is_Valid_Tour`, `Euclidean`, `Euclidean_Matrix` | Tolerance / lengths / geometry |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Index` | Seeded LCG |
| AS core | `Init_Pheromone`, `Build_Heuristic`, `Edge_Weight`, `Transition_Probability`, `Construct_Tour`, `Update_Pheromone`, `Colony_Update` | $\tau$, $\eta$, $p_{ij}$ |
| Driver | `Solve_TSP` | Best tour + length |

Named exception: `Invalid_Argument`.

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Ant colony optimization algorithms](https://en.wikipedia.org/wiki/Ant_colony_optimization_algorithms)
- M. Dorigo, V. Maniezzo, A. Colorni, *Ant System: Optimization by a Colony
  of Cooperating Agents*, IEEE Trans. Syst. Man Cybern. B **26**, 29–41 (1996)
- M. Dorigo, *Optimization, Learning and Natural Algorithms*, PhD thesis,
  Politecnico di Milano (1992)
- Sibling: [Ada-Bees-Algorithm](../ada-bees-algorithm/)
- Sibling: [Ada-Particle-Swarm](../ada-particle-swarm/)
- Sibling: [Ada-Tabu-Search](../ada-tabu-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
