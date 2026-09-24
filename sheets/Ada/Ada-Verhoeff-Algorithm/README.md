# Ada Verhoeff Algorithm Implemention

## Project Overview
This repository contains an Ada implementation of the **Verhoeff algorithm**. The Verhoeff algorithm is a mathematical checksum formula used for error detection. Developed by Dutch mathematician Jacobus Verhoeff, it overcomes the weaknesses of the simpler Luhn algorithm by effectively catching all single substitution errors and adjacent transposition errors. It achieves this by mapping numbers into the dihedral group $ D_5 $ structure.

## Features
* **Strong Typing**: Implements restrictive ranges (`Digit_Value`, `Position_Index`) intrinsic to Ada to guarantee that invalid transformations physically cannot compile.
* **Variant 1 - Generation**: `Generate_Check_Digit` calculates the check digit that should be appended to the end of a payload sequence. 
* **Variant 2 - Validation**: `Validate` verifies an alphanumeric string that already contains a Verhoeff checksum.
* **Safe Edge Case Handling**: Explicit constraint checking ensuring proper detection of invalid inputs (empty strings, alphabetic characters).

## Testing
This project integrates a V&V (Verification and Validation) approach embedded in its architecture. The initial philosophy operates under the assumption that the code is non-functional or susceptible to bounds overflow. A **PASS** state actively disproves this assumption.

**Test Categories:**
1. **Functional Correctness (Tests 1-2):** Ensures the implementation accurately mirrors mathematical expectations for generating and validating basic outputs.
2. **Robustness & Error Detection (Tests 3-5):** Validates that single-digit substitution and adjacent digit transposition accurately yield mathematically invalid checksums (The fundamental goal of the algorithm).
3. **Exception Handling (Tests 6-9):** Asserts that improper formats (alphanumeric injections, empty inputs) raise safe, controlled `Invalid_Input` exceptions instead of causing program crashes or silent failures.
4. **Boundary & Scalability (Tests 10-14):** Ensures that limits—like arbitrary leading zeroes, individual isolated digits, and infinite cyclic scaling—safely compute without causing `Constraint_Error` array bound overflows.

These rigorous parameters guarantee the software meets the high-reliability demands native to Ada engineering environments.

## Usage

### Compilation
The codebase can be dynamically built utilizing either GNU Make or directly with GNAT. There is no isolated `src/` folder; everything runs from the root directory.

To compile with Make:
```bash
make all
