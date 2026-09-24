# Grade 5 Mathematics Algorithms (Ada 2023)

Project Overview:
This project implements the foundational mathematical algorithms prescribed by the Bavarian Gymnasium Grade 5 Mathematics curriculum (LehrplanPLUS). The codebase features computationally safe, strictly-typed Ada 2023 implementations of core topics, including dynamic routing to various mathematical variants: rounding of large numbers across place values, area and perimeter calculations for planar rectangles, surface area and volume computation for cuboids, and sequential time unit decomposition.

Features:
* Rounding (Variant 1): Dynamically maps arbitrary 64-bit bounds to place values (Tens through Millions) using half-up arithmetic rules while checking for upper-limit overflows.
* 2D Geometry (Variants 2-3): Resolves perimeter and area, statically guaranteeing mathematical safety by mapping bounds to constrained physical subtypes.
* 3D Geometry (Variants 4-5): Processes 3-axis boundaries to return precise surface area and volumetric data.
* Strict Constraints (Variant 6): Preemptive edge-case validation ensuring dynamically strictly positive geometries.
* Time Decomposition (Variant 7): Safe reduction algorithms parsing raw seconds into normalized day/hour/minute arrays.

Usage:
Compile and execute the self-documenting test suite using the provided Makefile. The build mechanism directs compilation via GNAT into standard executable bin locations. No user interaction is required; the output streams the results of all variant operations.
Expected output:
$ make test
Running tests...
TEST 1 — Rounding (Tens)
  PASS — 1.1 Round down
  PASS — 1.2 Round half up
  PASS — 1.3 Round up
... [39 total assertions] ...
===  39 passed,  0 failed ===

Testing:
The self-contained `tests.adb` test suite thoroughly validates every unit. Functional correctness proves exact logic behavior (e.g., standard formulas); edge cases demonstrate zero bounds calculations; invariant boundaries show maximum bounds retention; error handling proves standard overflow and invalid dynamic configurations are accurately tracked and intercepted. This demonstrates complete functional validation under Ada's stringent environment.

Building:
Prerequisites: A GNAT compiler supporting Ada 2022/2023 (GNAT FSF or GNAT Pro).
Build Command: `make` (compiles and links via the enclosed GPR file).
Test Command: `make test` (builds and executes).
Clean Command: `make clean` (purges generated artifacts).
