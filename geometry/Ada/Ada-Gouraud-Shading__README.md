# Gouraud Shading in Ada 2023

## Project Overview
Gouraud shading is a classic computer graphics method introduced by Henri Gouraud in 1971 for rendering smooth, continuous lighting across polygonal 3D surfaces. Instead of performing computationally demanding lighting equations at every pixel (as in Phong shading) or using flat shading per polygon face, Gouraud shading calculates lighting intensity or color exclusively at polygon vertices based on surface normals. The resulting vertex colors are then linearly interpolated across polygon edges and interior scanlines using barycentric coordinates or scanline rasterization. This repository provides a complete, strongly-typed implementation written in Ada 2023 (ISO/IEC 8652:2023), featuring vertex normal averaging, Lambertian and Blinn-Phong illumination models, barycentric interpolation, and scanline rasterization with zero warnings under -gnatwa.

## Features
- Vertex Normal Averaging: Computes smooth vertex normals by accumulating adjacent face normal vectors weighted by polygon area.
- Lambertian Illumination: Calculates diffuse vertex intensity with ambient terms and angle of incidence clamping.
- Blinn-Phong Vertex Lighting: Full RGB illumination calculating ambient, diffuse, and specular highlights at polygon vertices.
- Barycentric Interpolation: Analytical per-pixel evaluation for arbitrary point testing in barycentric space.
- Scanline Triangle Rasterizer: High-performance edge-walking rasterizer for both scalar intensity and RGB color framebuffers.
- Strong Typing: Domain-specific types for Real, Intensity, Color_Component, RGB_Color, Vector_3D, and Framebuffer.
- Ada 2023 Contracts: Specification attributes including Pre, Post, and Global => null pure contracts.

## Usage
Build and run the test suite and API demonstration using make:

make test

Expected output:
Running tests...
TEST 1 -- Vector Geometry and Normalization
  PASS -- 1.1 Vector magnitude calculation is accurate (3,0,4 -> 5)
  PASS -- 1.2 Normalized vector components are correct (3/5, 0, 4/5)
  PASS -- 1.3 Normalized vector dot product with itself is 1.0
TEST 2 -- Vector Cross Product Orthogonality
  PASS -- 2.1 Cross product X and Y yields positive Z
  PASS -- 2.2 Orthogonal cross product dot with UX is 0
  PASS -- 2.3 Orthogonal cross product dot with UY is 0
TEST 3 -- Color Operations and Clamping
  PASS -- 3.1 Add colors clamps red component to 1.0
  PASS -- 3.2 Scale color halves green component accurately
  PASS -- 3.3 Multiply colors modulates channels correctly
TEST 4 -- Linear Interpolation
  PASS -- 4.1 Midpoint scalar interpolation is 0.5
  PASS -- 4.2 Color lerp at T=0.5 produces balanced Red
  PASS -- 4.3 Color lerp at T=0.5 preserves constant Green
TEST 5 -- Vertex Normal Averaging Across Adjacent Faces
  PASS -- 5.1 Resulting array length matches vertex count
  PASS -- 5.2 Shared vertex 1 normal has symmetric X cancellation
  PASS -- 5.3 Shared vertex 1 normal has positive upward Y orientation
TEST 6 -- Lambertian Vertex Lighting
  PASS -- 6.1 Direct incidence yields maximum lighting (1.0)
  PASS -- 6.2 Perpendicular light yields only ambient term (0.1)
  PASS -- 6.3 Back-facing light is clamped to ambient term (0.1)
TEST 7 -- Vertex Phong Illumination Model
  PASS -- 7.1 Red diffuse channel is illuminated
  PASS -- 7.2 Specular highlight adds white light to green channel
  PASS -- 7.3 Specular highlight adds white light to blue channel
TEST 8 -- Barycentric Gouraud Interpolation (Scalar)
  PASS -- 8.1 Center point is average of vertex intensities (0.5)
  PASS -- 8.2 Interpolation exactly at vertex V2 yields 1.0
  PASS -- 8.3 Interpolation on edge midpoint yields 0.5
TEST 9 -- Barycentric Gouraud Interpolation (RGB Color)
  PASS -- 9.1 Centroid Red is ~0.333
  PASS -- 9.2 Centroid Green is ~0.333
  PASS -- 9.3 Centroid Blue is ~0.333
TEST 10 -- Scanline Rasterization (RGB Triangle)
  PASS -- 10.1 Pixel near vertex 1 has predominant Red
  PASS -- 10.2 Pixel near vertex 2 has predominant Green
  PASS -- 10.3 Interior pixel has non-zero mixed channels
TEST 11 -- Scanline Rasterization (Scalar Mode)
  PASS -- 11.1 Pixel near low intensity corner is dark
  PASS -- 11.2 Pixel near high intensity corner is bright green
  PASS -- 11.3 Red and Blue channels remain zero
TEST 12 -- Edge Cases and Degenerate Geometry
  PASS -- 12.1 Collinear points raise Degenerate_Triangle_Error
  PASS -- 12.2 Rasterizing flat triangle completes without panic
  PASS -- 12.3 Flat triangle leaves surrounding cells uncorrupted
TEST 13 -- Error Handling
  PASS -- 13.1 Normalizing zero-length vector raises Invalid_Normal_Error
  PASS -- 13.2 Invalid vertex index raises Constraint_Error
  PASS -- 13.3 Math clamps avoid NaN or out of bounds intensity
TEST 14 -- Scanline Monotonicity and Edge Clamping
  PASS -- 14.1 Start of span is dark
  PASS -- 14.2 End of span is bright red
  PASS -- 14.3 Intermediate pixel is intermediate shade

===  42 passed,  0 failed ===

## Testing
The test suite in tests.adb validates functional correctness across several critical domains:
- Vector Mathematics: Ensures dot and cross products preserve standard geometric properties and normalization handles edge cases safely.
- Illumination Physics: Validates Lambertian cosine falloff, specular highlights, and backface illumination limits.
- Smooth Normal Convergence: Verifies that adjacent polygons sharing a common edge produce unified, area-weighted normal vectors to eliminate polygonal facet lines.
- Interpolation Precision: Barycentric coordinates and scanline edge steps are checked for monotonicity and exact boundary matches.
- Edge Cases & Exceptions: Confirms robust handling of zero-area collinear triangles, zero-length normal vectors, and out-of-bound vertex indexing.

## Building
Prerequisites:
- GNAT compiler supporting Ada 2022 / Ada 2023 (e.g., GNAT FSF 13+, GNAT Community 2021+, or Alire toolchain)
- GNU Make

To compile manually:
gnatmake -gnatwa -gnat2022 -Pgouraud_shading.gpr
