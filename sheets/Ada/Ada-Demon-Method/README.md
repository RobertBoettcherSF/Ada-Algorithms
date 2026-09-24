# Demon Algorithm (Ada 2023)

Educational, self-contained Ada 2023 package implementing the **Creutz demon
algorithm** — microcanonical Monte Carlo for the two-dimensional **Ising
model**. An auxiliary non-negative degree of freedom (the **demon**) stores
and supplies energy so that

$$
E_{\mathrm{system}} + E_d = \mathrm{const}.
$$

Based on [Wikipedia: Demon algorithm](https://en.wikipedia.org/wiki/Demon_algorithm)
and Creutz, *Phys. Rev. Lett.* **50**, 1411 (1983).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

**Sibling (no dependency):**
[Ada-Glauber-Dynamics](https://github.com/RobertBoettcherSF/Ada-Glauber-Dynamics)
implements the canonical-ensemble **heat-bath** (Glauber) dynamics for the
same Ising lattice. This package is microcanonical with a demon energy;
Glauber is canonical at fixed $\beta$. Link only — no shared code.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Ensemble** | Microcanonical | Fixed $E_{\mathrm{tot}}=E+E_d$ |
| **Model** | 2-D Ising, spins $\sigma_i=\pm 1$ | $L\times L$, periodic BCs |
| **Hamiltonian** | $H=-J\sum_{\langle i,j\rangle}\sigma_i\sigma_j-h\sum_i\sigma_i$ | Prefer $J=1$ (integer $\Delta E$) |
| **Extra DOF** | Demon energy $E_d\ge 0$ | No particle interaction beyond energy |
| **Accept** | Creutz rule on $\Delta E$ | Downhill always; uphill if $E_d\ge\Delta E$ |
| **Sweep** | $L^2$ random (or sequential) proposals | Seeded LCG |
| **Thermometer** | $\langle E_d\rangle$ | Continuous: $T=\langle E_d\rangle$; Ising discrete estimator |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Microcanonical ensemble

The **microcanonical ensemble** is the set of microscopic states with fixed
energy, volume, and particle number. Directly sampling configurations with a
prescribed energy by rejection is inefficient when the configuration space is
huge. The demon algorithm adds one extra non-negative energy reservoir so that
proposals can be accepted or rejected while **conserving** the sum of system
and demon energies. For large $N$ the demon’s $O(1)$ energy fluctuation does
not change macroscopic observables.

## Creutz demon algorithm

Procedure (Wikipedia / Creutz):

1. Choose a site at random and propose a spin flip $\sigma\to-\sigma$.
2. Compute the system energy change $\Delta E=2\sigma_i(JS+h)$ where
   $S$ is the four-neighbor sum (periodic BCs).
3. **If $\Delta E\le 0$:** always accept; give $|\Delta E|$ to the demon:
   $E_d\leftarrow E_d-\Delta E$ (demon energy increases).
4. **If $\Delta E>0$:** accept only when $E_d\ge\Delta E$; then
   $E_d\leftarrow E_d-\Delta E$. Otherwise **reject** (restore the spin).
5. Repeat. The demon never goes negative.

After equilibration, configurations are sampled from the microcanonical
surface at the conserved total energy $E+E_d$.

## Contrast with Metropolis / Glauber

| | Demon (Creutz) | Metropolis | Glauber (heat-bath) |
| --- | --- | --- | --- |
| Ensemble | Microcanonical | Canonical | Canonical |
| Control | Total energy $E+E_d$ | Temperature $T$ via $\beta$ | Temperature $T$ via $\beta$ |
| Uphill moves | Only if demon can pay | $e^{-\beta\Delta E}$ | Soft Fermi / resample |
| Extra DOF | Demon $E_d\ge 0$ | None | None |

Metropolis and Glauber target $P(\sigma)\propto e^{-\beta H(\sigma)}$. The
demon targets fixed $E_{\mathrm{tot}}$; temperature is an **observable**
inferred from the demon, not an input parameter.

## Temperature from the demon

- **Continuous classical demon** (unbounded continuum of energies):
  $\langle E_d\rangle = kT$. With $k=1$, `Temperature_From_Mean_Demon`
  returns $T=\langle E_d\rangle$.
- **Discrete Ising demon** (with $J=1$, $h=0$, $\Delta E\in\{0,\pm 4,\pm 8\}$
  so demon quanta of size $\varepsilon=4$):
  $$
  \langle E_d\rangle=\frac{\varepsilon}{e^{\varepsilon/T}-1}
  \quad\Rightarrow\quad
  T=\frac{\varepsilon}{\ln\bigl(1+\varepsilon/\langle E_d\rangle\bigr)}.
  $$
  Implemented as `Ising_Demon_Temperature_Estimator`. In any case,
  **higher target system energy** (more energy left for the demon after
  equilibration, or a hotter microcanonical shell) yields a **hotter**
  average demon — verified in the test suite.

## Ising demo

Ground state (all spins aligned, $J=1$, $h=0$): $E=-2L^2$. Putting excess
energy into the demon and running sweeps lets the lattice absorb energy while
$E+E_d$ stays fixed. Ordered (cold / low total energy) runs keep
$|m|$ large; disordered (hot / high total energy) runs drive $|m|$ toward $0$.

## API (`Demon_Method`)

| Symbol | Role |
| --- | --- |
| `Spin`, `Lattice`, `Config`, `Demon_State` | Spins $\pm 1$, grid, $(J,h)$, $E_d$ |
| `Init_All` / `Init_Random` | Ordered or random start |
| `Neighbor_Sum`, `Local_Field`, `Delta_E_Flip` | Local Ising helpers (PBC) |
| `Would_Accept`, `New_Demon_Energy` | Creutz accept predicate / update |
| `Demon_Update_Site` / `Demon_Sweep` | Microcanonical MCMC |
| `Energy`, `Total_Energy`, `Magnetization` | Observables + conservation |
| `Temperature_From_Mean_Demon` | Continuous $T=\langle E_d\rangle$ |
| `Ising_Demon_Temperature_Estimator` | Discrete $\varepsilon$-quanta estimator |
| `Seed_RNG`, `Next_Unit`, `Near` | Reproducible LCG and tolerance |

Capacity: `Max_L = 32`. Prefer $J=1$ so energies stay on an integer lattice.

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
demon_method.ads   package spec
demon_method.adb   package body
demon_method.gpr   GNAT project (Main = tests.adb)
Makefile           all / test / clean
tests.adb          standalone test driver
README.md          this file
.gitignore         obj/  bin/
```

## References

- [Wikipedia: Demon algorithm](https://en.wikipedia.org/wiki/Demon_algorithm)
- Michael Creutz, “Microcanonical Monte Carlo Simulation,”
  *Phys. Rev. Lett.* **50**, 1411–1414 (1983)
- H. Gould, J. Tobochnik, W. Christian,
  *An Introduction to Computer Simulation Methods*, Ch. 15 (3rd ed.)
- [Wikipedia: Microcanonical ensemble](https://en.wikipedia.org/wiki/Microcanonical_ensemble)
- [Wikipedia: Ising model](https://en.wikipedia.org/wiki/Ising_model)
- Sibling: [Ada-Glauber-Dynamics](https://github.com/RobertBoettcherSF/Ada-Glauber-Dynamics)
  (canonical heat-bath; no code dependency)
