# Self-Organizing Map (SOM) - Ada 2023 Implementation

---

## Project Overview

This repository contains an Ada 2023 (ISO/IEC 8652:2023) implementation of the [Self-organizing map](https://en.wikipedia.org/wiki/Self-organizing_map) algorithm. The SOM is an unsupervised artificial neural network trained to produce a low-dimensional, discretized representation of an input space. This implementation supports both sequential/online learning (updating nodes incrementally after individual samples) and batch training (aggregating updates over the dataset per epoch), making it highly configurable for various clustering constraints.

---

## Features

- **Strong Typing Guarantees:** Built with custom indexing layers (`Feature_Index`, `Grid_X`, `Sample_Index`, `Data_Value`) rather than primitive floating/integer variants.
- **Dual Training Paradigms:**
  - *Online Learning:* Sequential per-sample map updates simulating real-time adaptability.
  - *Batch Learning:* Denominator-driven accumulated sample updates, offering deterministic layout resolution.
- **Gaussian Neighborhood Functions:** Both models utilize exponential space decay for node influence matrices, maintaining topographical continuity.
- **Contract-Oriented Architecture:** Embedded `Pre`, `Global` aspects, alongside strict explicit exception bubbling for dimensionality constraints and parameters.

---

## Usage

Because this module is designed as an underlying algorithm layer rather than a standalone CLI tool, usage is showcased through the comprehensive testing executable, which acts as API verification.

Run the module tests via Make:

```bash
make test
```

**Expected Output:** A systematic breakdown of 13 primary test structures containing \~40 assertions, culminating in:

```plaintext
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` test suite serves the dual role of algorithmic demonstration and robustness assurance. Categories covered:

- **Functional Correctness:** Ensures distance matrices evaluate accurately, dataset slicers align, and standard topological convergence behaves correctly.
- **Edge Cases:** Verifies spatial array offsets correctly map (e.g., `Vector (2 .. 4)` mapping against `Vector (1 .. 3)`).
- **Error Handling:** Deliberately forces exceptions (`Dimension_Mismatch`, `Empty_Dataset`, `Invalid_Parameters`) by feeding impossible geometries and learning values.
- **Invariants:** Uses functional checks dynamically generated from pre-conditions (such as avoiding mutation on inputs designed explicitly for `Find_BMU`).

---

## Building

To build and use the Self-Organizing Map package, you will need:

- **Compiler:** GNAT (GNU Ada Translator).
- **Ada Standard:** Ada 2022/2023 (`-gnat2022` flag handles full subset compatibility natively).

Use `make` or manually run:

```bash
gnatmake -gnatwa -gnat2022 -Pself_organizing_map.gpr
```
