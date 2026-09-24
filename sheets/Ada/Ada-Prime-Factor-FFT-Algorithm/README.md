# Prime-Factor FFT Algorithm

## Project Overview
This repository contains a robust Ada 95/2012 implementation of the **Prime-factor FFT algorithm** (also known as the Good-Thomas algorithm). It transforms 1D time-domain signals into their frequency-domain representations by leveraging the Chinese Remainder Theorem (CRT) to map a 1D array into a 2D matrix. Unlike the Cooley-Tukey FFT, the Prime-factor algorithm relies on factors that are strictly coprime ($\gcd(N_1, N_2) = 1$) and completely eliminates the need for computational "twiddle factors".

## Features
* **Modular Math Dependencies**: Implements internal Extended Euclidean and Modular Inverse algorithms natively.
* **Naive DFT Fallback Base**: Used internally as the fundamental sub-transform for $N_1$ and $N_2$ length slices.
* **Out-of-Place Good-Thomas PFA Variant**: Provides isolated mappings that leave the source data unmodified (`PFA_Transform`).
* **In-Place PFA Variant**: Includes a footprint-compatible constrained interface (`PFA_Transform_In_Place`).
* **Inverse Transforms**: Full reversibility logic (scaling and sign inversion) natively implemented inside all variants.

## Testing 

This repository heavily prioritizes Verification & Validation (V&V) standards critical for scientific and hard-real-time safety codebases. A dedicated testing harness actively assumes the code is functionally incorrect. The suite outputs a PASS *only* when the execution actively disproves this negative assumption across math, function correctness, boundaries, and errors.

### What the test category verifies:
1. **Functional Correctness (Tests 1-3, 6-9, 12, 13)**: Proves that outputs identically match the mathematically expected answers (e.g., $N=6$ and $N=15$ compared against the textbook Naive $O(N^2)$ algorithm). Ensures Inverse matrices exactly recover pre-transform signals.
2. **Error Handling & Robustness (Tests 4, 5, 11)**: Actively feeds the system non-coprime inputs ($\gcd(N_1, N_2) \neq 1$) and bounds mismatch states, mandating that the environment throws constrained `Invalid_Factors` exceptions instead of undefined segfaults.
3. **Variant Matching (Tests 10, 11)**: Proves the in-place and out-of-place variants do not diverge mathematically across different system state memory layouts.

### Why these tests matter:
In aerospace, DSP routing, or embedded contexts, improper memory mapping or unhandled mathematical limitations (such as missing common-factor constraints) result in catastrophic system failure. The V&V layout formally guarantees that mathematically valid inputs process stably, and invalid states fail gracefully, ensuring determinism.

## Usage

### Compilation
The codebase uses `gnatmake` and a bundled GNAT Project file (`.gpr`). 
A GNU `Makefile` handles directory creation and execution.

Compile the main executable and the test harness by typing:
```bash
make all
