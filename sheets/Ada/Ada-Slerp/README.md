# Slerp: Spherical Linear Interpolation in Ada 2023

## Project Overview
Spherical Linear Interpolation (Slerp) is a mathematical formulation introduced by Ken Shoemake to animate 3D rotations smoothly. Operating on the unit sphere or the 3-sphere of unit quaternions, Slerp produces constant angular velocity along the shortest great-circle arc. This package provides a rigorous, high-assurance implementation of Slerp and its canonical variations in Ada 2023 (ISO/IEC 8652:2023), including Geometric Vector Slerp, Raw Quaternion Slerp, Shortest-Path Slerp, Normalized Linear Interpolation (Nlerp), and Spherical Quadrangle (Squad) cubic splines for C1 continuous orientation trajectories.

## Features
- **Geometric Vector Slerp**: Great-circle arc interpolation for 3D unit direction vectors.
- **Shortest-Path Quaternion Slerp**: Standard SO(3) spherical interpolation with double-cover negation handling.
- **Raw Quaternion Slerp**: Unclamped spherical arc interpolation without antipodal sign inversion.
- **Normalized Linear Interpolation (Nlerp)**: Commutative, computationally efficient linear approximation normalized to unit length.
- **Lie Algebra Operations**: Quaternion logarithm, exponential, and power functions for manifold transitions.
- **Spherical Quadrangle Interpolation (Squad)**: Smooth higher-order orientation splines with continuous first derivatives (C1 continuity).
- **Strong Typing & Ada Contracts**: Subprograms enforce `Pre`, `Post`, and `Global => null` aspects under the strict Ada 2023 standard.
- **Defensive Error Handling**: Automatic fallback for near-collinear vectors to avoid division-by-zero, with named exceptions for antipodal and degenerate inputs.

## Usage
To build and execute the test suite, run:

    make test

Expected output:

    Running tests...
    TEST 1 -- Vector Algebra & Normalization
      PASS -- 1.1 Vector norm calculation
      PASS -- 1.2 Normalized vector has unit norm
      PASS -- 1.3 Normalized components match ratio
    TEST 2 -- Vector Error Handling
      PASS -- 2.1 Zero-vector normalize raises Degenerate_Vector_Error
      PASS -- 2.2 Is_Normalized rejects zero-vector
      PASS -- 2.3 Dot product of orthogonal vectors is zero
    TEST 3 -- Geometric Slerp Endpoints & Midpoint
      PASS -- 3.1 Slerp at t=0 returns P0
      PASS -- 3.2 Slerp at t=1 returns P1
      PASS -- 3.3 Slerp at t=0.5 bisects 90-degree arc
    TEST 4 -- Geometric Slerp Identical & Collinear Vectors
      PASS -- 4.1 Slerp identical vectors returns same vector
      PASS -- 4.2 Slerp identical result is normalized
      PASS -- 4.3 Antipodal vector Slerp raises Invalid_Argument_Error
    TEST 5 -- Quaternion Fundamental Arithmetic
      PASS -- 5.1 Conjugate/Inverse product is Identity
      PASS -- 5.2 Rot_Z90 is normalized
      PASS -- 5.3 Zero quaternion inversion raises exception
    TEST 6 -- Raw Quaternion Slerp
      PASS -- 6.1 Raw Slerp t=0 matches Q0
      PASS -- 6.2 Raw Slerp t=1 matches Q1
      PASS -- 6.3 Raw Slerp t=0.5 produces expected 45-deg rotation
    TEST 7 -- Shortest Path Slerp (Hemisphere Flipping)
      PASS -- 7.1 Dot product is negative
      PASS -- 7.2 Shortest path Slerp stays on acute arc
      PASS -- 7.3 Resulting quaternion is normalized
    TEST 8 -- Nlerp Approximation Properties
      PASS -- 8.1 Nlerp t=0 matches start
      PASS -- 8.2 Nlerp t=1 matches end
      PASS -- 8.3 Nlerp at midpoint closely tracks exact Slerp
    TEST 9 -- Lie Algebra Mappings (Log / Exp / Power)
      PASS -- 9.1 Log pure vector part w=0
      PASS -- 9.2 Exp(Log(Q)) restores Q
      PASS -- 9.3 Q^0.5 produces half-angle rotation
    TEST 10 -- Squad Intermediate Point Construction
      PASS -- 10.1 Squad control point is normalized
      PASS -- 10.2 Control point W component is positive
      PASS -- 10.3 Control point rotation axis is along Z
    TEST 11 -- Squad Spline Interpolation
      PASS -- 11.1 Squad at t=0 hits starting quaternion
      PASS -- 11.2 Squad at t=1 hits ending quaternion
      PASS -- 11.3 Squad intermediate point is normalized
    TEST 12 -- Constant Angular Velocity Invariant
      PASS -- 12.1 Equal arc step 0->1 equals 1->2
      PASS -- 12.2 Equal arc step 1->2 equals 2->3
      PASS -- 12.3 All interpolated quaternions remain normalized
    TEST 13 -- Multi-Axis Orientation Interpolation
      PASS -- 13.1 Multi-axis Slerp result is normalized
      PASS -- 13.2 Multi-axis Nlerp result is normalized
      PASS -- 13.3 Slerp and Nlerp maintain positive real component

    ===  39 passed,  0 failed ===

## Testing
The test harness (`tests.adb`) validates the package against key verification criteria:
1. **Functional Correctness**: Ensures intermediate rotations bisect expected angle arcs and preserve identity boundaries at t=0 and t=1.
2. **Edge Cases**: Asserts stability for zero-magnitude inputs, antipodal configurations, and identical vectors.
3. **Double-Cover Invariance**: Verifies that quaternions q and -q yield the identical rotational trajectory under shortest-path algorithms.
4. **Lie Algebra & Squad Smoothness**: Confirms circular invertibility between Exp and Log, validating proper continuity for cubic spline nodes.
5. **Physical Invariants**: Evaluates constant angular velocity along interpolation steps, ensuring equal angles for equal increments of parameter t.

## Building
- **Language**: Ada 2023 (ISO/IEC 8652:2023)
- **Compiler**: GNAT (GCC 13+ or GNAT Pro supporting `-gnat2022` / `-gnat2023`)
- **Flags**: `-gnatwa -gnat2022` (compiles cleanly with zero warnings)
