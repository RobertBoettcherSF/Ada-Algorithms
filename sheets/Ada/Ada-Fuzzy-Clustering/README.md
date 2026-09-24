# Fuzzy Clustering — Ada 2023 (soft clustering / soft *k*-means)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Fuzzy clustering](https://en.wikipedia.org/wiki/Fuzzy_clustering):
**fuzzy / soft clustering** (also called **soft *k*-means**), in which each
data point can belong to more than one cluster via graded **memberships**
$w_{ij} \in [0, 1]$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Sibling packages
(independent — this repo does **not** depend on them; algorithms are
reimplemented here for a coherent survey library):

- **Ada-Fuzzy-C-Means** — dedicated FCM package (same Dunn/Bezdek core)
- **Ada-FLAME-Clustering** — Fuzzy clustering by Local Approximation of MEmberships
- **Ada-K-Means-Clustering** — hard Lloyd / naïve *k*-means (Voronoi partition)

## Soft vs hard clustering

In **hard clustering**, each observation is assigned to exactly one cluster
(exclusive labels).  In **fuzzy / soft clustering**, a point may belong to
several clusters at once with fractional grades.

Wikipedia’s apple example: hard clustering says an apple is red **or** green;
fuzzy clustering allows red **and** green to a degree — e.g. red $=0.5$,
green $=0.5$.  Grades are normalized to $[0,1]$.  They are **not**
always probabilities (some fuzzy schemes need not sum to 1); this package’s
flagship **Fuzzy *c*-means** uses the common **row-stochastic** convention
$\sum_j w_{ij}=1$.

### Membership grades

Membership grades indicate how strongly a point belongs to each cluster.
Points near a cluster center tend to have high membership for that cluster;
points on the boundary share membership across clusters.

Utilities in this package:

| Helper | Role |
| --- | --- |
| `Is_Row_Stochastic` | Validate $w_{ij}\in[0,1]$, rows sum to 1 |
| `Harden` / `Hard_Labels_From_Memberships` | Soft → hard via $\arg\max_j w_{ij}$ |
| `Soften_From_Hard` | Hard → soft one-hot memberships |
| `Max_Membership` | Peak membership $\max_j w_{ij}$ for a row |
| `Partition_Coefficient` | $\mathrm{PC}=(1/n)\sum_i\sum_j w_{ij}^2\in[1/c,1]$ |
| `Partition_Entropy` | $\mathrm{PE}=-(1/n)\sum_i\sum_j w_{ij}\log w_{ij}$ |
| `Max_Membership_Delta` | $\max\|W-W'\|_\infty$ (convergence) |

Hard partitions have $\mathrm{PC}=1$ and $\mathrm{PE}=0$; fuzzier
partitions lower PC and raise PE.

## Flagship algorithm: Fuzzy *c*-means (Dunn / Bezdek)

**Fuzzy *c*-means (FCM)** was developed by **J.C. Dunn** (1973) and improved
by **J.C. Bezdek** (1981).  It is the primary algorithm covered by the
Wikipedia article and the centerpiece of this survey package.

Given observations $\mathbf{x}_1,\ldots,\mathbf{x}_n\in\mathbb{R}^d$ and
$c$ clusters, FCM minimizes

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
w_{ij}=\Biggl(\sum_{k=1}^{c}
\Biggl(\frac{\|\mathbf{x}_i-\mathbf{c}_j\|}{\|\mathbf{x}_i-\mathbf{c}_k\|}
\Biggr)^{\frac{2}{m-1}}\Biggr)^{-1}
$$

**Zero-distance guard:** if $\mathbf{x}_i=\mathbf{c}_j$, set $w_{ij}=1$
and all other memberships for that point to 0 (numerically: squared distance
$\le$ `Distance_Eps`).

### Fuzzifier $m$

The hyper-parameter $m\in(1,\infty)$ controls fuzziness.  Larger $m$
yields fuzzier (more shared) partitions.  As $m\to 1^+$, memberships become
increasingly crisp and FCM approaches hard *k*-means.  Common default:
$m=2$.

### Soft *k*-means

Wikipedia equates fuzzy clustering with **soft *k*-means**.  In this package,
`Run_Soft_KMeans` is FCM with the fuzzifier forced to $m=2$ (other
`Parameters` fields are honored).

### Iteration

1. Choose $c$; initialize memberships randomly (seeded LCG) with row sums 1.
2. Update centers from $W$.
3. Update $W$ from centers.
4. Repeat until $\max|\Delta w|<\varepsilon$ or `Max_Iters`.

Metric: Euclidean $L_2$ / squared $L_2$.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Survey** | Soft vs hard + membership utilities | Harden / Soften / PC / PE |
| **Metric** | Euclidean $L_2$ / squared $L_2$ | `Distance`, `Squared_Distance` |
| **Init** | Seeded LCG random memberships | `Init_Memberships_Random` |
| **Updates** | Bezdek center + membership | `Update_Centers`, `Update_Memberships` |
| **Stop** | $\max\|\Delta W\|<\varepsilon$ | or `Max_Iters` |
| **Objective** | $J=\sum_i\sum_j w_{ij}^m\|x_i-c_j\|^2$ | `Objective_J` |
| **Soft *k*-means** | FCM with $m=2$ | `Run_Soft_KMeans` |
| **Caps** | `Max_Points`, `Max_Dims`, `Max_Clusters` | Educational bounds |

Strong typing uses domain types (`Real` digits 12, …).  Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Public API (summary)

**Types:** `Real`, `Point`, `Dataset`, `Centers`, `Membership_Matrix`,
`Hard_Labels`, `Parameters`, `Result`, `RNG_State`.

**Membership:** `Is_Row_Stochastic`, `Harden`, `Soften_From_Hard`,
`Max_Membership`, `Partition_Coefficient`, `Partition_Entropy`,
`Max_Membership_Delta`, `Hard_Labels_From_Memberships`.

**Geometry:** `Distance`, `Squared_Distance`, `Extract_Point`,
`Extract_Center`.

**FCM:** `Init_Memberships_Random`, `Update_Centers`, `Update_Memberships`,
`Objective_J`, `Run_Fuzzy_C_Means` / `Run_FCM` / `Run_Soft_KMeans`.

**RNG:** `Seed_RNG`, `Draw_Unit`.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pfuzzy_clustering.gpr`.  Main program is
`tests.adb` (no `main.adb`).  The suite uses a custom `Check` helper (no
`Ada.Assertions`); success ends with `Fail_Count = 0` and
`pragma Assert (Fail_Count = 0)`.

## Usage sketch

```ada
with Fuzzy_Clustering; use Fuzzy_Clustering;

declare
   Data : constant Dataset :=
     [[0.0, 0.0], [0.2, 0.1], [8.0, 8.0], [8.1, 7.9]];
   Params : Parameters := Default_Parameters;
   R : Result (N => 4, C => 2, D => 2);
   Labs : Hard_Labels (1 .. 4);
begin
   Params.C := 2;
   Params.Fuzzifier_M := 2.0;
   Params.Seed := 1;
   R := Run_Fuzzy_C_Means (Data, Params);
   Labs := Harden (R.Memberships);
   --  Or: R := Run_Soft_KMeans (Data, Params);
end;
```

## Layout

```
fuzzy_clustering.ads
fuzzy_clustering.adb
fuzzy_clustering.gpr
Makefile
tests.adb
README.md
.gitignore
```

## References

- [Wikipedia: Fuzzy clustering](https://en.wikipedia.org/wiki/Fuzzy_clustering)
- J.C. Dunn (1973); J.C. Bezdek (1981) — Fuzzy *c*-means
