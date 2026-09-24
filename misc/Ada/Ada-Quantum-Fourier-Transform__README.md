# Quantum Fourier Transform (Ada 2023)

## Project Overview
This project provides a robust, expert-level Ada 2023 implementation of the Quantum Fourier Transform (QFT) and its principal algorithmic variants. The quantum Fourier transform is a linear transformation on quantum states and serves as the quantum analogue of the classical discrete Fourier transform, powering core quantum algorithms such as Shor's algorithm and quantum phase estimation.

## Features
- **Exact QFT**: Full state-vector simulation of the exact quantum Fourier transform.
- **Approximate QFT (AQFT)**: Circuit simulation variant truncating small phase gates beyond precision level $m$ ($O(n \log n)$ approximation).
- **Inverse QFT (IQFT)**: Hermitian adjoint transformation reversing the QFT.
- **Basis State QFT**: Direct mapping of individual computational basis states.
- **Strong Typing & Contracts**: Custom domain types (`Real_Type`, `Complex_Value`, `Qubit_Count`, `Precision_Level`) and Ada 2023 `Pre`/`Post` contract aspects ensuring safety and correctness.

## Usage
To build and run the test suite:
    make test

Expected output:
    Running tests...
    === Running Quantum Fourier Transform Test Suite ===
      PASS — 1.1 Output length is 2
      ...
      === 39 passed, 0 failed ===

To clean build artifacts:
    make clean

## Testing
The standalone test suite (`tests.adb`) verifies 13 distinct categories covering:
- **Functional Correctness**: Exact QFT on 1-qubit and multi-qubit states, basis state mapping.
- **Algorithm Invariants**: Unitarity (norm preservation) and linear superposition properties.
- **Variants**: Round-trip Inverse QFT, Full and Reduced Precision Approximate QFT.
- **Error Handling**: Invalid dimensions, out-of-range precision levels, and invalid basis state indices.
- **Helpers**: Power-of-two validation and qubit count extraction.

## Building
- **Prerequisites**: GNAT compiler supporting Ada 2023 (`-gnat2022`).
- **Build Flags**: `-gnatwa -gnat2022` (all warnings enabled, zero warning tolerance).
