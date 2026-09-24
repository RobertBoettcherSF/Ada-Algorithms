# Radial Basis Function Network (Ada 2023)

---

## Project Overview

This project provides a robust, strongly typed Ada 2023 (ISO/IEC 8652:2023) implementation of a **Radial Basis Function Network (RBFN)**. An RBFN is an artificial neural network that uses radial basis functions as activation functions. The output of the network is a linear combination of radial basis functions of the inputs and neuron parameters. This implementation encapsulates initialization, activation scaling, standard vs. normalized evaluation strategies, and comprehensive error handling.

---

## Features

- **Multiple RBF Variants:** Includes native support for `Gaussian`, `Multiquadric`, `Inverse_Quadratic`, and `Inverse_Multiquadric` activation functions.
- **Normalization Strategy:** Supports Normalized Radial Basis Function Networks (NRBFN), which divides each activation by the sum of all activations to provide probability-like weighting.
- **Strong Typing:** Leverages Ada's domain typing (e.g., `Distance`, `Shape_Parameter`, `Dimension_Index`) to eliminate errors common in untyped numeric floating-point vectors.
- **Rigorous Contracts:** Uses Ada 2012/2022 `Pre`, `Post`, and `Global` contracts to formalize mathematically valid state constraints and zero side-effects.

---

## Usage

The package acts as a standalone library that can be instantiated and queried. The provided `tests.adb` program serves as an executable usage example as well as the test suite.

To execute the suite:

```bash
make test
```

**Expected Output:**  
The build environment will create necessary object folders and compile cleanly with zero warnings under `-gnatwa`. When run, it outputs the results of 13 separate test categories with 3+ assertions each, concluding with:

```plaintext
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` test suite focuses heavily on verification and validation. Categories covered include:

- **Functional Correctness:** Ensures Euclidean distances are accurate to 15 decimal digits, and tests each mathematical Activation type against manually calculated analytical baseline values.
- **Error Handling:** Intentionally induces failures by passing inputs with mismatched tensor shapes to verify robust detection and precise exception raising (`Dimension_Mismatch_Error`).
- **Edge Cases:** Analyzes extremely small topologies (e.g., a 1-center, 1-feature network) and detects floating-point underflow scenarios that uniquely plague Normalized networks (`Normalization_Error`).
- **Invariants:** Validates array bounds mappings across dynamic record discriminants during instantiation.

---

## Building

**Prerequisites:** GNAT (Ada compiler).

The compilation leverages the `-gnat2022` flag to utilize the latest features recognized by the Ada 2023 (ISO/IEC 8652:2023) standard.

```bash
make all    # Builds the binary
make clean  # Removes generated objects and binaries
```
