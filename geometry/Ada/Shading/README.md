# Shading Algorithms in Ada 2023

## Project Overview
This project provides a complete, strongly-typed implementation of 3D computer graphics shading techniques as detailed in the Wikipedia article on [Shading](https://en.wikipedia.org/wiki/Shading). Shading simulates depth perception and surface curvature in computer graphics by computing the local behavior of light interacting with geometric surfaces. The package implements standard illumination models (ambient, directional, point, and spotlight sources with distance falloff attenuation) and foundational polygon shading algorithms: Flat shading, Gouraud smooth shading, Phong smooth shading, and Deferred shading (multi-pass G-buffer rendering).

## Features
- Flat Shading: Evaluates the illumination model once per polygon using the geometric surface normal and polygon centroid, rendering faceted surfaces.
- Gouraud Shading: Evaluates illumination at each polygon vertex and bilinearly interpolates resulting color intensities across the surface using barycentric coordinates.
- Phong Shading: Bilinearly interpolates surface normal vectors across polygon vertices, re-normalizes them per sample, and evaluates full Phong illumination (ambient, diffuse, specular) per fragment.
- Deferred Shading: Implements a two-pass rendering architecture:
  - Pass 1 (Geometry Pass): Records surface position, normal, albedo, and depth into a G-Buffer with depth testing/culling.
  - Pass 2 (Lighting Pass): Iterates over the screen-space G-Buffer to compute lighting contributions without redundant shading of occluded fragments.
- Light Source Types:
  - Ambient Lighting: Omnidirectional omnipresent background lighting.
  - Directional Lighting: Parallel rays simulating distant light sources such as the Sun.
  - Point Lighting: Omnidirectional emission from a point source with distance falloff.
  - Spotlighting: Conical emission with angular cutoff and dropoff exponents.
- Distance Falloff: Configurable attenuation functions including constant (None, n = 0), linear (n = 1), quadratic (n = 2), and arbitrary power models.
- Ada 2023 Contracts: Pure strong typing (Real, Intensity_Value, Distance_Falloff, Material, etc.) with Pre and Post contract aspects ensuring valid geometric operations and bounded color values.

## Usage
Build and run the test executable using make:

    make test

Expected output:

    Running tests...
    TEST 1 -- Vector Primitives & Math Operations
      PASS -- 1.1 Vector addition
      PASS -- 1.2 Vector subtraction
      PASS -- 1.3 Dot product calculation (1*4 + 2*5 + 3*6 = 32)
    TEST 2 -- Vector Normalization and Cross Product
      PASS -- 2.1 Cross product of X and Y gives unit Z
      PASS -- 2.2 Vector magnitude of (0, 3, 4) is 5.0
      PASS -- 2.3 Normalized vector has unit magnitude
    TEST 3 -- Color Operations and Saturation Clamping
      PASS -- 3.1 Add colors clamps to 1.0 (0.6 + 0.5 = 1.0 clamped)
      PASS -- 3.2 Color modulation multiplies channels component-wise
      PASS -- 3.3 Color scale scales channel intensities
    TEST 4 -- Distance Falloff Variations
      PASS -- 4.1 Falloff None yields constant 1.0
      PASS -- 4.2 Linear falloff yields 1 / (1 + 3) = 0.25
      PASS -- 4.3 Quadratic falloff yields 1 / (1 + 9) = 0.10
      PASS -- 4.4 Custom cubic power falloff yields 1 / (1 + 27) ~ 0.0357
    TEST 5 -- Ambient and Directional Lighting Types
      PASS -- 5.1 Ambient lighting produces uniform ambient contribution
      PASS -- 5.2 Directional lighting illuminates diffuse component
      PASS -- 5.3 Red diffuse channel receives greater intensity than green/blue
    TEST 6 -- Point Light and Spot Light Types
      PASS -- 6.1 Point light attenuates with distance
      PASS -- 6.2 Surface inside spotlight cone receives illumination
      PASS -- 6.3 Surface outside spotlight cone receives zero contribution
    TEST 7 -- Flat Shading Variant
      PASS -- 7.1 Triangle face normal is correctly aligned (+Z)
      PASS -- 7.2 Flat shading produces positive illuminated diffuse color
      PASS -- 7.3 Flat shading produces valid color components within range
    TEST 8 -- Gouraud Shading Variant
      PASS -- 8.1 Gouraud shading evaluates vertex V0
      PASS -- 8.2 Gouraud shading evaluates vertex V1
      PASS -- 8.3 Gouraud interpolates midpoint intensity between vertices
    TEST 9 -- Phong Shading Variant
      PASS -- 9.1 Phong shading computes valid non-zero color at centroid
      PASS -- 9.2 Phong interpolated normal preserves realistic lighting
      PASS -- 9.3 Phong and Gouraud yield distinct results on curved surfaces due to per-pixel normals
    TEST 10 -- Deferred Shading Multi-Pass Pipeline
      PASS -- 10.1 Geometry pass marks pixel valid in G-Buffer
      PASS -- 10.2 G-Buffer accurately stores normal and depth values
      PASS -- 10.3 Lighting pass renders lit color for valid pixel and black for unlit pixel
    TEST 11 -- Deferred Shading Depth Overwrite
      PASS -- 11.1 Initial fragment placed in G-Buffer at depth 5.0
      PASS -- 11.2 Closer fragment overwrites distant fragment
      PASS -- 11.3 Farther fragment is culled by depth test
    TEST 12 -- Edge Cases: Degenerate Geometry
      PASS -- 12.1 Degenerate collinear triangle raises Degenerate_Geometry_Error
      PASS -- 12.2 Normalizing zero vector raises Zero_Vector_Error
      PASS -- 12.3 Zero sum barycentric weights raises Invalid_Weights_Error
    TEST 13 -- Invariants & Empty Lights Edge Case
      PASS -- 13.1 Empty light array produces completely black illumination
      PASS -- 13.2 Barycentric normalization preserves partition of unity
      PASS -- 13.3 Reflect vector on pure normal incident inverts direction

    ===  39 passed,  0 failed ===

To remove generated binaries and intermediate compilation objects:

    make clean

## Testing
The test suite in `tests.adb` exercises the API assuming the code is broken until proven otherwise. It covers:
- Functional Correctness: Verifies vector arithmetic, color math, and illumination calculations (Lambertian diffuse + Phong specular).
- Algorithm Variants: Directly exercises Flat shading, Gouraud shading, Phong shading, and Deferred shading passes.
- Lighting & Falloff Models: Validates ambient, directional, point, and conical spotlight illumination, as well as distance falloff functions (None, Linear, Quadratic, Custom Power).
- Depth Culling & Occlusion: Checks G-Buffer depth testing in deferred rendering.
- Edge Cases & Error Handling: Tests degenerate (collinear) polygons, zero-vector normalization, empty light arrays, and invalid barycentric coordinates.
- Invariants: Verifies color saturation bounds [0.0, 1.0] and partition of unity in barycentric coordinates.

## Building
Prerequisites:
- GNAT compiler supporting Ada 2022/Ada 2023 (`gnatmake` / GNAT Pro / FSF GNAT >= 12).
- GNU Make.

To compile the project directly:

    make
