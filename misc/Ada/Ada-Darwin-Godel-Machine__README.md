# Darwin-Gödel Machine

## Project Overview
This repository contains a robust Ada 2023 implementation of the Darwin-Gödel Machine (DGM) framework for Open-Ended Evolution of Self-Improving Agents based on Arxiv 2505.22954. It implements an architecture where an agent system leverages both Darwinian adaptation (population mutation across an evolving code space) and Gödel verification (rigorous constraints to ensure safety against runaway code bloat or functional regressions). The algorithm evaluates different environmental pressures (static vs dynamic brittleness) and evolution variants to optimize recursive self-improvement safely.

## Features
* Strict Proof vs Heuristic Verification: Implements distinct Gödel verification layers—Verify_Strict strictly limits agent code complexity sprawl, while Verify_Heuristic aggressively pursues optimal capability.
* Exhaustive & Preemptive Evaluation Loops: Evolution loops operate in Evolve_Exhaustive (finding the globally optimal candidate) or Evolve_Preemptive (dynamic halting upon satisfying aggressive capabilities bounds).
* Environmental Penalties: Supports Static_Env and Dynamic_Env configurations, punishing overly complex code strings under changing evolutionary pressures.
* High-Integrity Foundations: Adheres completely to Ada 2023 design patterns, featuring custom domain subtypes, explicit contractual annotations (Pre/Post/Global), robust exceptions, and 0-warnings compliance under -gnatwa.

## Usage
Ensure the GNAT toolchain is available on your path, then execute:
make test

Expected Output: The test binary will be synthesized into the bin/ directory and execute exactly 13 tests performing 39 discrete internal functional validations covering environments, data models, exception paths, and optimization loop logic constraints. At the end, you should see === 39 passed, 0 failed ===.

## Testing
The embedded test suite (tests.adb) operates as a comprehensive verification module and executable integration layer.
* Functional Correctness: Verifies algorithmic fitness progression mathematically maps over both static and dynamic penalty landscapes.
* Invariant Constraints: Proves Gödel safety gates correctly halt destructive agent paths (e.g., capability regression, excessive complexity).
* Edge Cases: Audits boundaries like mathematically unachievable capability thresholds, constraint failures on invalid parameters, and Population_Empty_Error interceptions across all loops.
* Validation Justification: Because self-modifying autonomous paradigms demand unparalleled safety, every verification check here ensures continuous operations stay functionally deterministic.

## Building
* Prerequisites: GNAT GCC Toolchain (gnatmake).
* Standards: Targets ISO/IEC 8652:2023 via the compiler flag -gnat2022.
* Automatically driven by the provided Makefile which binds configurations through darwin_godel.gpr.
