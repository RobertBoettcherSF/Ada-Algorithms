# Relevance Vector Machine (Ada 2023)

---

## Project Overview

This project provides a robust, zero-warning implementation of the **Relevance Vector Machine (RVM)** algorithm in Ada 2023 (ISO/IEC 8652:2023). It leverages sparse Bayesian learning to construct highly sparse predictive models by pruning basis functions down to a minimal set of "relevance vectors." Unlike Support Vector Machines (SVMs), the RVM natively provides probabilistic outputs for classification and removes the need to manually tune the penalty term (`C`).

---

## Features

- **Dual Operation Modes:** Contains variants for both Continuous Regression and Probabilistic Classification via Iteratively Reweighted Least Squares (IRLS).
- **Multiple Kernels:** Native support for Linear and Radial Basis Function (RBF) mapping.
- **Automatic Relevance Determination (ARD):** Aggressively prunes weights dynamically using maximum marginal likelihood, resulting in high sparsity models.
- **Standard Ada Matrix Math:** Built completely on `Ada.Numerics.Generic_Real_Arrays`, providing fast, standard, error-free linear algebra with Tikhonov regularization for numerical stability.
- **Memory Safe:** Utilizes `Ada.Finalization.Controlled` records for leak-proof automated garbage collection of internally allocated matrices and vectors.

---

## Building

To build and execute the project, you must have the GNAT compiler installed and capable of compiling modern Ada.

Simply utilize the provided `Makefile`:

```bash
make test
```

---

## Usage

No standard executable is required aside from the test driver. `tests.adb` demonstrates real-world use of both Classification and Regression paths.

**Expected Output when running `make test`:**

```plaintext
Running tests...
--- Relevance Vector Machine Test Suite ---
TEST 1 — Model Initialization State
  PASS — 1.1 Model is not trained initially
  ...
TEST 13 — Classification (RBF Kernel)
  PASS — 13.1 Non-linear Model trained successfully
  ...
===  39 passed,  0 failed ===
```

---

## Testing

The test suite spans 13 rigorously defined unit tests featuring 39 total assertions. Categories covered:

- **Lifecycle &amp; Integrity:** Checks initialization properties and validates resource allocation defaults.
- **Algorithm Correctness:** Synthesizes linear datasets (e.g., identity functions) and logic gates (AND) to verify exact math approximations.
- **Sparsity Validation:** Explicitly asserts that models dynamically drop unused basis functions based on prior updating rules.
- **Pre-conditions &amp; Edges:** Validates dimension checking and throws Ada's built-in `Assertion_Error` exceptions if mismatch attempts are logged (e.g., invalid feature counts, predict-before-train behavior).
