# Filtered Back-Projection — Ada 2023

Educational, self-contained Ada 2023 package implementing **discrete
parallel-beam filtered back-projection (FBP)** — the classical analytical
inversion of the 2-D Radon transform used as a teaching model for tomographic
reconstruction. Pipeline on small $N\times N$ grids ($N\le 32$):

1. build a disk / Shepp-lite phantom,
2. **forward project** (discrete Radon / sinogram),
3. apply a 1-D **Ram-Lak ramp filter** by spatial convolution (pure Ada, no
   FFT library),
4. **back-project** filtered rays onto the image and normalize.

Based on [Wikipedia: Radon transform](https://en.wikipedia.org/wiki/Radon_transform)
(inversion / filtered back-projection). See also
[Filtered back-projection](https://en.wikipedia.org/wiki/Filtered_back_projection).

Part of the **RobertBoettcherSF** Ada algorithm series.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Sibling / roadmap:

- Prior sheet: **[Ada-Birkhoff-Interpolation](https://github.com/RobertBoettcherSF/Ada-Birkhoff-Interpolation)**
- After this sheet: skip **Elementary** section + **Unrestricted** Ada $=x$ →
  next **[Kahan summation](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)**
- Grid style sibling: **[Ada-Tricubic-Interpolation](https://github.com/RobertBoettcherSF/Ada-Tricubic-Interpolation)**,
  **[Ada-Bilinear-Interpolation](https://github.com/RobertBoettcherSF/Ada-Bilinear-Interpolation)**

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Idea** | Discrete Radon inversion | Parallel-beam FBP |
| **Filter** | Spatial Ram-Lak convolution | $h[0]=\tfrac14$, odd lags $-1/(\pi^{2}k^{2})$ |
| **Phantom** | Disk / Shepp-lite | Teaching only |
| **Status** | `Ok` … `Ill_Started` | Incl. `Dimension_Error`, `Too_Small` |
| **Cap** | $N\le 32$, angles $\le 64$, bins $\le 48$ | Educational Float |
| **FFT** | Not required | Prefer pure Ada convolution |

## Brief history

Johann Radon (1917) introduced the transform that integrates a planar density
along lines, and gave an inversion formula. In tomography the measured
projections are (ideally) samples of $Rf$; recovering $f$ is the inverse
problem. The practical analytical method is **filtered back-projection**:
convolve each projection with a ramp (Ram-Lak) kernel whose Fourier
multiplier is $|k|$, then smear the filtered profiles back along the ray
directions and integrate over angle. Iterative methods exist; this package
teaches the classical FBP sketch only.

## Algorithm (this package)

**Forward projection.** For angles
$\theta_a = a\pi / N_A$ ($a=0..N_A-1$) and detector offsets
$t_b = b - (N_B-1)/2$, accumulate nearest-neighbour image samples along the
ray
$$
(x,y) = (c_x,c_y) + t\,(\cos\theta,\sin\theta) + u\,(-\sin\theta,\cos\theta)
$$
with step $\Delta u = 1/2$. For a consistent discrete measure,
$\sum_b S(a,b) \approx \sum_{i,j} V(i,j)$ at each angle.

**Ram-Lak filter.** Each projection row is convolved with the discrete ramp
impulse response
$$
h[k]=\begin{cases}
1/4 & k=0,\\
0 & k\text{ even},\ k\neq 0,\\
-1/(\pi^{2} k^{2}) & k\text{ odd.}
\end{cases}
$$
(spatial domain — no FFT).

**Back-projection.** For each pixel $(i,j)$, interpolate the filtered
sinogram at $t = (i-c_x)\cos\theta + (j-c_y)\sin\theta$ and accumulate; scale
by $\pi/N_A$:
$$
f(\mathbf{x})=\int_{0}^{\pi}({\mathcal{R}}f(\cdot,\theta)*h)
\bigl(\langle\mathbf{x},\mathbf{n}_{\theta}\rangle\bigr)\,d\theta.
$$

Artifacts on tiny grids (streaks, cupping, imperfect amplitude) are expected
and documented by the tests via correlation / center-vs-background checks —
not clinical CT quality.

## API summary

| Symbol | Role |
| --- | --- |
| `Image_2D`, `Sinogram` | Square image / angle×bin sinogram |
| `Max_N`, `Max_Angles`, `Max_Bins` | Hard caps ($32$, $64$, $48$) |
| `Status` | `Ok` / `Ill_Started` / `Dimension_Error` / `Too_Small` |
| `Image_Result`, `Sinogram_Result` | Value + `Stat` + `Success` |
| `Near`, `Image_Sum`, `Correlation` | Numeric helpers |
| `Make_Empty_Image`, `Make_Empty_Sinogram` | Zero builders |
| `Make_Disk_Phantom`, `Make_Shepp_Lite` | Teaching phantoms |
| `Forward_Project` | Discrete parallel-beam Radon |
| `Filter_Ram_Lak` | Spatial ramp convolution |
| `Back_Project` | Smear + $\pi/N_A$ normalize |
| `Reconstruct_FBP` | Full FBP pipeline |
| `Ram_Lak_Kernel_Value` | Exposed $h[k]$ for tests |

## Limits and caveats

- **Educational `Float`** — ordinary single precision on $N\le 32$; not a
  production CT kernel.
- **Discrete approximation** — nearest-neighbour rays, unit detector spacing,
  finite angles; streak / amplitude artifacts are normal.
- **No clinical claims** — phantoms are disks / Shepp-lite toys; do **not**
  treat results as medical imaging validation.
- **No external FFT** — Ram-Lak is spatial convolution by design (easy to
  read; fine at these sizes).

## Build and test

```text
make        # gnatmake -gnatwa -gnat2022 -Pfiltered_back_projection.gpr
make test   # run bin/tests — expect ALL PASSED
make clean
```

Requires GNAT with Ada 2022 support. There is **no** `main.adb`; `tests.adb`
is the sole main unit listed in `filtered_back_projection.gpr`.

## Layout (exactly 7 root files)

```text
.gitignore
Makefile
README.md
filtered_back_projection.ads
filtered_back_projection.adb
filtered_back_projection.gpr
tests.adb
```

## References

1. [Wikipedia: Radon transform](https://en.wikipedia.org/wiki/Radon_transform)
   — definition and filtered back-projection / inversion formula
2. [Wikipedia: Filtered back-projection](https://en.wikipedia.org/wiki/Filtered_back_projection)
3. G. N. Ramachandran and A. V. Lakshminarayanan, *Three-dimensional
   reconstruction from radiographs and electron micrographs…* (1971) —
   Ram-Lak ramp filter
4. Next after this sheet: **[Kahan summation](https://en.wikipedia.org/wiki/Kahan_summation_algorithm)**
   (skip Elementary section + Unrestricted Ada $=x$)
