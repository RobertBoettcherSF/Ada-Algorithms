# Mechanistic Interpretability in Ada 2023

## Project Overview
This repository provides a strongly-typed, contract-driven Ada 2023 implementation of core algorithms utilized in Mechanistic Interpretability. Mechanistic interpretability is the study of reverse-engineering neural networks into human-understandable algorithms. This package models key theoretical mechanisms including dictionary learning (Sparse Autoencoders), causal tracing via activation patching, and circuit-level abstraction through induction head simulation.

## Features
* **Dictionary Learning (Sparse Autoencoders):** Encode_SAE and Decode_SAE variants mapping dense neural activations into a sparse, interpretable high-dimensional feature space.
* **Activation Patching:** A causal tracing mechanism to patch clean network activations with corrupted counterfactual ones across user-defined masks.
* **Induction Head Circuit Analysis:** Simulation of an attention circuit mechanism that learns algorithmic in-context copying and next-token prediction.
* **Superposition Detection:** Evaluates polysemanticity to verify whether a network represents more independent orthogonal features than its baseline dimensionality.
* **Ada 2023 Contracts:** Uses Pre and Post conditions to strictly guarantee tensor shape and dimensional alignment.

## Usage
Run the following commands to build and run the test suite:

make test

Expected output confirms zero failures across all verification scenarios:

TEST 1 -- Linear Transform Basics
  PASS -- 1.1 Vector dimension preserved
  PASS -- 1.2 First element matches expected value
  PASS -- 1.3 Second element matches expected value
...
=== 39 passed, 0 failed ===

To remove build artifacts:

make clean

## Testing
The standalone test suite (tests.adb) doubles as executable documentation and validates the implementation across multiple verification and validation categories:
* **Functional Correctness:** Verifying linear projection transformations, non-linear activations (ReLU), and symmetric dictionary reconstruction error calculation.
* **Causal Intervention:** Validating selective activation swapping using full, null, and mixed boolean patching masks.
* **Polysemanticity & Superposition:** Verifying the mathematical thresholding that identifies when representation count exceeds geometric dimensionality.
* **Circuit Dynamics:** Verifying sequential state evaluation and prefix matching in induction heads across single-element, multi-token, and recurring-token sequences.
* **Contract Invariants & Bounds:** Deliberately testing dimensional mismatches (e.g., matrix-vector dimension disagreement) to ensure Ada contract assertions trap violations before execution.

## Building
* **Prerequisites:** GNAT compiler toolchain supporting modern Ada standards (GNAT Pro or FSF GNAT).
* **Language Standard:** Ada 2023 (ISO/IEC 8652:2023) enforced via the -gnat2022 compiler switch.
