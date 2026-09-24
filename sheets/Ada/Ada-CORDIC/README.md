# CORDIC — Ada 2023

Educational, self-contained Ada 2023 package for **CORDIC** (*coordinate
rotation digital computer*), Jack E. Volder’s circular shift-and-add algorithm
for $\sin$, $\cos$, $\mathrm{atan2}$, and vector magnitude. Prefills
$\theta_i=\arctan(2^{-i})$, runs **rotation** and **vectoring** modes with
gain $K$ / $1/K$ compensation, and caps iterations at $40$. Educational
`Long_Float` multiplies by $2^{-i}$ stand in for hardware arithmetic shifts.

Based on [Wikipedia: CORDIC](https://en.wikipedia.org/wiki/CORDIC).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Montgomery-Reduction](https://github.com/RobertBoettcherSF/Ada-Montgomery-Reduction)** — REDC / Montgomery multiply
- **BKM** — upcoming
- **Exponentiation by squaring** — upcoming
- **Addition-chain exponentiation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Table** | $\theta_i=\arctan(2^{-i})$ | Prefill $i=0..39$ at elaboration |
| **Rotation** | Drive residual $z\to 0$ | $\sin$/$\cos$ of an angle |
| **Vectoring** | Drive $y\to 0$ | $\mathrm{atan2}$ / magnitude |
| **Gain** | $K_n=\prod\cos\theta_i$ | Start $x\leftarrow K_n$; magnitude $x_n/A_n$ with $A_n=1/K_n$ |
| **Shift stand-in** | Multiply by $2^{-i}$ | Documents hardware shift-and-add |
| **Cap** | $n\le 40$ | `Max_Iterations = 40` |
| **Oracle** | `Exact_Sin` / `Exact_Cos` / `Exact_Atan2` / `Exact_Hypot` | Ada `Long_Elementary_Functions` |
| **Helpers** | `Near`, `Abs_Error`, `Rel_Error`, `Reduce_Angle` | Classroom utilities |

## Brief history

CORDIC was conceived in 1956 by Jack E. Volder at Convair to replace an analog
resolver in the B-58 navigation computer. The 1959 paper made the binary
circular algorithm public; Hewlett-Packard later shipped decimal CORDIC in the
HP 9100A and generalized it (Walther, 1971) to hyperbolic / linear modes used
in the HP-35. Because each micro-rotation needs only add, subtract, and a
bit-shift (plus a small arctangent ROM), CORDIC remains popular in FPGAs,
early FPUs (e.g. Intel 8087), and microcontroller math libraries when a full
multiplier is expensive.

## Algorithm (this package)

**Micro-rotation.** With $\gamma_i=\arctan(2^{-i})$ and direction
$\sigma_i=\pm 1$:

$$
\begin{aligned}
x_{i+1} &= x_i - \sigma_i\, y_i\, 2^{-i}, \\
y_{i+1} &= y_i + \sigma_i\, x_i\, 2^{-i}, \\
z_{i+1} &= z_i - \sigma_i\, \gamma_i.
\end{aligned}
$$

Each step is a scaled rotation by $\pm\gamma_i$. The omitted cosine factor
accumulates into the constant gain

$$
K_n=\prod_{i=0}^{n-1}\cos\gamma_i=\prod_{i=0}^{n-1}\frac{1}{\sqrt{1+2^{-2i}}},
\qquad
K_\infty\approx 0.6072529350088813.
$$

**Rotation mode** (sin / cos). Reduce the angle into $(-\pi,\pi]$, then fold
into $(-\pi/2,\pi/2]$ (negate both outputs if a $\pm\pi$ fold was used). Start
from $(x_0,y_0,z_0)=(K_n,\,0,\,\beta)$ and choose
$\sigma_i=\mathrm{sign}(z_i)$ so $z\to 0$. Then
$(x_n,y_n)\approx(\cos\beta,\sin\beta)$.

**Vectoring mode** (atan2 / magnitude). Fold the left half-plane so $x>0$,
start from the input vector with $z_0=0$, and choose $\sigma_i$ to drive
$y\to 0$. Then $z_n\approx\mathrm{atan2}(y,x)$ (plus a $\pm\pi$ quadrant
correction) and $x_n\approx A_n\sqrt{x^2+y^2}$ with $A_n=1/K_n$, so magnitude is
$x_n/A_n=x_n\,K_n$.

**Worked check.** Angle $\pi/4$: after enough iterations,
$\sin=\cos\approx\sqrt{2}/2$. Vector $(3,4)$: magnitude $5$;
$\mathrm{atan2}(4,3)=\arctan(4/3)$.

## API summary

| Symbol | Role |
| --- | --- |
| `Sin_Cos(Angle, Sin_V, Cos_V, Iterations)` | Rotation-mode sine and cosine |
| `Sin(Angle, Iterations)`, `Cos(...)` | Convenience wrappers |
| `Atan2(Y, X, Iterations)` | Vectoring-mode two-argument arctangent |
| `Magnitude(X, Y, Iterations)` | $\sqrt{X^2+Y^2}$ via vectoring $+1/K$ |
| `Arctan_Table(I)` | Prefill entry $\theta_i$ |
| `Gain_K(N)`, `Inv_Gain_K(N)` | $K_n$ and $1/K_n$ |
| `Reduce_Angle(Angle)` | Map into $(-\pi,\pi]$ |
| `Exact_Sin`, `Exact_Cos`, `Exact_Arctan`, `Exact_Atan2`, `Exact_Hypot` | Oracles |
| `Near`, `Abs_Error`, `Rel_Error` | Numeric helpers |
| `Iteration_Count` | Subtype $1..40$ |
| `Inv_K_Inf`, `K_Inf`, `Pi`, `Half_Pi`, … | Documented constants |

## Limits and caveats

- **Educational `Long_Float`** — multiplies by $2^{-i}$ replace shifts so the
  control flow matches hardware CORDIC without fixed-point scaling noise.
- **Cap** — `Max_Iterations = 40`; double precision is saturated earlier.
- **Convergence cone** — circular CORDIC converges for
  $|\beta|\lesssim\sum_i\arctan(2^{-i})\approx 1.743$ rad ($\approx 99.9^\circ$).
  This package reduces / folds angles so classroom inputs covering a full
  turn still work.
- **Origin** — `Atan2(0,0)` returns $0$ (educational; Ada leaves it
  implementation-defined).
- **Not** hyperbolic / linear CORDIC, BKM, or a multiprecision kernel.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pcordic.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `cordic.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
cordic.ads
cordic.adb
cordic.gpr
tests.adb
```

## License

Educational reference code for the RobertBoettcherSF Ada algorithm series.
