# BHT Algorithm (Brassard–Høyer–Tapp)

## Project Overview
This project provides a complete, strongly-typed Ada 2023 classical simulation of the Brassard–Høyer–Tapp (BHT) quantum algorithm for solving the collision problem. The algorithm natively combines the square root speedup of the classical birthday paradox with the square root speedup of Grover's quantum algorithm to achieve $O(N^{1/3})$ time complexity. Since quantum execution isn't physically realizable on native x86/ARM hardware, this package faithfully implements the BHT mathematical structuring: it explicitly orchestrates the classical randomization mapping phase, then seamlessly falls back into a deterministic iteration to rigorously simulate the quantum behavior of Grover's search on the remaining pool elements.

## Features
* **Simulate_BHT_2_To_1:** The classical simulation covering the standard quantum architecture variant for finding a collision inside a 2-to-1 function.
* **Simulate_BHT_R_To_1:** The generalized variant for detecting and recovering collisions inside a looser $r$-to-1 mapping layout.
* **Strong Typing:** Fully bespoke algorithmic data structures. Hardened `Domain_Value` and `Range_Value` subtypes enforce intrinsic mathematical constraints safely.
* **Contract-Based Integrity:** Subprograms explicitly bound via strict Ada `Pre` and `Post` contracts to enforce safety rules prior to internal logic evaluation.
* **Graceful Exception Handling:** Pre-engineered handling architectures output named exceptions (`Invalid_Domain_Error`, `Invalid_R_Error`, `Null_Oracle_Error`) whenever extreme constraints are intentionally violated.

## Usage
The primary entry point relies directly on the included standalone test suite mapping, which acts as both the verification harness and usage pipeline. Compile and test with the following:

    make test

Expected execution sequence output snippet:

    Running tests...
    TEST 1 -- BHT 2-to-1 Normal (N=10)
      PASS -- 1.1 Collision found
      PASS -- 1.2 Distinct inputs returned
      PASS -- 1.3 Correct semantic collision logic
    ... (13 tests total / 39 assertions) ...
    ===  39 passed,  0 failed ===

## Testing
The monolithic embedded test suite (`tests.adb`) applies rigid Verification and Validation (V&V) methodologies across multiple constraint profiles:
* **Functional Correctness:** Verifies algorithmic routing, validating classical generation matches with simulated search responses on expected targets.
* **Edge Cases:** Evaluates mathematical boundaries specifically targeting absolute minimal dimensions such as $N=2$ for 2-to-1 patterns or scaling sizes natively tracking identical ranges.
* **Error Handling:** Intentionally forces precondition failures to verify isolated state exits and explicitly capture predictable, defined exceptions without runtime faults.
* **Invariants (Negative Context Testing):** Asserts checking a heavily enforced 1-to-1 function securely sweeps the entire environment pool and reports zero false-positive collisions gracefully.

## Building
* **Prerequisites:** GNAT (GNU NYU Ada Translator) compiler and native `make` support.
* **Ada Version:** Developed strictly mirroring Ada 2023 specifications under ISO/IEC 8652:2023 constraints. Project compilation actively utilizes `-gnat2022` internally to enforce cutting-edge behaviors.
