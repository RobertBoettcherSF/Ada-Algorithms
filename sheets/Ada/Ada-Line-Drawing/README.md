# Line Drawing Algorithms in Ada 2023

## Project Overview
Line drawing algorithms approximate continuous line segments on discrete pixel grids. This project provides a complete, robust implementation of the primary classical rasterization algorithms described in computer graphics literature: the Naive Floating-Point Slope-Intercept algorithm, the Digital Differential Analyzer (DDA), Bresenham's Integer Line Algorithm, the Midpoint Line Algorithm, and Xiaolin Wu's Antialiased Line Algorithm. Each variant handles arbitrary slopes across all eight octants, negative coordinates, and degenerate zero-length segments.

## Features
- Naive Line Algorithm: Direct evaluation using slope-intercept calculation stepped along the dominant axis to prevent undersampling.
- Digital Differential Analyzer (DDA): Floating-point differential incrementation along the driving axis.
- Bresenham's Line Algorithm: Pure integer error accumulation algorithm optimized for all octants without division or floating-point rounding.
- Midpoint Line Algorithm: Implicit function decision variable formulation tracking the boundary between candidate raster points.
- Xiaolin Wu's Algorithm: Sub-pixel anti-aliasing generating coverage intensities (Intensity fixed-point type) for smooth line depiction.
- Strong Typing & Safety: Dedicated Coordinate, Coordinate_Distance, and Intensity types with postcondition contracts (Post) and Global => null purity annotations.

## Building
- Prerequisites: GNAT compiler supporting Ada 2022/2023 (gnatmake or gprbuild).
- Standard: ISO/IEC 8652:2023 (Ada 2023).
- Compile Flags: -gnatwa -gnat2022 ensuring zero compiler warnings.

Build command:
make

## Usage
Run the test suite:
make test

Expected output:
Running tests...
TEST 1 — Distance Metrics and Sizing
  PASS — 1.1 Chebyshev distance of diagonal segment
  PASS — 1.2 Manhattan distance of diagonal segment
  PASS — 1.3 Expected point count includes endpoints
TEST 2 — Single Point Segment Across Variants
  PASS — 2.1 Naive returns single element equal to origin
  PASS — 2.2 Bresenham returns single element equal to origin
  PASS — 2.3 Xiaolin Wu returns single full-intensity point
TEST 3 — Horizontal Line
  PASS — 3.1 Bresenham horizontal length is 7
  PASS — 3.2 DDA horizontal points stay on Y=0
  PASS — 3.3 Midpoint horizontal spans start to end
TEST 4 — Vertical Line
  PASS — 4.1 Bresenham vertical length is 5
  PASS — 4.2 Naive vertical points stay on X=0
  PASS — 4.3 DDA vertical points are monotonic in Y
TEST 5 — 45-Degree Diagonal Line
  PASS — 5.1 Bresenham has X=Y for all points
  PASS — 5.2 Midpoint has X=Y for all points
  PASS — 5.3 Naive has X=Y for all points
TEST 6 — Shallow Slope Segment
  PASS — 6.1 Bresenham 8-connectivity maintained
  PASS — 6.2 DDA length matches Chebyshev distance + 1
  PASS — 6.3 Midpoint matches Bresenham end coordinates
TEST 7 — Steep Slope Segment
  PASS — 7.1 Bresenham produces exactly 8 points
  PASS — 7.2 Naive produces continuous path
  PASS — 7.3 Midpoint endpoints are accurate
TEST 8 — Negative Slopes and Reverse Direction
  PASS — 8.1 Bresenham reverse step decreases X monotonically
  PASS — 8.2 DDA reverse step maintains connectivity
  PASS — 8.3 Midpoint terminates exactly at destination
TEST 9 — All Octants Traversal
  PASS — 9.1 Point counts correct across all 8 octants
  PASS — 9.2 Connectivity unbroken across all 8 octants
  PASS — 9.3 Endpoints accurately preserved across octants
TEST 10 — Negative Coordinate Space
  PASS — 10.1 Bresenham functions correctly in negative quadrant
  PASS — 10.2 DDA preserves negative endpoints
  PASS — 10.3 Naive preserves negative endpoints
TEST 11 — Directional Symmetry
  PASS — 11.1 Forward and backward lengths match
  PASS — 11.2 Forward start equals backward end
  PASS — 11.3 Forward and reverse pixel paths are symmetric
TEST 12 — Xiaolin Wu Antialiasing
  PASS — 12.1 Output contains shaded points
  PASS — 12.2 All alpha intensities bounded between 0.0 and 1.0
  PASS — 12.3 Shaded point count exceeds discrete Chebyshev length due to pairs
TEST 13 — Algorithm Agreement on Canonical Lines
  PASS — 13.1 Bresenham and Midpoint produce identical array lengths
  PASS — 13.2 Both algorithms agree on endpoints exactly
  PASS — 13.3 Pixels match perfectly along trajectory

===  39 passed,  0 failed ===

Clean build artifacts:
make clean

## Testing
The test suite in tests.adb validates 13 distinct categories with at least 3 assertions each:
1. Mathematical Invariants: Metric functions (Manhattan_Distance, Chebyshev_Distance, Expected_Point_Count).
2. Degenerate Edge Cases: Single-pixel segments where Start_Pt = End_Pt.
3. Cardinal Orientations: Strictly horizontal and vertical lines where dx = 0 or dy = 0.
4. Diagonal Lines: Exact 45-degree slopes where |dx| = |dy|.
5. Octant Traversal: All 8 directional octants verify that direction signs and step adjustments operate correctly.
6. Path Continuity: Verifies Chebyshev 8-connectivity along line trajectories without gaps.
7. Coordinate Range: Verification across negative and mixed-sign coordinate spaces.
8. Invariance & Symmetry: Verification that reversing endpoints yields symmetric raster paths.
9. Antialiasing Coverage: Verification of Xiaolin Wu pixel pair intensities bounded in [0.0, 1.0].
10. Cross-Algorithm Concordance: Verifies raster identity between Bresenham's and Midpoint formulations.
