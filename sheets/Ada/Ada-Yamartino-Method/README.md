# Yamartino Method (Ada 2023)

Educational, self-contained Ada 2023 package implementing the
[Wikipedia: Yamartino method](https://en.wikipedia.org/wiki/Yamartino_method)
— Robert J. Yamartino’s 1984 **single-pass** approximation of the
**circular mean** and **standard deviation** of wind direction (angular data).

Naive linear mean/variance on angles wrap incorrectly: 1° and 359° average
to 180° instead of ~0°. Circular statistics place directions on the unit
circle; Yamartino accumulates only $\sin\theta$ and $\cos\theta$ totals
so the interval can be reduced without storing every sample.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Circular mean** | $\theta_a = \mathrm{atan2}(s_a, c_a)$ | Four-quadrant |
| **Single-pass σ** | Yamartino $\varepsilon$ + arcsin factor | vs two-pass |
| **Online accumulator** | `Running_Yamartino` | $n$, $\sum\sin$, $\sum\cos$ |
| **Batch API** | `Yamartino` / `Yamartino_Degrees` | Convenience |
| **Two-pass reference** | `Circular_Mean`, angular / R-based std | Tests / compare |
| **Naive linear** | Documented **wrong** for wrap-around | Educational contrast |

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

## Features

| Area | Subprograms | Role |
| --- | --- | --- |
| Angles | `To_Radians`, `To_Degrees`, `Normalize_Angle`, `Normalize_Degrees` | Convert / wrap |
| Online | `Make_Empty`, `Reset`, `Add_Sample`, `Add_Degrees`, `Finalize`/`Compute` | Single-pass |
| Batch | `Yamartino`, `Yamartino_Degrees` | Array convenience |
| Result | `Yamartino_Result`, `Mean_Degrees`, `Std_Dev_Degrees` | Mean, σ, ε, R, n |
| Pieces | `Mean_Resultant_Length`, `Epsilon_From_Resultant`, `Yamartino_Sigma` | Formula parts |
| Reference | `Circular_Mean`, `Circular_Std_Dev_Two_Pass`, `Circular_Std_Dev_Angular` | Two-pass |
| Contrast | `Naive_Linear_Mean`, `Naive_Linear_Std_Dev` | Wrong on wrap |

Strong typing uses domain types (`Real` digits 12, `Angle_Radians`,
`Angle_Degrees`, `Running_Yamartino`, `Yamartino_Result`, …).
Public subprograms carry `Pre` / `Post` / `Global` where meaningful
(`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Empty_Sample` (also
`Degenerate_Geometry`), `Capacity_Exceeded`.

## Formula Summary

Accumulate over $n$ angles $\theta_i$:

$$
s_a = \frac{1}{n}\sum_{i=1}^{n}\sin\theta_i,\quad
c_a = \frac{1}{n}\sum_{i=1}^{n}\cos\theta_i
$$

$$
\theta_a = \text{arctan2}(s_a, c_a) \quad (\text{four-quadrant; Ada: Arctan(Y => } s_a \text{, X => } c_a \text{)})
$$

$$
\varepsilon = \sqrt{1 - (s_a^2 + c_a^2)},\qquad
\sigma_\theta = \arcsin(\varepsilon)\left[1 + \left(\frac{2}{\sqrt{3}} - 1\right)\varepsilon^3\right]
$$

Constant direction $\implies \varepsilon = 0 \implies \sigma_\theta = 0$. Oscillating or nearly uniform directions push $\varepsilon \to 1$ and $\sigma_\theta \to \pi / \sqrt{3}$.

## Usage

```bash
cd /workspace/ada-yamartino-method
make        # build bin/tests
make test   # build (if needed) and run the suite
make clean  # remove obj/ and bin/
```

There is no interactive `main.adb`; `tests.adb` is the project main.

## Testing

`tests.adb` is a standalone suite (local `Check`, no `Ada.Assertions`) with
14 sections covering:

- Convert / normalize helpers
- Empty accumulator / empty array raises
- Single sample and constant wind
- Wrap-around 1° / 359° (meteorological)
- Small dispersion vs two-pass closeness
- Opposing / high-dispersion winds
- Running accumulator ≡ batch
- Degree API
- $\varepsilon$ / $\sigma$ formula pieces
- Naive linear fails wrap-around where Yamartino succeeds
- High-$n$ synthetic stability
- Degenerate / cardinal / equivalent-angle fixtures

## Building

```text
gnatmake -gnatwa -gnat2022 -Pyamartino_method.gpr
```

Flags: **`-gnatwa`** (all warnings as diagnostics) and **`-gnat2022`**.
The package must compile with **zero errors and zero warnings**.

Layout (root only): `yamartino_method.ads` / `.adb` / `.gpr`, `Makefile`,
`tests.adb`, `README.md`, `.gitignore` (`obj/`, `bin/`).

## References

1. Yamartino, R. J. (1984). *A Comparison of Several “Single-Pass” Estimators
   of the Standard Deviation of Wind Direction.* Journal of Climate and
   Applied Meteorology, 23(9), 1362–1366.
   doi:10.1175/1520-0450(1984)023\<1362:ACOSPE\>2.0.CO;2
2. U.S. EPA. *Meteorological Monitoring Guidance for Regulatory Modeling
   Applications* (section 6.2.1).
3. Farrugia, P. S., & Micallef, A. (2006). *Comparative analysis of estimators
   for wind direction standard deviation.* Meteorological Applications, 13(1),
   29–41. doi:10.1017/S1350482705001982
4. [Wikipedia: Yamartino method](https://en.wikipedia.org/wiki/Yamartino_method)
