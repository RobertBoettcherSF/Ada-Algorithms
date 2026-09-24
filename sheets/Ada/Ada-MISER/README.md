# MISER — Ada 2023

Educational, self-contained Ada 2023 package implementing the **MISER**
algorithm (**recursive stratified sampling** for multidimensional Monte Carlo
integration) of Press & Farrar. A hyper-rectangle is recursively bisected
along the coordinate that most reduces a combined variance estimate; remaining
samples are allocated proportional to subregion standard deviations; leaf
regions use plain Monte Carlo. Also exposes `Plain_Monte_Carlo` for comparison.

Based on [Wikipedia: Monte Carlo integration](https://en.wikipedia.org/wiki/Monte_Carlo_integration)
(MISER / recursive stratified sampling section) and
[MISER algorithm](https://en.wikipedia.org/wiki/MISER_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (Monte Carlo survey series — **forthcoming**):

| Package | Role |
| --- | --- |
| [Ada-MISER](https://github.com/RobertBoettcherSF/Ada-MISER) | This package (recursive stratified MC) |
| [Ada-Metropolis-Hastings](https://github.com/RobertBoettcherSF/Ada-Metropolis-Hastings) | Forthcoming — MCMC / Metropolis–Hastings |
| [Ada-Wang-Landau](https://github.com/RobertBoettcherSF/Ada-Wang-Landau) | Forthcoming — Wang–Landau sampling |
| [Ada-VEGAS](https://github.com/RobertBoettcherSF/Ada-VEGAS) | Forthcoming — adaptive importance / stratified VEGAS |
| [Ada-Importance-Sampling](https://github.com/RobertBoettcherSF/Ada-Importance-Sampling) | Forthcoming — importance sampling survey |

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Recursive stratified MC | Concentrate points where variance is large |
| **Domain** | Axis-aligned hyper-rectangle | Educational $D\le 4$ |
| **Split** | Bisect one coordinate | Choose axis minimizing $\sigma_a+\sigma_b$ |
| **Explore** | Fraction `Dither` of budget | Estimate $\sigma$ on each half |
| **Allocate** | $N_a/(N_a+N_b)=\sigma_a/(\sigma_a+\sigma_b)$ | Remaining points after exploration |
| **Leaf** | Plain Monte Carlo | `Min_Points` / `Max_Depth` stop |
| **API** | `Integrand` access-to-function | `Result` with estimate + variance |
| **RNG** | Seeded `Float_Random` | Reproducible demos / tests |
| **Limits** | Educational `Real` (digits 15) | Not a production GSL/NR clone |

## Brief history

**MISER** (Press & Farrar, 1990) applies **recursive stratified sampling** to
multidimensional integration. Ordinary “divide every axis by two” explodes the
number of sub-volumes; instead, at each step one estimates along which single
coordinate a bisection pays off most, allocates the remaining evaluations
according to subregion standard deviations, and recurses. At a user-specified
depth (or when too few points remain) each leaf is integrated with **plain
Monte Carlo**. Leaf estimates and their variances are combined upward.

Naive Monte Carlo approximates

$$
I=\int_{\Omega} f(\mathbf{x})\,d\mathbf{x}
\approx V\langle f\rangle
=V\frac{1}{N}\sum_{i=1}^{N} f(\mathbf{x}_i)
$$

with error decreasing like $1/\sqrt{N}$. Stratification reduces the **grand
variance** by spending more samples where $f$ fluctuates.

## Method

For two disjoint halves $a$ and $b$ with equal volume share, the variance of
the combined mean estimate behaves as

$$
\mathrm{Var}(f)=\frac{\sigma_a^{2}(f)}{4N_a}+\frac{\sigma_b^{2}(f)}{4N_b}.
$$

This is minimized by allocating points in proportion to the standard
deviations:

$$
\frac{N_a}{N_a+N_b}=\frac{\sigma_a}{\sigma_a+\sigma_b}.
$$

**MISER** at each step:

1. Spend a fraction `Dither` of the local budget estimating $\sigma$ on both
   sides of every candidate mid-plane (one per coordinate).
2. Bisect along the coordinate with the smallest combined $\sigma_a+\sigma_b$.
3. Assign the **remaining** points with the allocation formula above.
4. Recurse; at leaves, return plain MC mean $\times$ volume and a variance
   estimate; sum estimates and variances upward.

`Config.Dither` here is the exploration fraction (Press/Farrar **PFAC**-style),
not the optional NR bisection-plane jitter (kept at exact midpoints for
clarity).

### Demos

- Unit square indicator of the unit disk $\rightarrow$ $\pi/4$.
- Constant integrand $\rightarrow$ exact volume scaling (near-zero variance).
- 1D polynomial $\int_0^1 x^{2}\,dx=1/3$, $\int_0^1 2x\,dx=1$.

## API summary

```ada
type Real is digits 15;
Max_Dimension : constant := 4;
subtype Dimension_Count is Positive range 1 .. Max_Dimension;

type Point is array (Positive range <>) of Real;

type Bounds (D : Dimension_Count) is record
   Lo, Hi : Point (1 .. D);
end record;

type Integrand is access function (X : Point) return Real;

type Config is record
   N_Points   : Positive      := 2_000;
   Dither     : Unit_Fraction := 0.1;  -- variance-exploration fraction
   Min_Points : Positive      := 15;
   Max_Depth  : Natural       := 12;
   Seed       : Integer       := 42;
end record;

type Result is record
   Estimate, Variance_Estimate, Std_Error : Real;
end record;

function Volume (B : Bounds) return Real;
function Bounds_Valid (B : Bounds) return Boolean;

function Plain_Monte_Carlo
  (F : Integrand; B : Bounds; Cfg : Config := (others => <>))
  return Result;

function Integrate_Miser
  (F : Integrand; B : Bounds; Cfg : Config := (others => <>))
  return Result;
```

Sample integrands: `Constant_One`, `Constant_Three`, `Quarter_Circle`,
`Poly_X_Squared`, `Poly_Linear_1D`, `Product_XY`, `Separable_Peak`.

## Caveats / limits

- Educational only: $D\le 4$, midpoint bisection (no NR dither jitter),
  simple $\sigma$-sum axis score, no GSL `alpha` refinement.
- Variance / standard-error estimates are **statistical**, not hard error
  bounds; rare features of $f$ can be missed.
- Exploration samples are spent on axis selection and are **not** reused in
  the recursive integral estimates (clearer pedagogy; slightly fewer effective
  integral samples than a production code).
- Indicator / discontinuous integrands (e.g. quarter circle) need generous
  `N_Points` for tight tolerances.
- Not a drop-in replacement for GSL `gsl_monte_miser` or Numerical Recipes
  `miser`.

## Build and test

```bash
make          # gnatmake -gnatwa -gnat2022 -Pmiser.gpr
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
| `miser.ads` | Package spec |
| `miser.adb` | Package body |
| `miser.gpr` | GNAT project (main = `tests.adb`) |
| `tests.adb` | Standalone test driver |

## References

- Press, W. H.; Farrar, G. R. (1990). “Recursive Stratified Sampling for
  Multidimensional Monte Carlo Integration.” *Computers in Physics* **4** (2):
  190.
- [Wikipedia: Monte Carlo integration](https://en.wikipedia.org/wiki/Monte_Carlo_integration)
- [Wikipedia: MISER algorithm](https://en.wikipedia.org/wiki/MISER_algorithm)
- Forthcoming siblings: Metropolis–Hastings, Wang–Landau, VEGAS, importance
  sampling (RobertBoettcherSF).
