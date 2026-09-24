# Canopy Clustering — Ada 2023

Educational, self-contained Ada 2023 package for the
[Wikipedia: Canopy clustering algorithm](https://en.wikipedia.org/wiki/Canopy_clustering_algorithm)
(**McCallum, Nigam, Ungar**, *KDD 2000*): unsupervised **pre-clustering** with
a loose distance threshold $T_1$ and a tight threshold $T_2$
($T_1 > T_2 > 0$).

Canopies are cheap approximate groups that may **overlap** (a point can belong
to several canopies). They are often used as preprocessing for
**k-means** or **hierarchical clustering** on large datasets.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling package:
**Ada-K-Means-Clustering**.

## Algorithm

1. Begin with the set of data points.
2. Remove a point from the set; start a new canopy containing it (the
   **center**).
3. For each remaining point: if distance to the canopy center $< T_1$,
   assign it to this canopy (multi-membership allowed).
4. If the distance is additionally $< T_2$, remove it from the original set
   (it cannot become the center of another canopy).
5. Repeat until the set is empty.

**Distance:** Euclidean L2 (here the “cheap” and “accurate” metrics coincide).
Comparisons use **strict** `<` as on Wikipedia.

**Determinism:** the next center is always the **lowest remaining index** in
the pool; remaining points are scanned in ascending index order.

## Project overview

| Concern | Approach | Notes |
| --- | --- | --- |
| Thresholds | $T_1 > T_2 > 0$ | Loose / tight |
| Distance | Euclidean L2 | Same metric for both steps |
| Membership | Multi-label | Point may join several canopies |
| Pool removal | $d < T_2$ | Cannot center later |
| Center pick | Lowest pool index | Stable / deterministic |
| Hard labels | Nearest center or first canopy | Optional exclusive labels |

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_Canopies` | Fixed educational limits |
| Types | `Real`, `Point`, `Dataset`, `Parameters`, `Result` | Domain model |
| Centers | `Canopy_Centers`, `Center_Point_Ids` | Center coords + source rows |
| Membership | `Membership`, `Canopy_Membership_List` | Matrix + per-point id lists |
| Helpers | `Near`, `Make_Parameters`, `Distance`, `Distance_To_Center` | Utilities |
| Run | `Run_Canopy`, `Canopy_Count_Of`, `Point_In_Canopy`, `Canopies_Of` | Core API |
| Hard labels | `Hard_Labels_Nearest_Center`, `Hard_Labels_First_Canopy` | Exclusive labels |

Named exceptions: `Invalid_Argument` (e.g. $T_1 \le T_2$),
`Capacity_Exceeded`.

## Curse of dimensionality

Because the algorithm relies on distance thresholds, applicability to
**high-dimensional** data is limited by the
[curse of dimensionality](https://en.wikipedia.org/wiki/Curse_of_dimensionality).
When only a cheap approximate low-dimensional distance is available, produced
canopies better preserve structure for a following k-means stage.

## Usage

```ada
with Canopy_Clustering; use Canopy_Clustering;

declare
   Data : Dataset (1 .. 4, 1 .. 2);
   Params : constant Parameters := Make_Parameters (2.0, 1.0);
   R : Result := Run_Canopy (Data, Params);
   Lab : Hard_Labels := Hard_Labels_Nearest_Center (R, Data);
begin
   null;  -- R.C canopies; R.Memb / R.Lists membership; Lab exclusive
end;
```

## Build & test

```bash
cd /workspace/ada-canopy-clustering
make clean && make
make test
```

Uses `gnatmake -gnatwa -gnat2022 -Pcanopy_clustering.gpr`. Main program is
`tests.adb` (no `main.adb`).

## Layout

```
canopy_clustering.ads   — public API
canopy_clustering.adb   — implementation
canopy_clustering.gpr   — GNAT project
Makefile
tests.adb               — custom Check helper (~80–120 PASS)
README.md
.gitignore              — obj/, bin/
```

## References

1. A. McCallum, K. Nigam, L. H. Ungar (2000).
   “Efficient Clustering of High Dimensional Data Sets with Application to
   Reference Matching,” *KDD 2000*, pp. 169–178.
   [doi:10.1145/347090.347123](https://doi.org/10.1145/347090.347123).
2. Wikipedia:
   [Canopy clustering algorithm](https://en.wikipedia.org/wiki/Canopy_clustering_algorithm).

## License

Educational / reference implementation. Not affiliated with the original
authors. Part of the RobertBoettcherSF Ada algorithm series.
