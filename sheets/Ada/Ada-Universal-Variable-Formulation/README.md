# Universal Variable Formulation in Ada 2023

## Project Overview
The Universal Variable Formulation is a unified mathematical framework in astrodynamics used to solve the two-body Kepler problem across all orbital regimes—elliptic (e < 1), parabolic (e = 1), and hyperbolic (e > 1)—without branch switching, coordinate singularities, or numerical instability near parabolic boundaries. Central to this approach are Stumpff functions c_k(z) and the universal anomaly chi, which generalize Kepler's equation and time-of-flight formulations through Gauss f and g Lagrange coefficients. This project provides a pure, zero-warning Ada 2023 (ISO/IEC 8652:2023) implementation encompassing vector kinematics, Stumpff transcendental evaluation, universal orbit propagation, and the universal Lambert boundary-value problem solver.

## Features
- Unified Conic Handling: Continuous propagation of position and velocity vectors across circular, elliptic, parabolic, and hyperbolic trajectories using a single algorithm.
- Stumpff Functions (c_0 through c_5): Accurate evaluation combining stable Taylor series expansions for |z| < 0.1 and exact trigonometric/hyperbolic closed-form expressions for larger values.
- Universal Kepler Solver: High-precision Newton-Raphson iteration solving for universal anomaly chi, with domain-specific starting estimates across orbit regimes.
- Gauss f and g Invariant Propagation: Exact state propagation with full preservation of specific mechanical energy and angular momentum.
- Universal Lambert Boundary Solver: Solves the orbit determination problem (finding velocity vectors v_1 and v_2 given r_1, r_2, and Delta t) for both prograde and retrograde orbital transfers.
- Strong Typing & Safety: Domain-specific types for distance, velocity, gravitational parameters, and universal anomaly, annotated with Ada contracts (Pre, Post, Global).

## Building
- Prerequisites: GNAT supporting Ada 2022/2023 (e.g., GNAT FSF 13+, GNAT Community 2021+, or Alire gnat_native).
- Compilation:
```bash
make
```
The compiler flags `-gnatwa -gnat2022` ensure clean compilation without any warnings.

## Usage
Run the standalone test suite:
```bash
make test
```

Expected output:
```text
Running tests...
=== Universal Variable Formulation Test Suite ===

TEST 1 -- 3D Vector Operations
  PASS -- 1.1 Vector addition and scalar scaling
  PASS -- 1.2 Dot product calculation (1*4 + 2*(-5) + 3*6 = 12)
  PASS -- 1.3 Cross product and magnitude calculation
TEST 2 -- Stumpff Functions: Near Zero (Parabolic Limit)
  PASS -- 2.1 c_0(0) = 1.0 and c_1(0) = 1.0
  PASS -- 2.2 c_2(0) = 1/2 = 0.5
  PASS -- 2.3 c_3(0) = 1/6
TEST 3 -- Stumpff Functions: Positive z (Elliptic Regime)
  PASS -- 3.1 c_0(0.25) matches cos(sqrt(z))
  PASS -- 3.2 c_1(0.25) matches sin(sqrt(z))/sqrt(z)
  PASS -- 3.3 c_2(0.25) and c_3(0.25) match analytic trigonometric formulas
TEST 4 -- Stumpff Functions: Negative z (Hyperbolic Regime)
  PASS -- 4.1 c_0(-0.25) matches cosh(sqrt(-z))
  PASS -- 4.2 c_1(-0.25) matches sinh(sqrt(-z))/sqrt(-z)
  PASS -- 4.3 c_2(-0.25) and c_3(-0.25) match analytic hyperbolic formulas
TEST 5 -- Higher-Order Stumpff Functions (c_4 and c_5)
  PASS -- 5.1 Identity z * c_4(z) + c_2(z) = 1/2
  PASS -- 5.2 Identity z * c_5(z) + c_3(z) = 1/6
  PASS -- 5.3 Continuity of higher orders at z = 0.05
TEST 6 -- Orbit Classification & Specific Mechanical Energy
  PASS -- 6.1 Energy of elliptic orbit is negative
  PASS -- 6.2 Energy of hyperbolic orbit is positive
  PASS -- 6.3 Escape velocity yields parabolic orbit type
TEST 7 -- Circular LEO Propagation Over One Full Orbit
  PASS -- 7.1 State returns to initial position after full period
  PASS -- 7.2 State returns to initial velocity after full period
  PASS -- 7.3 Energy is strictly conserved throughout full period
TEST 8 -- Half-Period Circular Orbit Propagation
  PASS -- 8.1 Position is inverted at pi radians (X approx -7000)
  PASS -- 8.2 Velocity is inverted at pi radians (Vy approx -V_circ)
  PASS -- 8.3 Orbital radius magnitude is unchanged
TEST 9 -- Hyperbolic Orbit Propagation
  PASS -- 9.1 Orbit remains hyperbolic at future epoch
  PASS -- 9.2 Specific energy conserved along hyperbolic arc
  PASS -- 9.3 Distance monotonically increases after periapsis outbound
TEST 10 -- Time Reversibility Invariant
  PASS -- 10.1 Position recovered after forward-backward cycle
  PASS -- 10.2 Velocity recovered after forward-backward cycle
  PASS -- 10.3 Angular momentum vector conserved across steps
TEST 11 -- Propagate_State Record Wrapper
  PASS -- 11.1 Advanced position is distinct from start
  PASS -- 11.2 State wrapper preserves energy
  PASS -- 11.3 State wrapper invertibility via negative step
TEST 12 -- Universal Lambert Problem Solution
  PASS -- 12.1 Computed initial velocity V1 has prograde trajectory (Vy > 0)
  PASS -- 12.2 Propagated position from V1 matches target R2 within tolerance
  PASS -- 12.3 Propagated velocity at t2 matches Lambert terminal velocity V2
TEST 13 -- Error Handling and Singularities
  PASS -- 13.1 Specific_Mechanical_Energy raises Invalid_State on zero R
  PASS -- 13.2 Lambert raises Singularity_Error for collinear 180 deg geometry
  PASS -- 13.3 Propagating for Dt = 0.0 returns unchanged state without error

=== 39 passed, 0 failed ===
```

## Testing
The test executable tests.adb validates 13 distinct verification criteria across four primary disciplines:
1. Functional Correctness: Exact series matching for Stumpff transcendental functions, Kepler equation convergence, and energy/angular momentum invariants.
2. Dynamic Invariants: Closed-loop orbital period verification, coordinate inversion at pi radians, and time reversibility (t -> t + Delta t -> t).
3. Boundary Value Solvers: Universal Lambert orbital transfers verified by forward numerical propagation of computed initial velocities to match target terminal coordinates.
4. Defensive Programming & Edge Cases: Proper raising of Invalid_State, Singularity_Error, and Convergence_Error on physical singularities (zero radius, collinear transfer planes, vanishing derivatives).
