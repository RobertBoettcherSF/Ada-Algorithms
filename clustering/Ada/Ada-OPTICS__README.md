# OPTICS — Ada 2023 (Ordering Points To Identify the Clustering Structure)

Educational, self-contained Ada 2023 package for
[Wikipedia: OPTICS algorithm](https://en.wikipedia.org/wiki/OPTICS_algorithm):
**OPTICS** (*Ordering points to identify the clustering structure*) by
**Mihael Ankerst**, **Markus M. Breunig**, **Hans-Peter Kriegel**, and
**Jörg Sander** (*ACM SIGMOD'99*, pp. 49–60, 1999).

OPTICS is a **density-based** clustering method closely related to
**DBSCAN**. It addresses a major DBSCAN limitation — one global ε fails on
**varying density** — by producing a **cluster-ordering** of all points
together with **core-distance** and **reachability-distance** annotations.
Clusters appear as **valleys** in the **reachability plot** (ordering on the
x-axis, reachability on the y-axis). A horizontal cut at threshold **ξ ≤ ε**
yields a **DBSCAN-equivalent** flat clustering.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

This is an **educational reconstruction** of the Wikipedia / Ankerst et al.
pseudocode (prefer the paper for research use). Reference implementations
also exist in ELKI and scikit-learn.

Part of the **RobertBoettcherSF Ada algorithms series** (siblings:
[SUBCLU](https://en.wikipedia.org/wiki/SUBCLU), DBSCAN-style density clustering).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Distance** | Euclidean $L_2$ | All dimensions |
| **Core point** | $\|N_\varepsilon(p)\| \ge \mathrm{MinPts}$ | Includes $p$ itself |
| **Core-distance** | $\mathrm{MinPts}$-th smallest dist in $N_\varepsilon(p)$ | `Undefined` if not core |
| **Reachability** | $\max(\text{core-dist}(p), \mathrm{dist}(p,o))$ | From core $p$ to $o$ |
| **Seeds** | Min-heap by reachability | $\text{Undefined} \equiv +\infty$ |
| **Extraction** | $\xi$ threshold cut | DBSCAN-equivalent labels |

## Parameters

| Name | Role |
| --- | --- |
| **Eps (ε)** | Maximum neighborhood radius (also complexity cutoff) |
| **MinPts** | Minimum points in an ε-ball for a **core** point |
| **ξ (Xi)** | Reachability threshold for flat extraction (ξ ≤ ε) |

## Definitions

- **Core point:** $|N_\varepsilon(p)| \ge \mathrm{MinPts}$ (neighborhood includes $p$).
- **$\text{core-dist}_{\varepsilon,\mathrm{MinPts}}(p)$:** `Undefined` if $|N_\varepsilon(p)| < \mathrm{MinPts}$; else the **$\mathrm{MinPts}$-th smallest** distance in $N_\varepsilon(p)$ (self contributes distance 0).
- **$\text{reachability-dist}(o, p)$:** `Undefined` if $p$ is not core; else $\max(\text{core-dist}(p), \mathrm{dist}(p,o))$.
- **UNDEFINED** is exposed as constant `Undefined` (`-1.0`) plus explicit `Has_Core_Distance` / `Has_Reachability` flags on results.

## Cluster extraction (ξ cut)

Walk the OPTICS order with current `ClusterId` (initially Noise):

1. If reachability is Undefined **or** > ξ:
   - If core-distance is defined **and** ≤ ξ → start a **new** cluster.
   - Else → label **Noise**.
2. Else (reachability ≤ ξ) → assign the current `ClusterId`
   (may still be Noise if no cluster has started).

The first point in the order has Undefined reachability; it starts a cluster
iff it is a core point w.r.t. ξ. Noise points never join a dense valley under
the chosen threshold. Steepness-based hierarchical extraction is omitted;
threshold extraction is required and sufficient for DBSCAN-equivalent results.

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims` | Fixed educational limits |
| Data | `Dataset`, `Point`, `Parameters` | Inputs |
| State | `Optics_Point`, `Ordered_Result`, `Labels` | Ordering + labels |
| Sentinel | `Undefined`, `Noise_Label` | UNDEFINED / noise |
| Helpers | `Near`, `Make_Parameters` | Validation / tolerance |
| Metric | `Distance`, `Neighbor_Count`, `Core_Distance`, `Is_Core_Point` | L2 / core |
| Core | `Run_OPTICS` | Cluster-ordering |
| Extract | `Extract_DBSCAN_Clustering`, `Labels_At_Xi` | ξ threshold cut |
| Query | `Cluster_Count_Of`, `Noise_Count_Of` | Inspect labels |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

## Build and test

```bash
cd /workspace/ada-optics   # or your clone path
make clean && make         # gnatmake -gnatwa -gnat2022 -Poptics.gpr
make test                  # runs bin/tests
```

Layout (repo root only): `optics.ads`, `optics.adb`, `optics.gpr`,
`Makefile`, `tests.adb`, `README.md`, `.gitignore`.  
Main program is **`tests.adb`** (no `main.adb`). Objects in `obj/`,
executable in `bin/`.

## References

1. Mihael Ankerst, Markus M. Breunig, Hans-Peter Kriegel, Jörg Sander.
   *OPTICS: Ordering Points To Identify the Clustering Structure*.
   ACM SIGMOD'99, pp. 49–60, 1999.
2. [Wikipedia: OPTICS algorithm](https://en.wikipedia.org/wiki/OPTICS_algorithm)
3. Related: DBSCAN (Ester et al. 1996), SUBCLU, OPTICS-OF, HDBSCAN, ELKI.

## License

Educational / reference implementation for the Ada algorithms series.
