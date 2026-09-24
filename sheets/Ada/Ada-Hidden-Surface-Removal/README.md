# Hidden-Surface Determination in Ada 2023

## Project Overview
Hidden-surface determination (also known as visible surface determination or occultation processing) is a fundamental problem in 3D computer graphics: determining which surfaces and parts of surfaces are visible from a given perspective point. This package provides an Ada 2023 (ISO/IEC 8652:2023) implementation of the primary algorithms classified in computer graphics literature: object-space methods (Back-Face Culling), list-priority sorting algorithms (Painter's Algorithm), image-space algorithms (Depth-Buffer / Z-Buffer and Scanline Z-Buffer), and point-sampling ray formulations (Ray Casting).

## Features
* **Object-Space Back-Face Culling**: Evaluates surface normal vectors against a camera sightline, discarding non-visible geometric primitives before rendering.
* **Painter's Algorithm**: Implements depth sorting from furthest to nearest geometric bounds, painting sequentially to achieve proper surface occlusion.
* **Z-Buffer (Depth Buffer)**: Performs per-pixel depth comparison during rasterization, allowing arbitrary rendering order while guaranteeing proper visual occlusions.
* **Scanline Z-Buffer**: Processes surface intersections scanline-by-scanline across active geometric bounds.
* **Ray Casting Determination**: Computes visible surfaces via analytical ray-polygon intersection tests (Möller–Trumbore intersection algorithm).
* **Strongly Typed Geometric Types**: Dedicated types for Screen coordinates, 3D Coordinates, Depth Values, and Color channels.
* **Ada Contract Aspects**: `Pre`, `Post`, and `Global` contracts applied to all public APIs for formal verification.

## Usage
Run the test suite using GNU Make:

```bash
make test
```

Expected output:

```text
Running tests...
TEST 1 — Vector Operations and Triangle Normal
  PASS — 1.1 Cross product yields perpendicular Z axis
  PASS — 1.2 Dot product of orthogonal vectors is zero
  PASS — 1.3 Counter-clockwise normal points towards viewer +Z
TEST 2 — Normalization and Error Handling
  PASS — 2.1 Vector magnitude calculation is accurate
  PASS — 2.2 Normalized vector has unit length
  PASS — 2.3 Zero vector raises Zero_Vector_Error
TEST 3 — Degenerate Triangle Error Detection
  PASS — 3.1 Collinear points raise Invalid_Triangle_Error
  PASS — 3.2 Triangle ID preserved
  PASS — 3.3 Color preserved
TEST 4 — Back-Face Culling Point Logic
  PASS — 4.1 Front-facing counter-clockwise triangle not culled
  PASS — 4.2 Clockwise winding triangle recognized as back-face
  PASS — 4.3 Culling responds correctly to reversed viewpoint
TEST 5 — Bulk Back-Face Culling Pipeline
  PASS — 5.1 Correct number of surviving front-facing triangles
  PASS — 5.2 First surviving is T_Front
  PASS — 5.3 Second surviving is T_Back
TEST 6 — Edge Case: Empty Input Arrays
  PASS — 6.1 Empty input returns zero output count
  PASS — 6.2 Output length stays 0
  PASS — 6.3 Sort on empty array executes cleanly
TEST 7 — Painter's Depth Sorting
  PASS — 7.1 Furthest item sorted first for painter order
  PASS — 7.2 Nearest item sorted last
  PASS — 7.3 Ascending order places nearest first
TEST 8 — Buffer Clear Operations
  PASS — 8.1 Color buffer cleared to black
  PASS — 8.2 Depth buffer cleared to 1.0 (far plane)
  PASS — 8.3 Boundary pixel initialized
TEST 9 — Painter's Algorithm Raster Output
  PASS — 9.1 Overlapping pixel at (1,1) shows foreground color (Red)
  PASS — 9.2 Uncovered background corner (14,14) remains clear
  PASS — 9.3 Near triangle vertex origin rendered
TEST 10 — Z-Buffer Depth Buffering Correctness
  PASS — 10.1 Front triangle dominates pixel despite order
  PASS — 10.2 Depth buffer contains closest Z value
  PASS — 10.3 Background pixel depth not leaked outside triangle
TEST 11 — Ray-Casting Determination
  PASS — 11.1 Pixel directly in line of sight (2,2) resolves to Red
  PASS — 11.2 Pixel (1,1) resolves to front triangle
  PASS — 11.3 Outside ray misses geometry and stays black
TEST 12 — Scanline Z-Buffer Algorithm
  PASS — 12.1 Scanline correctly resolves front surface at (3,3)
  PASS — 12.2 Scanline Z-Buffer depth matches foreground depth
  PASS — 12.3 Line outside triangle bounds stays unaffected
TEST 13 — Analytical Ray Intersection Accuracy
  PASS — 13.1 Ray hitting triangle returns Hit = True
  PASS — 13.2 Hit depth matches triangle plane distance
  PASS — 13.3 Ray outside boundary returns Hit = False

===  39 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` validates 13 distinct verification areas with 39 individual assertions:
* **Functional Correctness**: Verifies vector cross and dot products, surface normals, depth ordering, raster overwrite, Z-buffer ordering independence, and Ray-Casting intersection.
* **Edge Cases**: Covers empty triangle input arrays, boundary screen coordinate checks, and reverse viewing vectors.
* **Error Handling**: Verifies that zero-length vectors raise `Zero_Vector_Error` and collinear degenerate triangles raise `Invalid_Triangle_Error`.
* **Invariants**: Ensures depth buffers are bounded in range [0.0, 1.0] and that front-most geometry dominates the raster output regardless of submission order.

## Building
* **Prerequisites**: GNAT compiler supporting Ada 2022/2023 (`gnatmake`, `gcc`).
* **Standards**: Built with `-gnatwa -gnat2022` according to ISO/IEC 8652:2023.
