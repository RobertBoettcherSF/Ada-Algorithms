# Fuzzy c-means (FCM) Clustering — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: Fuzzy clustering — Fuzzy c-means](https://en.wikipedia.org/wiki/Fuzzy_clustering#Fuzzy_c-means_clustering):
**Fuzzy c-means (FCM)**, a form of **soft clustering** (also called soft
*k*-means) in which each data point can belong to more than one cluster with
graded **memberships** $w_{ij}\in[0,1]$ that sum to 1 across clusters for
each point.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Sibling packages
(independent — this repo does **not** depend on them):

- **Ada-K-Means-Clustering** — hard Lloyd / naïve *k*-means (Voronoi partition)
- **Ada-Expectation-Maximization** — EM / GMM soft responsibilities

## History (Dunn / Bezdek)

Fuzzy *c*-means was developed by **J.C. Dunn** (1973) and improved by
**J.C. Bezdek** (1981).  It is one of the most widely used fuzzy clustering
algorithms and is closely related to hard *k*-means: both minimize a sum of
squared distances to cluster centers, but FCM allows fractional memberships
controlled by a **fuzzifier** $m$.

## Relation to *k*-means

*k*-means is the hard special case: memberships are restricted to
$w_{ij}\in\{0,1\}$.  FCM uses the same Euclidean / squared-Euclidean geometry
but replaces the crisp assignment step with a soft update.  As the fuzzifier
$m\to 1^+$, memberships become increasingly crisp and FCM approaches hard
*k*-means.  Larger $m$ yields fuzzier (more shared) partitions.

## Objective and updates

Given observations $\mathbf{x}_1,\ldots,\mathbf{x}_n\in\mathbb{R}^d$ and $c$ clusters, FCM minimizes

$$
J(W,C)=\sum_{i=1}^{n}\sum_{j=1}^{c} w_{ij}^{m}\,\|\mathbf{x}_i-\mathbf{c}_j\|^2
$$

with row-stochastic memberships $\sum_j w_{ij}=1$, $w_{ij}\ge 0$.

**Centroid update** (weighted mean):

$$
\mathbf{c}_j=\frac{\sum_i w_{ij}^{m}\,\mathbf{x}_i}{\sum_i w_{ij}^{m}}
$$

**Membership update** (Bezdek):

$$
w_{ij}=\left(\sum_{k=1}^{c}\left(\frac{\|\mathbf{x}_i-\mathbf{c}_j\|}{\|\mathbf{x}_i-\mathbf{c}_k\|}\right)^{\frac{2}{m-1}}\right)^{-1}
$$

**Zero-distance guard:** if 𝐱ᵢ = 𝐜ⱼ, set wᵢⱼ = 1 and all other memberships for that point to 0 (numerically: squared distance ≤ `Distance_Eps`).

### Iteration

1. Choose $c$; initialize memberships randomly (seeded LCG) with row sums 1 (or initialize centers then compute $W$).
2. Update centers from $W$.
3. Update $W$ from centers.
4. Repeat until $\max|\Delta w|<\varepsilon$ or `Max_Iters`.

Common default: $m=2$. Metric in this package: Euclidean ($L_2$).

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Metric** | Euclidean ($L_2$) / squared ($L_2$) | `Distance`, `Squared_Distance` |
| **Init** | Seeded LCG random memberships | `Init_Memberships_Random` |
| **Updates** | Bezdek center + membership | `Update_Centers`, `Update_Memberships` |
| **Stop** | $\max\Vert\Delta W\Vert < \varepsilon$ | or `Max_Iters` |
| **Quality** | Fuzzy objective ($J$); PC | `Objective_J`, `Partition_Coefficient` |
| **Hard labels** | Argmax membership | `Hard_Labels_From_Memberships` |
| **Capacity** | Bounded arrays | `Max_Points`, `Max_Dims`, `Max_Clusters` |

## Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Types | `Real`, `Point`, `Dataset`, `Centers`, `Membership_Matrix`, `Hard_Labels`, `Parameters`, `Result` | Domain + run config / outcome |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point`, `Extract_Center` | $L_2$ helpers |
| Init | `Init_Memberships_Random`, `Seed_RNG`, `Draw_Unit` | Row-stochastic $W$; LCG |
| Steps | `Update_Centers`, `Update_Memberships`, `Objective_J` | One FCM iteration pieces |
| Driver | `Run_Fuzzy_C_Means` / `Run_FCM` | Full loop → `Result` |
| Post | `Hard_Labels_From_Memberships`, `Partition_Coefficient`, `Max_Membership_Delta` | Crisp labels; PC; convergence |
| Errors | `Invalid_Argument`, `Capacity_Exceeded` | Bad $m \le 1$, $C$, shapes, caps |

`Parameters`: `C`, `Fuzzifier_M` (default 2), `Eps`, `Max_Iters`, `Seed`.

`Result`: `Centers`, `Memberships`, `Objective_J`, `Iters`, `Converged`.

## Build and test

```bash
cd /workspace/ada-fuzzy-c-means
make clean && make          # gnatmake -gnatwa -gnat2022 -Pfuzzy_c_means.gpr
make test                   # runs bin/tests; Fail_Count must be 0
```

Main program is `tests.adb` (no `main.adb`).  Objects go to `obj/`, executable
to `bin/tests`.

## Layout

```
fuzzy_c_means.ads   — package spec (Fuzzy_C_Means)
fuzzy_c_means.adb   — package body
fuzzy_c_means.gpr   — GNAT project (Main = tests.adb)
Makefile
tests.adb
README.md
.gitignore          — obj/, bin/
```

## References

- [Fuzzy clustering — Fuzzy c-means clustering (Wikipedia)](https://en.wikipedia.org/wiki/Fuzzy_clustering#Fuzzy_c-means_clustering)
- Dunn, J.C. (1973). A fuzzy relative of the ISODATA process.
- Bezdek, J.C. (1981). *Pattern Recognition with Fuzzy Objective Function Algorithms*.
