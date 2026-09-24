# Odlyzko–Schönhage Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **Odlyzko–Schönhage**
algorithm (ASCII package name `Odlyzko_Schonhage`; Schönhage’s name is
spelled with ö in prose), following
[Wikipedia: Odlyzko–Schönhage algorithm](https://en.wikipedia.org/wiki/Odlyzko%E2%80%93Sch%C3%B6nhage_algorithm).

Classroom sketches only: evaluate a **truncated Dirichlet polynomial**

$$
P(s)=\sum_{n=1}^{N} n^{-s}
$$

at many abscissae, contrasting a naive $O(MN)$ batch with FFT-inspired
structure. This is **not** a production Riemann-zeta / Riemann–Siegel
engine.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.

Sibling packages (multiplication / FFT lineage — sheet rows for these are
already covered; **skip duplicates**):

- **[Ada-Schoenhage-Strassen](https://github.com/RobertBoettcherSF/Ada-Schoenhage-Strassen)** — NTT / convolution teaching sketch
- **[Ada-Karatsuba](https://github.com/RobertBoettcherSF/Ada-Karatsuba)** — Karatsuba multiply
- **[Ada-Toom-Cook](https://github.com/RobertBoettcherSF/Ada-Toom-Cook)** — Toom-3 digit-vector multiply
- **[Ada-Multiplication-Algorithms](https://github.com/RobertBoettcherSF/Ada-Multiplication-Algorithms)** — survey of classical fast products

**Next new work:** Tonelli–Shanks (not a multiply-family duplicate).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Domain** | `type Real is digits 15`; optional `Complex` | `+`, `*`, `Near` |
| **Single point** | `Naive_Dirichlet_Poly` | $P(s)=\sum n^{-s}$, $s>1$ |
| **Naive batch** | `Naive_Batch` | $O(M\cdot N)$ |
| **FFT helpers** | `DFT` / `IDFT` | Cooley–Tukey radix-2 |
| **Poly multipoint** | `Polynomial_Eval_FFT` | Roots-of-unity via DFT |
| **Geometric batch** | `Fast_Batch_Geometric` | $n^{-(S_0+jH)}=n^{-S_0}(n^{-H})^j$ |
| **OS sketch** | `Odlyzko_Schonhage_Sketch` | Blocked Taylor + geometric fallback |
| **Demos** | `Zeta_Partial`, `Eta_Partial` | $\sigma>1$ / alternating |
| **Caps** | $\mathrm{Max\_N}=\mathrm{Max\_M}=256$ | Fast classroom tests |
| **Errors** | `Invalid_Argument` | Bad sizes, non-pot FFT, $S\le 1$ |

## Wikipedia idea (FFT multipoint)

The main point of Odlyzko–Schönhage (Odlyzko & Schönhage, 1988) is to use
the **fast Fourier transform** to speed evaluation of a finite Dirichlet
series of length $N$ at $O(N)$ equally spaced values from $O(N^{2})$ down
to roughly $O(N^{1+\varepsilon})$ (at the cost of storing
$O(N^{1+\varepsilon})$ intermediate values).

The same idea applies not only to $\zeta(s)$ but to many Dirichlet series.

### Why ζ / Riemann–Siegel / $\pi(x)$ care

The **Riemann–Siegel formula** for $\zeta(1/2+it)$ with large $t$ uses a
Dirichlet polynomial with about $N\approx\sqrt{t}$ terms. Computing about
$N$ such values with a naive double loop costs $\sim N^{2}\sim t$ per
“block”, and finding zeros with imaginary part up to $T$ historically sat
near $T^{3/2+\varepsilon}$ work. Multipoint FFT acceleration reduces that
toward about $T^{1+\varepsilon}$. Gourdon (2004) used related technology to
verify RH for the first $10^{13}$ zeros; Odlyzko’s large-height computations
likewise rely on fast multipoint Dirichlet evaluation.

This package only illustrates the **classroom skeleton** of that idea.

## Algorithms (this package)

### 1. Naive single-point Dirichlet

For real $s>1$,

$$
P(s)=\sum_{n=1}^{N} n^{-s}=\sum_{n=1}^{N}\exp(-s\log n).
$$

`Naive_Dirichlet_Poly` / `Zeta_Partial` implement this directly.

### 2. Naive batch — $O(MN)$

`Naive_Batch` evaluates $P$ independently at $M$ abscissae. Baseline
complexity when $M\sim N$ is quadratic.

### 3. FFT helpers (Cooley–Tukey)

`DFT` / `IDFT` on power-of-two `Complex_Array`s. Round-trip recovers the
input within float noise. These are the **speeding ingredient** behind
multipoint evaluation at roots of unity.

### 4. Ordinary polynomial multipoint via FFT

If $Q(z)=\sum_{j} a_j z^j$, then the values $Q(\omega^k)$ at $N$-th roots
of unity are exactly the DFT of the coefficient vector. `Polynomial_Eval_FFT`
demonstrates that textbook FFT multipoint fact; `Polynomial_Eval_Naive` is
the $O(N^{2})$ oracle.

### 5. Geometric rewrite — `Fast_Batch_Geometric`

On the arithmetic progression $s_j=S_0+jH$,

$$
n^{-s_j}=n^{-S_0}\cdot(n^{-H})^j.
$$

Incremental multiply across $j$ matches `Naive_Batch` within $\sim 10^{-8}$
on small grids and exposes the geometric structure that heavier OS methods
accelerate.

### 6. `Odlyzko_Schonhage_Sketch` (educational)

Blocked Taylor expansion of $n^{-(C+\delta)}$ about block centres, with
geometric fallback when the step $H$ is not tiny. **Asymptotic intent** of
the real algorithm: $O(N^{1+\varepsilon})$ for $O(N)$ equally spaced
points versus $O(N^{2})$ naive. Toy sizes only ($\le 256$).

### 7. Eta partial

$$
\eta_N(s)=\sum_{n=1}^{N}(-1)^{n-1}n^{-s}
$$

for light alternating-series demos ($s>0$ in this sketch).

## Educational toy caveat

- Digits-15 `Real` / `Complex` only — no multiprecision, no Riemann–Siegel
  outer formula, no zero finder.
- Caps $\mathrm{Max\_N},\mathrm{Max\_M}\le 256$ keep tests fast; production
  ζ heights need enormous $N$ and careful analysis of truncation /
  approximation error.
- The sketch’s complexity is still classroom-scale; the README states the
  $O(N^{1+\varepsilon})$ **intent**, not a benchmark claim.

## Build and test

```bash
make        # gnatmake -gnatwa -gnat2022 -Podlyzko_schonhage.gpr
make test   # bin/tests — expect ≥ 80 PASS, zero FAIL
make clean
```

Requires GNAT with Ada 2022 support. `SPARK_Mode => Off`.

## API brief

| Entity | Role |
| --- | --- |
| `Real`, `Complex` | Digits-15 domain |
| `Naive_Dirichlet_Poly` | Single $P(s)$ |
| `Naive_Batch` | Multipoint $O(MN)$ |
| `DFT` / `IDFT` | Radix-2 FFT pair |
| `Polynomial_Eval_FFT` | Coeffs → values at roots of unity |
| `Fast_Batch_Geometric` | Geometric equally-spaced batch |
| `Odlyzko_Schonhage_Sketch` | Blocked educational OS sketch |
| `Zeta_Partial` / `Eta_Partial` | Partial $\zeta$ / $\eta$ |
| `Invalid_Argument` | Domain / size errors |

## References

- Odlyzko, A. M.; Schönhage, A. (1988), “Fast algorithms for multiple
  evaluations of the Riemann zeta function”, *Trans. Amer. Math. Soc.*
- Wikipedia: Odlyzko–Schönhage algorithm (link above)
- Gourdon (2004), large-scale zero verification notes
