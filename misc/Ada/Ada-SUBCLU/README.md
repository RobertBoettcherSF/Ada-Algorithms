# SUBCLU — Ada 2023 (density-connected subspace clustering)

Educational, self-contained Ada 2023 package for
[Wikipedia: SUBCLU](https://en.wikipedia.org/wiki/SUBCLU):
**SUBCLU** (*density-connected subspace clustering*) by
**Karin Kailing**, **Hans-Peter Kriegel**, and **Peer Kröger**
(*Proc. SIAM Int. Conf. on Data Mining (SDM'04)*, pp. 246–257, 2004).

SUBCLU finds **axis-parallel** clusters in **subspaces** of high-dimensional
data. It builds on **DBSCAN**: a cluster is a maximal density-connected set
under parameters **ε (Eps)** and **MinPts**. A bottom-up, Apriori-style
search enumerates promising subspaces using the **downward-closure**
property: a density-connected set in subspace $S$ is also density-connected
in every $T \subseteq S$.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

This is an **educational reconstruction** of the Wikipedia / SDM'04
pseudocode (prefer paper semantics for research use). An example
implementation also exists in the ELKI framework.

Part of the **RobertBoettcherSF Ada algorithms series**.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Distance** | $L_2$ on selected dims only | Subspace projection |
| **DBSCAN** | Core / density-reachability | Same Eps, MinPts as classic DBSCAN |
| **1D pass** | DBSCAN per attribute | Seeds $S_1$, $C_1$ |
| **Candidates** | Differ-by-one join + prune | Apriori-style |
| **Higher-D** | DBSCAN on best lower cluster | Minimize points scanned |
| **Closure** | Density-connected in $S \implies$ in $T \subseteq S$ | Prunes empty candidates |

## Parameters

| Name | Role |
| --- | --- |
| **Eps (ε)** | Neighborhood radius in the active subspace metric |
| **MinPts** | Minimum points in an ε-ball for a **core** point |

Same roles as in DBSCAN.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_Subspaces`, `Max_Clusters` | Fixed educational limits |
| Data | `Dataset`, `Subspace`, `Point_Subset`, `Parameters` | Inputs |
| Helpers | `Near`, `Make_Subspace`, `Subspace_*`, `Differ_By_One` | Subspace algebra |
| Metric | `Distance`, `Neighborhood_Count`, `Is_Core_Point` | L2 in subspace |
| Core | `DBSCAN` | Density-connected clusters in one subspace |
| Search | `Generate_Candidate_Subspaces`, `Run_SUBCLU` | Full bottom-up SUBCLU |
| Query | `Clustered_In_Subspace`, `Total_Clustered_Points` | Inspect results |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

## Algorithm sketch

1. For each attribute $a$, run $\mathrm{DBSCAN}(DB, \{a\}, \varepsilon, \mathrm{MinPts})$; keep non-empty $S_1$, $C_1$.
2. While $C_k \neq \emptyset$:  
   $\mathrm{CandS}_{k+1} := \mathrm{GenerateCandidateSubspaces}(S_k)$.
3. For each candidate, pick **bestSubspace** = $k$-subset with minimal total clustered points; for each cluster $cl$ therein, run $\mathrm{DBSCAN}(cl, cand, \ldots)$ and union.
4. Record subspaces that still contain clusters into $S_{k+1}$, $C_{k+1}$.

`GenerateCandidateSubspaces` joins pairs of $k$-spaces that differ in exactly one attribute, then **prunes** any $(k+1)$-candidate whose some $k$-subset is absent from $S_k$.

## Build and test

```bash
cd /workspace/ada-subclu   # or your clone path
make clean && make         # gnatmake -gnatwa -gnat2022 -Psubclu.gpr
make test                  # runs bin/tests
```

Layout (repo root only): `subclu.ads`, `subclu.adb`, `subclu.gpr`,
`Makefile`, `tests.adb`, `README.md`, `.gitignore`.  
Main program is **`tests.adb`** (no `main.adb`). Objects in `obj/`,
executable in `bin/`.

## References

1. Karin Kailing, Hans-Peter Kriegel, Peer Kröger.
   *Density-Connected Subspace Clustering for High-Dimensional Data*.
   SDM'04, pp. 246–257, 2004.
2. [Wikipedia: SUBCLU](https://en.wikipedia.org/wiki/SUBCLU)
3. Related: DBSCAN (Ester et al.), CLIQUE, PreDeCon, ELKI.

## License

Educational / reference implementation for the Ada algorithms series.
