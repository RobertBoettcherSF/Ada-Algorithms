# FLAME Clustering — Ada 2023 (Fuzzy clustering by Local Approximation of MEmberships)

Educational, self-contained Ada 2023 package for
[Wikipedia: FLAME clustering](https://en.wikipedia.org/wiki/FLAME_clustering):
**FLAME** (*Fuzzy clustering by Local Approximation of MEmberships*) —
dense peaks become **Cluster Supporting Objects (CSOs)**; type-3 objects
receive fuzzy memberships by iterating a neighborhood linear combination
that minimizes the **Neighborhood Approximation Error (NAE)**
(Fu & Medico, *BMC Bioinformatics* 2007).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series.  Sibling packages
include **Ada-Fuzzy-C-Means**, **Ada-K-Means-Clustering**, and
**Ada-WACA-Clustering**.

## Algorithm (three steps)

1. **Structure extraction**
   - Build a **KNN** graph (Euclidean).
   - **Density** per object: $\mathrm{density}(x)=1/\overline{d}(x,\mathrm{KNN}(x))$ (mean distance; floor `Distance_Eps` if coincident).
   - Classify: **CSO** (density strictly higher than all $K$ neighbors), **Outlier** (strictly lower than all neighbors **and** density $<$ `Outlier_Threshold`), else **Rest** (type 3).

2. **Local approximation of fuzzy memberships**
   - $M =$ #CSOs $+ 1$ (extra column = outlier group).
   - Init: each CSO has fixed membership $1$ to its cluster; outliers fixed $1$ to the outlier group; type-3 equal $1/M$ to all columns.
   - Iterate until convergence (Jacobi):
     $\mathbf{p}^{t+1}(x)=\sum_{y\in N(x)} w_{xy}\,\mathbf{p}^{t}(y)$
     with $\sum w_{xy}=1$ and **inverse-distance** weights $w_{xy}\propto 1/(d_{xy}+\varepsilon)$. CSOs/outliers stay fixed.
   - This drives **NAE** $E=\sum_{x\in X}\|\mathbf{p}(x)-\sum_y w_{xy}\mathbf{p}(y)\|^2$ toward zero.

3. **Cluster construction**
   - **Hard** (one-to-one): $\arg\max$ membership (`Hard_Labels_From_Memberships`).
   - **Soft** (one-to-multiple): membership $>$ threshold (`Threshold_Assign`).
  
Distance ties in KNN prefer the **lower point index**.  Density ties never
create a CSO or outlier versus that neighbor (strict inequalities).

## Features / public API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_K_Neighbors`, `Max_Clusters` | Fixed educational limits |
| Types | `Dataset`, `Densities`, `Object_Kind`, `KNN_Graph`, `Membership_Matrix`, `Labels`, `Assignment_Matrix`, `Parameters`, `Flame_Result` | Domain |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point`, `Near` | $L_2$ helpers |
| Step 1 | `Build_KNN`, `Estimate_Densities`, `Classify_Objects` | Structure |
| Step 2 | `Init_Memberships`, `Neighborhood_Weights`, `Neighborhood_Approximation_Error`, `Approximate_Memberships` | NAE iteration |
| Step 3 | `Hard_Labels_From_Memberships`, `Threshold_Assign` | Crisp / soft assign |
| Driver | `Run_FLAME`, `Count_CSOs`, `Max_Membership_Delta` | Full pipeline |
| Errors | `Invalid_Argument`, `Capacity_Exceeded` | Bad $K$, shapes, caps |

`Parameters`: `K`, `Outlier_Threshold`, `Max_Iters`, `Eps`, `Assign_Threshold`.

`Flame_Result`: densities, kinds, KNN graph, memberships, CSO list,
hard labels, iters, converged, final NAE.

## Usage

```ada
with Flame_Clustering; use Flame_Clustering;

declare
   Data : constant Dataset (1 .. 6, 1 .. 2) :=
     [1 => [0.0, 0.0], 2 => [0.1, 0.1], 3 => [0.2, 0.0],
      4 => [5.0, 5.0], 5 => [5.1, 5.1], 6 => [5.0, 5.2]];
   Params : constant Parameters :=
     (K => 2, Outlier_Threshold => 0.01, Max_Iters => 100,
      Eps => 1.0E-8, Assign_Threshold => 0.4);
   R : constant Flame_Result := Run_FLAME (Data, Params);
begin
   --  R.Hard_Labels (I), R.Memberships (I, J), R.Kinds (I)
   null;
end;
```

## Build and test

```bash
cd /workspace/ada-flame-clustering
make clean && make          # gnatmake -gnatwa -gnat2022 -Pflame_clustering.gpr
make test                   # runs bin/tests; Fail_Count must be 0
```

Main program is `tests.adb` (no `main.adb`).  Objects go to `obj/`, executable
to `bin/tests`.

## Layout

```
flame_clustering.ads   — package spec (Flame_Clustering)
flame_clustering.adb   — package body
flame_clustering.gpr   — GNAT project (Main = tests.adb)
Makefile
tests.adb
README.md
.gitignore             — obj/, bin/
```

## References

1. L. Fu, E. Medico, “FLAME, a novel fuzzy clustering method for the analysis
   of DNA microarray data,” *BMC Bioinformatics*, 2007.
2. Wikipedia: [FLAME clustering](https://en.wikipedia.org/wiki/FLAME_clustering).

## License

Educational / reference implementation. Not affiliated with the original
authors.
