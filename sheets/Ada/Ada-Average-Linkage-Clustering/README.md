# Average-Linkage Clustering / UPGMA — Ada 2023

Educational, self-contained Ada 2023 package for
[Wikipedia: UPGMA](https://en.wikipedia.org/wiki/UPGMA)
(**unweighted pair group method with arithmetic mean**; Sokal & Michener):
**agglomerative hierarchical** clustering that merges, at each step, the two
clusters with the **smallest mean pairwise distance**. Despite the name
“unweighted”, UPGMA uses **size-weighted (proportional) averaging** so that
every original observation contributes equally to each average; the related
**WPGMA** method uses a simple (equal-weight) average of the two cluster
distances and is *not* implemented here.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Related siblings:
[Ada-Single-Linkage-Clustering](https://en.wikipedia.org/wiki/Single-linkage_clustering)
(`ada-single-linkage-clustering`),
[Ada-Complete-Linkage-Clustering](https://en.wikipedia.org/wiki/Complete-linkage_clustering)
(`ada-complete-linkage-clustering`),
[Ada-Wards-Method](https://en.wikipedia.org/wiki/Ward%27s_method)
(`ada-wards-method`).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Linkage** | $D(A,B)=\frac{1}{\|A\|\|B\|}\sum_{x\in A}\sum_{y\in B}d(x,y)$ | Mean pairwise (UPGMA) |
| **Update** | $d(A\cup B,X)=(\|A\|\,d(A,X)+\|B\|\,d(B,X))/(\|A\|+\|B\|)$ | Size-weighted / proportional |
| **Input** | Points (Euclidean L2) **or** proximity matrix | `Build_Distance_Matrix` |
| **Algorithm** | Naive proximity-matrix agglomeration | Wikipedia steps; $O(n^3)$ |
| **Dendrogram** | $N-1$ merges `(Left, Right, Height, Size)` | Leaves `1..N`; merge $m$ → id $N+m$ |
| **Flat cut** | By $K$ clusters **or** height threshold $T$ | `Cut_Dendrogram` / `Labels_At_Height` |
| **Complexity** | Naive $O(n^3)$ | Educational; $n\le 64$ |

## Formula

Cluster distance (mean of all cross pairs):

$$
D(A,B)=\frac{1}{|A|\,|B|}\sum_{x\in A}\sum_{y\in B} d(x,y).
$$

After merging $A$ and $B$, distance to any remaining cluster $X$:

$$
d(A\cup B,\,X)=\frac{|A|\,d(A,X)+|B|\,d(B,X)}{|A|+|B|}.
$$

**WPGMA note (README only):** WPGMA would instead use the simple average
$\bigl(d(A,X)+d(B,X)\bigr)/2$ (no size weights). That yields a *weighted*
result with respect to the original observations; UPGMA’s proportional
averaging is the unweighted one. This package implements **UPGMA only**.

## Ultrametric / molecular-clock caveat

UPGMA builds a **rooted** dendrogram and assumes an **ultrametric** tree
(equal root-to-tip distances). For contemporaneous molecular sequences that
assumption is equivalent to a **molecular clock**. When rates vary, prefer
methods that do not force ultrametricity (e.g. neighbour-joining).

## Naive algorithm (Wikipedia)

1. Start with $N$ singleton clusters; build the pairwise distance matrix.
2. Find the pair of alive clusters with minimum average-linkage distance $D$.
3. Record a merge at height $D$; create a new cluster of size $|A|+|B|$.
4. Update distances to every other cluster with the size-weighted formula above.
5. Repeat until one cluster remains ($N-1$ merges).

## Features / Public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Real` | Fixed educational limits |
| Data | `Point`, `Dataset`, `Distance_Matrix` | Observations / proximity |
| Tree | `Merge_Record`, `Dendrogram`, `Hierarchy_Result` | Merge history |
| Flat | `Labels`, `Parameters` | Partitions / cut height |
| Geometry | `Euclidean_Distance`, `Build_Distance_Matrix` | L2 and pairwise matrix |
| Linkage | `Average_Linkage_Distance`, `UPGMA_Distance`, `Cluster_Distance` | Mean pairwise |
| Run | `Run_Average_Linkage` / `Run_UPGMA` (points **or** matrix) | Full dendrogram |
| Query | `Merge_Height` | Height of merge step |
| Cut | `Cut_Dendrogram`, `Labels_At_Height` | $K$-cut / height threshold |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

## Working example (Wikipedia bacteria JC69)

Five bacteria 5S rRNA JC69 distances ($a..e$):

|   | a | b | c | d | e |
|---|---|---|---|---|---|
| a | 0 | 17 | 21 | 31 | 23 |
| b | 17 | 0 | 30 | 34 | 21 |
| c | 21 | 30 | 0 | 28 | 39 |
| d | 31 | 34 | 28 | 0 | 43 |
| e | 23 | 21 | 39 | 43 | 0 |

UPGMA merges:

1. $a{+}b$ @ **17**; updated $D\to c,d,e =$ **25.5, 32.5, 22**
2. $(ab){+}e$ @ **22**; size-weighted $D(((ab)e),c)=30$, $D(((ab)e),d)=36$
3. $c{+}d$ @ **28**
4. $((ab)e){+}(cd)$ @ **33**

Tests assert this merge order, heights, and first / size-weighted updates.

## Build and test

```bash
cd /workspace/ada-average-linkage-clustering
make clean && make
make test
```

- `make` — `gnatmake -gnatwa -gnat2022 -Paverage_linkage_clustering.gpr`
- `make test` — run `bin/tests` (custom `Check` helper; no `Ada.Assertions`)
- `make clean` — remove `obj/` and `bin/`

Expect `Passed: N  Failed: 0` with exit status 0 and **zero** `-gnatwa`
warnings.

## Layout

```
ada-average-linkage-clustering/
├── average_linkage_clustering.ads
├── average_linkage_clustering.adb
├── average_linkage_clustering.gpr
├── Makefile
├── tests.adb
├── README.md
└── .gitignore          # obj/, bin/
```

No `main.adb` — the test suite is the main program.

## References

- [UPGMA](https://en.wikipedia.org/wiki/UPGMA) — Wikipedia
- Sokal, R. R. & Michener, C. D. (1958). A statistical method for evaluating
  systematic relationships. *University of Kansas Science Bulletin*.
- RobertBoettcherSF Ada algorithm series (siblings listed above).
