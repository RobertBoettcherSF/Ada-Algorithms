# Glauber Dynamics (Ada 2023)

Educational, self-contained Ada 2023 package implementing **Glauber dynamics** —
classical single-spin-flip **heat-bath** Markov-chain Monte Carlo for the
two-dimensional **Ising model** — named after **Roy J. Glauber** (1963).

Based on [Wikipedia: Glauber dynamics](https://en.wikipedia.org/wiki/Glauber_dynamics).
An optional **Metropolis** single-spin acceptance helper is included for
comparison (same equilibrium when detailed balance and ergodicity hold).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Model** | 2-D Ising, spins $\sigma_i=\pm 1$ | $L\times L$, periodic BCs |
| **Hamiltonian** | $H=-J\sum_{\langle i,j\rangle}\sigma_i\sigma_j-h\sum_i\sigma_i$ | Nearest neighbors |
| **Dynamics** | Heat-bath (Glauber) site resample | Also Metropolis helper |
| **Local field** | $h_i=J\sum_{\mathrm{nn}}\sigma+h$ | Four neighbors |
| **Acceptance** | $P(\sigma_i=+1)=1/(1+e^{-2\beta h_i})$ | Fermi / logistic form |
| **Sweep** | $L^2$ site updates | Random / sequential / checkerboard |
| **Observables** | $m$, energy density, $\chi$ estimator | Exact $2\times 2$ checks |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Historical note (Roy J. Glauber, 1963)

Roy J. Glauber introduced time-dependent statistics for the Ising model in
*Journal of Mathematical Physics* **4**, 294–307 (1963). The resulting
single-spin-flip master equation — now called **Glauber dynamics** — is a
standard way to simulate the Ising model on a computer and to study
non-equilibrium relaxation toward thermal equilibrium.

## Ising model

Each lattice site carries a classical spin $\sigma_{x,y}\in\{+1,-1\}$. With
nearest-neighbor coupling $J$ and external field $h$, the energy is

$$
H=-J\sum_{\langle i,j\rangle}\sigma_i\sigma_j-h\sum_i\sigma_i.
$$

On an $L\times L$ torus (periodic boundary conditions) there are $N=L^2$ sites
and $2L^2$ bonds. Ferromagnetic $J>0$ favors aligned neighbors; the reduced
inverse temperature is $\beta=1/T$ ($k_B=1$).

## Algorithm (heat-bath / Glauber)

Wikipedia’s presentation of Glauber’s algorithm on the square lattice:

1. Choose a site $(x,y)$ at random.
2. Sum the four nearest neighbors
   $S=\sigma_{x+1,y}+\sigma_{x-1,y}+\sigma_{x,y+1}+\sigma_{x,y-1}$ (with wrap).
3. Form the would-be flip cost $\Delta E=2\sigma_{x,y}(JS+h)$.
4. Flip with the Fermi probability
   $p(\Delta E)=1/(1+e^{\beta\Delta E})$.

Equivalently, **resample** the spin from the conditional Bernoulli heat-bath
distribution given the local field $h_i=JS+h$:

$$
P(\sigma_i\leftarrow +1)=\frac{1}{1+e^{-2\beta h_i}}.
$$

When $\Delta E=0$ (or $\beta\to 0$), $p=\tfrac12$. At very low temperature,
uphill flips are almost never accepted and downhill flips almost always are.

One **sweep** performs $N=L^2$ attempted site updates (random sites, sequential
raster, or checkerboard sublattices).

## Comparison to Metropolis

The **Metropolis–Hastings** single-spin rule accepts a proposed flip with

$$
p(\Delta E)=\begin{cases}
1, & \Delta E\le 0,\\
e^{-\beta\Delta E}, & \Delta E>0.
\end{cases}
$$

Glauber and Metropolis differ in functional form (especially at high $T$) and
optionally in how sites are proposed, but at equilibrium any MCMC that is
**ergodic** and satisfies **detailed balance** samples the same Boltzmann
distribution $P(\sigma)\propto e^{-\beta H(\sigma)}$. Both algorithms keep
$p(\Delta E)\neq 0$ for finite $\beta$, so every configuration remains reachable.

For the 2-D square Ising model the critical temperature is approximately
$T_c\approx 2.269$ (Onsager; $J=1$, $h=0$).

## Detailed balance and MCMC

Detailed balance requires that the probability flux $A\to B$ equal $B\to A$ in
equilibrium. With Boltzmann weights $e^{-\beta E}$, spending more time in
low-energy states compensates for rarer uphill transitions — so long-run
histograms from Glauber or Metropolis match exact Boltzmann averages (verified
here on the $2\times 2$ torus by enumerating all $16$ configurations).

## API (`Glauber_Dynamics`)

| Symbol | Role |
| --- | --- |
| `Spin`, `Lattice`, `Config` | Spins $\pm 1$, $L\times L$ grid, $(J,h,\beta)$ |
| `Init_All` / `Init_Random` | Ordered or random start |
| `Neighbor_Sum`, `Local_Field` | $S$ and $h_i$ with PBC |
| `Delta_E_Flip` | $\Delta E=2\sigma_i h_i$ |
| `Heatbath_Prob_Plus` | $P(+1\mid h_i,\beta)$ |
| `Heatbath_Flip_Prob` | Wikipedia Fermi flip probability |
| `Glauber_Update_Site` / `Glauber_Sweep` | Heat-bath MCMC |
| `Metropolis_Accept_Prob` / `Metropolis_Update_Site` / `Metropolis_Sweep` | Comparison helper |
| `Magnetization`, `Energy`, `Energy_Density` | Observables |
| `Susceptibility_Estimator` | $\chi\approx\beta N(\langle m^2\rangle-\langle m\rangle^2)$ |
| `Exact_2x2_*` | Partition function and Boltzmann means |
| `Seed_RNG`, `Next_Unit`, `Near` | Reproducible LCG and tolerance helper |

Capacity: `Max_L = 32`.

## Build and test

```bash
make clean && make
make test
```

- Ada 2023 via `gnatmake -gnatwa -gnat2022`
- GPR main: `tests.adb` (no `main.adb`)
- Expect exit status `0`, zero `-gnatwa` warnings, and **Fail_Count = 0**
  with at least **100** `PASS` lines

## Layout

```
glauber_dynamics.ads   package spec
glauber_dynamics.adb   package body
glauber_dynamics.gpr   GNAT project (Main = tests.adb)
Makefile               all / test / clean
tests.adb              standalone test driver
README.md              this file
.gitignore             obj/  bin/
```

## References

- [Wikipedia: Glauber dynamics](https://en.wikipedia.org/wiki/Glauber_dynamics)
- Roy J. Glauber, “Time-Dependent Statistics of the Ising Model,”
  *J. Math. Phys.* **4**, 294–307 (1963)
- [Wikipedia: Ising model](https://en.wikipedia.org/wiki/Ising_model)
- [Wikipedia: Metropolis–Hastings algorithm](https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm)
- J.-C. Walter & G. T. Barkema, “An introduction to Monte Carlo methods,”
  *Physica A* **418**, 78–87 (2015)
