# Ada 2023 GrabCut Segmentation

---

## Project Overview

This repository provides an Ada 2023 (ISO/IEC 8652:2023) implementation of the **GrabCut image segmentation algorithm**. GrabCut uses an iterative graph-cut (max-flow/min-cut) approach coupled with statistical modeling (Gaussian mixture models) to effectively separate foreground from background in an image. This implementation uses a highly reliable Edmonds-Karp maximum flow solver and provides strong typing, explicit bounding models, and memory-safe dynamic constraints.

---

## Features

- **Segment\_By\_Box:** Initializes the segmentation model using a specified bounding box, automatically tagging outside elements as background.
- **Segment\_By\_Mask:** Allows passing user-defined exact masks (such as brush strokes) for dynamic and accurate iterative segmentation.
- **Segment\_One\_Shot:** Runs the iterative cycle automatically until convergence or the optimal iteration boundary is reached.
- **Strong Typing and Safe Memory:** Validates array bounds strictly, avoids infinite variances, and manages internal graph matrix sizes using secure memory allocation/deallocation.
- **Zero Compilation Warnings:** Strictly adheres to Ada safety principles natively resolving without warnings under `-gnatwa`.

---

## Building

Ensure you have a recent version of GNAT capable of Ada 2022/2023 features (`-gnat2022`).

```bash
make
```

---

## Usage and Testing

The executable `tests.adb` acts simultaneously as the functional test suite and the main usage example, demonstrating how to interface with the core logic. To build and execute the tests:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
TEST 1 — Validation Helpers
  PASS — 1.1 Valid box returns True
  PASS — 1.2 Out of bounds box returns False
...
===  39 passed,  0 failed ===
```

---

## Testing Breakdown

The test suite systematically covers:

- **Validation Checks:** Ensures bounds constraints safely reject invalid geometric inputs.
- **Initialization Boundaries:** Verifies arrays construct matching memory bounds.
- **Graph Cut Processing:** Confirms the flow algorithm cleanly partitions regions using data and smoothness penalties.
- **GMM Constraints:** Proves mathematical functions avoid NaN/Division by zero in zero-variance inputs.
- **Memory Access Control:** Ensures out-of-range arrays raise predefined exceptions rather than producing unhandled crashes.
