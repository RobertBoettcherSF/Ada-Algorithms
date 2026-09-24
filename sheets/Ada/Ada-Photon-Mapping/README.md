# Photon Mapping in Ada 2023

## Project Overview
Photon Mapping is a two-pass global illumination algorithm invented by Henrik Wann Jensen that decouples the representation of illumination from scene geometry. In the first pass, photons are emitted from light sources, traced through the scene via ray-object intersections and Russian roulette scattering, and deposited into a spatial data structure. In the second pass, the scene is rendered by combining ray tracing for direct lighting and specular reflections with nearest-neighbor density estimations from the photon map for caustics, diffuse indirect illumination, and participating media.

## Features
- Complete spatial KD-Tree construction using recursive 3D median-split partitioning.
- Nearest-neighbor radius querying for arbitrary query points in Euclidean space.
- Russian Roulette interaction modeling for diffuse reflection, specular reflection, and absorption.
- Ray-Sphere surface intersection calculations with surface normal generation.
- Three surface radiance density estimation filters:
  - Constant (uniform circle kernel)
  - Linear (cone filter)
  - Gaussian filter
- Volumetric photon mapping density estimation for participating scattering media.
- Multi-component two-pass synthesis combining direct illumination, specular reflection, caustics, and global indirect lighting.
- Pure Ada 2023 strong typing, contract-based programming (`Pre` conditions), and zero-warning compilation under `-gnatwa`.

## Building
- Prerequisites: GNAT Ada compiler supporting Ada 2022/2023 (e.g., GNAT FSF 13+ or GNAT Community Edition with Ada 2022/2023 enabled).
- Compile target using make:

```bash
make
```

## Usage

Run the standalone test suite:

```bash
make test
```

Expected output:

```text
Running tests...
TEST 1 — Vector Operations
  PASS — 1.1 Dot product of orthogonal vectors is zero
  PASS — 1.2 Norm calculation computes Pythagorean distance
  PASS — 1.3 Vector scaling multiplies magnitude linearly
TEST 2 — Spectral Operations
  PASS — 2.1 Spectral addition sums R component
  PASS — 2.2 Spectral addition sums G component
  PASS — 2.3 Spectral scaling halves power values
TEST 3 — Ray-Sphere Intersection Direct Hit
  PASS — 3.1 Direct ray hits sphere
  PASS — 3.2 Hit point matches surface front
  PASS — 3.3 Normal vector faces backwards along ray axis
TEST 4 — Ray-Sphere Intersection Miss
  PASS — 4.1 Offset ray misses sphere
  PASS — 4.2 Hit point remains at default origin
  PASS — 4.3 Normal remains zeroed on miss
TEST 5 — Russian Roulette Probabilities
  PASS — 5.1 Low roll triggers diffuse scatter
  PASS — 5.2 Mid-range roll triggers specular bounce
  PASS — 5.3 High roll triggers absorption
TEST 6 — Single Photon Tracing
  PASS — 6.1 Traced photon deposits at hit position Z
  PASS — 6.2 Traced photon retains incoming power spectrum
  PASS — 6.3 Incident vector direction preserved
TEST 7 — Kd-Tree Edge Cases
  PASS — 7.1 Empty tree remains zero length
  PASS — 7.2 Single element length intact
  PASS — 7.3 Single root splits on X-axis (plane 0)
TEST 8 — Kd-Tree Multi-Photon Construction
  PASS — 8.1 Multi-tree preserves length count
  PASS — 8.2 Median element placed at root index 2
  PASS — 8.3 Left split element ordered before median
TEST 9 — Nearest Neighbor Photon Search
  PASS — 9.1 Search locates exactly two close neighbors
  PASS — 9.2 Far point outside radius excluded
  PASS — 9.3 Closest photon included in query result
TEST 10 — Surface Radiance Estimation (Constant Filter)
  PASS — 10.1 Surface radiance R is positive
  PASS — 10.2 Constant filter computes uniform color channels
  PASS — 10.3 Radiance falls within physically expected limits
TEST 11 — Linear and Gaussian Filtering Comparison
  PASS — 11.1 Linear filter computes positive radiance
  PASS — 11.2 Gaussian filter produces positive radiance
  PASS — 11.3 Differing filter weighting produces distinct values
TEST 12 — Volume Radiance Estimation
  PASS — 12.1 Volumetric radiance produces non-zero red channel
  PASS — 12.2 Volumetric radiance scales isotropically
  PASS — 12.3 Zero scattering coefficient yields zero volume radiance
TEST 13 — Full Two-Pass Synthesis
  PASS — 13.1 Two-pass synthesis totals R channel
  PASS — 13.2 Two-pass synthesis totals G channel
  PASS — 13.3 Two-pass synthesis totals B channel

===  39 passed,  0 failed ===
```

To clean build artifacts:

```bash
make clean
```

## Testing
The test suite in `tests.adb` exercises 13 distinct functional test cases with 39 granular assertions covering:
- Mathematical foundation: vector spaces, dot products, norm calculations, and spectral arithmetic.
- Geometric optics: ray-sphere intersection, grazing incidence, and hit misses.
- Stochastic processes: Russian roulette boundary intervals for absorption and reflection.
- Spatial partitioning: empty trees, single-node trees, balanced KD-tree median partitioning, and bounded spherical range search.
- Illumination estimation: surface irradiance estimation using constant, linear, and Gaussian kernel filters.
- Volumetric rendering: participating media scattering and coefficient boundary handling.
- Full two-pass synthesis: assembling distinct illumination passes into the final color.
