# Image-Based Lighting (IBL) in Ada 2023

## Project Overview
Image-Based Lighting (IBL) is an advanced rendering technique where omnidirectional photographic or synthetic environment maps serve as surrounding light sources for virtual 3D objects. This package provides an Ada 2023 (ISO/IEC 8652:2023) implementation of the standard lighting algorithms detailed in optical rendering literature and the Wikipedia article on Image-Based Lighting. The package implements mirror specular reflection, diffuse cosine-weighted hemisphere convolution, real-time irradiance estimation via 9-coefficient order-2 Spherical Harmonics (Ramamoorthi-Hanrahan model), and the modern split-sum Cook-Torrance/GGX approximation used in physically based rendering (PBR) pipelines.

## Features
- Strongly Typed Geometric and Color Primitives: Dedicated types for vectors, spherical coordinates, equirectangular matrices, and linear RGB photometric radiances.
- Contract-Based Subprogram Signatures: Rigorous Pre and Post contract aspects ensuring unit vector invariants, positive angular intervals, and valid array dimensions.
- Variant 1 — Mirror Reflection Mapping: Evaluates reflected view rays R = V - 2(V.N)N on latitude-longitude environment maps.
- Variant 2 — Diffuse Hemisphere Convolution: Numerically integrates cosine-weighted hemispherical irradiance E(N) = Integral (L(w) max(N.w, 0) dw).
- Variant 3 — Spherical Harmonics (Order 2, 9 Coefficients): Fast projection of 360-degree environment radiance into orthogonal SH basis functions, coupled with the closed-form analytic convolution formula for diffuse ambient light.
- Variant 4 — Split-Sum PBR Specular Approximation:
  - Importance-sampled GGX pre-filtered environment mapping using low-discrepancy 2D Hammersley sequences.
  - Precomputed 2D Bidirectional Reflectance Distribution Function (BRDF) integration Look-Up Table (LUT).
  - Integration of Fresnel-Schlick terms with scale-bias factors and pre-filtered color.
- Robust Error Handling: Explicit domain validation preventing division by zero on degenerate vectors and handling boundary constraints gracefully.

## Usage
The standalone test executable doubles as both an automated regression suite and an API usage demonstration.

```bash
# Build test suite
make

# Run tests
make test

# Clean artifacts
make clean
```

### Expected Output

```text
Running tests...
TEST 1 — Vector Arithmetic and Normalization
  PASS — 1.1 Vector magnitude calculation is accurate
  PASS — 1.2 Normalized vector has unit length
  PASS — 1.3 Orthogonal dot product evaluates to 0.0
TEST 2 — Normalization Zero-Length Vector Error Handling
  PASS — 2.1 Invalid_Direction_Error trapped for zero vector
  PASS — 2.2 Trapped state verified true
  PASS — 2.3 Normal vector length constraint respected
TEST 3 — Direction to Spherical Coordinate Round-trip
  PASS — 3.1 Theta angle within [0, Pi]
  PASS — 3.2 Phi azimuth within [0, 2*Pi]
  PASS — 3.3 Direction round-trip preserves orientation
TEST 4 — Equirectangular Texture Sampling
  PASS — 4.1 North pole samples top row (Row 1)
  PASS — 4.2 South pole samples bottom row (Row 2)
  PASS — 4.3 Sample colors are non-negative
TEST 5 — Mirror Reflection Mapping
  PASS — 5.1 Evaluated color red channel in range
  PASS — 5.2 Evaluated color green channel in range
  PASS — 5.3 Evaluated color blue channel in range
TEST 6 — Mirror Reflection Perpendicular Ray
  PASS — 6.1 Reflected ray goes straight down
  PASS — 6.2 Green channel matches direct bottom sample
  PASS — 6.3 Blue channel matches direct bottom sample
TEST 7 — Diffuse Hemisphere Irradiance Convolution
  PASS — 7.1 White environment produces positive irradiance
  PASS — 7.2 Diffuse convolution balances R and G
  PASS — 7.3 Diffuse convolution balances G and B
TEST 8 — Spherical Harmonics Projection
  PASS — 8.1 Order-0 L0,0 coefficient is strictly positive
  PASS — 8.2 Order-0 coefficient exhibits equal RGB in white env
  PASS — 8.3 Higher order odd bands near zero for isotropic lighting
TEST 9 — Spherical Harmonics Reconstruction
  PASS — 9.1 Reconstructed SH irradiance is non-zero
  PASS — 9.2 Reconstructed SH channels are roughly balanced
  PASS — 9.3 Irradiance clamp ensures non-negative values
TEST 10 — Split-Sum Pre-filtered Specular
  PASS — 10.1 Roughness 0 defaults to direct sample
  PASS — 10.2 Rough sample produces valid color values
  PASS — 10.3 Pre-filtering converges without NaN or negative values
TEST 11 — Precomputed BRDF Look-Up Table
  PASS — 11.1 LUT dimensions correctly set
  PASS — 11.2 BRDF Scale value is non-negative
  PASS — 11.3 BRDF Scale + Bias bounded by physical range
TEST 12 — Split-Sum Specular Combination
  PASS — 12.1 Specular combination scales with F0 Red
  PASS — 12.2 Specular combination scales with F0 Green
  PASS — 12.3 Specular combination scales with F0 Blue
TEST 13 — Boundary Invariants and Clamping
  PASS — 13.1 Negative red component clamped to 0.0
  PASS — 13.2 Positive green component preserved
  PASS — 13.3 Negative blue component clamped to 0.0
  PASS — 13.4 Zero color remains 0.0

===  42 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` covers:
- Functional Correctness: Mathematical precision of spherical-to-Cartesian mappings, Snell's reflection law, and Fresnel-Schlick combination formulas.
- Edge Cases: Near-degenerate vectors, grazing view angles, pole discontinuities, zero-roughness inputs, and bounds checking on lookup matrices.
- Error Handling: Exception raising on degenerate normalization operations.
- Invariants: Energy conservation invariants on BRDF integrals, non-negativity of radiance clamp routines, and isotropic balance in uniform environments.

## Building
- Prerequisites: GNAT compiler supporting Ada 2022 / Ada 2023 (e.g., GNAT FSF 13+, GNAT 14+, or GNAT Pro).
- Standard: ISO/IEC 8652:2023.
- Build Flag: `-gnatwa -gnat2022` with zero compiler warnings.
