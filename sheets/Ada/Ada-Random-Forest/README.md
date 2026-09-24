# Ada 2023 Random Forest Implementation

---

## Project Overview

This repository contains a full Ada 2023 (ISO/IEC 8652:2023) implementation of the **Random Forest algorithm** as described on Wikipedia. It provides an ensemble learning methodology utilizing Bagging (Bootstrap Aggregating) and the Random Subspace Method (feature bagging) across an arbitrary number of decision trees. Both Classification and Regression models are supported natively.

---

## Features

- **Variants Supported:**
  - `Standard_Random_Forest`: Standard Breiman formulation where a random subset of features is evaluated at each node to find the most optimal data split.
  - `Extra_Trees` (Extremely Randomized Trees): A variant that further randomizes splitting by picking random threshold values instead of the optimal threshold.
- **Classification:** Utilizes Gini Impurity and majority voting.
- **Regression:** Utilizes Variance Reduction (Mean Squared Error minimization) and prediction averaging.
- **Strong Typing:** Domain-specific types (`Feature_Value`, `Target_Value`, `Class_Label`) enforcing logical safety at compile time.
- **Ada Contracts:** `Pre`, `Post`, and `Global => null` expressions statically enforce bounds checking, dimension matching, and data purity.
- **No Dynamic Allocation:** Uses bounded max-node arrays internally for extremely rapid, zero-leak tree generation.

---

## Building and Usage

**Prerequisites:** GNAT (tested against `gnatmake` / Ada 2022/2023 modes).

To build and execute the test suite:

```bash
make test
```

**Expected Output:**  
The system compiles cleanly with `-gnatwa` (zero warnings). Upon execution, the test suite acts as an integrated API usage demonstration, showing 14 test categories with over 40 distinct assertions validating edge cases, algorithmic variants, and contract failures. It will output:

```plaintext
===  42 passed,  0 failed ===
```

---

## Testing

The `tests.adb` test suite verifies functional correctness, parameter bounds checks, invariant validations, and exception handling logic:

- **Functional Correctness:** Validates predictions mathematically align with basic datasets (XOR logic, linear progressions).
- **Edge Cases:** Ensures single-row datasets or data with pure label compositions stop building and evaluate to leaves rapidly without crashing.
- **Error Handling:** Verifies that violations of matrix lengths or dimensions are successfully caught by preconditions (`pragma Assert` checking), throwing appropriate `Constraint` or `Assertion` errors.
- **Variants Coverage:** Each of the 4 combinations (Standard Classification, Standard Regression, Extra Trees Classification, Extra Trees Regression) is explicitly modeled and evaluated.
