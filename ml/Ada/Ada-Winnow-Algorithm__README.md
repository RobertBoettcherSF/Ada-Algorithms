# Ada Winnow Algorithm Implementation

## Project Overview
This repository contains a robust, strongly-typed Ada implementation of the **Winnow algorithm**—a linear classifier machine learning algorithm originally developed by Nick Littlestone. The algorithm is similar to the perceptron but leverages a multiplicative weight-update scheme, making it exceptionally effective in scenarios with a vast number of features where only a few are genuinely relevant (e.g., text classification).

## Features
- **Standard Winnow Model (Winnow1):** The primary multiplicative weight update scheme where weights are promoted or demoted based on an adjustable `Alpha` multiplier upon encountering False Negatives and False Positives.
- **Balanced Winnow Variant:** An alternative implementation retaining two weights per feature (positive and negative). It evaluates symmetric updates which is superior for datasets containing structurally negative evidence.
- **Tunable Parameters:** Supports fully parametric configuration of the `Alpha` learning rate and `Threshold` boundaries.
- **Strong Safety Typing:** Features are constrained strictly to binary values (`range 0 .. 1`), delegating out-of-bounds error handling directly to Ada's inherent type-safe compiler constraints.

## Testing
This repository rigorously adheres to **Verification & Validation (V&V)** principles crucial for critical systems, ensuring the implementation strictly meets theoretical requirements and operates robustly under duress.

### The Test Philosophy
The test suite (`tests.adb`) explicitly adopts a *pessimistic assumption strategy*. It approaches the codebase assuming it is intrinsically broken (e.g., "Assume boundary checks fail"). Tests only output **PASS** when they successfully disprove this assumption, conclusively proving correct programmatic behavior.

### What is Verified?
The test suite consists of 13+ distinct terminal-executable tests mapping across four categories:
1. **Functional Correctness:** Verifies algorithmic math calculations (multiplicative promotion/demotion matches Alpha scaling precisely).
2. **Error & Edge Case Handling:** Proves the system gracefully traps vectors of mismatched lengths and categorically rejects invalid configurations (like `Alpha <= 1.0`).
3. **Variant Consistency:** Checks that the symmetric updates within the Balanced Model perform their split mathematics accurately. 
4. **Machine Learning Convergence:** Validates the entire predictive pipeline by dynamically training models to mimic standard boolean logic gates (OR, AND) over several epochs. 

### Why These Tests Matter
By structurally validating that inputs cannot overflow memory (via index-matching checks) and that weights behave mathematically deterministically, these tests guarantee that this algorithm is safe to embed inside high-reliability software architectures.

## Usage
### Compilation 
Ensure you have the GNAT Ada compiler installed. The repository operates from a flat directory structure without a `src/` folder layout. 

You can build the project natively utilizing the provided `Makefile`:

```bash
make all
