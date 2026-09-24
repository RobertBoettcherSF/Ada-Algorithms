# Phong Shading in Ada 2023

## Project Overview
Phong shading is an interpolation technique in 3D computer graphics that computes surface illumination on a per-pixel level by interpolating normal vectors across polygonal surfaces. First introduced by Bui Tuong Phong in 1975, this approach produces smooth specular highlights and eliminates the faceted appearance characteristic of Gouraud shading. This package provides an ISO/IEC 8652:2023 Ada implementation featuring normal interpolation across triangular faces, the classic Phong reflection model, and the Jim Blinn half-vector optimization (Blinn-Phong) across point and directional light sources.

## Features
* **Barycentric Normal Interpolation**: Per-fragment normal calculation interpolating vertex normals with partition-of-unity contract checks.
* **Classic Phong Illumination**: Evaluates ambient, Lambertian diffuse, and empirical specular reflection based on the reflection vector: `R = 2(N · L)N - L`.
* **Blinn-Phong Illumination**: Evaluates specular reflection using the halfway vector: `H = (L + V) / ||L + V||`, lowering computational overhead and preventing backward lobe artifacts.
* **Point and Directional Lights**: Point light evaluation with quadratic distance attenuation (`1 / (k_c + k_l * d + k_q * d^2)`) as well as non-attenuating directional lights.
* **Strongly Typed Linear Algebra & Color Safety**: Domain-specific types for vectors, unit normals, coordinates, shininess exponents, and color modulation with automatic saturation clamping in `[0.0, 1.0]`.
* **Ada 2023 Verification Contracts**: Subprograms leverage `Pre`, `Post`, and `Global => null` contract aspects.

## Usage
Run the test suite using `make`:

```bash
make test
```

Expected output:
```text
Running tests...
TEST 1 — Vector Fundamentals and Normalization
  PASS — 1.1 Vector norm calculation
  PASS — 1.2 Normalization yields unit length
  PASS — 1.3 Dot product of orthogonal vectors is zero
  PASS — 1.4 Cross product basis correctness
TEST 2 — Reflection Vector Geometry
  PASS — 2.1 45-degree reflection angle X symmetry
  PASS — 2.2 45-degree reflection angle Y symmetry
  PASS — 2.3 Direct normal reflection matches incoming vector
TEST 3 — Halfway Vector for Blinn-Phong
  PASS — 3.1 Symmetrical vectors produce purely vertical halfway vector
  PASS — 3.2 Halfway vector vertical component is 1.0
  PASS — 3.3 Halfway vector has unit length
TEST 4 — Barycentric Normal Interpolation
  PASS — 4.1 Pure vertex normal matches exactly
  PASS — 4.2 Normal length after interpolation is normalized
  PASS — 4.3 Midpoint normal has equal components
TEST 5 — Color Space Operations and Clamping
  PASS — 5.1 Addition clamps red channel at 1.0
  PASS — 5.2 Modulation computes channel-wise product
  PASS — 5.3 Scaling scales channel intensity correctly
TEST 6 — Distance Attenuation Formulation
  PASS — 6.1 Constant attenuation gives unity factor
  PASS — 6.2 Quadratic attenuation matches inverse polynomial
  PASS — 6.3 Attenuation at distance 0 is 1.0
TEST 7 — Classic Phong Point Light Illumination
  PASS — 7.1 Frontal lighting emits non-zero red intensity
  PASS — 7.2 Color channels remain balanced for white source
  PASS — 7.3 Maximum channel does not overflow 1.0
TEST 8 — Back-Face and Shadow Illumination
  PASS — 8.1 Light from behind produces zero diffuse component
  PASS — 8.2 Green channel equals pure ambient term
  PASS — 8.3 Blue channel equals pure ambient term
TEST 9 — Blinn-Phong Point Light Specular Peak
  PASS — 9.1 Blinn-Phong produces valid illuminated range
  PASS — 9.2 Blinn-Phong and Classic Phong are both bright on specular peak
  PASS — 9.3 Channel balance holds for Blinn-Phong with white light
TEST 10 — Classic Phong Directional Light
  PASS — 10.1 Directional light colors red channel strongly
  PASS — 10.2 Directional light green channel higher than blue
  PASS — 10.3 Attenuation is infinite (no distance decay)
TEST 11 — Blinn-Phong Directional Light
  PASS — 11.1 Blinn-Phong directional calculates non-zero response
  PASS — 11.2 Preserves input color hue predominance
  PASS — 11.3 Ambient floor is preserved
TEST 12 — Error Handling for Degenerate Inputs
  PASS — 12.1 Zero vector normalization raises Zero_Vector_Error
  PASS — 12.2 Non-unitary barycentric coords raise Invalid_Barycentric_Coord
  PASS — 12.3 Opposing normal cancellation raises Degenerate_Normal_Error
TEST 13 — Material Shininess Invariant
  PASS — 13.1 Broader specular lobe yields higher off-axis intensity
  PASS — 13.2 Narrow specular lobe preserves non-negative color
  PASS — 13.3 Diffuse contributions remain invariant across shininess shifts

===  40 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` covers:
* **Functional Correctness**: Validates physical geometry laws (reflection angle symmetry, halfway vector direction, cross products, dot products).
* **Illumination Invariants**: Verifies that back-facing lights drop diffuse and specular components, channel clipping prevents color overflow, and higher shininess exponents tighten highlight lobes.
* **Edge Cases & Error Handling**: Verifies that degenerate barycentric weights, zero-length vectors, and opposed canceling vertex normals raise expected named exceptions (`Zero_Vector_Error`, `Invalid_Barycentric_Coord`, `Degenerate_Normal_Error`).

## Building
* **Prerequisites**: GNAT compiler supporting Ada 2022/2023 (`gnat`, `gnatmake`, or `gprbuild`).
* **Standard**: ISO/IEC 8652:2023 (Ada 2023).
* **Compilation Flags**: Clean build under `-gnatwa -gnat2022`.
