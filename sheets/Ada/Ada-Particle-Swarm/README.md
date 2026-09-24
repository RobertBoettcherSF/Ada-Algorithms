# Particle Swarm Optimization — Ada 2023

Educational, self-contained Ada 2023 package implementing **particle
swarm optimization** (PSO) — a population-based **metaheuristic** in
which candidate solutions (**particles**) move through a search box
with velocities updated from inertia, personal best, and global best.

Based on [Wikipedia: Particle swarm optimization](https://en.wikipedia.org/wiki/Particle_swarm_optimization)
(Kennedy & Eberhart, 1995).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Harmony-Search](../ada-harmony-search/)** — harmony memory
  improvisation
- **[Ada-Simulated-Annealing](../ada-simulated-annealing/)** — Metropolis
  cooling on a single walk
- **[Ada-Random-Search](../ada-random-search/)** — independent random
  samples under a fixed budget

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Swarm** | $S$ particles with $x$, $v$, personal best $p$ | Global best $g$ shared |
| **Update** | $v \leftarrow \omega v + c_1 r_1 (p-x) + c_2 r_2 (g-x)$ | Then $x \leftarrow x+v$ |
| **Clamp** | Box $[Lo,Hi]^n$ | Positions stay feasible |
| **Search** | Continuous box, $n\le 8$ | Sphere / Rosenbrock / Shifted_Sphere |
| **Track** | Best cost / best $x$ / iterations | Returned in `Result` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Kennedy and Eberhart (1995) introduced PSO as a stylized model of
social behaviour (bird flocks / fish schools). Each particle remembers
its own best-so-far location and is attracted toward the swarm's best
known location; an inertia term retains momentum. The method needs no
gradients and makes few assumptions about the objective, but like other
metaheuristics it does not guarantee a global optimum.

## Algorithm

For each particle $i=1,\ldots,S$ with position $x_i$, velocity $v_i$,
and personal best $p_i$, and with swarm global best $g$:

$$
v_{i,d} \leftarrow \omega\, v_{i,d} + c_1 r_1 (p_{i,d}-x_{i,d}) + c_2 r_2 (g_d-x_{i,d})
$$

$$
x_i \leftarrow x_i + v_i
$$

then clamp each coordinate of $x_i$ to the box. If $f(x_i)<f(p_i)$
update $p_i$; if that also improves $g$, update $g$. Here $r_1,r_2\sim
U(0,1)$, $\omega$ is inertia, and $c_1$, $c_2$ are cognitive / social
coefficients (Wikipedia $\varphi_p$, $\varphi_g$). Defaults follow a
common Clerc-style constriction pair: $\omega=0.729$,
$c_1=c_2=1.49445$.

Initialization: $x\sim U(\mathrm{box})$, $p\leftarrow x$,
$v\sim U(-|\mathrm{Hi}-\mathrm{Lo}|,|\mathrm{Hi}-\mathrm{Lo}|)$,
then set $g$ from the best initial $p$.

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |

## API (`Particle_Swarm`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Bounds`, `Config`, `Result`, `Particle`, `Swarm` | $S$, $\omega$, $c_1$, $c_2$, seed |
| Helpers | `Near`, `Clamp`, `Default_Config` | Tolerance / box clamp |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform` | Seeded LCG |
| Swarm core | `Init_Swarm`, `Step`, `Best_Particle_Index` | One Kennedy–Eberhart step |
| Objectives | `Sphere`, `Rosenbrock`, `Shifted_Sphere` | Continuous tests |
| Drivers | `Minimize_Box` | Box search |

Named exception: `Invalid_Argument` (inverted bounds, null objective,
Rosenbrock with $\mathrm{Dim}<2$).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Particle swarm optimization](https://en.wikipedia.org/wiki/Particle_swarm_optimization)
- J. Kennedy, R. Eberhart, *Particle Swarm Optimization*, Proc. IEEE
  International Conference on Neural Networks, 1942–1948 (1995)
- Sibling: [Ada-Harmony-Search](../ada-harmony-search/)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)
- Sibling: [Ada-Random-Search](../ada-random-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
