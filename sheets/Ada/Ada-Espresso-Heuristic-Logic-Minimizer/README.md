# Espresso Heuristic Logic Minimizer (Ada 2023)

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of the core **Espresso heuristic logic minimizer** loop. Espresso is an algorithm used to minimize Boolean functions by manipulating representations of prime implicants (cubes). Unlike exact minimization strategies like Quine-McCluskey, Espresso utilizes heuristics to handle complex logic structures iteratively without factorial time complexity, shrinking the boolean cover representation by expanding and reducing logical cubes.

---

## Features

- **Strong Typing:** Uses strictly defined `Logic_Value` and `Cube` types rather than implicit bitwise logic on integers.
- **Dynamic Cover Representation:** Uses Ada 2012+ `Indefinite_Vectors` to manage cubes of varied system size.
- **Variant 1 — `Minimize_Single_Pass`:** Executes a fast, greedy approach covering `Expand` and `Irredundant` phases.
- **Variant 2 — `Minimize_Iterative`:** Executes the classic multi-pass heuristic loop incorporating the `Reduce` step to escape local minima prior to expanding, continuing until convergence.
- **Robust Edge Cases:** Protects algorithm invariants via explicit Ada preconditions and dynamically raised `Invalid_Cover` / `Inconsistent_Covers` exceptions.

---

## Usage

To execute the test suite and verify behavior, run `make test`.

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Overlaps
  PASS — 1.1 Partial overlap with Dont_Care
  PASS — 1.2 Explicit conflict prevents overlap
  PASS — 1.3 Self always overlaps
TEST 2 — Subsumes
  PASS — 2.1 Broader cube subsumes narrower
  PASS — 2.2 Narrow cube does not subsume broader
  PASS — 2.3 Self always subsumes
...
===  39 passed,  0 failed ===
```

---

## Testing

The embedded test suite (`tests.adb`) doubles as both the unit validation and the primary usage example of the library:

- **Functional Correctness:** Validates `Overlaps`, `Subsumes`, `Expand`, `Reduce`, and `Irredundant` logic against expected theoretical logic outcomes.
- **Integration Tests:** Executes both `Minimize_Single_Pass` and `Minimize_Iterative` loops against known truth tables (e.g., minimizing XOR and OR setups).
- **Edge Cases:** Validates functionality gracefully handles empty logic sets (both empty `ON-set`s and empty `OFF-set` constraints).
- **Error Handling:** Tests deliberate validation failures to ensure structural safety violations trigger expected runtime exceptions before progressing to unsafe memory states.

---

## Building

- **Prerequisites:** A recent version of GNAT (GCC Ada Compiler).
- **Ada Standard:** The code compiles strictly under Ada 2022/2023 standards (`-gnat2022`).
- Build artifacts are constructed clean, strictly avoiding any warnings underneath the `-gnatwa` flag.
