# Ada 2023 Naive Bayes Classifier

---

## Project Overview

This project provides an implementation of the **Naive Bayes Classifier** in Ada 2023 (ISO/IEC 8652:2023). It comprehensively addresses three primary data model variants described in standard machine learning literature: **Gaussian Naive Bayes** (for normally-distributed continuous data), **Multinomial Naive Bayes** (for frequency/count-based data like text), and **Bernoulli Naive Bayes** (for binary/boolean presence data). The implementations use logarithm-based arithmetic strictly to prevent underflow over probabilities.

---

## Features

- **Gaussian Variant:** Ideal for continuous numeric features. Includes epsilon variance smoothing to gracefully handle static feature slices and prevent divide-by-zero bounds limits.
- **Multinomial Variant:** Implements Laplace (Add-one) smoothing standard. Optimized for discrete counts and term frequencies.
- **Bernoulli Variant:** Includes thresholding (converts magnitudes to presence) and boolean probability absence tracking, smoothed with Lidstone formulations.
- **Ada Native Design:** Strong custom subtyping for `Class_ID`, robust generic math derivations, and strict bounds handling. Features discriminants dynamically constructed during model creation rather than relying on access types.
- **Warning Free:** Compliant up to GNAT `-gnatwa -gnat2022`. Includes standard Ada 2012/2022 contracts (`Pre`) that seamlessly carry forward into Ada 2023 environments.

---

## Usage

The primary entry point is the integrated test suite `tests.adb`, which concurrently operates as an API usage example showing both valid training procedures and data error handling.

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
--- Starting Naive Bayes Tests ---
TEST 1 - Gaussian Basic Train & Predict
  PASS - 1.1 Model built successfully
  PASS - 1.2 Predict Class 1
  PASS - 1.3 Predict Class 2
...
===  39 passed,  0 failed ===
```

---

## Testing

The embedded test suite exercises over 13 edge scenarios containing 3 assertions each to prove functional correctness and error resilience:

- **Functional Correctness:** Training and inference verifications evaluating outputs over Gaussian, Multinomial, and Bernoulli subsets.
- **Edge Cases:** Assesses smoothing mechanics over flat variances and completely missing dataset classes. Checks threshold conversions for Bernoulli values.
- **Error Handling / Invariants:** Deliberately invalid inputs (length boundary mismatches, mismatched class labels, impossible Alpha factors) to guarantee system stability and contract validation.

---

## Building

**Prerequisites:**

- Standard GNAT build environment (`gnatmake`).
- Ada 2022/2023 standards compliance.

Build the environment purely with standard compilation procedures:

```bash
make
```
