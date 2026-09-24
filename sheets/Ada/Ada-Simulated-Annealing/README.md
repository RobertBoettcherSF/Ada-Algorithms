# Simulated Annealing — Ada 2023

Educational, self-contained Ada 2023 package implementing **simulated
annealing** (SA) — a probabilistic **metaheuristic** for approximating the
**global optimum** of an objective over a large search space, inspired by
metallurgical annealing (slow cooling).

Based on [Wikipedia: Simulated annealing](https://en.wikipedia.org/wiki/Simulated_annealing)
(Kirkpatrick, Gelatt & Vecchi, *Science* **220**, 671, 1983; Černý, *JOTA*
**45**, 41, 1985; Metropolis et al., 1953).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling package: **[Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/)** —
STUN transforms barriers above the best-so-far energy; SA cools temperature
on the raw landscape (comparison below).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Accept uphill moves early, then cool | Escape local minima |
| **Accept** | Metropolis $P=\min(1,e^{-\Delta E/T})$ | Minimization |
| **Cool** | Geometric $T\leftarrow\alpha T$ (optional linear) | Stop at $T_{\min}$ or max iters |
| **Search** | 1-D continuous walk + TSP-lite | Gaussian / uniform / pair-swap |
| **Track** | Best-so-far $(x^\star,E^\star)$ | Updated on improvement |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Similar ideas appeared independently (Pincus 1970; Khachaturyan et al.
1979/1981). Kirkpatrick, Gelatt Jr., and Vecchi (1983) popularized the
method and name **simulated annealing** on combinatorial problems such as
the traveling salesman problem; Černý (1985) independently gave a
thermodynamical TSP simulation. The acceptance rule adapts the
**Metropolis–Hastings** Monte Carlo criterion (Metropolis et al., 1953).

## Metropolis acceptance

At temperature $T>0$, a candidate move with energy change
$\Delta E=E_{\mathrm{new}}-E$ is accepted with probability

$$
P(\Delta E,T)=\min\bigl(1,\exp(-\Delta E/T)\bigr).
$$

Downhill moves ($\Delta E\le 0$) are always accepted. As $T\to 0$, uphill
moves become vanishingly rare and the dynamics approach greedy descent.
At $T=0$ this package uses the greedy rule: accept iff $\Delta E\le 0$.

## Cooling schedule

The algorithm starts at a high $T_0$ and gradually lowers $T$ so the walk
first explores coarsely, then settles into low-energy basins.

**Geometric** (default):

$$
T\leftarrow\alpha\,T,\qquad 0<\alpha<1.
$$

**Linear** (optional): interpolate from $T_0$ toward $T_{\min}$ by budget
progress $r\in[0,1]$:

$$
T(r)=T_0+(T_{\min}-T_0)\,r.
$$

Iteration stops when $T\le T_{\min}$ or a maximum iteration count is
reached. Cooling is applied every `Cool_Every` steps.

## Versus stochastic tunneling (STUN)

| | Simulated annealing (SA) | Stochastic tunneling (STUN) |
| --- | --- | --- |
| Landscape | Raw $E(x)$ | Transformed $f_{\mathrm{STUN}}$ |
| Temperature | Usually cooled over time | Fixed $\beta$ common; $\gamma$ sets tunnel scale |
| Barriers | Must climb full $\Delta E$ | Barriers above $E_0$ flattened |
| Best-so-far | Tracked for reporting | **Defines** the transform floor $E_0$ |

See the sibling **Ada-Stochastic-Tunneling** repository for the STUN
transform $f_{\mathrm{STUN}}=1-e^{-(E-E_0)/\gamma}$.

## Built-in 1-D test functions

| Function | Form (sketch) | Global structure |
| --- | --- | --- |
| `Double_Well` | $(x^2-1)^2+0.15\,x$ | Deeper min near $x\approx-1$; local near $+1$ |
| `Rastrigin_1D` | $x^2-10\cos(2\pi x)+10$ | Global min $0$ at $x=0$ |
| `Quadratic` / `Shifted_Quadratic` | $x^2$, $(x-3)^2$ | Unimodal sanity checks |

Combinatorial demo: `Minimize_TSP` — pair-swap neighbors on a closed tour
with $n\le 8$ cities.

## API (`Simulated_Annealing`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Config`, `Result`, `Objective_Fn`, `Cooling_Kind` | $T_0,T_{\min},\alpha$, step, iters |
| Helpers | `Near` | Absolute tolerance compare |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Gaussian`, `Next_Uniform`, `Next_Natural` | Seeded LCG |
| Accept | `Accept_Probability`, `Metropolis_Accept` | $P=\min(1,e^{-\Delta E/T})$ |
| Cool | `Cool_Geometric`, `Cool_Linear` | Schedules |
| Objectives | `Double_Well`, `Rastrigin_1D`, `Quadratic`, `Shifted_Quadratic` | Test landscapes |
| Driver | `Minimize_1D` | Continuous SA on $[L_o,H_i]$ |
| Combinatorial | `Tour_Length`, `Minimize_TSP` | TSP-lite $n\le 8$ |

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

- [Wikipedia: Simulated annealing](https://en.wikipedia.org/wiki/Simulated_annealing)
- S. Kirkpatrick, C. D. Gelatt Jr., M. P. Vecchi, *Optimization by Simulated
  Annealing*, Science **220**, 671–680 (1983)
- V. Černý, *Thermodynamical approach to the traveling salesman problem*,
  J. Optim. Theory Appl. **45**, 41–51 (1985)
- N. Metropolis et al., *Equation of State Calculations by Fast Computing
  Machines*, J. Chem. Phys. **21**, 1087 (1953)
- Sibling: [Ada-Stochastic-Tunneling](../ada-stochastic-tunneling/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
