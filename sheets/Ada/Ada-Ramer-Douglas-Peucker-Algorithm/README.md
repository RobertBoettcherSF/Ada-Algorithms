# Ramer-Douglas-Peucker Algorithm in Ada 2023

## Project Overview
The Ramer-Douglas-Peucker (RDP) algorithm is a classic decimation algorithm for polygonal curves that downsamples a curve composed of line segments to a similar curve with fewer vertices. It calculates the perpendicular distance of each point to the chord formed by the segment endpoints, retaining points exceeding an epsilon threshold and recursively or iteratively simplifying the sub-segments. This package provides a strongly-typed, ISO/IEC 8652:2023-compliant implementation offering recursive, iterative (stack-based), index-filtering, and boolean-mask variations.

## Features
- **Strong Typing**: Coordinate and non-negative Distance domain types preventing type confusion.
- **Contract Aspects**: Formal `Pre` and `Post` conditions guarding invariants across all public APIs.
- **Classic Recursive (`Simplify`)**: Standard recursive divide-and-conquer implementation.
- **Iterative Stack-based (`Simplify_Iterative`)**: Heap-safe, non-recursive stack variant eliminating deep call stacks.
- **Masking & Index Variants (`Simplify_Mask`, `Simplify_Indices`)**: Exposes point retention decisions directly without reallocating coordinate arrays.
- **Geometry Helpers**: Self-contained `Euclidean_Distance` and `Perpendicular_Distance` routines with collinearity and zero-length chord safeguards.

## Usage
Build and run the test harness using the Makefile:

make test

Expected output:
TEST 1 — Euclidean Distance Calculations
  PASS — 1.1 3-4-5 Triangle Distance
  PASS — 1.2 Distance to self is zero
  PASS — 1.3 Symmetry holds
TEST 2 — Perpendicular Distance Helpers
  PASS — 2.1 Perpendicular offset matches Y coordinate
  PASS — 2.2 Point on chord gives zero distance
  PASS — 2.3 Coincident endpoints fall back to Euclidean distance
TEST 3 — Empty and Single Element Input
  PASS — 3.1 Empty input returns length 0
  PASS — 3.2 Single point returns length 1
  PASS — 3.3 Iterative empty returns length 0
TEST 4 — Two-Point Segment (Boundary Case)
  PASS — 4.1 Recursive retains both endpoints
  PASS — 4.2 Iterative retains both endpoints
  PASS — 4.3 Mask is True for both indices
TEST 5 — Collinear Points Elimination
  PASS — 5.1 All interior collinear points simplified away
  PASS — 5.2 First point preserved
  PASS — 5.3 Last point preserved
TEST 6 — Single Peak Retention
  PASS — 6.1 Peak retained when epsilon < peak height
  PASS — 6.2 Peak removed when epsilon > peak height
  PASS — 6.3 Retained mid point X coordinate matches
TEST 7 — Non-zero Array Bounds Compatibility
  PASS — 7.1 Correct length with 10-based indexing
  PASS — 7.2 Preserves original start index in indices list
  PASS — 7.3 Preserves original end index in indices list
TEST 8 — Equivalence of Recursive and Iterative Variants
  PASS — 8.1 Recursive and iterative produce identical lengths
  PASS — 8.2 Output coordinates match across variants
  PASS — 8.3 Iterative retains significant peak points
TEST 9 — Mask Variant Invariants
  PASS — 9.1 Mask length equals input length
  PASS — 9.2 Boundary endpoints are true
  PASS — 9.3 Off-chord peak marked true
TEST 10 — Simplify_Indices Variant
  PASS — 10.1 Exactly three points kept
  PASS — 10.2 First index is 1
  PASS — 10.3 Middle index matches sharp peak at 3
TEST 11 — Zero Epsilon Invariant
  PASS — 11.1 Zero epsilon retains all non-collinear points
  PASS — 11.2 First point intact
  PASS — 11.3 Third point intact
TEST 12 — Large Polyline Benchmark Profile
  PASS — 12.1 High compression achieved on near-flat path
  PASS — 12.2 Significant peak retained
  PASS — 12.3 Iterative output matches recursive length
TEST 13 — Extreme Outlier Rejection with Huge Epsilon
  PASS — 13.1 Simplification collapses to 2 points under large epsilon
  PASS — 13.2 Beginning point retained
  PASS — 13.3 Ending point retained

===  39 passed,  0 failed ===

## Testing
The test suite in `tests.adb` systematically validates:
1. **Functional Correctness**: Exact point retention and geometric distance calculations.
2. **Boundary and Edge Cases**: 0-length curves, 1-point paths, and 2-point line segments.
3. **Array Indexing Invariants**: Preserving correct behavior with non-1 array lower bounds (`Points'First > 1`).
4. **Variant Equivalence**: Validating that iterative and recursive algorithms produce identical point sets.
5. **Epsilon Invariants**: Verification of zero-epsilon stability and extreme-epsilon simplification collapse.

## Building
- **Compiler**: GNAT (FSF GNAT 12+ or GNAT Community / GNAT Pro supporting Ada 2022 / Ada 2023).
- **Language Standard**: Ada 2023 (`-gnat2022` / `-gnat2023`).
- **Flags**: `-gnatwa` (all warnings enabled; builds with zero warnings).
