# Constructive Solid Geometry (CSG) in Ada 2023

## Project Overview
This project provides a robust Ada 2023 implementation of Constructive Solid Geometry (CSG), a modeling technique used in 3D computer graphics and CAD to construct complex geometries by combining simpler objects using Boolean operations. The implementation models the CSG tree and utilizes Signed Distance Fields (SDF) to mathematically evaluate solid boundaries, allowing for exact point-in-solid queries.

## Features
* Primitives: Supports structural variants like Sphere and Box (Cuboid) utilizing exact geometric bounds.
* Boolean Operations: Fully implements structural tree operations:
  * Union: Merging geometries together.
  * Intersection: Finding overlapping geometric space.
  * Difference: Subtracting geometries from one another.
* SDF Evaluation: Exact Signed Distance Field calculations map 3D space recursively over the structure.
* Safety & Contracts: Designed with strict Ada 2023 contracts (Pre, Post), distinct typing bounds, recursive memory management algorithms, and dynamic invariants.

## Usage
Run the built-in test suite to observe the CSG algorithms in action evaluating structural constraints and logic combinations:

make test

Expected output will display PASS for all mathematical boundaries, logical assertions, and memory-safety validations, summarizing with "=== 45 passed,  0 failed ===".

## Testing
The standalone test executable (tests.adb) doubles as the operational API usage guide. It covers critical functionality including:
* Functional Correctness: Exact point extraction and validation against complex structures (e.g., subtracting unions from base bounds).
* Edge Cases: Empty intersections, total eclipses, overlapping exact boundaries.
* Error Handling: Defensively capturing precondition failures and invalid geometric bounding requests.
* Invariants: Proving memory management consistency and numerical precision thresholds via strict structural containment evaluations.

## Building
* Prerequisites: GNAT (GNU Ada Translator) compiler toolchain.
* Standard: Written in Ada 2023 (ISO/IEC 8652:2023). Uses -gnat2022 flag along with -gnatwa warning checks ensuring absolute compilation cleanliness.
