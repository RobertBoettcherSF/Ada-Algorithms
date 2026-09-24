# Xiaolin Wu's Line Algorithm in Ada 2023

## Project Overview
Xiaolin Wu's line algorithm is an efficient algorithm for computer graphics line rasterization that produces high-quality antialiased lines. Unlike Bresenham's algorithm, which only selects the single closest pixel along the path, Wu's algorithm calculates the fractional distance between the idealized continuous mathematical line and the nearest two discrete pixel centers on the minor axis. It distributes pixel intensities proportionally between these adjacent pixels based on sub-pixel coverage, effectively smoothing jagged edges and preserving perceptual line thickness. This implementation provides standard 2D buffer rasterization, callback-based memory-free streaming, full RGBA alpha compositing, and viewport-clipped line drawing in Ada 2023.

## Features
- Standard Buffer Rasterization: Direct 2D intensity grid line drawing with sub-pixel endpoint and midpoint interpolation.
- Callback Streaming Rasterization: Memory-efficient streaming interface using access-to-subprogram callbacks for embedded environments or GPU streaming pipelines.
- RGBA Alpha-Compositing Variant: Direct Porter-Duff source-over blending onto color grids with antialiased edge coverage calculations.
- Clipped Viewport Variant: Bounded rasterization constrained by rectangular window bounds.
- Strong Typing & Contracts: Custom types (Intensity, Pixel_Coordinate, Coordinate, RGBA_Color, Point_2D) with Ada 2023 contracts (Pre, Global).
- Energy Conservation: Guarantees that the combined coverage of paired antialiased pixels sums to 1.0 across continuous line spans.
- Symmetry / Direction Invariance: Identical rasterization output regardless of whether lines are traced from start to end or end to start.

## Usage
Run the test suite via the Makefile:
make test

Expected output:
mkdir -p obj bin
gnatmake -gnatwa -gnat2022 -Pxiaolin_wu.gpr
...
Running tests...
TEST 1 — Helper Functions
  PASS — 1.1 Round_Coord positive and negative
  PASS — 1.2 Floor_Coord positive and negative
  PASS — 1.3 Fractional_Part and Reverse_Fractional_Part
TEST 2 — Color Compositing
  PASS — 2.1 50% white over black yields ~128 gray
  PASS — 2.2 0% coverage leaves background untouched
  PASS — 2.3 Color_To_Grayscale correctly weights RGB
TEST 3 — Degenerate Point Line
  PASS — 3.1 Single point rasterized at exact coord
  PASS — 3.2 Neighbor pixel remains untouched
  PASS — 3.3 Far pixel remains untouched
TEST 4 — Horizontal Line
  PASS — 4.1 Start and end of horizontal line fully covered
  PASS — 4.2 Intermediate points on horizontal line fully covered
  PASS — 4.3 Adjacent row has zero intensity for integer horizontal line
TEST 5 — Vertical Line
  PASS — 5.1 Vertical line endpoints drawn
  PASS — 5.2 Vertical line intermediates drawn
  PASS — 5.3 Adjacent columns remain zero
TEST 6 — Diagonal Line
  PASS — 6.1 Diagonal start point covered
  PASS — 6.2 Diagonal midpoint covered
  PASS — 6.3 Diagonal end point covered
TEST 7 — Antialiasing Invariant
  PASS — 7.1 Lower adjacent pixel received antialiased weight
  PASS — 7.2 Upper adjacent pixel received antialiased weight
  PASS — 7.3 Pair sum approximates 1.0 (coverage partition)
TEST 8 — Direction Invariance
  PASS — 8.1 Rasterization is symmetrical
  PASS — 8.2 Forward drew active pixels
  PASS — 8.3 Backward drew active pixels matching forward
TEST 9 — Callback Variant
  PASS — 9.1 Callback emitted pixels
  PASS — 9.2 Callback accumulated non-zero intensity
  PASS — 9.3 Pixel count scales proportionally to line length
TEST 10 — RGBA Direct Rendering
  PASS — 10.1 Horizontal RGBA line changed red channel
  PASS — 10.2 Untouched RGBA line background intact
  PASS — 10.3 Endpoint has correct color
TEST 11 — Clipped Viewport
  PASS — 11.1 Pixel before Min_X was clipped away
  PASS — 11.2 Pixels within clipping box rendered
  PASS — 11.3 Pixel after Max_X was clipped away
TEST 12 — Out-of-Bounds Line Handling
  PASS — 12.1 Visible portion inside buffer drawn
  PASS — 12.2 Midpoint inside buffer drawn
  PASS — 12.3 Off-line buffer areas remain pristine
TEST 13 — Micro Sub-Pixel Step
  PASS — 13.1 Micro-step plotted onto nearest rounded pixel
  PASS — 13.2 Surrounding points maintain zero
  PASS — 13.3 Value is within valid intensity bounds

===  39 passed,  0 failed ===

## Testing
The test suite in tests.adb covers:
- Helper Unit Arithmetic: Verifies Round_Coord, Floor_Coord, Fractional_Part, and Reverse_Fractional_Part over positive and negative ranges.
- Color Compositing: Confirms alpha blending math and grayscale conversions.
- Degenerate Geometries: Verifies single-point lines, micro-step sub-pixel segments, and lines outside the target buffer.
- Axis-Aligned & Diagonal Paths: Tests horizontal, vertical, and diagonal slopes for correct coordinate handling and steep/non-steep switching.
- Physical Invariants: Confirms energy conservation (dual-pixel intensity sums to 1.0) and direction invariance (P0 -> P1 matches P1 -> P0).
- API Coverage: Evaluates direct intensity grids, callback rasterization, RGBA compositing, and viewport clipping.

## Building
- Compiler: GNAT supporting Ada 2022 / Ada 2023 (-gnat2022 or -gnat2023).
- Flags: -gnatwa -gnat2022 for strict warning compliance.
- Build target: make or gnatmake -Pxiaolin_wu.gpr.
