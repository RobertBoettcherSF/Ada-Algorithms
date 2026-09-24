# Radiosity (3D Computer Graphics Global Illumination) in Ada 2023

## Project Overview
Radiosity is a finite-element global illumination algorithm that computes view-independent diffuse interreflections of light within a 3D scene. Unlike stochastic path tracing, standard radiosity accounts for diffuse light paths (represented as LD*E) by dividing surfaces into planar patches and solving the discrete rendering equation: B_i = E_i + rho_i * Sum_j(F_ij * B_j), where B_i is radiosity (radiant flux density), E_i is intrinsic emission, rho_i is surface reflectance (albedo), and F_ij is the geometric view/form factor. This Ada 2023 implementation provides the classical formulation alongside every major algorithmic variation described in the literature: direct matrix inversion, synchronous Jacobi gathering, asynchronous Gauss-Seidel gathering, progressive refinement (shooting radiosity), and single-bounce direct lighting.

## Features
- Strong Domain Typing: Specialized scalar types for Flux_Density (W/m^2), Reflectance, Form_Factor, Real, and 3D spatial vectors, rejecting raw, untyped floats.
- Ada Contract Aspects: Robust Pre and Post conditions ensuring geometric non-degeneracy, normalization invariants, matrix dimensions, and conservation constraints.
- Direct Matrix Inversion: Infinite-bounce solution via Gaussian elimination with partial row pivoting solving (I - rho * F) * B = E.
- Classical Jacobi Gathering: Synchronous iteration sweeps computing simultaneous multi-bounce light propagation.
- Gauss-Seidel Gathering: In-place iterative solver utilizing newly calculated radiosities immediately, accelerating convergence.
- Progressive Refinement (Shooting Radiosity): Energy-priority solver iteratively dispatching unshot radiant power from the brightest surface patch, enabling intermediate preview states and reciprocity-based redistribution.
- Single-Bounce Mode: Low-overhead direct illumination approximation evaluating first-order reflections only.
- Differential Form Factor Evaluator: Closed-form analytic point-to-point view factor computation considering mutual orientation, distance decay, and visibility culling.
- Power and Conservation Metrics: Total emitted and total scene power calculation utilities to verify radiative equilibrium.
- Zero Warnings: Conforms strictly to Ada 2023 standard (-gnat2022/-gnat2023) and compiles warning-free under -gnatwa.

## Usage
Build and run the standalone test suite and usage demonstration via the provided Makefile:

    make test

