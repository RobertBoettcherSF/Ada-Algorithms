# Ray Tracing in Ada 2023

## Project Overview
Ray tracing is a graphics rendering technique that simulates the physical transport of light rays by tracing their paths backward from the eye or virtual camera into a synthetic 3D scene. This implementation models geometric ray-sphere intersections, illumination based on the classical Phong model with hard shadow rays, recursive Whitted-style specular reflection and dielectric transmission (Snell's law and Fresnel approximation), and distribution ray tracing for glossy reflections.

## Features
- Strong custom types for 3D vectors (Vector3), colors (Color), rays (Ray), materials (Material), spheres (Sphere), and scenes (Scene).
- Complete vector space primitives: dot products, cross products, vector norms, and normalization with zero-norm checks.
- Direct Ray Tracing: standard ray-casting supporting ambient, diffuse, and Phong specular shading with occlusion-tested shadow rays.
- Whitted-Style Recursive Ray Tracing: evaluates multi-bounce specular reflection and dielectric refraction (Snell's law with total internal reflection).
- Distribution Ray Tracing: stochastic sample perturbation for simulating glossy specular reflections and blurry highlights.
- Full viewport rasterizer (Render_Scene) producing pixel color buffers.
- Precondition and postcondition contracts validating geometry, scene capacity, and vector operations.

## Usage
Run the automated test suite using Make:

make test

Expected output:

Running tests...
TEST 1 — Vector Arithmetic
  PASS — 1.1 Vector addition matches components
  PASS — 1.2 Vector subtraction matches components
  PASS — 1.3 Vector scaling scales each axis
TEST 2 — Dot and Cross Products
  PASS — 2.1 Orthogonal vectors produce zero dot product
  PASS — 2.2 Cross product of X and Y yields positive Z
  PASS — 2.3 Self dot product matches length squared
TEST 3 — Vector Normalization
  PASS — 3.1 Magnitude of normalized vector equals 1.0
  PASS — 3.2 Normalized direction matches proportional components
  PASS — 3.3 Normalizing zero-vector raises Zero_Norm_Error
TEST 4 — Sphere Intersection Direct Hit
  PASS — 4.1 Ray aimed straight at sphere records a hit
  PASS — 4.2 Hit distance is exactly 2.0 units away
  PASS — 4.3 Hit normal points directly toward ray origin
TEST 5 — Sphere Intersection Miss
  PASS — 5.1 Parallel offset ray registers no hit
  PASS — 5.2 Ray pointing away from sphere registers no hit
  PASS — 5.3 Distance remains uncalculated when no hit occurs
TEST 6 — Law of Reflection
  PASS — 6.1 Reflection reverses normal direction component
  PASS — 6.2 Reflection preserves tangent direction component
  PASS — 6.3 Reflected vector preserves unit magnitude
TEST 7 — Snell's Law of Refraction
  PASS — 7.1 Normal incident ray propagates through undeflected
  PASS — 7.2 Refracted ray retains downward movement
  PASS — 7.3 Total internal reflection returns zero vector
TEST 8 — Scene Closest Intersection
  PASS — 8.1 Scene tracks populated sphere count
  PASS — 8.2 Closest intersection selects foreground object
  PASS — 8.3 Selected distance matches nearest sphere boundary
TEST 9 — Scene Capacity Limits
  PASS — 9.1 Added maximum allowable 16 objects
  PASS — 9.2 Overflowing object limit raises Capacity_Error
  PASS — 9.3 Scene bounds remain intact
TEST 10 — Direct Ray Tracing and Shadowing
  PASS — 10.1 Direct illuminated sphere yields non-zero red color
  PASS — 10.2 Ray missing scene geometry returns black background
  PASS — 10.3 Ambient light is preserved under direct shading
TEST 11 — Whitted Recursive Ray Tracing
  PASS — 11.1 Whitted recursive tracing executes successfully
  PASS — 11.2 Depth 0 truncates reflections to direct term
  PASS — 11.3 Returned color components stay clamped in [0, 1]
TEST 12 — Distribution Ray Tracing
  PASS — 12.1 Distribution ray tracing integrates multiple samples
  PASS — 12.2 Output values are valid non-negative numbers
  PASS — 12.3 High shininess preserves specular intensity
TEST 13 — Dielectric Tracing and Image Render
  PASS — 13.1 Glass dielectric material returns combined color
  PASS — 13.2 Viewport buffer renders expected bounds
  PASS — 13.3 Center viewport pixel registers object hit

===  39 passed,  0 failed ===

## Testing
The test suite in tests.adb covers four main verification criteria:
1. Functional Correctness: Validates vector mathematics, dot/cross products, Snell's law refraction, reflection angles, and quadratic sphere-ray intersection geometry.
2. Edge Cases: Asserts behavior on near misses, spheres located behind ray origins, rays parallel to surface planes, and total internal reflection (TIR).
3. Error Handling: Tests handling of degenerate vector inputs (zero-length normalization) and bounds limit enforcement on scene objects through Capacity_Error.
4. Invariant Validation: Enforces clamped [0.0, 1.0] color ranges, unitary vector lengths after normalization, and non-decreasing recursive depth limits.

## Building
- Compiler: GNAT (FSF GNAT or GNAT Pro supporting Ada 2022 / Ada 2023 ISO/IEC 8652:2023).
- Build Flags: -gnatwa -gnat2022 to ensure zero compilation warnings and compliance with modern standard features.
- Build targets: make all, make test, and make clean.
