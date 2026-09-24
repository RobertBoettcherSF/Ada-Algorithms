# Harmony Search — Ada 2023

Educational, self-contained Ada 2023 package implementing **harmony
search** (HS) — a population-based **metaheuristic** that maintains a
**harmony memory** of candidate solutions and improvises new candidates
by combining memory consideration with random pitch adjustment.

Based on [Wikipedia: Harmony search](https://en.wikipedia.org/wiki/Harmony_search)
(Zong Woo Geem, Joong Hoon Kim & G. V. Loganathan, 2001). Note: that
Wikipedia title may redirect to the broader list of metaphor-based
metaheuristics; the algorithm notes below follow Geem et al.

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Simulated-Annealing](../ada-simulated-annealing/)** — Metropolis
  cooling on a single walk
- **[Ada-Tabu-Search](../ada-tabu-search/)** — short-term tabu memory on
  local moves
- **[Ada-Random-Search](../ada-random-search/)** — independent random
  samples under a fixed budget

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Memory** | Harmony memory of size $HMS$ | Population of candidate vectors |
| **Improvise** | Per-coordinate HMCR / PAR / $BW$ | Memory, pitch, or random |
| **Update** | Replace worst if better | Strict minimization |
| **Search** | Continuous box + discrete bits | $n\le 8$; OneMax bits $\le 32$ |
| **Track** | Best cost / best $x$ / improvisations | Returned in `Result` |
| **RNG** | Seeded 32-bit LCG | Reproducible tests |

## Brief history

Geem, Kim, and Loganathan (2001) introduced harmony search as a
phenomenon-mimicking optimizer inspired by jazz improvisation: musicians
draw on memory, adjust pitch, and explore new notes. In optimization
language (metaphor-free), HS keeps a pool of feasible solutions, samples
coordinates from that pool with probability HMCR, optionally perturbs
them with probability PAR, otherwise samples uniformly in bounds, and
admits a candidate when it improves on the worst pool member.

## Algorithm

Maintain harmony memory $\mathrm{HM}=\{x^{(1)},\ldots,x^{(HMS)}\}$ with
objective values $f(x^{(k)})$. For each improvisation, build a new
harmony $x'$ coordinate-wise. For dimension $j$:

$$
x'_j=
\begin{cases}
x^{(r)}_j \pm U\cdot BW & \text{with prob. HMCR, then PAR (pitch)} \\
x^{(r)}_j & \text{with prob. HMCR, else no pitch} \\
U(\mathrm{Lo}_j,\mathrm{Hi}_j) & \text{with prob. }1-\mathrm{HMCR}
\end{cases}
$$

where $r$ is a uniform random memory index and $U$ is uniform noise.
After evaluating $f(x')$, if $f(x') < f(x^{(\mathrm{worst})})$ then
replace the worst member. Repeat for `Max_Improvisations`.

Discrete (bit-string) variant: memory consideration copies a bit; pitch
adjustment flips that bit (Hamming neighbor); otherwise a fresh random
bit is drawn.

## Built-in demos

| Driver / objective | Form (sketch) | Notes |
| --- | --- | --- |
| `Sphere` | $f(x)=\sum_i x_i^2$ | Unique min $0$ at origin |
| `Rosenbrock` | $(1-x)^2+100(y-x^2)^2$ | Banana; min $0$ at $(1,1)$ |
| `Shifted_Sphere` | $\sum_i (x_i-1)^2$ | Min $0$ at $(1,\ldots,1)$ |
| `Minimize_OneMax` | cost $=$ \# of `False` bits | Discrete HS |

## API (`Harmony_Search`)

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Bounds`, `Config`, `Result`, `Harmony_Memory` | $HMS$, HMCR, PAR, $BW$, seed |
| Helpers | `Near`, `Clamp`, `Default_Config` | Tolerance / box clamp |
| RNG | `Seed_RNG`, `Next_Unit`, `Next_Uniform`, `Next_Natural` | Seeded LCG |
| HM core | `Init_HM`, `Improvise`, `Update_HM`, `Best_Index`, `Worst_Index` | Continuous memory |
| Bit HM | `Init_Bit_HM`, `Improvise_Bits`, `Update_Bit_HM` | Discrete memory |
| Objectives | `Sphere`, `Rosenbrock`, `Shifted_Sphere` | Continuous tests |
| Drivers | `Minimize_Box`, `Minimize_OneMax` | Box / OneMax search |

Named exception: `Invalid_Argument` (inverted bounds, null objective,
empty memory misuse).

## Build and test

```bash
make clean && make
make test
```

Requires GNAT with Ada 2022/2023 support (`gnatmake -gnatwa -gnat2022`).
The GPR main is `tests.adb` (no `main.adb`). Expect **Fail_Count = 0** and
at least **100** PASS lines.

## References

- [Wikipedia: Harmony search](https://en.wikipedia.org/wiki/Harmony_search)
  (may redirect to metaphor-based metaheuristics)
- Z. W. Geem, J. H. Kim, G. V. Loganathan, *A New Heuristic Optimization
  Algorithm: Harmony Search*, Simulation **76**(2), 60–68 (2001)
- Sibling: [Ada-Simulated-Annealing](../ada-simulated-annealing/)
- Sibling: [Ada-Tabu-Search](../ada-tabu-search/)
- Sibling: [Ada-Random-Search](../ada-random-search/)

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
