# Wang–Landau — Ada 2023

Educational, self-contained Ada 2023 package implementing **Wang–Landau**
sampling (**flat-histogram density-of-states** estimation) of Wang & Landau.
The walk maintains estimates $\ln g(E)$ and a visit histogram $H(E)$; proposed
neighbour moves are accepted with probability $\min\bigl(1,e^{\ln g(E)-\ln g(E')}\bigr)$;
after each step $\ln g(E)\leftarrow\ln g(E)+\ln f$ and $H(E)\leftarrow H(E)+1$.
When $H$ is flat enough, $f\leftarrow\sqrt{f}$ (equivalently $\ln f\leftarrow\ln f/2$)
and $H$ is reset; the run stops when $f-1$ is below a configured threshold.

Based on [Wikipedia: Wang and Landau algorithm](https://en.wikipedia.org/wiki/Wang_and_Landau_algorithm)
and Wang & Landau (2001).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (Monte Carlo survey series):

| Package | Role |
| --- | --- |
| [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER) | Recursive stratified Monte Carlo integration |
| [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau) | This package (flat-histogram DOS) |
| [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings) | Forthcoming — MCMC / Metropolis–Hastings |
| [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling) | Forthcoming — Gibbs sampling |
| [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo) | Forthcoming — Hybrid / Hamiltonian MC |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Flat-histogram DOS | Visit all energies roughly equally |
| **State** | $\ln g(E)$, $H(E)$ | Update after every MC step |
| **Accept** | $\min(1,\exp(\ln g(E)-\ln g(E')))$ | Multicanonical / $1/g$ bias |
| **Refine** | $\ln f\leftarrow\ln f/2$ when flat | Classical $f\leftarrow\sqrt{f}$ |
| **Models** | Two-level, binomial bits, 1D Ising | Exact $g(E)$ available for tests |
| **API** | `Config` / `Result` / `Estimate_*` | Seeded `Float_Random` |
| **Limits** | Tiny discrete spectra | Educational, not production WL |

## Brief history

**Wang–Landau** (Fugao Wang & David P. Landau, 2001) estimates the
**density of states** $g(E)$ (or microcanonical entropy $S(E)=\ln g(E)$) by a
**non-Markovian** random walk. Unlike Metropolis–Hastings at fixed temperature,
the instantaneous acceptance uses the running estimate of $g$, which gradually
flattens the energy histogram. The modification factor $f>1$ starts large
(fast exploration) and is reduced toward $1$ (refinement). The resulting
$\hat g(E)$ enables multicanonical reweighting and thermodynamics at any
temperature from a single DOS estimate.

## Method

Initialize $\ln g(E)\leftarrow 0$, $H(E)\leftarrow 0$, and $\ln f\leftarrow\ln f_0$
(classically $\ln f_0=1$ so $f_0=e$). From configuration $r$ with energy $E$:

1. Propose $r'$ (spin flip / neighbour / uniform microstate) with energy $E'$.
2. Accept with
   $$
   A=\min\bigl(1,\exp(\ln g(E)-\ln g(E'))\bigr)
   $$
   (symmetric proposals; otherwise include the usual Hastings ratio).
3. Update the **visited** energy after the accept/reject decision:
   $$
   \ln g(E)\leftarrow\ln g(E)+\ln f,\qquad H(E)\leftarrow H(E)+1.
   $$
4. When $H$ is **flat enough** (here: every allowed bin visited and
   $\min H\ge \texttt{Flatness}\cdot\langle H\rangle$), set
   $$
   \ln f\leftarrow\frac{\ln f}{2}
   $$
   (i.e. $f\leftarrow\sqrt{f}$), reset $H\leftarrow 0$, and begin a new stage.
5. Stop when $f-1<\texttt{F\_Final}$ (or a stage cap is hit).

Normalize the estimated DOS via a stable softmax of $\ln g$ so that
$\sum_E \hat g(E)$ matches a chosen total (e.g. $2^L$ for the bit model).

### Educational models

- **Two-level toy.** $G_0$ labelled microstates at $E=0$, $G_1$ at $E=1$;
  uniform proposals. Exact $g=(G_0,G_1)$.
- **Binomial / bits.** $L$ bits, $E=\mathrm{wt}(x)$, single-bit flips.
  Exact $g(E)=\binom{L}{E}$.
- **1D Ising.** $N\le 8$ spins $\pm 1$, periodic BC, $J=1$,
  $E=-\sum_i s_i s_{i+1}$; single-spin flips. Exact $g$ by $2^N$ enumeration.

Optional helper: canonical mean energy
$\langle E\rangle_T=\sum_E E\,g(E)e^{-E/T}/\sum_E g(E)e^{-E/T}$ from $\ln g$.

## API summary

```ada
type Real is digits 15;
Max_Bins : constant := 32;

type Config is record
   Flatness        : Unit_Fraction := 0.8;
   F_Final         : Positive_Real := 1.0E-8;
   Ln_F_Initial    : Positive_Real := 1.0;
   Max_Stages      : Positive      := 40;
   Steps_Per_Check : Positive      := 1_000;
   Min_Entries     : Positive      := 100;
   Seed            : Integer       := 42;
end record;

type Result (Last_Bin : Bin_Index) is record
   Ln_G        : Ln_G_Array (0 .. Last_Bin);
   Visits      : Visit_Array (0 .. Last_Bin);  -- last stage
   Stages, Total_Steps : Natural;
   Converged   : Boolean;
   Final_Ln_F  : Real;
end record;

function N_Bins (R : Result) return Bin_Count;

function Estimate_Two_Level (G0, G1 : Positive; Cfg : Config := ...)
  return Result;
function Estimate_Binomial (L : Positive; Cfg : Config := ...)
  return Result;
function Estimate_Ising_1D (N : Positive; Cfg : Config := ...)
  return Result;
--  Aliases: Run_Two_Level, Run_Binomial, Run_Ising_1D,
--  Estimate_Density_Of_States (= binomial).

function Normalize_Density (Ln_G : Ln_G_Array; Total : Non_Negative := 1.0)
  return Density_Array;
function Exact_Binomial_Density (L : Positive) return Density_Array;
function Exact_Ising_1D_Density (N : Positive) return Density_Array;
function Relative_L1 (Estimate, Exact : Density_Array) return Non_Negative;
function Canonical_Mean_Energy
  (Ln_G : Ln_G_Array; Energies : Energy_Array; T : Positive_Real)
  return Real;
```

## Caveats / limits

- Educational only: tiny discrete spectra (`Max_Bins = 32`, Ising $N\le 8$),
  simple flatness rule, no continuum binning / kernel density tricks.
- Convergence of $\hat g$ is statistical; tolerances in tests are deliberately
  loose. Production WL uses longer stages, better flatness criteria, and
  often $1/t$ schedules.
- Unreachable Ising energies (exact $g=0$) are masked out of the flatness
  check via a one-time $2^N$ enumeration; binomial / two-level visit all bins.
- Not a drop-in replacement for production Wang–Landau codes in condensed-matter
  packages.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pwang_landau.gpr
make test     # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. Zero warnings expected under
`-gnatwa -gnat2022`.

## Layout

Exactly seven root files (no `main.adb`):

| File | Role |
| --- | --- |
| `.gitignore` | Ignores `obj/`, `bin/` |
| `Makefile` | `all` / `test` / `clean` |
| `README.md` | This document |
| `wang_landau.ads` | Package spec |
| `wang_landau.adb` | Package body |
| `wang_landau.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- Wang, F.; Landau, D. P. (2001). “Efficient, Multiple-Range Random Walk
  Algorithm to Calculate the Density of States.” *Phys. Rev. Lett.* **86** (10):
  2050–2053.
- [Wikipedia: Wang and Landau algorithm](https://en.wikipedia.org/wiki/Wang_and_Landau_algorithm)
- Siblings: [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER);
  forthcoming [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings),
  [Ada-Gibbs-Sampling](https://github.com/RobertBoettcherSF/Ada-Gibbs-Sampling),
  [Ada-Hybrid-Monte-Carlo](https://github.com/RobertBoettcherSF/Ada-Hybrid-Monte-Carlo).