### Expected Output
    TEST 1 -- Vector Algebra and Normalization Mechanics
      PASS -- 1.1 Magnitude of (3,4,0) is 5.0
      PASS -- 1.2 Normalized vector has unit length
      PASS -- 1.3 Dot product of orthogonal vectors is zero
      PASS -- 1.4 Vector addition gives component sum
    TEST 2 -- Differential Form Factor Calculation
      PASS -- 2.1 Directly opposing form factor matches theoretical 1/(4*pi)
      PASS -- 2.2 Back-facing surface yields zero form factor
      PASS -- 2.3 Coincident points return zero form factor
    TEST 3 -- Scene Validation and Invariants
      PASS -- 3.1 Well-formed scene is recognized as valid
      PASS -- 3.2 Scene containing unnormalized normal is rejected
      PASS -- 3.3 Empty scene fails validation
    TEST 4 -- Scene Form Factor Matrix Assembly
      PASS -- 4.1 Diagonal self-view form factor is zero (planar patch)
      PASS -- 4.2 Symmetric mutual exchange between identical patches
      PASS -- 4.3 Form factor magnitude is physically positive and strictly bounded below 1
    TEST 5 -- Direct Matrix Inversion Solver
      PASS -- 5.1 Emitter radiosity exceeds initial emission due to back-reflections
      PASS -- 5.2 Passive receiver develops positive secondary radiosity
      PASS -- 5.3 Radiosity ratio closely matches albedo * form factor
    TEST 6 -- Jacobi Gathering Iterative Solver
      PASS -- 6.1 Jacobi terminates within iteration budget
      PASS -- 6.2 Jacobi patch 1 matches direct matrix solution
      PASS -- 6.3 Jacobi patch 2 matches direct matrix solution
    TEST 7 -- Gauss-Seidel Accelerated Iterative Solver
      PASS -- 7.1 Gauss-Seidel converges within limits
      PASS -- 7.2 Gauss-Seidel requires no more iterations than synchronous Jacobi
      PASS -- 7.3 Gauss-Seidel radiosity agrees with direct solver
    TEST 8 -- Progressive Refinement / Shooting Variant
      PASS -- 8.1 Progressive shooting executes successfully
      PASS -- 8.2 Shooting solver converges near analytical emitter solution
      PASS -- 8.3 Shooting solver converges near analytical receiver solution
    TEST 9 -- Single-Bounce Approximation
      PASS -- 9.1 Emitter single-bounce retains initial self-emission
      PASS -- 9.2 Passive receiver receives exactly rho * F * E1
      PASS -- 9.3 Single-bounce is strictly less than full infinite-bounce radiosity
    TEST 10 -- Three-Patch Room Enclosure
      PASS -- 10.1 Floor receives energy from ceiling luminaire
      PASS -- 10.2 Reflector wall receives energy from scene
      PASS -- 10.3 Direct and iterative solvers agree on multi-patch configuration
    TEST 11 -- Energy Conservation and Monotonicity
      PASS -- 11.1 Emitted power matches Area * Emission (2.0 * 50 = 100 W)
      PASS -- 11.2 Total leaving flux density exceeds pure initial emission due to interreflection
      PASS -- 11.3 Individual patch radiosities are strictly positive
    TEST 12 -- Zero Reflectance Blackbody Surfaces
      PASS -- 12.1 Blackbody emitter radiosity equals its self-emission
      PASS -- 12.2 Blackbody receiver radiosity remains exactly zero
      PASS -- 12.3 Single bounce matches full solution for blackbody surfaces
    TEST 13 -- Error Handling and Preconditions
      PASS -- 13.1 Normalize (0,0,0) raises Invalid_Patch_Error
      PASS -- 13.2 Isolated single planar patch retains exact self-emission
      PASS -- 13.3 Unit albedo patch is accepted by Is_Valid_Patch
    TEST 14 -- Progressive Shooting Monotonicity
      PASS -- 14.1 Step limit 1 executes exactly 1 step
      PASS -- 14.2 Receiver radiosity increases monotonically from step 1 to step 5
      PASS -- 14.3 Total scene energy grows monotonically with iterations towards steady state

    ===  45 passed,  0 failed ===

## Testing
The test suite tests.adb validates 14 test groups containing 45 distinct assertions across several critical categories:
1. Geometric and Vector Correctness: Validates vector norm, normalization, dot products, and orthogonalities.
2. Differential Form Factor Accuracy: Validates orientation handling, back-face culling, collinear singularity avoidance, and numerical adherence to the theoretical differential area integral (1 / (4 * pi)).
3. Scene Verification and Boundary Contracts: Validates normal unit-length enforcement, patch area positivity, and albedo boundaries.
4. Matrix Inversion Equivalence: Asserts that direct linear Gaussian solving produces physically consistent interreflection amplification.
5. Numerical Convergence of Solvers: Verifies that Jacobi gathering, Gauss-Seidel gathering, and Progressive Shooting all converge to the direct matrix inversion solution within specified tolerance thresholds.
6. Energy Conservation and Boundary Regimes: Tests blackbody (zero reflectance) absorption limits and monotonic energy accumulation during iterative shooting steps.
7. Error Handling: Verifies appropriate exception raising when encountering degenerate data like zero vectors or ill-formed scenes.

## Building
- Prerequisites: GNAT compiler supporting Ada 2022/2023 (such as GNAT FSF 12, 13, 14, or GNAT Pro).
- Standard: ISO/IEC 8652:2023 (Ada 2023).
- Build command: make (or gnatmake -gnatwa -gnat2022 -Pradiosity.gpr).
