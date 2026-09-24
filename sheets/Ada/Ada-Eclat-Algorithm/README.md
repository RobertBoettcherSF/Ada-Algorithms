# Eclat Algorithm in Ada 2023

---

## Project Overview

This repository provides a highly rigorous, strongly-typed implementation of the **Eclat (Equivalence Class Transformation)** algorithm in Ada 2023. Eclat is a popular algorithm used for frequent itemset mining. Unlike algorithms such as Apriori, which use a horizontal database format and generate-and-test approaches, Eclat utilizes a vertical database format (mapping items to sets of transaction IDs) and performs a depth-first search using fast set intersections. This implementation includes both Standard Eclat and the optimized **dEclat (Diffset Eclat)** variant, which further reduces memory consumption and intersection times by tracking the differences between Transaction ID lists rather than the full lists themselves.

---

## Features

- **Standard Eclat (`Mine_Standard`):** Computes itemset support through pure Transaction ID (TID) set intersection.
- **Diffset Eclat (`Mine_Diffset`):** The highly optimized dEclat variant, computing support by tracking differences of TID sets across its depth-first recursive traversal (dynamically shifting from TID sets at level 1 to Diffsets at levels 2+).
- **Vertical Database Abstraction:** Fully encapsulated `Vertical_DB` object to safely track item-to-TID structures.
- **Strong Typing:** Ada distinct types utilized for `Item_ID`, `Transaction_ID`, and `Support_Count` to prevent accidental logic errors and bound-issues.
- **Ada 2023 Contracts:** Ensures reliability through preconditions and comprehensive exception handling for invalid operations (like zero or negative `min_sup`).

---

## Usage

The provided `tests.adb` acts simultaneously as the functional test suite and as comprehensive usage documentation, demonstrating database construction and mining procedure execution.

To compile and run the suite, use the provided Makefile:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Empty Database Behavior
  PASS — 1.1 Item_Count is 0
  PASS — 1.2 Mine_Standard returns empty on empty DB
  PASS — 1.3 Mine_Diffset returns empty on empty DB
TEST 2 — Item Addition and Idempotency
  PASS — 2.1 Item_Count is 1
  PASS — 2.2 Item_Count still 1 after duplicate TID
  PASS — 2.3 Support is exactly 2 despite duplicate addition
...
===  39 passed,  0 failed ===
```

---

## Testing

The embedded test suite exercises the implementation across several dimensions for **Verification and Validation**:

- **Functional Correctness:** Explicitly checks specific generated itemset arrays and computed support values across various scenarios (isolated sets, subsets, multi-level recombinations).
- **Equivalence Verification:** Guarantees that the theoretical dEclat memory-optimized path yields exactly the same itemset configurations and supports as the Standard Eclat procedure.
- **Edge Cases:** Proves correct behavior on empty databases, absent combinations, unattainable `min_sup` thresholds, and non-sequential IDs.
- **Error Handling:** Validates strict precondition behaviors (e.g., properly handling &lt; 1 minimum supports via explicit contract failure/exceptions).

---

## Building

**Prerequisites:**

- GNAT Ada Compiler (supports Ada 2022/2023 standards, e.g., GNAT FSF or GNAT Pro).
- GNU Make.

To just build without executing the test run:

```bash
make all
```

**Ada Standard:** This code is compiled specifically with the `-gnat2022` flag to utilize modern container iterations, aspect contracts, and strong typing paradigms available in the latest ISO/IEC 8652 revisions.
