# ID3 Decision Tree Algorithm in Ada 2023

---

## Project Overview

This repository contains a complete, robust implementation of the **Iterative Dichotomiser 3 (ID3)** machine learning algorithm in Ada 2023 (ISO/IEC 8652:2023). Developed for strict type safety and reliability, this library produces a categorical decision tree used for classifying data instances. It gracefully manages datasets, dynamically determines maximum entropy splits via multiple criterion algorithms, and constructs a navigable tree capable of inferences—even maintaining safety constraints when evaluating previously unseen categories.

---

## Features

- **Multiple Splitting Criteria:** Supports standard *Information Gain* (basic ID3) and *Gain Ratio* (C4.5 precursor variation) out-of-the-box.
- **Strong Typing:** Completely avoids primitive types (`Integer`, `Float`) for core logic by leveraging robust domain constraints (`Attribute_ID`, `Class_ID`, `Metric_Value`).
- **Graceful Inference Handling:** Automatically cascades to default majority-class decisions when a testing instance presents a previously unobserved categorical value.
- **Contract-Oriented Validation:** Integrates Ada `Pre` contracts and named exception-raising (`Empty_Dataset_Error`, `Invalid_Data_Error`) to catch dimensionality discrepancies immediately.
- **No Unchecked Warnings:** Complies fully cleanly under `-gnatwa` ensuring no dead code or unsafe conventions.

---

## Usage

Because this is a library, the exact usage is dynamically demonstrated within the provided extensive test suite. To test the logic, execute:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Empty Dataset Exceptions
  PASS — 1.1 Entropy raises exception on empty dataset
  PASS — 1.2 Information_Gain raises exception on empty dataset
  PASS — 1.3 Build_Tree raises exception on empty dataset
... [Additional test feedback continues] ...
=== 42 passed,  0 failed ===
```

---

## Testing

The embedded standalone test suite `tests.adb` conducts rigorous validation checks consisting of more than 14 independent test blocks containing exactly three checks per test (a total of 42 assertions).

**Categories of tests explicitly validated include:**

- **Functional Correctness:** Exact checks against known Information Gain entropy logarithms, verifying accurate attribute partitioning.
- **Edge Cases:** Testing datasets with 0 entropy homogeneity, single-elements, subsets that collapse mathematically (Division by Zero avoidance), and processing an empty `Attribute_Set`.
- **Error Handling:** Validating structural constraints such as instances mapping to attributes far larger than their internal `Num_Attributes` constraint logic natively catches missing boundaries gracefully.
- **Invariants:** Ensuring accurate Leaf fallbacks when evaluating unseen prediction classes and affirming memory cleanliness post-allocation (`Free_Tree`).
- **Variant Coverage:** `Build_Tree` operates over both Split Criteria (Information Gain vs Gain Ratio) under test validation.

---

## Building

**Prerequisites:** GNAT compiler (GCC Ada compiler) suite with Make tools.

This project uses the `-gnat2022` flag natively resolving it to the Ada 2023 standard specification (ISO/IEC 8652:2023).

```bash
make all   # Builds binaries only
make test  # Builds and executes test suite
make clean # Removes temporary object files
```
