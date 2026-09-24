# Shamir's Secret Sharing in Ada

## Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation of Shamir's Secret Sharing algorithm. The scheme divides a secret into `N` parts (shares), requiring any `K` of them (the threshold) to mathematically reconstruct the original secret. It implements both the highly secure Finite Field variant (operating over a prime modulus to guarantee perfect secrecy) and the insecure Integer Arithmetic variant strictly for conceptual demonstration and educational purposes, as outlined in cryptographic literature.

## Features
* **Finite Field Variant (Dynamic):** Splits a secret using an underlying prime modulus field (`M_31` Mersenne prime) and generates random polynomial coefficients natively in Ada.
* **Finite Field Variant (Static):** Allows for explicit provisioning of polynomial coefficients for verifiable secret sharing architectures and deterministic unit testing.
* **Integer Arithmetic Variant:** Provides an insecure alternative that utilizes plain integer arithmetic, recreating the pedagogical stepping-stone detailed in cryptographic theory.
* **Strong Safety & Contracts:** Employs Ada 2023 design patterns including `Pre` and `Global` aspects, avoiding implicit conversions, and implementing explicit validations (`Threshold_Error`, `Invalid_Share_Error`).

## Usage
To test the integration and observe functionality, no separate `main.adb` is required. The program is driven by `tests.adb` which behaves as both the executable runner and the API consumption example.

Execute via the included Makefile:

```bash
make test
```

Expected output:

```text
Running tests...
TEST 1 — Modular Inverse
  PASS — 1.1 Inv(1) = 1
  PASS — 1.2 Inv(P-1) = P-1
  PASS — 1.3 Inv(123) * 123 = 1
...
TEST 13 — Error on Insufficient Shares
  PASS — 13.1 Reconstruct detects lack of FF shares
  PASS — 13.2 Reconstruct detects lack of Int shares
  PASS — 13.3 Empty array correctly triggers Threshold_Error

===  39 passed,  0 failed ===
```

## Testing
The embedded test suite (`tests.adb`) achieves coverage across four primary categories to assure verification and validation:
1. **Functional Correctness:** Ensures algebraic operations (`Modular_Inverse`, `Evaluate_Polynomial`) behave flawlessly according to field theory.
2. **Reconstruction & Combinatorics:** Verifies that distinct and mixed subsets of generated shares accurately recombine to produce identical secret material.
3. **Variant Consistency:** Cross-checks the functional determinism for both random generation and strict coefficient provisioning.
4. **Error Handling & Edge Cases:** Purposely attempts threshold under-provisioning, injection of duplicated shares, and empty allocations to validate that exact named exceptions fire off reliably without corrupting execution state.

## Building
**Prerequisites:** GNAT compiler (compatible with `-gnat2022`).

```bash
make all    # Compiles project and links binary under bin/
make clean  # Removes artifact object files and bin target
```
