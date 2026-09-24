# Complete-Linkage Clustering — Ada 2023 (Farthest Neighbour)

Educational, self-contained Ada 2023 package for
[Wikipedia: Complete-linkage clustering](https://en.wikipedia.org/wiki/Complete-linkage_clustering):
**agglomerative hierarchical** clustering that merges, at each step, the two
clusters whose **farthest** pair of points (one from each) has the **smallest**
such distance. Also known as **farthest neighbour clustering**. Complete
linkage tends to find **compact clusters of approximately equal diameters**,
avoiding the chaining phenomenon of single linkage.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling:
[Ada-Single-Linkage-Clustering](../ada-single-linkage-clustering/)
($D=\min$ / nearest neighbour).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Linkage** | $D(X,Y)=\max_{x\in X,\,y\in Y} d(x,y)$ | Max pairwise (complete / farthest) |
| **Input** | Points (Euclidean L2) **or** proximity matrix | `Build_Distance_Matrix` |
| **Algorithm** | Naive proximity-matrix agglomeration | Wikipedia steps; $O(n^3)$ |
| **Dendrogram** | $N-1$ merges `(Left, Right, Height, Size)` | Leaves `1..N`; merge $m$ → id $N+m$ |
| **Flat cut** | By $K$ clusters **or** height threshold | `Cut_Dendrogram` / `Labels_At_Height` |
| **Complexity** | Naive $O(n^3)$; CLINK $O(n^2)$ known | Educational; $n\le 64$ |

## Formula

$$
D(X,Y) = \max_{x \in X, \, y \in Y} d(x,y).
$$

After merging clusters $(r)$ and $(s)$, distances to any remaining cluster $(k)$ update by

$$
d[(r,s),(k)] = \max \{ d[(k),(r)], \, d[(k),(s)] \}.
$$
## Naive algorithm (corrected merge choice)

1. Start with $N$ singleton clusters, $L(0)=0$, $m=0$; build the
   proximity matrix of pairwise distances.
2. Find the most similar pair $(r),(s)$ — the pair with the **smallest**
   complete-linkage distance $D$ in the current matrix.
   (**Note:** Wikipedia’s naive step text incorrectly writes
   $d[(r),(s)]=\max d[(i),(j)]$; the working example correctly selects the
   **minimum** matrix entry. This package implements **min-of-$D$** to choose
   the merge, and **max** when updating.)
3. $m:=m+1$; merge into clustering $m$; set $L(m)=d[(r),(s)]$.
4. Update the matrix: delete rows/cols of $r,s$; set new distances
   $d[(r,s),k]=\max(d[k,r],d[k,s])$.
5. Stop when one cluster remains; otherwise go to step 2.

Defays (1977) **CLINK** is an optimally efficient $O(n^2)$ scheme analogous
to SLINK for single linkage; this package teaches the clear naive method.

## Contrast with single linkage

| | Single linkage | Complete linkage |
| --- | --- | --- |
| $D(X,Y)$ | $\min$ pairwise | $\max$ pairwise |
| Update | $\min\{d[k,r],d[k,s]\}$ | $\max\{d[k,r],d[k,s]\}$ |
| Tendency | Long thin **chains** | **Compact** equal-diameter blobs |
| Sibling package | `ada-single-linkage-clustering` | this repo |

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Real` | Fixed educational limits |
| Data | `Point`, `Dataset`, `Distance_Matrix` | Observations / proximity |
| Tree | `Merge_Record`, `Dendrogram`, `Hierarchy_Result` | Merge history |
| Flat | `Labels`, `Parameters` | Partitions / cut height |
| Geometry | `Euclidean_Distance`, `Build_Distance_Matrix` | L2 and pairwise matrix |
| Linkage | `Complete_Linkage_Distance`, `Cluster_Distance` | $D(X,Y)=\max$ |
| Run | `Run_Complete_Linkage` (points **or** matrix) | Full dendrogram |
| Query | `Merge_Height` | Height of merge step |
| Cut | `Cut_Dendrogram`, `Labels_At_Height` | $K$-cut / height threshold |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

## Working example (Wikipedia bacteria JC69)

Five bacteria $a..e$ distance matrix:

|   | a | b | c | d | e |
|---|---|---|---|---|---|
| a | 0 | 17 | 21 | 31 | 23 |
| b | 17 | 0 | 30 | 34 | 21 |
| c | 21 | 30 | 0 | 28 | 39 |
| d | 31 | 34 | 28 | 0 | 43 |
| e | 23 | 21 | 39 | 43 | 0 |

Verified merge sequence (complete linkage):

1. $a{+}b$ at height **17**; updated $D$ to $c,d,e$ = $\max$ → 30, 34, 23
2. $(ab){+}e$ at height **23**
3. $c{+}d$ at height **28**
4. $((ab)e){+}(cd)$ at height **43**

(Same JC69 matrix under single linkage yields a different tree — first merge
still $a{+}b@17$, then chaining via min updates.)

## Build and test

```bash
cd /workspace/ada-complete-linkage-clustering
make clean && make
make test
```

- `make` — `gnatmake -gnatwa -gnat2022 -Pcomplete_linkage_clustering.gpr`
- `make test` — run `bin/tests` (custom `Check` helper; no `Ada.Assertions`)
- `make clean` — remove `obj/` and `bin/`

Expect `Passed: N  Failed: 0` with exit status 0 and **zero** `-gnatwa`
warnings.

## Layout

```
ada-complete-linkage-clustering/
├── complete_linkage_clustering.ads
├── complete_linkage_clustering.adb
├── complete_linkage_clustering.gpr
├── Makefile
├── tests.adb
├── README.md
└── .gitignore          # obj/, bin/
```

No `main.adb` — the test suite is the main program.

## References

- [Complete-linkage clustering (Wikipedia)](https://en.wikipedia.org/wiki/Complete-linkage_clustering)
- Defays, D. (1977). An efficient algorithm for a complete link method
  (CLINK). *The Computer Journal*.
- Everitt, Landau & Leese — *Cluster Analysis* (compact-cluster discussion).
- Related: single-linkage clustering, UPGMA / WPGMA, Ward’s method.
