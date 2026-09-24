# Lanczos Resampling — Ada 2023

Educational, self-contained Ada 2023 package implementing **Lanczos
resampling**: reconstruct a discrete 1-D signal (or resize a 2-D image) by
convolving samples with the **Lanczos kernel** — a normalized sinc windowed
by a second, longer sinc. With parameter $a$ (typically $2$ or $3$),

$$
L(x)=\begin{cases}
\mathrm{sinc}(x)\,\mathrm{sinc}(x/a) & |x|<a,\\
0 & |x|\ge a,
\end{cases}
\qquad
\mathrm{sinc}(x)=\frac{\sin(\pi x)}{\pi x},\quad \mathrm{sinc}(0)=1.
$$

One-dimensional interpolation at a real site $x$ is

$$
S(x)=\sum_{i=\lfloor x\rfloor-a+1}^{\lfloor x\rfloor+a} s_i\, L(x-i),
$$

with edge handling (clamp / reflect / zero) when $i\notin[0,N-1]$. Cap
$n\le 256$ for 1-D signals and $N\le 64$ per 2-D axis; educational
`Float`. Separable 2-D resize applies nested 1-D passes.

> **Not** the Krylov / tridiagonal eigenvalue algorithm. That lives in
> **[Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos)**
> (Wikipedia *Lanczos algorithm*). This package is the **image / signal
> sinc-window filter** (Wikipedia *Lanczos resampling*).

Based on [Wikipedia: Lanczos resampling](https://en.wikipedia.org/wiki/Lanczos_resampling).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling packages:

- **[Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation)** — piecewise-constant / Voronoi
- **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)** — tensor-product Catmull–Rom on 3-D grids
- **Bilinear interpolation** — upcoming
- **Bicubic interpolation** — upcoming

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Sinc-window reconstruction | Duchon / Lanczos $\sigma$-window |
| **Kernel** | $L(x)=\mathrm{sinc}(x)\mathrm{sinc}(x/a)$ | Support $\|x\|<a$ |
| **1-D** | Discrete convolution with $L$ | Exact at integers |
| **2-D** | Separable nested 1-D | Educational image resize |
| **Edges** | Clamp / Reflect / Zero | Fetch $s_i$ out of range |
| **Status** | `Ok` … `Ill_Started` | Incl. `Empty`, `Out_Of_Domain`, `Bad_Parameter` |
| **Cap** | $n\le 256$, $N\le 64$/axis | `Max_Signal`, `Max_Image`; $a\le 8$ |

## Brief history

Claude Duchon named the filter after Cornelius Lanczos because the window
is the central lobe of a stretched sinc — the same $\sigma$-factor Lanczos
used to tame the Gibbs phenomenon in truncated Fourier series. In imaging
it became a popular “best compromise” interpolator for scaling and
rotation: sharper than bilinear, with less ringing than an ideal
brick-wall sinc. This package teaches the **kernel definition** and the
**1-D / separable 2-D** formulas from Wikipedia, not a production GPU
texture path.

## Algorithm (this package)

### Kernel

$\mathrm{sinc}$ is the **normalized** sinc. At $x=0$ both factors are $1$,
so $L(0)=1$. At every other integer $\|k\|<a$, $\mathrm{sinc}(k)=0$, hence
$L(k)=0$. Outside $\|x\|\ge a$ the kernel is identically zero (compact
support of width $2a$).

### 1-D resampling

Given samples $s_0,\ldots,s_{N-1}$ on the unit lattice, evaluate $S(x)$ by
summing $2a$ taps centred on $\lfloor x\rfloor$. Indices $i$ outside
$[0,N-1]$ are resolved by `Edge_Mode`:

- **Clamp** — repeat endpoint values
- **Reflect** — mirror the index about the ends
- **Zero** — treat missing samples as $0$

Because $L(k)=\delta_{k0}$ on the integers inside the support, $S(i)=s_i$
exactly (within Float roundoff). Constant signals are only
**approximately** preserved — Lanczos is not a partition of unity.

### 2-D / resize

`Resample_2D` nests 1-D passes (horizontal lines weighted along $y$).
`Resize_1D` / `Resize_2D` map output index $j$ to source coordinate

$$
x=j\cdot\frac{N-1}{N'-1}
\qquad(N'>1),\qquad x=0\ (N'=1),
$$

so integer scale $N'=N$ is an identity (up to Float noise). Separable
2-D resize: horizontal pass per row, then vertical pass per column.

## API summary

| Symbol | Role |
| --- | --- |
| `Signal_1D`, `Image_2D` | Packed 1-D / 2-D lattices |
| `Max_Signal`, `Max_Image`, `Max_A` | Caps ($256$, $64$, $8$) |
| `A_Param` | Lanczos $a\in 1..8$ (typical $2$ or $3$) |
| `Status` | `Ok` / `Empty` / `Out_Of_Domain` / `Bad_Parameter` / `Ill_Started` |
| `Edge_Mode` | `Clamp` / `Reflect` / `Zero` |
| `Eval_Result`, `Resize_*_Result` | Value or container + `Stat` / `Success` |
| `Near`, `Sinc`, `Kernel` | Numeric helpers + $L_a(x)$ |
| `Is_Valid_*`, `In_Domain` | Domain utilities |
| `Get`, `Set`, `Fetch` | Accessors / edge-aware fetch |
| `Resample_1D`, `Resample_2D` | Convolution evaluation |
| `Resize_1D`, `Resize_2D` | Separable resize |
| `Make_Constant_1D`, `Make_Ramp_1D`, `Make_Impulse_1D` | 1-D builders |
| `Make_Constant_2D`, `Make_Ramp_2D`, `Make_Checkerboard_2D` | 2-D builders |
| `Make_Example_*` | Canonical impulse / ramp / checker |

## Limits and caveats

- **Not Ada-Lanczos** — eigenvalue Krylov method is a different package /
  Wikipedia page.
- **Educational `Float`** — ordinary single precision; not a production
  image scaler.
- **Approximate constants** — kernel weights do not sum to exactly $1$ at
  every fractional offset; tests use a modest tolerance.
- **Ringing** — negative side lobes can overshoot near sharp edges (Gibbs);
  that is inherent to the filter, not a bug.
- **Caps** — $n\le 256$, $N\le 64$/axis, $a\le 8$; oversized resize requests
  return `Out_Of_Domain`.

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Planczos_resampling.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `lanczos_resampling.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
lanczos_resampling.ads
lanczos_resampling.adb
lanczos_resampling.gpr
tests.adb
```

## References

1. [Wikipedia: Lanczos resampling](https://en.wikipedia.org/wiki/Lanczos_resampling)
2. Claude E. Duchon, *Lanczos Filtering in One and Two Dimensions*,
   Journal of Applied Meteorology (1979).
3. Contrast: [Wikipedia: Lanczos algorithm](https://en.wikipedia.org/wiki/Lanczos_algorithm)
   / [Ada-Lanczos](https://github.com/RobertBoettcherSF/Ada-Lanczos) (eigenvalues).
4. Siblings: [Ada-Nearest-Neighbor-Interpolation](https://github.com/RobertBoettcherSF/Ada-Nearest-Neighbor-Interpolation),
   [Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation);
   upcoming Bilinear, Bicubic.
