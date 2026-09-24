# Linde–Buzo–Gray (LBG) Algorithm — Ada 2023

Educational, self-contained Ada 2023 package for the
[Linde–Buzo–Gray algorithm](https://en.wikipedia.org/wiki/Linde–Buzo–Gray_algorithm)
(**LBG**): an iterative **vector quantization (VQ)** procedure that improves a
codebook for a training set to **local optimality**. It combines
**Lloyd iteration** with a **splitting** technique so that larger codebooks are
grown from smaller ones.

Named after **Yoseph Linde**, **Andrés Buzo**, and **Robert M. Gray**, who
published the method in **1980** in the *IEEE Transactions on Communications*
(“An Algorithm for Vector Quantizer Design”, vol. 28, no. 1, pp. 84–95,
doi:[10.1109/TCOM.1980.1094577](https://doi.org/10.1109/TCOM.1980.1094577)).

Language: **Ada 2023** (ISO/IEC 8652:2023), compiled with GNAT (`-gnat2022`).

Part of the **RobertBoettcherSF** Ada algorithm series. Sibling package:
**[Ada-Lloyds-Algorithm](../ada-lloyds-algorithm/)** (discrete Lloyd / k-means
and CVT relaxation). LBG uses Lloyd as its inner refinement step.

## Relation to Lloyd / Lloyd–Max

- **Lloyd’s algorithm** (and the scalar **Lloyd–Max** quantizer) refines a
  *fixed-size* set of reconstruction points by alternating nearest-neighbor
  assignment and centroid updates.
- **LBG** adds **codebook splitting**: start from the global training mean
  (one codeword), then repeatedly replace each codevector $y$ with
  $\{y, y+\varepsilon\}$ (a small perturbation) and re-run Lloyd. Because
  every previous codevector remains in the enlarged book, the new codebook is
  at least as good as the old one before Lloyd improves it further.

Splitting is the usual practical way to design a VQ codebook of size $M$
(often a power of two) without a poor random initialization of all $M$
words at once.

## Project Overview

| Concern | Approach | Notes |
| --- | --- | --- |
| **Metric** | Euclidean $L_2$ / SSE | `Distance`, `Squared_Distance`, `Distortion` |
| **Inner loop** | Lloyd assign → centroid | `Run_Lloyd` |
| **Growth** | Split $y \mapsto \{y, y+\varepsilon\}$ | `Split_Codebook` |
| **Full design** | Mean → split+Lloyd until $M$ | `Run_LBG` / `Design_Codebook` |
| **Empty cell** | Keep previous codevector | Documented; `Empty_Flags` |
| **Stop** | Relative distortion change $\le$ `Stop_Epsilon` | or `Max_Lloyd_Iters` |

## Features

| Area | Subprograms / types | Role |
| --- | --- | --- |
| Caps | `Max_Points`, `Max_Dims`, `Max_Codewords` | Fixed educational limits |
| Types | `Point`, `Dataset` / `Training_Set`, `Codebook`, `Labels`, `Parameters`, `LBG_Result` | Domain model |
| Geometry | `Distance`, `Squared_Distance`, `Extract_Point` / `Extract_Codeword` | $L_2$ helpers |
| Partition | `Nearest_Codeword`, `Assign` | Voronoi of the sample |
| Update | `Update_Centroids`, `Centroid`, `Mean_Point` | Means; empty → keep |
| Quality | `Distortion`, `Average_Distortion` | Total / mean SSE |
| Split | `Split_Codebook` | Double with $+\varepsilon$ |
| Fit | `Run_Lloyd`, `Run_LBG` / `Design_Codebook` | Refine / full design |

Strong typing uses domain types (`Real` digits 12, …). Public subprograms
carry `Pre` / `Post` / `Global` where meaningful (`SPARK_Mode => Off`).

Named exceptions: `Invalid_Argument`, `Capacity_Exceeded`.

## Algorithm (Wikipedia + Linde/Buzo/Gray 1980)

### One split step (Wikipedia)

```
linde-buzo-gray(training, old-codebook):
  new-codebook ← {}
  for each old-codevector in old-codebook:
    insert old-codevector into new-codebook
    insert old-codevector + ε into new-codebook
  return lloyd(new-codebook, training)
```

### Lloyd refinement

```
lloyd(codebook, training):
  do
    previous ← codebook
    clusters ← partition training by nearest codevector
    for each cluster: codevector ← centroid of cluster
  while |error(previous) - error(codebook)| > ε_stop
  return codebook
```

**Empty cells:** if a cluster has no training vectors, this package **keeps**
the previous codevector and sets `Empty(k) := True`.

### Full design to $M$ codewords

1. $c_0 \leftarrow$ mean of the training set; codebook $\leftarrow \{c_0\}$.
2. While $|\mathrm{codebook}| < M$: split each vector into $y$ and
   $y+\varepsilon\cdot e_1$ (scalar $\varepsilon$ on the first coordinate,
   forming a small perturbation vector); run Lloyd until the relative
   distortion change is below `Stop_Epsilon` (or `Max_Lloyd_Iters`).
3. Return final codebook, assignments, and distortion.

If a doubling would exceed `Target_Size`, only the first `Target_Size`
entries of the split book are kept (supports non–power-of-two $M$).

Distortion is squared Euclidean error
$\sum_i \|x_i - y_{\ell_i}\|^2$.

## Build and test

```bash
cd /workspace/ada-linde-buzo-gray
make clean && make          # gnatmake -gnatwa -gnat2022 -Plinde_buzo_gray.gpr
make test                  # runs bin/tests; Fail_Count must be 0
```

Layout (root only): `linde_buzo_gray.ads`, `linde_buzo_gray.adb`,
`linde_buzo_gray.gpr`, `Makefile`, `tests.adb`, `README.md`, `.gitignore`.
Main program is `tests.adb` (no `main.adb`).

## Public API (summary)

- **Types:** `Real`, `Point`, `Dataset` / `Training_Set`, `Codebook`, `Labels`,
  `Empty_Flags`, `Parameters`, `LBG_Result`
- **Geometry:** `Distance`, `Squared_Distance`, `Extract_Point`,
  `Extract_Codeword`, `Near`
- **VQ primitives:** `Nearest_Codeword`, `Assign`, `Update_Centroids`,
  `Centroid`, `Mean_Point`, `Distortion`, `Average_Distortion`
- **Algorithms:** `Split_Codebook`, `Run_Lloyd`, `Run_LBG`, `Design_Codebook`
- **Exceptions:** `Invalid_Argument`, `Capacity_Exceeded`

## References

1. Linde, Y.; Buzo, A.; Gray, R. (1980). “An Algorithm for Vector Quantizer
   Design”. *IEEE Transactions on Communications* **28** (1): 84–95.
2. Gray, R.; Gersho, A. (1992). *Vector Quantization and Signal Compression*.
   Springer.
3. Wikipedia:
   [Linde–Buzo–Gray algorithm](https://en.wikipedia.org/wiki/Linde–Buzo–Gray_algorithm).
