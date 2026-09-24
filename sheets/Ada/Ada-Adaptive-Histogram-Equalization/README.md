# Adaptive Histogram Equalization (Ada Implementation)

## Project Overview
This repository provides a highly robust, purely analytical implementation of the Adaptive Histogram Equalization (AHE) algorithms in Ada. This system is designed to improve the contrast in images specifically bounded by mathematical constraints typical in embedded, medical imaging, or strict aerospace software pipelines. It maps intensity distribution strictly through calculated Cumulative Distribution Functions (CDFs).

## Features
- **Global HE:** Baseline standard Histogram Equalization.
- **Sliding Window AHE:** Contextual equalization via localized sliding sub-regions (Odd windows enforced).
- **Sliding Window CLAHE (Contrast-Limited AHE):** Enforces a `Clip_Limit` to artificially dampen noise amplification in otherwise homogeneous image sections, solving standard AHE's largest drawback.
- **Block-Based CLAHE:** Implements a tiled processing grid (computed blocks with nearest-neighbor mapping) maximizing computational throughput vs a pixel-by-pixel sliding window.

## Testing (Verification & Validation)
This codebase embraces aggressive pessimistic testing methodologies. We verify that the software meets requirement intent (V&V standard definitions), while validating boundary constraints natively built into the Ada typing system.

**What categories the tests verify:**
1. **Functional Correctness:** Ensures CDF limits hit absolute bounds without missing 0 or exceeding 255 limit types. Verifies algorithmic redistribution dampens single-pixel outliers (Asserts CLAHE suppresses peaks vs AHE).
2. **Error & Boundary Handling:** Prevents catastrophic divisions (empty arrays) and ensures bounds logic doesn't crash on edges (`Grid_Rows > Image Dimensions`).
3. **Pessimistic Assumptions:** Tests assume integer overflows will occur at limits, verifying bounds logic explicitly halts them and handles single-pixel or extremely flat noise images predictably.

**Why these tests matter:**
In mission-critical contexts (e.g., medical x-ray image processing), unhandled exceptions natively crashing out due to an even window dimension size or an over/underflow in CDF translation is unacceptable. These constraints mathematically guarantee safety margins despite untamed data inputs.

## Usage

### Compilation
The project requires the GNAT toolchain (Ada compiler). To compile the framework natively:
```bash
make all
