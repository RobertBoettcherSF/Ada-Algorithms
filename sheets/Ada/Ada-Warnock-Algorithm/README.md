# Warnock Algorithm in Ada 2023

## Project Overview
The Warnock algorithm is a classic area-subdivision hidden-surface removal technique developed by John Warnock in 1969. It addresses rendering complexity in computer graphics through a divide-and-conquer strategy: a viewport area is recursively subdivided into four quadtree quadrants until visibility within each area can be decisively resolved. This implementation in Ada 2023 provides a strongly typed, complete 3D polygon visibility determination and rendering engine across four distinct variants: standard recursive point/sample resolution, depth-limited discrete framebuffer rasterization, adaptive supersampling for antialiased boundary blending, and diagnostic spatial complexity profiling.

## Features
* **Full Warnock Case Resolution**: Implements the four classic Warnock decision rules (disjoint polygons, single contained polygon, single surrounding polygon, and frontmost surrounding polygon test).
* **Strongly Typed Geometric Domain**: Custom types for viewport boundaries, polygonal vertices, planar equations, and 32-bit RGBA color models without reliance on unchecked primitives.
* **Variant 1 - Standard Recursive Sample**: Recursively computes the area color using pure Warnock logic with terminal center sampling down to a floating-point resolution threshold.
* **Variant 2 - Framebuffer Rasterizer**: Renders 3D polygon scenes into a 2D discrete pixel grid matrix with bounded quadtree recursion depth.
* **Variant 3 - Adaptive Supersampling**: Antialiased rendering that recursively evaluates subquadrants and averages color boundaries when edge ambiguities persist at pixel limits.
* **Variant 4 - Diagnostic Profiling**: Traverses the quadtree structure to measure exact traversal counts and maximum tree depth, profiling spatial subdivision efficiency.
* **Contract-Based Design**: Rigorous Ada Pre-condition annotations guarding planar validity and viewport boundaries.

## Usage
Build and run the comprehensive test suite with:

```bash
make test
```

Expected output:
```text
mkdir -p obj bin
gnatmake -gnatwa -gnat2022 -Pwarnock_algorithm.gpr
...
Running tests...
TEST 1 — Area Metrics and Validation
  PASS — 1.1 Area validity check
  PASS — 1.2 Area width calculation
  PASS — 1.3 Area height and center calculation
...
===  42 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` validates:
* **Functional Correctness**: Geometric ray-casting point-in-polygon checks, line-line edge intersections, quadrant subdivision coordinate alignment, and plane Z-depth evaluations.
* **Visibility Invariants**: Correct color output when multiple overlapping polygons compete for depth precedence.
* **Edge Cases**: Empty polygon arrays, out-of-bounds geometries, completely surrounding polylines, boundary-grazing segments, and degenerate viewport dimensions.
* **Error Handling & Preconditions**: Rejection of negative/zero area dimensions and tilted plane singular evaluations.

## Building
Prerequisites:
* GNAT Ada compiler supporting Ada 2022/2023 (`gnatmake` or GPRbuild).
* GNU Make.

Command to build standalone binary:
```bash
make
```

Artifacts are compiled into `obj/` and executables placed into `bin/`. Clean artifacts with:
```bash
make clean
```
