# Lloyd's Algorithm — Ada 2023 (Voronoi Iteration / k-means)

Educational, self-contained Ada 2023 package for
[Wikipedia: Lloyd's algorithm](https://en.wikipedia.org/wiki/Lloyd%27s_algorithm):
**Lloyd's algorithm** (also *Voronoi iteration* or *relaxation*), named after
**Stuart P. Lloyd** of Bell Labs. Lloyd proposed the method in **1957** as a
technique for pulse-code modulation; the work circulated widely and was
published in **1982**. A similar algorithm was developed independently by
**Joel Max** (1960), which is why the scalar-quantization form is often called
the **Lloyd–Max** algorithm.

In the continuous setting the algorithm repeatedly (1) builds the
**Voronoi diagram** of *k* sites, (2) computes the **centroid** of each
Voronoi cell, and (3) moves each site to its cell centroid. Iterating yields
an approximate **centroidal Voronoi tessellation (CVT)**.

On a **finite point set** the same iteration is exactly the classic
**batch k-means** (Lloyd / Forgy) procedure:

1. Assign each data point to the nearest site (Voronoi partition of the sample).
2. Move each site to the mean of its assigned points.
3. Repeat until sites move less than `Tol` or `Max_Iters` is reached.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. A natural vector-
quantization sibling is the **Linde–Buzo–Gray (LBG)** algorithm (upcoming in
the series if not already present).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Metric** | Euclidean $L_2$ | `Distance`, `Squared_Distance` |
| **Discrete step** | Assign → centroid update | Sample Voronoi + means |
| **Empty cluster** | Keep previous site + mark | `Empty_Flags`; optional `Degenerate_Cluster` |
| **Init** | Spaced data indices | `Init_Sites_From_Data` |
| **Stop** | $\max_k \Vert \mu_k'-\mu_k \Vert < \mathrm{Tol}$ | or `Max_Iters` |
| **CVT approx** | Uniform 2-D pixel grid | `Run_Lloyd_Grid_2D` |
| **Quality** | Within-cluster SSE / inertia | $\sum_i \Vert x_i-\mu_{\ell_i} \Vert^2$ |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_Sites` | Fixed educational limits |
| Types | `Point`, `Dataset`, `Sites`, `Labels`, `Parameters`, `Lloyd_Result` | Domain model |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point` / `Extract_Site` | $L_2$ helpers |
| Partition | `Nearest_Site`, `Assign_Labels` | Voronoi of the sample |
| Update | `Compute_Centroids` | Means; empty → keep + mark |
| Quality | `Within_Cluster_SSE` / `Inertia` | SSE alias pair |
| Init | `Init_Sites_From_Data` | Spaced indices (doc'd) |
| Fit | `Run_Lloyd` / `Run_KMeans` | Discrete Lloyd iteration |
| CVT | `Run_Lloyd_Grid_2D` | Grid relaxation in a bbox |

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`,
`Degenerate_Cluster`.

## Algorithm notes

### Continuous relaxation (CVT)

Given sites $s_1,\ldots,s_k$ in a domain $\Omega$:

$$
V_i=\{x\in\Omega:\|x-s_i\|\le\|x-s_j\|\ \forall j\},
\qquad
s_i \leftarrow \frac{\int_{V_i} x\,dx}{\int_{V_i} dx}.
$$

Exact Voronoi construction in high dimension is non-trivial; a common
approximation labels a fine pixel grid (or Monte Carlo samples) by nearest
site and averages coordinates — exactly what `Run_Lloyd_Grid_2D` does in 2-D.

### Discrete / k-means form

On data $\{x_1,\ldots,x_n\}$:

$$
\ell_i=\arg\min_k\|x_i-\mu_k\|^2,
\qquad
\mu_k\leftarrow\frac{1}{|C_k|}\sum_{i\in C_k}x_i
\quad(C_k=\{i:\ell_i=k\}).
$$

**Empty clusters:** if $C_k=\emptyset$, this package **keeps** the previous
$\mu_k$ and sets `Empty(k) := True`. Optionally `Raise_Empty` raises
`Degenerate_Cluster` after the keep update.

**Initialization:** `Init_Sites_From_Data` copies spaced data rows
$i_j=1+\lfloor(j-1)(N-1)/(K-1)\rfloor$ (for $K>1$); not random Forgy /
k-means++ — deterministic for tests.

Inertia (SSE) is nonincreasing under standard assign-then-update when
centroids are true means of nonempty clusters.

## Applications (from Wikipedia)

- Scalar / vector **quantization** and data compression (Lloyd–Max; LBG).
- Computer graphics: **dithering**, **stippling**, sampling.
- **Mesh smoothing** for finite-element triangle meshes.
- Approximating **centroidal Voronoi tessellations**.

## Build and test

```bash
cd /workspace/ada-lloyds-algorithm
make clean && make        # gnatmake -gnatwa -gnat2022 -Plloyds_algorithm.gpr
make test                 # runs bin/tests; Fail_Count must be 0
```

Layout (root only): `lloyds_algorithm.ads`, `lloyds_algorithm.adb`,
`lloyds_algorithm.gpr`, `Makefile`, `tests.adb`, `README.md`, `.gitignore`.
No `main.adb` — the test harness is the main program.

## Usage

```ada
with Lloyds_Algorithm; use Lloyds_Algorithm;

declare
   Data : constant Dataset :=
     [[0.0, 0.0], [0.1, 0.0], [5.0, 5.0], [5.1, 5.0]];
   Params : constant Parameters :=
     (K => 2, Max_Iters => 50, Tol => 1.0E-6);
   R : constant Lloyd_Result := Run_Lloyd (Data, Params);
   --  or: Run_KMeans (Data, Init_Sites_From_Data (Data, 2), Params);
begin
   pragma Assert (R.Converged);
   --  R.Centroids, R.Lab, R.Inertia, R.Iters, R.Empty
end;
```

Grid CVT sketch:

```ada
Box  : constant BBox_2D := (0.0, 1.0, 0.0, 1.0);
Init : constant Sites := [[0.2, 0.2], [0.8, 0.8]];
CVT  : constant Sites :=
  Run_Lloyd_Grid_2D (Box, Resolution => 32, Init => Init);
```

## References

- [Lloyd's algorithm — Wikipedia](https://en.wikipedia.org/wiki/Lloyd%27s_algorithm)
- Stuart P. Lloyd, “Least squares quantization in PCM,” *IEEE Trans. Information Theory*, 1982 (Bell Labs tech. report 1957).
- Joel Max, “Quantizing for minimum distortion,” *IRE Trans. Information Theory*, 1960.
- Related: k-means clustering; Linde–Buzo–Gray (LBG) VQ; centroidal Voronoi tessellations.

## License

Educational reference implementation for the RobertBoettcherSF Ada series.
