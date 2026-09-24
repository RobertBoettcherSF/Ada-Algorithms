# Path Tracing in Ada 2023

## Project Overview
Path tracing is a Monte Carlo rendering algorithm introduced by James Kajiya in 1986 to solve the rendering equation. It simulates the physical transport of light by tracing stochastic ray paths backward from the camera into the scene. This Ada 2023 implementation provides a strongly typed, zero-warning implementation of the algorithm with three distinct integration variants: Pure Monte Carlo Path Tracing, Next Event Estimation (explicit light source sampling), and Russian Roulette stochastic termination.

## Features
* Pure Monte Carlo Path Tracing: Unbiased path expansion with diffuse cosine-weighted hemispherical sampling and specular reflection.
* Next Event Estimation (NEE): Direct illumination sampling at each bounce to accelerate radiance convergence.
* Russian Roulette Termination: Unbiased probabilistic ray termination based on surface reflectance throughput.
* Analytical Sphere Ray Tracing: Exact algebraic quadric intersections with surface normal derivation.
* Strong Typing: Custom types for Vector_3D, Radiance, Color_RGB, Ray, Material, and Sphere.
* Contract-Driven: Preconditions and invariants annotating all core geometric and radiometric subprograms.

## Usage
Build and run the test suite:

```bash
make test
```

Expected output:

```text
Running tests...
TEST 1 -- Vector Arithmetic
  PASS -- 1.1 Vector addition component sum
  PASS -- 1.2 Vector subtraction component difference
  PASS -- 1.3 Vector dot product accuracy
TEST 2 -- Normalization and Cross Product
  PASS -- 2.1 Un-normalized length equals 5.0
  PASS -- 2.2 Normalized vector has unit length
  PASS -- 2.3 Right-hand orthogonal cross product creates Z unit
TEST 3 -- Degenerate Vector Handling
  PASS -- 3.1 Normalizing zero vector raises Degenerate_Vector_Error
  PASS -- 3.2 Division by zero raises Degenerate_Vector_Error
  PASS -- 3.3 Valid vector division preserves ratio
TEST 4 -- Specular Reflection
  PASS -- 4.1 X direction remains positive
  PASS -- 4.2 Y direction sign inverts upwards
  PASS -- 4.3 Length preserved under reflection
TEST 5 -- Radiance Math and Clamping
  PASS -- 5.1 Radiance addition arithmetic
  PASS -- 5.2 Radiance multiplication by albedo
  PASS -- 5.3 Radiance clamped to unit interval [0, 1] in Color conversion
TEST 6 -- Ray-Sphere Intersection
  PASS -- 6.1 Hit record confirms sphere intersection
  PASS -- 6.2 Distance to sphere surface is exactly 4.0
  PASS -- 6.3 Miss record returns False for hit
TEST 7 -- Multi-Object Scene Intersections
  PASS -- 7.1 Intersect_Scene detects hit
  PASS -- 7.2 Nearest sphere occludes farther sphere (distance = 2.5)
  PASS -- 7.3 Nearest sphere material is identified (Red Albedo)
TEST 8 -- Pure Path Tracing Direct Light
  PASS -- 8.1 Directly visible emissive sphere returns Red radiance
  PASS -- 8.2 Direct emissive sphere returns Green radiance
  PASS -- 8.3 Direct emissive sphere returns Blue radiance
TEST 9 -- Next Event Estimation Direct Lighting
  PASS -- 9.1 NEE illuminates diffuse surface from light source
  PASS -- 9.2 NEE produces balanced white light on grey albedo
  PASS -- 9.3 Radiance is non-negative and finite
TEST 10 -- Russian Roulette Termination
  PASS -- 10.1 Russian Roulette hits direct emitter cleanly
  PASS -- 10.2 Russian Roulette color consistency G
  PASS -- 10.3 Russian Roulette color consistency B
TEST 11 -- Cosine Sampling Hemisphere
  PASS -- 11.1 Generated sample is normalized
  PASS -- 11.2 Generated sample points into positive hemisphere
  PASS -- 11.3 Sampling with extreme U1=0.0 stays oriented with normal
TEST 12 -- Unified Trace_Ray API
  PASS -- 12.1 Pure path multi-sample average matches emitter
  PASS -- 12.2 NEE multi-sample average matches emitter
  PASS -- 12.3 Dispatch preserves positive non-zero radiance
TEST 13 -- Scene Validation and Invariants
  PASS -- 13.1 Positive radius sphere validates successfully
  PASS -- 13.2 Negative radius sphere fails scene validation
  PASS -- 13.3 Empty scene validation evaluates to False
TEST 14 -- Background Miss Invariant
  PASS -- 14.1 Ray pointing away from all geometry returns 0.0 Red
  PASS -- 14.2 Ray pointing away returns 0.0 Green
  PASS -- 14.3 Ray pointing away returns 0.0 Blue

=== 42 passed, 0 failed ===
```

## Testing
The test suite in tests.adb covers four main verification and validation categories:
* Geometric and radiometric calculations: Vector operations (addition, subtraction, scaling, cross/dot product), vector normalization, specular reflection vectors, and cosine-weighted hemispherical distributions to guarantee physical plausibility.
* Error handling and defensive programming: Verification that Degenerate_Vector_Error is raised on zero-length normalization and division by zero.
* Intersection invariants: Analytical ray-sphere intersection correctness, distance ordering, and proper foreground-to-background occlusion in multi-object environments.
* Radiometric integration correctness: Pure path direct emitter evaluation, shadow ray transmission for Next Event Estimation, and probabilistic unbiased termination with Russian Roulette.

## Building
* Compiler: GNAT toolchain supporting ISO/IEC 8652:2023 (compiled with -gnat2022 and -gnatwa).
* Build tool: GNU Make.

Command references:
* `make`: Compiles tests.adb to bin/tests via GNAT project management.
* `make test`: Executes the complete test harness.
* `make clean`: Deletes the obj/ and bin/ directories.
