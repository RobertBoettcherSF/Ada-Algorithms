# Orbital Mechanics in Ada 2023

## Project Overview
This project provides a robust, strongly-typed implementation of fundamental two-body orbital mechanics in Ada 2023 (ISO/IEC 8652:2023), modeled after the principles described in the Wikipedia entry for Orbital Mechanics. The implementation encompasses the foundational formulations governing Keplerian motion, including the Vis-Viva equation for all conic trajectory regimes (elliptic, parabolic, hyperbolic), Kepler's Third Law and its harmonic inversions, specific mechanical energy and momentum conservation, and iterative numerical solvers for both elliptic and hyperbolic formulations of Kepler's Equation using Newton-Raphson iteration.

## Features
* Strong typing eliminating raw primitives: domain types for `Distance`, `Speed`, `Gravitational_Parameter`, `Eccentricity`, `Time_Seconds`, and `Radians`.
* Subtype categorization enforcing physical validity at compile- and run-time (`Elliptic_Eccentricity`, `Hyperbolic_Eccentricity`, `Positive_Distance`, `Positive_Time`).
* Ada contract aspects (`Pre`, `Post`) guarding mathematical domain constraints.
* Orbital velocity formulations:
  * General Vis-Viva Equation: `v^2 = mu * (2/r - 1/a)`
  * Circular velocity: `v_c = sqrt(mu / r)`
  * Escape velocity: `v_esc = sqrt(2 * mu / r)`
  * Hyperbolic excess velocity: `v_inf = sqrt(-mu / a)`
* Kepler's Third Law (Harmonic Law):
  * Period calculation from semi-major axis
  * Inverted calculation: semi-major axis from orbital period
  * Mean motion (angular frequency) computation
* Specific orbital invariants:
  * Specific orbital energy (vis-viva conservation)
  * Specific relative angular momentum: `h = sqrt(p * mu)`
  * Semi-latus rectum computation
* Apsidal geometry (periapsis and apoapsis calculations).
* Kepler's Equation solvers:
  * Elliptic solver for `M = E - e * sin(E)`
  * Hyperbolic solver for `M_h = e * sinh(H) - H`
  * True anomaly derivation from eccentric anomaly
  * Radial distance evaluation as a function of true anomaly
* Coplanar two-impulse Hohmann transfer orbit analyzer (Delta-V budgets and transfer time of flight).

## Usage
Run the test suite using the standard Makefile target:

```bash
make test
```

Expected output:

