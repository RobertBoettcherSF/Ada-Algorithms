# k-means++ — Ada 2023 (Arthur & Vassilvitskii 2007)

Educational, self-contained Ada 2023 package for
[Wikipedia: k-means++](https://en.wikipedia.org/wiki/K-means++):
**k-means++** seeding by **David Arthur** and **Sergei Vassilvitskii** (2007),
followed by standard **Lloyd / batch k-means** refinement.

Vanilla k-means (Lloyd’s algorithm) can converge to clusterings that are
*arbitrarily* bad relative to the optimal objective.  k-means++ addresses
this by carefully choosing the initial centers with **$D^2$ sampling**, then
proceeding with the usual assign / centroid-update loop.

**Guarantee:** with this initialization, the algorithm is
**$O(\log k)$-competitive** in expectation to the optimal k-means solution
(Arthur & Vassilvitskii 2007).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Siblings:
**Ada-Lloyds-Algorithm** (discrete Lloyd / CVT), and
**Ada-K-Means-Clustering** (upcoming umbrella).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Metric** | Euclidean $L_2$ | `Distance`, `Squared_Distance` |
| **Seeding** | $D^2$ sampling | `Init_Centers_KMeansPP` |
| **Determinism** | LCG `Seed` / `Uniform_Draws` / farthest-point | Reproducible tests |
| **Refinement** | Lloyd assign + means | `Run_Lloyd` / `Run_KMeans` |
| **Pipeline** | seed + Lloyd | `Run_KMeansPP` |
| **Stop** | $\max_k \Vert \mu_k'-\mu_k \Vert < \mathrm{Tol}$ | or `Max_Iters` |
| **Quality** | Within-cluster SSE / inertia | $\sum_i \Vert x_i-\mu_{\ell_i} \Vert^2$ |
| **Empty cluster** | Keep previous center + mark | `Empty_Flags` |

## Algorithm (Arthur & Vassilvitskii 2007)

1. Choose the **first** center uniformly at random among the data points.
2. For each remaining point $x$, let $D(x)$ be the distance to the nearest
   already-chosen center.
3. Choose the next center with probability proportional to $D(x)^2$.
4. Repeat steps 2–3 until $k$ centers have been chosen.
5. Proceed with standard **Lloyd / k-means** (assign → centroid update).

Intuition: spreading the initial centers reduces the chance of the
rectangle-style failure mode where Lloyd freezes on a suboptimal partition
(documented in the test suite: wide rectangle, forced mid-edge init vs
k-means++ / farthest-point seeding).

### Relation to Lloyd / k-means

k-means++ is an **initialization** for k-means, not a replacement for the
iteration.  After seeding, this package runs the same discrete Lloyd loop as
`Ada-Lloyds-Algorithm` (reimplemented locally — no package dependency).

## Features / public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_K` | Fixed educational limits |
| Types | `Real`, `Point`, `Dataset`, `Centers`/`Sites`, `Labels`, `Parameters`, `Result`, `D2_Weights`, `Uniform_Draws` | Domain model |
| RNG | `RNG_State`, `Seed_RNG`, `Draw_Unit`, `Draw_Index` | Simple 32-bit LCG |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point` / `Extract_Center` | $L_2$ helpers |
| D² | `Nearest_Center`, `Min_Squared_Distance_To_Centers`, `Compute_D2_Weights`, `Sum_D2` | Seeding primitives |
| Partition | `Assign_Labels`, `Compute_Centroids` | Lloyd step |
| Quality | `Within_Cluster_SSE` / `Inertia` | SSE |
| Init | `Init_Centers_Uniform_First`, `Init_Centers_KMeansPP` (Seed or Draws), `Init_Centers_Farthest_Point`, `Init_Centers_From_Indices` | Seeding variants |
| Fit | `Run_Lloyd` / `Run_KMeans`, `Run_KMeansPP` | Refinement / full pipeline |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

### Determinism for tests

- `Parameters.Seed` drives an internal **LCG** (Numerical Recipes constants).
- `Init_Centers_KMeansPP (Data, K, Draws)` accepts an explicit stream of
  Uniform$[0,1)$ draws.
- `Init_Centers_Farthest_Point` is a **deterministic greedy** helper:
  always pick $\arg\max_x D(x)^2$ after a fixed first index.

## Build & test

```bash
cd /workspace/ada-k-means-plus-plus
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pk_means_plus_plus.gpr`.  Main program is
`tests.adb` (no `main.adb`).

## Layout

```
k_means_plus_plus.ads   — public API
k_means_plus_plus.adb   — implementation
k_means_plus_plus.gpr   — GNAT project
Makefile
tests.adb               — custom Check helper (~100 PASS)
README.md
.gitignore              — obj/, bin/
```

## References

1. David Arthur, Sergei Vassilvitskii (2007). *k-means++: The Advantages of
   Careful Seeding.* SODA.
2. [Wikipedia: k-means++](https://en.wikipedia.org/wiki/K-means++)
3. Stuart P. Lloyd (1982). *Least squares quantization in PCM.* (Lloyd’s
   algorithm — the refinement step.)
