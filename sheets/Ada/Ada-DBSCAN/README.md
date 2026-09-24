# DBSCAN — Ada 2023 (Density-Based Spatial Clustering of Applications with Noise)

Educational, self-contained Ada 2023 package for
[Wikipedia: DBSCAN](https://en.wikipedia.org/wiki/DBSCAN):
**DBSCAN** (*Density-Based Spatial Clustering of Applications with Noise*) by
**Martin Ester**, **Hans-Peter Kriegel**, **Jörg Sander**, and **Xiaowei Xu**
(*KDD'96*, pp. 226–231, 1996).

DBSCAN is a **density-based** clustering method with parameters **Eps (ε)** and
**MinPts**. It discovers **arbitrarily shaped** clusters, labels **noise**, and
needs no preset cluster count (unlike **k-means**). Points are **core**,
**border**, or **noise** according to the size of their ε-neighborhood.

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

This is an **educational reconstruction** of the Wikipedia / Ester et al.
**original query-based** algorithm (linear `RangeQuery`). Prefer the paper for
research use. Reference implementations also exist in ELKI and scikit-learn.

Part of the **RobertBoettcherSF Ada algorithms series** (siblings:
[Ada-OPTICS](https://en.wikipedia.org/wiki/OPTICS_algorithm),
[Ada-SUBCLU](https://en.wikipedia.org/wiki/SUBCLU)).

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Distance** | Euclidean L2 | All dimensions |
| **Core point** | \|N_ε(p)\| ≥ MinPts | Includes p itself |
| **Directly reachable** | q within ε of core p | Border may be last |
| **Reachable** | Chain of core points | Density-connected clusters |
| **Noise** | Not reachable from any core | May be reassigned if later reached |
| **RangeQuery** | Linear scan | Index optional in production |

## Parameters

| Name | Role |
| --- | --- |
| **Eps (ε)** | Neighborhood radius |
| **MinPts** | Minimum points in an ε-ball for a **core** point (counts self) |

## Definitions

- **Core point:** \|N_ε(p)\| ≥ MinPts (neighborhood includes p).
- **Border point:** not core, but density-reachable from some core (ε-neighbor of a core).
- **Noise:** not reachable from any core.
- **Labels:** `Undefined_Label` (−1) during the run; `Noise_Label` (0); positive cluster ids.

Border points first labeled Noise in the outer loop can be **reassigned** when
reached from a core’s seed expansion (Wikipedia / Ester et al.).

## Advantages vs k-means

- No need to choose *k* a priori.
- Finds **non-convex** / elongated clusters.
- Explicit **noise** model.
- Deterministic given a fixed scan order (aside from border points that touch
  more than one cluster).

Trade-off: ε and MinPts must still be chosen; varying density is harder
(see **OPTICS**).

## Features / API

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims` | Fixed educational limits |
| Data | `Dataset`, `Point`, `Parameters` | Inputs |
| Labels | `Labels`, `Result`, `Point_Kind` | Outcomes |
| Sentinel | `Undefined_Label`, `Noise_Label` | Undefined / noise |
| Helpers | `Near`, `Make_Parameters` | Validation / tolerance |
| Metric | `Distance`, `Range_Query`, `Neighbor_Count`, `Is_Core_Point` | L2 / core |
| Core | `Run_DBSCAN` | Clustering |
| Query | `Cluster_Count_Of`, `Noise_Count_Of` | Inspect labels |

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Global` where meaningful (`SPARK_Mode => Off`).

## Build and test

```bash
cd /workspace/ada-dbscan   # or your clone path
make clean && make         # gnatmake -gnatwa -gnat2022 -Pdbscan.gpr
make test                  # runs bin/tests
```

Layout (repo root only): `dbscan.ads`, `dbscan.adb`, `dbscan.gpr`,
`Makefile`, `tests.adb`, `README.md`, `.gitignore`.  
Main program is **`tests.adb`** (no `main.adb`). Objects in `obj/`,
executable in `bin/`.

## References

1. Martin Ester, Hans-Peter Kriegel, Jörg Sander, Xiaowei Xu.
   *A Density-Based Algorithm for Discovering Clusters in Large Spatial
   Databases with Noise*. KDD'96, pp. 226–231, 1996.
2. [Wikipedia: DBSCAN](https://en.wikipedia.org/wiki/DBSCAN)
3. Related: OPTICS (Ankerst et al. 1999), SUBCLU, HDBSCAN, ELKI.

## License

Educational / reference implementation for the Ada algorithms series.
