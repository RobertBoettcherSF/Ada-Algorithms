# Metropolis Light Transport in Ada 2023

## Project Overview

This project provides a complete, robust Ada 2023 (ISO/IEC 8652:2023) implementation of the Metropolis Light Transport (MLT) algorithm originally introduced by Eric Veach and Leonidas J. Guibas (1997). The package models light paths as Markov chains, exploring path space via targeted mutation strategies to efficiently resolve complex visibility and high-variance indirect paths like caustics. It implements both classic path-space mutations (bidirectional perturbations and lens subpath modifications) and Kelemen et al.'s Primary Sample Space Metropolis Light Transport (PSSMLT) reformulation.

## Features

* Domain-specific strong typing for physical quantities: `Radiance_Real`, `Unit_Real`, `Coordinate_2D`, and `Color_RGB`.
* Full contract assertions using Ada 2023 `Pre` and `Post` aspects ensuring topological correctness and non-negative scalar values.
* Classic Veach-Guibas Path Mutations:
  * Bidirectional Mutation: Discards and resamples subpaths connecting camera and light sources.
  * Perturbation Mutation: Applies subtle coordinate shifts along specular/diffuse vertex chains.
  * Lens Subpath Mutation: Replaces ray origins through the camera lens and shifts film plane coordinates.
* Primary Sample Space MLT (PSSMLT):
  * Unit hypercube mutation using large steps and correlated small Gaussian steps.
  * Inversion mapping from primary samples into valid physical light transport paths.
* Monte Carlo Normalization: Unbiased estimation of the normalization factor using bootstrap independent path generation.
* Energy deposition and film accumulation over discrete 2D film pixel buffers.
* Zero external dependencies: Built using core language facilities and GNAT-clean design (`-gnatwa -gnat2022`).

## Usage

Build the test executable using the provided Makefile:

    make

Run the comprehensive test suite:

    make test

Expected output:

    Running tests...
    TEST 1 — RNG Initialization and Determinism
      PASS — 1.1 Matching seeds produce equal first value
      PASS — 1.2 Sequential generation changes state
      PASS — 1.3 Values remain in valid unit range
    TEST 2 — Color Operations and Luminance
      PASS — 2.1 Addition calculates correctly
      PASS — 2.2 Scaling calculates correctly
      PASS — 2.3 Luminance reflects ITU-R BT.709 weights
    TEST 3 — Acceptance Probability Function
      PASS — 3.1 Equal energy yields 1.0 acceptance
      PASS — 3.2 Higher proposed energy clamps to 1.0
      PASS — 3.3 Lower proposed energy calculates exact ratio
      PASS — 3.4 Zero past energy automatically accepts
    TEST 4 — Path Validity Verification
      PASS — 4.1 Complete Camera-Light path is valid
      PASS — 4.2 Single-vertex path is invalid
      PASS — 4.3 Path ending in Diffuse vertex is invalid
    TEST 5 — Bidirectional Mutation Proposal
      PASS — 5.1 Generates expected vertex count
      PASS — 5.2 Formed path maintains valid endpoints
      PASS — 5.3 Scalar contribution is positive
    TEST 6 — Perturbation Mutation Behavior
      PASS — 6.1 Preserves path length
      PASS — 6.2 Retains path validity
      PASS — 6.3 Modifies intermediate vertex coordinates
    TEST 7 — Lens Subpath Mutation Behavior
      PASS — 7.1 Maintains structural length
      PASS — 7.2 Retains endpoint validity
      PASS — 7.3 Scalar luminance remains non-zero
    TEST 8 — Primary Sample Space State Proposal
      PASS — 8.1 Dimension is preserved
      PASS — 8.2 Small perturbation values remain bounded
      PASS — 8.3 Value shifts from original state
    TEST 9 — Primary Sample Path Evaluation & Error Handling
      PASS — 9.1 Evaluates into valid path
      PASS — 9.2 Evaluates positive scalar contribution
      PASS — 9.3 Insufficient sample dimensions raise Invalid_Dimension_Error
    TEST 10 — Standard MLT Mutation Step
      PASS — 10.1 Produces valid outcome path
      PASS — 10.2 Length remains compliant with limits
      PASS — 10.3 Initial path length is non-zero
    TEST 11 — Primary Sample Space MLT Mutation Step
      PASS — 11.1 Maintains valid light path
      PASS — 11.2 State dimensions remain consistent
      PASS — 11.3 Scalar contribution remains positive
    TEST 12 — Normalization Factor Estimation
      PASS — 12.1 Normalization factor is strictly positive
      PASS — 12.2 Normalization factor produces realistic non-infinite radiance
      PASS — 12.3 Factor scales reciprocal values predictably
    TEST 13 — Complete Scene Rendering Execution
      PASS — 13.1 Film buffer accumulates non-zero radiance
      PASS — 13.2 Film bounds are correctly dimensioned
      PASS — 13.3 PSSMLT mode successfully runs and updates film

    === 39 passed, 0 failed ===

Clean build artifacts:

    make clean

## Testing

The verification strategy in `tests.adb` follows an adversarial model, systematically validating every public subprogram across several core testing categories:

* **Functional Correctness:** Validates mathematical consistency of photometric calculations (ITU-R BT.709 luminance), vector color addition, scaling, and the Metropolis acceptance probability ratio.
* **Path Invariants:** Confirms that path mutation routines maintain structural validity (paths must connect a `Camera` vertex to a `Light` vertex and remain within buffer boundaries).
* **Algorithmic Mutations:** Verifies that both path-space proposals (bidirectional, perturbation, lens) and primary sample space proposals preserve dimensionality and generate legitimate candidates without zero-division or range errors.
* **Error Handling and Edge Cases:** Ensures that malformed path states and insufficient primary sample dimensions raise expected exceptions (`Invalid_Dimension_Error`) rather than generating unconstrained runtime faults.
* **End-to-End Execution:** Verifies that both standard MLT and PSSMLT integrate into full scene rendering pipelines, stably depositing energy into multi-pixel film buffers.

## Building

### Prerequisites

* GNAT compiler toolchain supporting Ada 2022/2023 (ISO/IEC 8652:2023).
* GNU Make.

Compiler flags used: `-gnatwa -gnat2022`.
