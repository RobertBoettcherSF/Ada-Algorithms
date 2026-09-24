# k-means Clustering — Ada 2023 (Lloyd / naïve k-means)

Educational, self-contained Ada 2023 package for
[Wikipedia: k-means clustering](https://en.wikipedia.org/wiki/K-means_clustering):
**k-means clustering**, a method of **vector quantization** originally from
**signal processing**, that partitions $n$ observations into $k$ clusters
in which each observation belongs to the cluster with the nearest **mean**
(cluster center / centroid).  The resulting partition of the data space is a
set of **Voronoi cells**.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Sibling packages
(independent — this repo does **not** depend on them):

- **Ada-Lloyds-Algorithm** — discrete Lloyd / continuous CVT grid form
- **Ada-K-Means-Plus-Plus** — Arthur & Vassilvitskii (2007) D² seeding
- **Ada-Linde-Buzo-Gray** — LBG vector quantization

## Objective (WCSS / inertia)

Given observations $\mathbf{x}_1,\ldots,\mathbf{x}_n \in \mathbb{R}^d$,
k-means seeks a partition $S=\{S_1,\ldots,S_k\}$ minimizing the
**within-cluster sum of squares (WCSS)**:

$$
\arg\min_S \sum_{i=1}^{k}\sum_{\mathbf{x}\in S_i}\|\mathbf{x}-\boldsymbol{\mu}_i\|^2
$$

where $\boldsymbol{\mu}_i$ is the mean of points in $S_i$. WCSS is also called inertia or within-cluster SSE.

where $\boldsymbol{\mu}_i$ is the mean of points in $S_i$.  WCSS is also
called **inertia** or within-cluster SSE.

**Squared Euclidean caveat:** k-means minimizes *squared* Euclidean distances
(variance).  It does **not** minimize ordinary Euclidean distances (the harder
Weber problem / geometric median).  For Euclidean-median clustering see
k-medians / k-medoids.

## Standard / naïve algorithm (Lloyd)

The classic iterative refinement (Stuart P. Lloyd, Bell Labs 1957 / published
1982; often called **Lloyd’s algorithm** or the **Forgy** method when started
from random data points) is:

1. Given initial means $m_1,\ldots,m_k$.
2. **Assignment:** assign each $\mathbf{x}$ to the nearest mean
   (by **squared** Euclidean distance) — a Voronoi partition of the sample.
3. **Update:** set $m_i \leftarrow$ mean of points assigned to $i$.
   Empty cluster policy in this package: **keep** the previous mean and mark
   `Empty(i) := True`.
4. Repeat until means move less than `Tol`, assignments are stable, or
   `Max_Iters` is reached.

This is a local heuristic for an **NP-hard** problem; different inits can
yield different local optima.

### Relation to EM / GMM and k-means++

- k-means is closely related to the **expectation–maximization (EM)**
  algorithm for **Gaussian mixture models (GMM)**: both iteratively refine
  cluster centers. Soft EM/GMM allows anisotropic Gaussians; hard k-means
  tends to find clusters of comparable spatial extent.
- **k-means++** (Arthur & Vassilvitskii 2007) improves *initialization* via
  $D^2$ sampling ($O(\log k)$-competitive in expectation) then runs the same
  Lloyd loop — see sibling **Ada-K-Means-Plus-Plus**.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Metric** | Euclidean ($L_2$) / squared ($L_2$) | `Distance`, `Squared_Distance` |
| **Iteration** | Assign → centroid update | Lloyd / naïve k-means |
| **Empty cluster** | Keep previous mean + mark | `Empty_Flags` |
| **Init** | Forgy (seeded LCG), spaced indices, user indices | `Init_Centers_*` |
| **Stop** | $\max_i \Vert m_i'-m_i \Vert < \mathrm{Tol}$ or stable labels | or `Max_Iters` |
| **Quality** | WCSS / SSE / inertia | $\sum_i \Vert x_i - \mu_{\ell_i} \Vert^2$ |

## Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_K` | Fixed educational limits |
| Types | `Real`, `Point`, `Dataset`, `Centers`, `Labels`, `Empty_Flags`, `Index_List`, `Parameters`, `Result` | Domain model |
| RNG | `RNG_State`, `Seed_RNG`, `Draw_Unit`, `Draw_Index` | 32-bit LCG for Forgy |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point`, `Extract_Center` | $L_2$ helpers |
| Partition | `Nearest_Center`, `Assign_Labels` | Voronoi of the sample |
| Update | `Compute_Centroids` | Means; empty → keep + mark |
| Quality | `Within_Cluster_SSE` / `WCSS` / `Inertia` | SSE alias triple |
| Init | `Init_Centers_Forgy`, `Init_Centers_From_Indices`, `Init_Centers_Spaced` | Seeding |
| Fit | `Run_Lloyd` / `Run_KMeans` (with Init or Forgy one-shot) | Lloyd iteration |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

`Parameters` fields: `K`, `Max_Iters`, `Tol`, `Seed`.
`Result` fields: `Centers`, `Lab`, `Empty`, `WCSS`, `Inertia`, `Iters`,
`Converged`.

## Build & test

```bash
cd /workspace/ada-k-means-clustering
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pk_means_clustering.gpr`.  Main program is
`tests.adb` (no `main.adb`).

## Layout

```
k_means_clustering.ads   — public API
k_means_clustering.adb   — implementation
k_means_clustering.gpr   — GNAT project
Makefile
tests.adb                — custom Check helper (~100 PASS)
README.md
.gitignore               — obj/, bin/
```

## References

1. [Wikipedia: k-means clustering](https://en.wikipedia.org/wiki/K-means_clustering)
2. Stuart P. Lloyd (1982). *Least squares quantization in PCM.* IEEE Trans.
   Information Theory.
3. E. Forgy (1965). *Cluster analysis of multivariate data.* (Forgy init.)
4. David Arthur, Sergei Vassilvitskii (2007). *k-means++: The Advantages of
   Careful Seeding.* SODA.
