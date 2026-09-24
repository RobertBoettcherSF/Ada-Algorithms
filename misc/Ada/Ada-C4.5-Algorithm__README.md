# C4.5 Algorithm (Decision Tree Classifier) in Ada 2023

---

## Project Overview

This project provides a complete, strongly-typed implementation of the **C4.5 algorithm decision tree classifier**, written purely in Ada 2023 (ISO/IEC 8652:2023). Based on the concepts described by Ross Quinlan, it leverages information entropy to construct robust classification models from both continuous and discrete dataset attributes.

---

## Features

- **Information Entropy &amp; Gain Ratio Calculations:** Mathematically handles Shannon entropy for optimal split selection.
- **Continuous Attributes:** Dynamically sorts and discovers optimal dataset thresholds (*A ≤ v*) internally.
- **Discrete Attributes:** Provides multi-way branching matching the original C4.5 specification.
- **Missing Values (`Build_Tree_Handle_Missing`):** Implements a C4.5 variant that routes records with missing feature data down majority consensus branches during inference/training.
- **Post-Pruning (`Build_Tree_Pruned`):** Supports bottom-up reduced-error pruning to collapse redundant subtree branches into majority-class leaves, reducing tree complexity and potential overfitting.

---

## Building

**Prerequisites:** GNAT compiler (supports Ada 2022/2023 standards).

To compile the standalone test suite natively:

```bash
make
```

---

## Usage and Testing

The project compiles to a standalone test executable that simultaneously acts as a rigorous unit test suite and a programmatic usage example.

Run the tests via Make:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
--- Starting C4.5 Algorithm Test Suite ---
TEST 1 — Entropy Calculations
  PASS — 1.1 Pure dataset entropy is 0.0
  PASS — 1.2 50/50 dataset entropy is 1.0
  PASS — 1.3 Even split 4 elements is 1.0
TEST 2 — Standard Tree Building (Base Cases)
  PASS — 2.1 Tree built from pure dataset classifies correctly
  PASS — 2.2 Handles unseen values purely
  PASS — 2.3 Tree destroyed successfully
...
===  39 passed,  0 failed ===
```

---

## Testing Categories Covered

- **Functional Correctness:** Verifies Shannon entropy mathematics and exact boundary evaluations on subsets.
- **Edge Cases:** Verifies single-element training sequences, datasets heavily laden with missing values, and attribute ties.
- **Error Handling:** Defends against uninitialized tree pointers preventing segmentation faults.
- **Invariants:** Proves that memory deallocation executes perfectly, regardless of node split types or tree depths.
