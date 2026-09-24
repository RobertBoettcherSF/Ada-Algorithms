# Alpha Max Plus Beta Min Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the **alpha max plus beta
min** high-speed approximation of Pythagorean addition
$|z|=\sqrt{a^{2}+b^{2}}$ (complex magnitude / 2-D vector norm / hypotenuse)
**without** squares or square roots. Educational `Long_Float`.

Based on
[Wikipedia: Alpha max plus beta min algorithm](https://en.wikipedia.org/wiki/Alpha_max_plus_beta_min_algorithm).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages (related numeric helpers):

- **[Ada-Square-Root-Algorithms](https://github.com/RobertBoettcherSF/Ada-Square-Root-Algorithms)** — Heron / digit-by-digit / bisection / inv-sqrt Newton
- **[Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root)** — Newton / Halley $n$-th roots
- **Spigot** — upcoming
- **Rounding** — upcoming
- **Newton multiplicative inverse** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Core** | $\alpha\,\mathbf{Max}+\beta\,\mathbf{Min}$ | $\mathbf{Max}=\max(\|a\|,\|b\|)$, $\mathbf{Min}=\min(\|a\|,\|b\|)$ |
| **Half** | $\alpha=1$, $\beta=\tfrac12$ | Classic; largest error $\approx 11.80\%$ |
| **Quarter** | $\alpha=1$, $\beta=\tfrac14$ | Shift-friendly; $\approx 11.61\%$ |
| **Shift** | $\alpha=1$, $\beta=\tfrac38$ | Binary-shift friendly; $\approx 6.80\%$ |
| **Fifteenths** | $\alpha=\tfrac{15}{16}$, $\beta=\tfrac{15}{32}$ | Tighter shift fit; $\approx 6.25\%$ |
| **Optimal** | $\alpha_{0}\approx 0.9604$, $\beta_{0}\approx 0.3978$ | Minimax geometric; $\approx 3.96\%$ |
| **Clamped** | $\max(\mathbf{Max},\alpha\,\mathbf{Max}+\beta\,\mathbf{Min})$ | Wiki fix when $\alpha<1$ near axes |
| **Two-segment** | $\max(\|z_{0}\|,\|z_{1}\|)$ | Optional second coefficient pair |
| **Oracle** | `Exact_Hypot` via $\sqrt{a^{2}+b^{2}}$ | Educational; keep magnitudes modest |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error` | Classroom utilities |

## Brief history

DSP and graphics pipelines often need $|a+bi|=\sqrt{a^{2}+b^{2}}$ at high
throughput. Full squares and square roots are expensive in early digital
hardware and still costly in some FPGA / fixed-point paths. The **alpha max
plus beta min** estimator replaces them with a comparison, a multiply (or
bit-shift), and an add. Lyons (*Understanding Digital Signal Processing*) and
community “DSP Trick: Magnitude Estimator” notes popularized the form; Wikipedia
records the geometric optimal $(\alpha_{0},\beta_{0})$ and common dyadic
presets suited to shift-add circuitry.

## Algorithm (this package)

**Goal.** Approximate

$$
|z|=\sqrt{a^{2}+b^{2}}
$$

by

$$
|z|\approx\alpha\,\mathbf{Max}+\beta\,\mathbf{Min},
$$

where $\mathbf{Max}=\max(|a|,|b|)$ and $\mathbf{Min}=\min(|a|,|b|)$.

**Closest geometric coefficients** (Wikipedia):

$$
\alpha_{0}=\frac{2\cos\frac{\pi}{8}}{1+\cos\frac{\pi}{8}}=1-\tan^{2}\frac{\pi}{16}\approx 0.960433870103,
$$

$$
\beta_{0}=\frac{2\sin\frac{\pi}{8}}{1+\cos\frac{\pi}{8}}=2\tan\frac{\pi}{16}\approx 0.397824734759,
$$

with maximum relative error about $3.96\%$.

**Clamped improvement** (when $\alpha<1$, the raw estimate can fall below
$\mathbf{Max}$ near the axes — geometrically impossible):

$$
|z|\approx\max\bigl(\mathbf{Max},\,\alpha\,\mathbf{Max}+\beta\,\mathbf{Min}\bigr).
$$

**Two-segment** form takes the max of two linear estimates
$|z_{0}|=\alpha_{0}\,\mathbf{Max}+\beta_{0}\,\mathbf{Min}$ and
$|z_{1}|=\alpha_{1}\,\mathbf{Max}+\beta_{1}\,\mathbf{Min}$.

**Worked check.** For the $3$-$4$-$5$ triangle,
$\alpha_{0}\cdot 4+\beta_{0}\cdot 3\approx 5.04$ versus exact $5$. With
$\alpha=1$, $\beta=\tfrac12$: $4+\tfrac32=5.5$. With $\alpha=1$,
$\beta=\tfrac38$: $4+1.125=5.125$.

## API summary

| Symbol | Role |
| --- | --- |
| `Approx(A,B,Alpha,Beta)` | Core $\alpha\,\mathbf{Max}+\beta\,\mathbf{Min}$ |
| `Approx_Half(A,B)` | Preset $\alpha=1$, $\beta=\tfrac12$ |
| `Approx_Quarter(A,B)` | Preset $\alpha=1$, $\beta=\tfrac14$ |
| `Approx_Shift_Friendly(A,B)` | Preset $\alpha=1$, $\beta=\tfrac38$ |
| `Approx_Fifteenths(A,B)` | Preset $\alpha=\tfrac{15}{16}$, $\beta=\tfrac{15}{32}$ |
| `Approx_Optimal(A,B)` | Preset $(\alpha_{0},\beta_{0})$ |
| `Approx_Clamped` / `Approx_Optimal_Clamped` | $\max(\mathbf{Max},\ldots)$ |
| `Approx_Two_Segment` | $\max(\|z_{0}\|,\|z_{1}\|)$ |
| `Exact_Hypot(A,B)` | Oracle $\sqrt{A^{2}+B^{2}}$ (`Long_Float`) |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Alpha_*` / `Beta_*` / `Max_Rel_*` | Documented constants and error ceilings |

## Limits and caveats

- **Educational `Long_Float`** — double precision; not a fixed-point DSP kernel.
- **`Exact_Hypot` overflow** — naive $A^{2}+B^{2}$ can overflow for huge
  magnitudes; tests keep values modest. Production code should use a scaled
  hypot.
- **Approximation, not exact** — each preset has a documented max relative
  error; use `Exact_Hypot` (or a real hypot) when accuracy matters.
- **$\alpha<1$ near axes** — raw Optimal / Fifteenths undershoot $\mathbf{Max}$;
  prefer `Approx_Optimal_Clamped` when that matters.
- **Two-segment cost** — roughly doubles arithmetic; may defeat the purpose on
  some hardware (as Wikipedia notes).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Palpha_max_plus_beta_min.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `alpha_max_plus_beta_min.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
alpha_max_plus_beta_min.ads
alpha_max_plus_beta_min.adb
alpha_max_plus_beta_min.gpr
tests.adb
```

## References

1. [Wikipedia: Alpha max plus beta min algorithm](https://en.wikipedia.org/wiki/Alpha_max_plus_beta_min_algorithm)
2. Lyons, Richard G. — *Understanding Digital Signal Processing*, §13.2 (Prentice Hall, 2004).
3. Griffin, Grant — “DSP Trick: Magnitude Estimator.”
4. Siblings: [Ada-Square-Root-Algorithms](https://github.com/RobertBoettcherSF/Ada-Square-Root-Algorithms),
   [Ada-Nth-Root](https://github.com/RobertBoettcherSF/Ada-Nth-Root);
   upcoming Spigot, Rounding, Newton multiplicative inverse.
