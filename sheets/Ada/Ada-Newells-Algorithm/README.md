# Newell's Algorithm in Ada 2023

## Project Overview
Newell's algorithm (introduced by Martin Newell, Richard Newell, and Tom Sancha in 1972) is a fundamental hidden-surface removal algorithm in 3D computer graphics. It extends the classical Painter's Algorithm by resolving depth ordering ambiguities through five progressive geometric tests. Polygons are initially sorted according to their maximum depth (distance from the viewpoint) and then sequentially verified against overlapping candidate polygons. When two polygons overlap in depth, Newell's tests determine whether one can be safely drawn before the other, or if polygon splitting is required to resolve cyclic overlaps. This repository provides a complete, modern Ada 2023 implementation featuring strict and adaptive polygon subdivision variants.

## Features
* Strong Typing: Dedicated scalar types `Real`, `Point_3D`, `Plane_3D`, and domain subtypes for vertices and depth bounds.
* Newell's Plane Normal Estimation: Robust plane calculation from arbitrary non-convex planar 3D polygons using Newell's summation method.
* The Five Newell Ordering Tests:
  * Test 1: Z depth bounds disjointness test.
  * Test 2: Screen-space XY bounding box overlap test.
  * Test 3: Planar half-space test (polygon P strictly behind the plane of polygon Q).
  * Test 4: Planar half-space test (polygon Q strictly in front of the plane of polygon P).
  * Test 5: Full 2D projected polygon silhouette intersection and point containment.
* Strict Sort Variant (`Sort_Polygons_Strict`): Non-preemptive sorting algorithm that detects cyclic overlaps and raises `Cyclic_Overlap_Error`.
* Adaptive Split Variant (`Sort_Polygons_Adaptive`): Automatically bisects obstructing polygons along the Z dimension when cyclic dependencies occur, guaranteeing a resolved depth ordering.
* Zero Warnings: Verified under `gnatmake -gnatwa -gnat2022`.

## Usage
To build the test suite and run all verification checks:

```bash
make test
```

Expected output:
```text
TEST 1 -- Plane Computation via Newell's Method
  PASS -- 1.1 Normal X is zero
  PASS -- 1.2 Normal Y is zero
  PASS -- 1.3 Normal Z is unit (+1 or -1)
TEST 2 -- Test 1: Z Disjointness
  PASS -- 2.1 P is strictly behind Q in Z
  PASS -- 2.2 Q is not behind P in Z
  PASS -- 2.3 Composite test passes
...
=== 39 passed,  0 failed ===
```

To remove all build artifacts:
```bash
make clean
```

## Testing
The test suite in `tests.adb` contains 13 test suites with over 39 assertions covering:
* Geometric primitives: Plane equation normal estimation and bounding box calculations.
* Individual unit verification of each of the 5 Newell tests.
* Full multi-polygon depth ordering verification (strict back-to-front ordering).
* Inversion resolution where a polygon with deeper minimum Z must be drawn after another polygon.
* Edge cases: Empty lists, single polygon lists, and zero-area degenerate polygons.
* Exception handling: Verification that degenerate geometry raises `Degenerate_Polygon_Error` and cyclic overlaps are detected.
* Adaptive sorting: Execution of polygon depth-splitting to resolve cycles.

## Building
* Compiler: GNAT supporting Ada 2022 / Ada 2023 (e.g., GNAT FSF 12+, 13+, or 14+).
* Standard: ISO/IEC 8652:2023.
* Tools: `gnatmake` and GNU `make`.
