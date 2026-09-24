# Ada 2023 Perceptron Implementation

---

## Project Overview

This repository provides a highly robust, zero-warning Ada 2023 implementation of the classic **Perceptron algorithm** for machine learning, based on its formal definition. It handles dynamic dimensionality out-of-the-box and features heavily enforced type safety and bounds checking through Ada preconditions.

---

## Features

- **Standard Perceptron:** The classic online error-driven learning rule.
- **Pocket Algorithm:** Maintains the longest sequential run of correct classifications (best for non-separable/noisy datasets), ensuring that performance never artificially crashes after encountering a noisy example.
- **Averaged Perceptron:** Eliminates oscillations by projecting predictions against a stable running average of all weight iterations across the entire model's lifecycle.
- **Robust Type Constraints:** Utilizes custom types (`Real`, `Matrix`, `Vector`) and dynamic predicate verification on classifications (+1, -1 only).
- **Zero Dependencies:** Relies exclusively on core language and basic `Text_IO`.
- **Zero Compilation Warnings:** Complies fully under `-gnatwa`.

---

## Building

**Prerequisites:** GNAT Compiler supporting Ada 2022/2023 (`gnatmake`).

```bash
make
```

---

## Usage &amp; Testing

A standalone functional test application serves dual purposes: verifying structural logic safely and demonstrating immediate API usage examples.

```bash
make test
```

---

## Testing Capabilities

The suite implements 14 test profiles with 53 assertions, exercising:

- **Functional Correctness:** OR gate and AND gate linear separation tasks.
- **Noisy/Inseparable Data Resolution:** XOR gates ensuring model safety in non-ideal real-world distributions.
- **Precondition Contract Validation:** Asserting safe aborts on tensor/dimension mismatches.
- **Edge Handling:** Parameters such as zero-value and illegal negative learning rates.
