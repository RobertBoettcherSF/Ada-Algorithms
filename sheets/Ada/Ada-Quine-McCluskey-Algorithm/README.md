# Quine-McCluskey Algorithm Implementation in Ada

## Project Overview
This repository contains an implementation of the Quine-McCluskey logic minimization algorithm written in Ada. The implementation transforms Boolean functions (represented by minterms) into their most simplified sum-of-products form, ensuring strict type safety and memory robustness inherent to Ada. 

## Features
The codebase supports **ALL variants** and steps of the algorithm as specified in computational logic theory:
- **Variant 1: Prime Implicant Generation:** Identifies all prime implicants recursively based on bit-distance properties.
- **Variant 2: Heuristic / Greedy Minimization:** Uses essential prime implicants and greedy heuristics to solve the prime implicant chart, favoring execution speed.
- **Variant 3: Exact Minimization (Petrick's Method Equivalence):** Uses exact set cover backtracking algorithms to guarantee mathematically minimal representations (perfect for complex cyclic cores).
- **"Don't Cares" Logic Handling:** Safely optimizes minterms across undefined states.

## Testing
We adhere strictly to systems engineering principles of Verification & Validation (V&V):
- **Verification:** Does the code match theoretical requirements? (e.g., merging "100" and "101" to "10-")
- **Validation:** Does the code behave correctly in the wild under assumed stress or failure scenarios?

The provided `tests.adb` is built under a **"pessimistic assumption" test philosophy**: We assume the code is broken. The tests pass *only* when that assumption is provably disproven. 

**Test Categories Addressed:**
1. **Functional Correctness:** Ensures helper math algorithms (`Count_Ones`, `Covers`) correctly implement Boolean algebra foundations.
2. **Edge Cases:** Evaluates behavior with empty inputs, tautology conditions (all minterms exist), and disjoint/single variables. Proves graceful handling rather than system crashes.
3. **Error Handling / Robustness:** Asserts that overlapping bounds between Minterms and Don't Cares trigger explicit `Invalid_Input_Error` exceptions, avoiding silent critical calculation failures.
4. **Algorithmic Pathing:** Tests ensure `Minimize_Exact` triggers cyclic resolution, validating that branching logic operates functionally on NP-hard reductions like Petrick's Method equivalence.

*Why these tests matter:* In critical systems design where Ada is typically deployed (Aerospace, Defense, Avionics), Boolean logic simplifications dictate physical hardware gates. Silent failures or unhandled edge cases translate to systemic hardware failure. The V&V suite proves systemic correctness.

## Usage

### Compilation
The codebase uses GNAT project file setups. Simply use the included Makefile from the root directory:
```bash
make
