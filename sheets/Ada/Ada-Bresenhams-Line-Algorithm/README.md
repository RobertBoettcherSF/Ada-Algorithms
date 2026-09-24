# Bresenham's Line Algorithm in Ada 2023

## Project Overview
This project provides a robust, strongly typed, and formally annotated implementation of Bresenham's Line Algorithm in Ada 2023 (ISO/IEC 8652:2023). The package rasterizes straight 2D line segments across a discrete coordinate grid using purely incremental integer arithmetic. The algorithm avoids floating-point operations and costly divisions by maintaining an error term that tracks the distance between fractional line coordinates and the nearest discrete pixel center. The implementation provides classic first-octant rasterization, generalized all-octant line generation, immediate-mode callback execution, and multi-pixel width line extrusion.

## Features
- First-Octant Baseline (`Line_Octant_0`): Classic formulation for lines where 0 <= dy <= dx with non-negative direction.
- General All-Octant Line Generation (`Line_General`): Fully generalized rasterizer covering all 8 octants, horizontal lines, vertical lines, and degenerate single-pixel lines using integer error accumulation.
- Immediate-Mode Callback (`Line_General_Callback`): Direct plotting invocation through an access-to-subprogram parameter, eliminating dynamic allocations and buffer overhead.
- Thick Line Generation (`Line_Thick`): Parallel perpendicular sweep extrusion producing lines of specified discrete pixel thickness.
- Analytical Helpers: Subprograms for computing Chebyshev distance, Manhattan distance, expected line lengths, and octant preconditions.
- Formal Verification Contracts: Subprograms are annotated with Ada Pre/Post contract conditions and SPARK Mode readiness.

## Usage
Run the test suite using `make`:

    make test

Expected output:

    Running tests...
    TEST 1 — Octant 0 Baseline Line
      PASS — 1.1 Exact length matches dx + 1
      PASS — 1.2 First point is start
      PASS — 1.3 Last point is target
    TEST 2 — Single Point
      PASS — 2.1 Length is 1
      PASS — 2.2 Coordinates remain unchanged
      PASS — 2.3 Expected length helper confirms 1
    TEST 3 — Perfect Horizontal Line
      PASS — 3.1 West to East length is 11
      PASS — 3.2 Constant Y preserved
      PASS — 3.3 East to West reverses start/end points correctly
    TEST 4 — Perfect Vertical Line
      PASS — 4.1 South to North length is 8
      PASS — 4.2 Constant X preserved
      PASS — 4.3 North to South endpoint matches
    TEST 5 — Exact Diagonal Lines
      PASS — 5.1 Slope 1 has equal coordinates at each step
      PASS — 5.2 Slope -1 sum is invariant
      PASS — 5.3 Both lines match length 6
    TEST 6 — Steep Line Rasterization
      PASS — 6.1 Length matches dy + 1
      PASS — 6.2 Sequence is monotonically non-decreasing in X and Y
      PASS — 6.3 Monotonic step-wise 8-connectivity
    TEST 7 — Negative Coordinates Handling
      PASS — 7.1 Start point correct in negative space
      PASS — 7.2 End point reached in negative space
      PASS — 7.3 Span length corresponds to delta-Y + 1
    TEST 8 — Directional Invariance / Symmetry
      PASS — 8.1 Forward and backward lengths identical
      PASS — 8.2 Pixels mirror exactly in reverse
      PASS — 8.3 Endpoints match opposite directions
    TEST 9 — Immediate Callback Execution
      PASS — 9.1 Callback executed 11 times
      PASS — 9.2 Final coordinate observed is endpoint
      PASS — 9.3 Length matches Chebyshev distance + 1
    TEST 10 — Helper Logic Validation
      PASS — 10.1 Manhattan distance calculation
      PASS — 10.2 Chebyshev distance calculation
      PASS — 10.3 Octant 0 validator detects valid vs invalid inputs
    TEST 11 — Thick Line Rasterization (X-Major)
      PASS — 11.1 Thick line point count is length * thickness
      PASS — 11.2 First layer contains start point offset
      PASS — 11.3 Middle layer contains original start point
    TEST 12 — Thick Line Rasterization (Y-Major)
      PASS — 12.1 Thick line point count is length * thickness
      PASS — 12.2 First cross layer shifted perpendicularly in X
      PASS — 12.3 Second cross layer shifted perpendicularly in X
    TEST 13 — Strict Grid Connectivity Invariant
      PASS — 13.1 Every point is 8-connected to predecessor
      PASS — 13.2 Start is (-15, 30)
      PASS — 13.3 End is (40, -10)

    === 39 passed, 0 failed ===

## Testing
The test suite in `tests.adb` covers:
- Functional Correctness: Validating raster paths across horizontal, vertical, diagonal, and arbitrary slope segments.
- Edge Cases: Zero-length line segments (single point), negative coordinate regimes, and exact reverse symmetry.
- Continuous 8-Connectivity: Asserting that Chebyshev distance between any consecutive pixel pair strictly equals 1.
- Immediate Callback Execution: Verifying the invocation count and endpoint arrival of pointer-based plot pipelines.
- Thick Line Topology: Verifying dimensional extrusion count and layer offsets across both X-dominant and Y-dominant directions.

## Building
Prerequisites:
- GNAT toolchain supporting Ada 2022 / Ada 2023 (`gnatmake`, `gcc`).
- GNU Make.

Build commands:
- `make`: Compiles package files and builds the `bin/tests` binary cleanly with `-gnatwa -gnat2022`.
- `make test`: Builds and executes the test harness.
- `make clean`: Removes generated `obj/` and `bin/` directories.
