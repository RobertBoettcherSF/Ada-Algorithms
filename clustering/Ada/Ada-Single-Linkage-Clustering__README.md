# Single-Linkage Clustering — Ada 2023 (Nearest Neighbour / Friends-of-Friends)

Educational, self-contained Ada 2023 package for
[Wikipedia: Single-linkage clustering](https://en.wikipedia.org/wiki/Single-linkage_clustering):
**agglomerative hierarchical** clustering that merges, at each step, the two
clusters containing the **closest pair of points** not yet in the same
cluster. Also known as **nearest-neighbour clustering**; in astronomy the
same idea is the **friends-of-friends (FoF)** algorithm for galaxy groups.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Related sibling:
[Ward's method](https://en.wikipedia.org/wiki/Ward%27s_method) minimum-variance
linkage (`ada-wards-method`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Linkage** | $D(X,Y)=\min_{x\in X,\,y\in Y} d(x,y)$ | Min pairwise (single link) |
| **Input** | Points (Euclidean $L_2$) **or** proximity matrix | `Build_Distance_Matrix` |
| **Algorithm** | Naive proximity-matrix agglomeration | Wikipedia steps; $O(n^3)$ |
| **Dendrogram** | $N-1$ merges `(Left, Right, Height, Size)` | Leaves `1..N`; merge $m \to$ id $N+m$ |
| **Flat cut** | By $K$ clusters **or** height threshold $T$ | FoF-style `Labels_At_Height` |
| **Complexity** | Naive $O(n^3)$ (SLINK $O(n^2)$ equivalent OK) | Educational; $n \le 64$ |

## Formula

$$
D(X,Y)=\min_{x\in X,\,y\in Y} d(x,y).
$$

After merging clusters $(r)$ and $(s)$, distances to any remaining cluster
$(k)$ update by

$$
d[(r,s),(k)]=\min\{d[(k),(r)],\,d[(k),(s)]\}.
$$

## Naive algorithm (Wikipedia)

1. Start with $N$ singleton clusters, $L(0)=0$, $m=0$; build the
   proximity matrix of pairwise distances.
2. Find the most similar pair $(r),(s)$ with minimum $d[(i),(j)]$.
3. $m:=m+1$; merge into clustering $m$; set $L(m)=d[(r),(s)]$.
4. Update the matrix: delete rows/cols of $r,s$; set new distances
   $d[(r,s),k]=\min(d[k,r],d[k,s])$.
5. Stop when one cluster remains; otherwise go to step 2.

Single linkage tends to form **long thin (chained)** clusters — useful for
filamentary structure (FoF in astronomy), less ideal when compact blob
separation is required (prefer complete linkage or Ward).

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Real` | Fixed educational limits |
| Data | `Point`, `Dataset`, `Distance_Matrix` | Observations / proximity |
| Tree | `Merge_Record`, `Dendrogram`, `Hierarchy_Result` | Merge history |
| Flat | `Labels`, `Parameters` | Partitions / cut height |
| Geometry | `Euclidean_Distance`, `Build_Distance_Matrix` | $L_2$ and pairwise matrix |
| Linkage | `Single_Linkage_Distance`, `Cluster_Distance` | $D(X,Y)=\min$ |
| Run | `Run_Single_Linkage` (points **or** matrix) | Full dendrogram |
| Query | `Merge_Height` | Height of merge step |
| Cut | `Cut_Dendrogram`, `Labels_At_Height` | $K$-cut / FoF threshold |
Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

## Working example

Wikipedia’s five-bacteria JC69 distance matrix ($a..e$):

|   | a | b | c | d | e |
|---|---|---|---|---|---|
| a | 0 | 17 | 21 | 31 | 23 |
| b | 17 | 0 | 30 | 34 | 21 |
| c | 21 | 30 | 0 | 28 | 39 |
| d | 31 | 34 | 28 | 0 | 43 |
| e | 23 | 21 | 39 | 43 | 0 |

First merge $a+b$ at height 17; updated distances to $c,d,e$ are
21, 31, 21. Next merges join $c$ and $e$ at height 21 (pairwise under
tie-break), then $d$ at 28. Tests assert this sequence.

## Build and test

```bash
cd /workspace/ada-single-linkage-clustering
make clean && make
make test
```

- `make` — `gnatmake -gnatwa -gnat2022 -Psingle_linkage_clustering.gpr`
- `make test` — run `bin/tests` (custom `Check` helper; no `Ada.Assertions`)
- `make clean` — remove `obj/` and `bin/`

Expect `Passed: N  Failed: 0` with exit status 0 and **zero** `-gnatwa`
warnings.

## Layout

```
ada-single-linkage-clustering/
├── single_linkage_clustering.ads
├── single_linkage_clustering.adb
├── single_linkage_clustering.gpr
├── Makefile
├── tests.adb
├── README.md
└── .gitignore          # obj/, bin/
```

No `main.adb` — the test suite is the main program.

## References

- [Single-linkage clustering (Wikipedia)](https://en.wikipedia.org/wiki/Single-linkage_clustering)
- Sibson, R. (1973). SLINK: an optimally efficient algorithm for the
  single-link cluster method. *The Computer Journal*.
- Gower & Ross (1969). Minimum spanning trees and single linkage cluster
  analysis.
- Related: Ward’s method, complete linkage, UPGMA / WPGMA.
