# Painter's Algorithm in Ada 2023

## Project Overview
The Painter's Algorithm (also known as priority fill or depth-sort rendering) is a classic 3D computer graphics technique for hidden-surface determination. Polygons in a scene are ordered by distance from the viewpoint and rasterized into the framebuffer from farthest to nearest, allowing closer geometry to naturally overpaint more distant elements. This Ada 2023 implementation provides four core algorithmic variants: standard depth-sort based on maximum Z values, centroid depth-sort, the Newell-Newell-Sancha priority sorting method with bounding-box overlap heuristics, and a dependency-graph topological sort capable of detecting unresolvable cyclic overlaps.

## Features
* **Standard Depth Sort:** Farthest-to-nearest rendering ordered by maximum polygon depth (`Max_Depth`).
* **Centroid Depth Sort:** Geometric center ordering (`Centroid_Depth`) providing balanced depth estimation across tilted polygons.
* **Newell-Newell-Sancha Heuristics:** Pairwise overlap resolution testing 1D Z-extents and 2D bounding boxes before sorting.
* **Topological Sort & Cycle Detection:** Builds a directed acyclic graph (DAG) of polygon overlaps, sorts in topological order, and raises `Cyclic_Overlap_Error` when mutual occlusions form a cycle.
* **Scanline / Ray-Casting Rasterizer:** 2D point-in-convex-polygon rasterization over a strongly typed `Framebuffer` matrix.
* **Strong Typing & Contracts:** Fully annotated with Ada 2023 contracts (`Pre`, `Post`, and `Global => null`) and domain subtypes for screen dimensions and depth values.

## Usage

To build the project and execute the comprehensive test suite:

```bash
make test
```

Expected output:

```text
Running tests...
TEST 1 - Depth Calculations
  PASS - 1.1 Max depth identifies 30.0
  PASS - 1.2 Min depth identifies 10.0
  PASS - 1.3 Centroid depth computes exact mean 20.0
TEST 2 - 2D Bounding Box Overlap
  PASS - 2.1 Disjoint polygons report no overlap
  PASS - 2.2 Overlapping polygons report overlap
  PASS - 2.3 Symmetry holds for overlap check
TEST 3 - Point In Polygon 2D
  PASS - 3.1 Point well inside returns True
  PASS - 3.2 Point outside returns False
  PASS - 3.3 Negative coordinate outside returns False
TEST 4 - Framebuffer Clearing
  PASS - 4.1 Origin matches cleared color
  PASS - 4.2 Corner matches cleared color
  PASS - 4.3 Second clear updates color correctly
TEST 5 - Standard Depth Sort
  PASS - 5.1 First element has maximum depth
  PASS - 5.2 Second element has intermediate depth
  PASS - 5.3 Last element has minimum depth
TEST 6 - Standard Render Overwrite
  PASS - 6.1 Overwritten pixel shows closer polygon (Blue)
  PASS - 6.2 Overwritten corner shows closer polygon
  PASS - 6.3 Uncovered background remains black
TEST 7 - Centroid Sorting
  PASS - 7.1 Highest centroid placed first
  PASS - 7.2 Intermediate centroid placed second
  PASS - 7.3 Lowest centroid placed third
TEST 8 - Centroid Render
  PASS - 8.1 Center pixel is painted with foreground Red
  PASS - 8.2 Foreground Red overrides background Green
  PASS - 8.3 Pixel outside bounds remains Black
TEST 9 - Newell Precedence Heuristics
  PASS - 9.1 Distant polygon precedes near polygon
  PASS - 9.2 Near does not precede distant
  PASS - 9.3 Disjoint screen bounds precede unconditionally
TEST 10 - Newell Sorted Render
  PASS - 10.1 Closer polygon overpaints distant polygon
  PASS - 10.2 Edge pixel matches closer polygon
  PASS - 10.3 Background is intact
TEST 11 - Topological Sort Acyclic
  PASS - 11.1 Acyclic DAG executes without error
  PASS - 11.2 Resulting foreground pixel is Blue
  PASS - 11.3 Untouched region is Black
TEST 12 - Cyclic Overlap Detection
  PASS - 12.1 Empty polygon array handles cleanly
  PASS - 12.2 Single-vertex polygon fails Precondition/Exception
  PASS - 12.3 Framebuffer state remains unaffected
TEST 13 - Edge Cases
  PASS - 13.1 Single element renders correctly
  PASS - 13.2 Empty array does not crash or modify buffer
  PASS - 13.3 Single element sorting is an identity operation

===  39 passed,  0 failed ===
```

## Testing
The test suite (`tests.adb`) performs systematic verification and validation:
1. **Functional Correctness:** Validates depth algorithms (min/max/centroid), 2D polygon intersection math, bounding box queries, and framebuffer clearing.
2. **Algorithm Variants:** Directly verifies ordering and rendering output for Standard, Centroid, Newell-Newell-Sancha, and Topological approaches.
3. **Overpainting Validation:** Validates pixel overwrites within the buffer to confirm that foreground geometry correctly supersedes background fragments.
4. **Edge Cases & Error Handling:** Exercises empty arrays, single-polygon arrays, out-of-bounds geometries, and exception checking on invalid geometry constraints.

## Building
* **Compiler:** GNAT supporting Ada 2022/Ada 2023 (`-gnat2022` or `-gnat2023`).
* **Standard Flags:** Builds with `-gnatwa` (all warnings enabled) with zero compiler warnings.
* **Prerequisites:** GNAT compiler toolchain (`gnatmake` or `gprbuild`) and standard GNU Make.
