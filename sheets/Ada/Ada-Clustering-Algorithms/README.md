# Clustering Algorithms — Ada 2023 (Cluster analysis survey)

Educational, self-contained Ada 2023 **survey** package for
[Wikipedia: Cluster analysis](https://en.wikipedia.org/wiki/Cluster_analysis)
(*Data clustering* redirects here): partitioning a set of objects into
groups (**clusters**) such that intra-group similarity is higher than
inter-group similarity.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Sibling packages
(independent — this repo does **not** depend on them; compact
representatives are reimplemented here):

| Sibling | Model |
| --- | --- |
| **Ada-K-Means-Clustering** / **Ada-Lloyds-Algorithm** / **Ada-K-Means-Plus-Plus** | Centroid (Lloyd / naïve *k*-means) |
| **Ada-Single-Linkage-Clustering** / **Ada-Complete-Linkage-Clustering** / **Ada-Average-Linkage-Clustering** | Connectivity (hierarchical) |
| **Ada-DBSCAN** / **Ada-OPTICS** | Density |
| **Ada-Expectation-Maximization** | Distribution (EM / GMM — mentioned only) |
| **Ada-Fuzzy-Clustering** / **Ada-Fuzzy-C-Means** | Soft / fuzzy centroid |
| **Ada-Canopy-Clustering** / **Ada-FLAME-Clustering** / **Ada-WACA-Clustering** | Related clustering |

## Cluster analysis family (Wikipedia)

Wikipedia groups major algorithms by **cluster model**:

1. **Connectivity models** — hierarchical agglomerative / divisive linkage
   (single, complete, average, Ward, …).  Clusters form by distance
   connectivity; a dendrogram records merge heights.
2. **Centroid models** — each cluster has a center; Lloyd / *k*-means
   alternates assignment and mean update, minimizing WCSS / inertia.
3. **Density models** — clusters are dense regions separated by sparse
   areas; **DBSCAN** / **OPTICS** label core, border, and noise points.
4. **Distribution models** — soft assignment under mixture models
   (Expectation–Maximization / Gaussian mixtures).  Covered by the
   sibling EM package; **not** implemented here.

## What this package implements

| Area | API | Notes |
| --- | --- | --- |
| **Shared** | `Dataset`, `Point`, `Distance`, `Squared_Distance`, `Labels`, `Noise_Label` | Euclidean $L_2$ |
| **Centroid** | `Run_KMeans`, `Assign_Labels`, `Update_Centroids`, Forgy / Spaced init | Lloyd iteration |
| **Connectivity** | `Build_Distance_Matrix`, `Run_Single_Linkage`, `Run_Single_Linkage_Cut`, `Cut_Dendrogram` | Naive min-link |
| **Density** | `Range_Query`, `Run_DBSCAN` | Ester et al. query-based |
| **Evaluation** | `WCSS` / `Within_Cluster_SSE`, `Mean_Silhouette`, `Dunn_Index` | Internal indices |

Caps: `Max_Points`, `Max_Dims`, `Max_K`.  Exceptions: `Invalid_Argument`,
`Capacity_Exceeded`.

### Internal evaluation

- **WCSS** — within-cluster sum of squares $\sum_i\|x_i-\mu_{\ell(i)}\|^2$.
- **Silhouette** — per-point $s=(b-a)/\max(a,b)$ with $a$ = mean
  intra-cluster distance, $b$ = mean distance to the nearest other
  cluster; package reports the mean over non-noise points.
- **Dunn index** — $\min$ inter-cluster distance / $\max$ intra-cluster
  distance (higher is denser / better separated).

## Public API (summary)

**Types:** `Real`, `Point`, `Dataset`, `Centers`, `Labels`, `Noise_Label`,
`Distance_Matrix`, `Dendrogram`, `Merge_Record`, `KMeans_Parameters`,
`KMeans_Result`, `DBSCAN_Parameters`, `DBSCAN_Result`, `Init_Kind`,
`RNG_State`.

**Geometry:** `Distance`, `Squared_Distance`, `Extract_Point`,
`Extract_Center`, `Near`.

**Centroid:** `Nearest_Center`, `Assign_Labels`, `Update_Centroids`,
`Init_Centers_Forgy`, `Init_Centers_Spaced`, `Init_Centers_From_Indices`,
`Run_KMeans`.

**Connectivity:** `Build_Distance_Matrix`, `Run_Single_Linkage`,
`Labels_At_Height`, `Cut_Dendrogram`, `Run_Single_Linkage_Cut`.

**Density:** `Range_Query`, `Neighbor_Count`, `Run_DBSCAN`,
`Cluster_Count_Of`, `Noise_Count_Of`.

**Evaluation:** `Within_Cluster_SSE`, `WCSS`, `Mean_Silhouette`,
`Dunn_Index`.

## Build and test

```bash
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pclustering_algorithms.gpr`.  Main
program is `tests.adb` (no `main.adb`).  The suite uses a custom `Check`
helper (no `Ada.Assertions`); success ends with `Fail_Count = 0` and
`pragma Assert (Fail_Count = 0)`.

## Usage sketch

```ada
with Clustering_Algorithms; use Clustering_Algorithms;

declare
   Data : constant Dataset :=
     [[0.0, 0.0], [0.2, 0.1], [8.0, 8.0], [8.1, 7.9]];
   KP : KMeans_Parameters := Default_KMeans;
   RK : KMeans_Result (N => 4, K => 2, D => 2);
   DP : DBSCAN_Parameters := Default_DBSCAN;
   RD : DBSCAN_Result (1, 4);
   SL : Labels (1 .. 4);
begin
   KP.K := 2;
   KP.Init := Spaced;
   RK := Run_KMeans (Data, KP);

   DP.Eps := 1.0;
   DP.MinPts := 2;
   RD := Run_DBSCAN (Data, DP);

   SL := Run_Single_Linkage_Cut (Data, 1.0);
   --  Mean_Silhouette (Data, RK.Lab);  Dunn_Index (Data, RK.Lab);
end;
```

## Layout

```
clustering_algorithms.ads
clustering_algorithms.adb
clustering_algorithms.gpr
Makefile
tests.adb
README.md
.gitignore
```
