# Stochastic Tunneling (STUN) — Ada 2023

Educational, self-contained Ada 2023 package implementing **stochastic
tunneling** (STUN) — a Monte Carlo **global optimization** method that
samples a nonlinearly transformed objective so the dynamical process can
**tunnel** through barriers that would trap ordinary simulated annealing.

Based on [Wikipedia: Stochastic tunneling](https://en.wikipedia.org/wiki/Stochastic_tunneling)
(Wenzel & Hamacher, *Phys. Rev. Lett.* **82**, 3003, 1999; Hamacher & Wenzel,
related work).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Flatten barriers above best-so-far $E_0$ | Preserve loci of minima |
| **Transform** | $f_{\mathrm{STUN}}=1-e^{-(E-E_0)/\gamma}$ | Clamp to $0$ if $E<E_0$ |
| **Accept** | Metropolis on $\Delta f_{\mathrm{STUN}}$ with $\beta$ | $T=1/\beta$ |
| **Search** | 1-D continuous random walk | Gaussian or uniform steps |
| **Track** | Best-so-far $(x^\star,E_0)$ | Updated on improvement |
| **Compare** | Optional plain Metropolis / SA | Same proposals, raw $\Delta E$ |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## The STUN idea

Metropolis Monte Carlo proposes a move with energy change $\Delta E$ and
accepts with

$$
\min\bigl(1;\exp(-\beta\cdot\Delta E)\bigr).
$$

On a rugged landscape (e.g. spin-glass–like barriers), uphill moves are
rare at useful $\beta$, so the walker is trapped for long times. STUN
instead samples a **transformed** effective potential $f_{\mathrm{STUN}}$
that suppresses wells lying **above** the best minimum found so far and
enhances deeper wells. If the process escapes the current basin, it is
less likely to be trapped by higher local minima — accelerating exploration
while still preserving the locations of true minima of $E$.

## Transform formula

This package uses $\gamma$ as an **energy scale** (temperature-like):

$$
f_{\mathrm{STUN}}(E,E_0,\gamma)=
\begin{cases}
0, & E < E_0 \quad\text{(clamp)},\\
1-\exp\bigl(-(E-E_0)/\gamma\bigr), & E \ge E_0.
\end{cases}
$$

At $E=E_0$ one has $f_{\mathrm{STUN}}=0$. As $E-E_0$ grows, $f_{\mathrm{STUN}}$
saturates toward $1$, so large barriers look similar and are easier to
cross under Metropolis dynamics on $f_{\mathrm{STUN}}$. Wikipedia often
writes $1-\exp(-\gamma_{\mathrm{wiki}}\cdot(E-E_0))$; the two conventions
are related by $\gamma=1/\gamma_{\mathrm{wiki}}$.

Acceptance uses the Metropolis criterion on the transformed difference:

$$
\min\bigl(1;\exp(-\beta\cdot\Delta f_{\mathrm{STUN}})\bigr),
\quad
\Delta f_{\mathrm{STUN}}=f_{\mathrm{STUN}}(E')-f_{\mathrm{STUN}}(E).
$$

$E_0$ is the lowest raw energy evaluated so far and is updated whenever a
new record is found.

## Versus simulated annealing

| | Simulated annealing (SA) | Stochastic tunneling (STUN) |
| --- | --- | --- |
| Landscape | Raw $E(x)$ | Transformed $f_{\mathrm{STUN}}$ |
| Temperature | Usually cooled over time | Fixed $\beta$ common; $\gamma$ sets tunnel scale |
| Barriers | Must climb full $\Delta E$ | Barriers above $E_0$ flattened |
| Best-so-far | Optional logging | **Defines** the transform floor $E_0$ |

Plain Metropolis / SA remains useful at high $T$; on a double-well barrier
problem with high $\beta$, STUN typically escapes the shallow well more
often than raw-energy Metropolis (soft check in the test suite).

Related methods (not implemented here): **parallel tempering**, genetic
algorithms, differential evolution; see Wikipedia “Other approaches”.

## Built-in 1-D test functions

| Function | Form (sketch) | Global structure |
| --- | --- | --- |
| `Double_Well` | $(x^2-1)^2+0.15\,x$ | Deeper min near $x\approx-1$; local near $+1$ |
| `Tall_Double_Well` | $25(x^2-1)^2+0.2\,x$ | Barrier $\sim 25$; STUN vs Metropolis demo |
| `Rastrigin_1D` | $x^2-10\cos(2\pi x)+10$ | Global min $0$ at $x=0$ |
| `Sum_Of_Gaussians` | $-\sum_k A_k e^{-(x-\mu_k)^2/(2\sigma_k^2)}$ | Deepest well at $x\approx-2$ |
| `Quadratic` / `Shifted_Quadratic` | $x^2$, $(x-3)^2$ | Unimodal sanity checks |

## API (`Stochastic_Tunneling`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Config`, `Result`, `Objective_Fn` | $\gamma,\beta$, step, iters; best $x,E$ |
| Helpers | `Near` | Absolute tolerance compare |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Gaussian`, `Next_Uniform` | Seeded LCG |
| Transform | `Stun_Transform` | $f_{\mathrm{STUN}}(E,E_0,\gamma)$ with clamp |
| Accept | `Metropolis_Accept_Prob`, `Metropolis_Accept_Stun` | On $\Delta f_{\mathrm{STUN}}$ |
| Compare | `Metropolis_Accept_Energy`, `Minimize_1D_Metropolis` | Raw $\Delta E$ SA-style |
| Objectives | `Double_Well`, `Tall_Double_Well`, `Rastrigin_1D`, … | Multimodal / unimodal toys |
| Driver | `Minimize_1D` | STUN walk on $[L_o,H_i]$ |

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

- [Wikipedia: Stochastic tunneling](https://en.wikipedia.org/wiki/Stochastic_tunneling)
- W. Wenzel & K. Hamacher, *A Stochastic tunneling approach for global
  minimization*, Phys. Rev. Lett. **82**, 3003–3007 (1999)
- K. Hamacher & W. Wenzel, *The Scaling Behaviour of Stochastic Minimization
  Algorithms in a Perfect Funnel Landscape*, Phys. Rev. E **59**, 938 (1999)
- N. Metropolis et al., *Equation of State Calculations by Fast Computing
  Machines*, J. Chem. Phys. **21**, 1087 (1953)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
