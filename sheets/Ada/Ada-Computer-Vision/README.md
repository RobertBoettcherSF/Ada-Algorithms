# Computer Vision Foundations in Ada 2023

---

## Project Overview

This project provides a robust, strongly-typed implementation of foundational algorithms from the field of **Computer Vision**, written strictly in Ada 2023 (ISO/IEC 8652:2023). It processes digital images by translating RGB pixels to specialized Grayscale matrices and performing matrix Convolution to extract higher-level features (such as spatial gradients indicating object edges) using various operators.

---

## Features

- **RGB to Grayscale Conversion (Average):** Simplistic processing using mathematically flat RGB channel extraction.
- **RGB to Grayscale Conversion (Luminosity):** Standard perceptual conversion mapped to Rec. 709 luminance values matching human ocular geometry.
- **2D Discrete Convolution:** A generic feature extraction pipeline mapping 3x3 kernels across standard matrices applying safe zero-padding edge rendering boundaries.
- **Sobel X-Gradient:** Edge detection highlighting stark vertical edges by suppressing uniform horizontals.
- **Sobel Y-Gradient:** Edge detection highlighting stark horizontal edges by suppressing uniform verticals.
- **Sobel Total Magnitude:** Complete normalized spatial edge map utilizing the Euclidean norm of bidirectional Sobel gradients.
- **Strict Typing and Integrity:** Mathematical safety is natively driven by array constraint limits, rigorous `Clamp` limits, and strict preconditions mapped dynamically on edge cases.

---

## Usage

This project operates strictly as a standalone suite relying solely on the built-in test harness `tests.adb` serving both as exhaustive verification mechanism and pragmatic usage documentation.

Run the testing suite using `make`:

```bash
make test
```

**Expected Output:**

```plaintext
...
TEST 10 - Sobel Magnitude on Vertical Edge Image
  PASS - 10.1 Left side detects strong magnitude
  PASS - 10.2 Center remains zero magnitude
  PASS - 10.3 Right side negative gradient recovered as positive magnitude
...
===  39 passed,  0 failed ===
```

---

## Testing

The standalone unit testing file covers multi-layered operational scopes required for software validation and verification in Ada:

- **Functional Correctness:** Mathematical verification spanning pixel extraction coefficients and spatial translation logic.
- **Edge Cases:** Asserts strict boundary enforcement validating standard safety over limits handling 1x1 image matrices and deep convolution padding behaviors.
- **Error Handling / Preconditions:** Validation affirming exceptions propagate cleanly (`Dimension_Error`) protecting operations dynamically before zero-length vector crashes occur.
- **Invariants:** Guarantees postcondition requirements dictating transformation size bounds are respected permanently invariant of local kernel mutations.

---

## Building

**Prerequisites:** A compliant GNAT compiler toolchain supporting modern Ada (2022+ functionality is required, passed dynamically via `-gnat2022`). Standard GNU Make utility handles automatic construction logic.

Clean the environment dynamically:

```bash
make clean
```
