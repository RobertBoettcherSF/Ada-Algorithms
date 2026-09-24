# Scanline Rendering in Ada 2023

## Project Overview
This project provides a robust, strongly typed Ada 2023 implementation of scanline rendering algorithms for computer graphics, based on the principles outlined in the Scanline Rendering literature. Scanline rendering solves the visible surface determination and rasterization problem row by row (scanline by scanline), rather than processing pixels arbitrarily or buffering whole-frame polygonal depth blindly. The package features 2D polygon fill with parity/even-odd edge table processing, 3D scanline rasterization with linear depth interpolation (Z-buffering), and scanline hidden-surface removal using span coherence.

## Features
- **2D Scanline Polygon Rasterization (`Render_Polygon_2D`)**: Implements the classic Edge Table (ET) and Active Edge Table (AET) algorithm with even-odd parity filling for convex, concave, and self-intersecting polygons.
- **3D Scanline Z-Buffering (`Render_Scene_3D_ZBuffer`)**: Rasterizes scenes of 3D polygonal primitives by interpolating depth gradients (dz/dx and dz/dy) along edges and scanline spans, determining visibility per pixel.
- **Span-Based Hidden-Surface Removal (`Render_Scanline_Spans`)**: Evaluates depth across individual scanline segments without requiring full multi-megabyte 2D frame allocations for intermediate passes.
- **Strong Typing & Safety**: Domain types for coordinates (`Screen_Coordinate_X`, `Screen_Coordinate_Y`), color values, and depths ensure bounds validity at compile time.
- **Ada 2023 Contracts**: Subprogram declarations leverage contract aspects including `Pre` conditions and `Global => null` purity annotations.

## Usage
Build and run the test suite using `make`:

```bash
make test
```

Expected output:
```text
Running tests...
TEST 1 -- Clear Frame Buffer
  PASS -- 1.1 Origin is black
  PASS -- 1.2 Center is black
  PASS -- 1.3 Center is white after clear
TEST 2 -- Clear Depth Buffer
  PASS -- 2.1 Origin depth initialized
  PASS -- 2.2 Max boundary depth initialized
  PASS -- 2.3 Depth buffer reset to zero
TEST 3 -- 2D Triangle Rasterization
  PASS -- 3.1 Centroid is filled
  PASS -- 3.2 Outside pixel is untouched
  PASS -- 3.3 Triangle area has non-zero filled pixels
TEST 4 -- 2D Concave Polygon Fill
  PASS -- 4.1 Interior of top limb is colored
  PASS -- 4.2 Interior of vertical limb is colored
  PASS -- 4.3 Concave exterior pocket remains black
TEST 5 -- 2D Degenerate Polygon Handling
  PASS -- 5.1 Degenerate collinear points don't crash
  PASS -- 5.2 Zero area polygon draws minimal or no pixels
  PASS -- 5.3 Far-off pixel remains background
TEST 6 -- Point In Convex Hull
  PASS -- 6.1 Center point is inside hull
  PASS -- 6.2 Exterior point is outside hull
  PASS -- 6.3 Right exterior point is outside hull
TEST 7 -- 3D Z-Buffer Occlusion
  PASS -- 7.1 Overlapping pixel resolves to nearer green triangle
  PASS -- 7.2 Non-overlapping far section remains red
  PASS -- 7.3 Depth buffer correctly stores nearest Z
TEST 8 -- 3D Z-Buffer Submission Invariance
  PASS -- 8.1 Overlapping pixel resolves to nearer green triangle despite reverse order
  PASS -- 8.2 Far triangle does not overwrite nearer depth
  PASS -- 8.3 Outside region remains untouched black
TEST 9 -- Scanline Span Processing
  PASS -- 9.1 Near span pixel at Y=25 is white
  PASS -- 9.2 Far span non-overlapped pixel is blue
  PASS -- 9.3 Unrendered scanline Y=10 remains black
TEST 10 -- Slanted Depth Interpolation
  PASS -- 10.1 Left pixel rendered
  PASS -- 10.2 Right pixel rendered
  PASS -- 10.3 Depth strictly increases along X for slanted plane
TEST 11 -- Empty Scene Handling
  PASS -- 11.1 Zero polygons rendered without error
  PASS -- 11.2 Frame buffer untouched
  PASS -- 11.3 Depth buffer remains at initial clear value
TEST 12 -- Extreme Screen Boundaries
  PASS -- 12.1 Max coordinate rendering executes without range fault
  PASS -- 12.2 Max edge pixel colored
  PASS -- 12.3 Origin unaffected
TEST 13 -- Multiple Non-Overlapping Polygons
  PASS -- 13.1 First separate triangle rendered
  PASS -- 13.2 Second separate triangle rendered
  PASS -- 13.3 Space between triangles remains black
TEST 14 -- Parity Self-Intersection Fill
  PASS -- 14.1 Left lobe rendered
  PASS -- 14.2 Right lobe rendered
  PASS -- 14.3 Outside perimeter untouched

===  42 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` exercises all public subprograms across 14 distinct test blocks, asserting functional correctness, numerical edge cases, and algorithmic invariants:
- **Functional Correctness**: Verifies 2D filling of simple and concave shapes, correct color application, and proper 3D depth ordering.
- **Occlusion & Depth Invariance**: Asserts that nearer polygons consistently obscure farther geometry regardless of the order in which polygons are submitted to the rasterizer.
- **Edge Cases**: Covers empty scenes, zero-area / collinear polygons, screen coordinate boundaries (`Screen_Coordinate_X'Last`, `Screen_Coordinate_Y'Last`), and self-intersecting figures.
- **Depth Gradients**: Validates that depth interpolation faithfully tracks non-orthogonal planar slopes along the scanline span.

## Building
- **Prerequisites**: GNAT compiler supporting Ada 2022 / Ada 2023 (`gnatmake` with `-gnat2022` or `-gnat2023`), `make`.
- **Standard**: ISO/IEC 8652:2023 (Ada 2023).
- **Clean compilation**: Builds cleanly under `-gnatwa` with zero warnings.
