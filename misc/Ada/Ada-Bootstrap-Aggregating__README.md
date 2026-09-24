# Bootstrap Aggregating (Bagging) in Ada 2023

---

## Project Overview

This repository provides a strongly-typed, completely reusable Ada 2023 implementation of the **Bootstrap Aggregating (Bagging)** meta-algorithm. Bagging is a popular machine learning ensemble method used to improve the stability and accuracy of standard algorithms by training independent base models on random resamplings of the original dataset with replacement.

---

## Features

- **Classification Bagging Variant:** Aggregates predictions across multiple discrete classifiers using Majority Voting. Incorporates deterministic tie-breaking.
- **Regression Bagging Variant:** Aggregates predictions across multiple continuous regressors using Averaging.
- **Data-Agnostic Design:** Operates abstractly over `Dataset_Index` rather than imposing a rigid vector structure on your data. Users supply interfaces that handle the underlying dataset mapping.
- **Strict Validations:** Implements both Ada contract aspects (`Pre`) and run-time validations ensuring robustness against edge cases (zero inputs, null accesses).
- **Automated Memory Management Utilities:** Contains built-in deallocation subprograms `Free_Classifier_Ensemble` and `Free_Regressor_Ensemble` to safely wipe dynamically generated models without memory leaks.

---

## Building

To compile and build the test suite, ensure you have GNAT installed. This project takes advantage of Ada 2023 (ISO/IEC 8652:2023) features, requiring compilation with the `-gnat2022` flag.

Simply invoke `make`:

```bash
make
```

---

## Testing

This repository includes a rigorous standalone test suite (`tests.adb`) constructed to both validate correct behavior and demonstrate API usage.

To run the suite:

```bash
make test
```

**Test Coverage Categories:**

- **Functional Correctness:** Verifies mathematical correctness of averaging and majority mode logic.
- **Random Sampling Attributes:** Confirms sample boundaries, dataset limits, and sample sizes strictly conform to Bagging theory.
- **Edge Cases:** Evaluates empty ensembles, single-model environments, and multi-way deterministic tie-breaking.
- **Error Handling:** Validates strict rejection of invalid sizes (0 elements), null trainer bounds, and empty array queries via explicit exceptions.
- **Memory Integrity:** Asserts that double-deallocation and element clearing execute seamlessly.

---

## Expected Output

The test execution lists pass states for 13 unique test scenarios representing nearly 40 assertions, culminating in a clean pass record:

```plaintext
--- Starting Bootstrap Aggregating Test Suite ---
...
===  39 passed,  0 failed ===
```