```text
Running tests...
============================================================
           ORBITAL MECHANICS TEST SUITE                     
============================================================
TEST 1 -- Circular Orbital Velocity
  PASS -- 1.1 LEO circular velocity near 7672 m/s
  PASS -- 1.2 GEO circular velocity near 3075 m/s
  PASS -- 1.3 LEO velocity is strictly higher than GEO velocity
TEST 2 -- Escape Velocity
  PASS -- 2.1 Earth surface escape speed is approx 11186 m/s
  PASS -- 2.2 Exact sqrt(2) ratio with circular speed
  PASS -- 2.3 Escape velocity decreases with higher altitude
TEST 3 -- General Vis-Viva Equation
  PASS -- 3.1 Vis-Viva circular match when 1/a = 1/r
  PASS -- 3.2 Parabolic velocity matches escape velocity
  PASS -- 3.3 Hierarchy: v_circ < v_elliptic_apogee_transfer < v_esc
TEST 4 -- Kepler's Third Law (Harmonic Law)
  PASS -- 4.1 LEO period is roughly 92.5 minutes (5555 s)
  PASS -- 4.2 GEO period equals one sidereal day (approx 86164 s)
  PASS -- 4.3 Mean motion relation n = 2*pi / T
TEST 5 -- Inversion: Semi-Major Axis from Period
  PASS -- 5.1 Calculated GEO semi-major axis is 42,164 km
  PASS -- 5.2 Period-to-Axis-to-Period round-trip consistency
  PASS -- 5.3 Monotonicity: longer period gives strictly larger semi-major axis
TEST 6 -- Specific Mechanical Energy
  PASS -- 6.1 Bound circular orbit energy matches -mu / (2*a)
  PASS -- 6.2 Parabolic escape energy is zero
  PASS -- 6.3 Hyperbolic orbit has positive energy
TEST 7 -- Apsidal Geometry
  PASS -- 7.1 Periapsis rp = a*(1-e) is 8,000,000 m
  PASS -- 7.2 Apoapsis ra = a*(1+e) is 12,000,000 m
  PASS -- 7.3 Average of rp and ra equals semi-major axis
  PASS -- 7.4 Semi-latus rectum p = a*(1 - e^2) = 9,600,000 m
TEST 8 -- Kepler Solver (Elliptic Orbit)
  PASS -- 8.1 Solver satisfies Kepler equation M = E - e*sin(E)
  PASS -- 8.2 Zero mean anomaly produces zero eccentric anomaly
  PASS -- 8.3 Pi anomaly symmetry: M = pi yields E = pi
TEST 9 -- Kepler Solver (Hyperbolic Orbit)
  PASS -- 9.1 Hyperbolic Kepler residual e*sinh(H) - H - M = 0
  PASS -- 9.2 Hyperbolic excess speed sqrt(-mu/a) evaluates correctly
  PASS -- 9.3 H has same sign as M
TEST 10 -- True Anomaly and Radial Position
  PASS -- 10.1 E = 0 corresponds to true anomaly nu = 0
  PASS -- 10.2 Radius at nu = 0 is periapsis distance
  PASS -- 10.3 Radius at nu = pi is apoapsis distance
TEST 11 -- Hohmann Transfer (LEO to GEO)
  PASS -- 11.1 First burn Delta V_1 near 2425 m/s
  PASS -- 11.2 Second burn Delta V_2 near 1466 m/s
  PASS -- 11.3 Total Delta V near 3891 m/s
  PASS -- 11.4 Time of flight is approx 5.27 hours (18990 s)
TEST 12 -- Specific Angular Momentum Invariant
  PASS -- 12.1 Angular momentum h = sqrt(p*mu) matches r_p * v_p
  PASS -- 12.2 Periapsis and Apoapsis angular momentum are identical (conservation)
  PASS -- 12.3 Speed at periapsis is strictly higher than at apoapsis
TEST 13 -- Edge Cases and Robustness
  PASS -- 13.1 Singularity_Error correctly raised on negative kinetic energy
  PASS -- 13.2 Eccentricity = 0 yields rp == ra == a
  PASS -- 13.3 Eccentricity = 1.0 yields periapsis rp = 0 for collision path

===  42 passed,  0 failed ===
```

## Testing
The test suite in `tests.adb` executes 13 distinct test scenarios containing 42 discrete assertions:
* **Functional Correctness:** Asserts numerical accuracy of vis-viva equations, escape speeds, and orbital periods against established values for LEO and GEO regimes.
* **Conservation Laws:** Validates that total specific orbital energy matches theoretical values for bound, parabolic, and hyperbolic orbits, and confirms angular momentum conservation across periapsis and apoapsis.
* **Iterative Convergence:** Exercises Newton-Raphson solvers across both elliptic and hyperbolic regimes, confirming that substituted roots solve Kepler's equation to within numerical tolerances.
* **Edge Cases & Invariants:** Verifies behavior at circular eccentricity bounds (`e = 0.0`), collision trajectories (`e = 1.0`), and guarantees `Singularity_Error` triggers when orbital parameters violate energy constraints.

## Building
* **Compiler Requirements:** GNAT supporting Ada 2022 / Ada 2023 (`-gnat2022` or `-gnat2023`).
* **Flags:** Zero warnings under `-gnatwa`.
* **Clean Artifacts:** Run `make clean` to remove build directories (`obj/` and `bin/`).
