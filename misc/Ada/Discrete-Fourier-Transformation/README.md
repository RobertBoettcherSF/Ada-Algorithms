# Discrete Fourier Transform (DFT) in Ada

## Project Overview
This repository provides a strict, mathematically robust implementation of the Discrete Fourier Transform (DFT) algorithm in Ada. It accurately transforms temporal/spatial domain signals into the frequency domain, fulfilling the rigid requirements of critical signal processing applications without relying on external mathematical abstraction layers outside of the standard Ada Numerics library.

## Features
The `Discrete_Fourier_Transform` package implements the following mathematical variants based on their standard mathematical definitions:
* **Forward 1D DFT:** Standard base implementation.
* **Inverse 1D DFT (IDFT):** Exact inverse recovery featuring $1/N$ scaling.
* **Unitary Forward/Inverse 1D DFT:** Symmetric normalization variants using $1/\sqrt{N}$ scaling to ensure strict energy conservation.
* **Real-Valued Forward 1D DFT:** Optimized wrapper natively handling `Float` input pipelines.
* **Multidimensional (2D) Forward DFT:** Handles spatial frequency extraction for matrix forms (e.g., image data).

## Testing (Verification & Validation)
Testing operates on a pessimistic **V&V constraint framework**: the codebase is continuously assumed to be faulty or non-compliant until a test explicit disproves this assumption (a `PASS` state).

### What Each Category Verifies:
1. **Functional Correctness (Identity Tests):** Assumes inverse transforms are lossy. Tests like the "Bi-directional Identity" prove that applying a DFT followed by an IDFT identically reconstructs the original signal without data destruction.
2. **Mathematical Theorems:** Assumes the transforms leak signal energy. Validated by enforcing Parseval's Theorem constraint (`TEST 14`) on the Unitary DFT, proving `Energy(Time) == Energy(Frequency)`.
3. **Edge Case Safety:** Assumes 0-length sequences will crash the system (e.g., division by zero). Tests inject 0-length 1D and 2D bounds to assert safe constraint deflection (`Empty_Array_Error`).
4. **Physical Properties:** Assumes logical symmetry is broken. Evaluated by feeding real-valued constraints and verifying mathematical conjugate symmetry in the outputs (`X(k) = X*(N-k)`).

### Why These Tests Matter:
In V&V standards for critical systems (e.g. avionics radar data analysis), signal processing anomalies directly induce critical hardware faults. By aggressively testing boundary invariants rather than just "happy paths", we guarantee reliability, algorithm safety, and strict memory safety. 

## Usage

### Compilation
The project utilizes the GNAT toolchain and requires no external packages.

Build using `make`:
```bash
make all
