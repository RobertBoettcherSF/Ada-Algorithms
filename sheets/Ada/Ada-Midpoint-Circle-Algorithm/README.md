# Midpoint Circle Algorithm in Ada 2023

## Project Overview
The Midpoint Circle Algorithm (also known as Bresenham's circle algorithm) determines the points needed for rasterizing a circle on a discrete 2D grid using solely integer addition, subtraction, and bit shifts. By evaluating an implicit quadratic decision parameter at the midpoint between adjacent candidate pixels, the algorithm calculates one octant and mirrors the coordinates across the remaining seven octants via 8-way symmetry. This project provides a robust, zero-warning implementation adhering to ISO/IEC 8652:2023 (Ada 2023). It includes the standard midpoint formulation, Jesko's optimized inner-difference variant, a non-overlapping horizontal scanline rasterizer for solid filled circles, an implicit equation point classifier, and a generic streaming pixel drawer.

## Features
- **Standard Midpoint Formulation:** Uses 8-way symmetric rasterization with decision variables initialized at `1 - R`.
- **Jesko's Method:** Optimized variant using difference stepping (`t1`, `t2`) for architectures with specific register architectures.
- **Filled Circle Rasterization:** Emits horizontal scanline segments without duplicate pixel writes or gaps.
- **Point Classification:** Determines if arbitrary coordinates reside strictly `Inside`, `On_Boundary`, or `Outside` the circle.
- **Generic Pixel Callback:** Enables integration directly into framebuffers or display drivers without heap allocation.
- **Strong Typing & Safety:** Utilizes bounded coordinate and radius types (`Coordinate`, `Radius_Type`), contract aspects (`Pre`, `Post`), and strict overflow checking.

## Usage
Run the comprehensive test suite directly using GNU Make:

make test

Expected output:

Running tests...
TEST 1 -- Zero Radius Boundary
  PASS -- 1.1 Count is exactly 1
  PASS -- 1.2 Emitted point matches center X
  PASS -- 1.3 Emitted point matches center Y
TEST 2 -- Standard Circle Cardinal Points Verification
  PASS -- 2.1 Top cardinal point found
  PASS -- 2.2 Bottom cardinal point found
  PASS -- 2.3 Horizontal cardinal points found
...
=== 39 passed,  0 failed ===

To clean intermediate object files and binaries:

make clean

## Testing
The test suite in `tests.adb` satisfies the assumption that the code is defective until proven otherwise. It comprises 13 distinct tests with 39 granular checks:
- **Functional Correctness:** Verifies pixel generation against the cardinal axes, cardinal directions, and 8-fold symmetry.
- **Mathematical Invariant Verification:** Validates that all emitted discrete coordinates fall within the exact theoretical discrete error band of x^2 + y^2 - R^2 <= 2R + 5.
- **Edge Cases:** Evaluates degenerate circles (R = 0), large radii (R = 50,000), and coordinate translations across negative axes.
- **Robust Error Handling:** Checks buffer protection via custom `Buffer_Too_Small` exception guards when destination arrays are undersized.
- **Algorithmic Equivalence:** Validates convergence between the standard Midpoint formula and Jesko's variant.

## Building
- **Prerequisites:** GNAT toolchain supporting Ada 2022/2023 (`gnatmake` / `gprbuild`).
- **Language Standard:** Ada 2023 (ISO/IEC 8652:2023), compiled cleanly under `-gnatwa -gnat2022`.
