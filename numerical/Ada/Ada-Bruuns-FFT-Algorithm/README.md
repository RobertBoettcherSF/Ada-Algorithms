# Bruun's FFT Algorithm - Ada Implementation

## Project Overview
This project provides a critical-system-ready Ada implementation of Bruun's Fast Fourier Transform (FFT) algorithm. Originally proposed by G. Bruun in 1978, this variant utilizes an unusual recursive polynomial-factorization approach that relies exclusively on real coefficients until the final stage. The codebase includes strictly-typed support for power-of-two optimizations and H. Murakami's 1996 generalization for arbitrary even composite lengths.

## Features
- **Power-of-Two Real FFT (`FFT_Power_Of_Two_Real`)**: Conceptually mirrors Bruun's original 1978 factorization specifically aimed at real-valued data sets.
- **Power-of-Two Complex FFT (`FFT_Power_Of_Two_Complex`)**: Expands the polynomial tree to accommodate standard complex signal sequences.
- **Arbitrary Even Composite FFT (`FFT_Arbitrary_Composite`)**: Support for non-power-of-two composite signals, applying Murakami's generalized radix reductions.
- **Strict Boundary Defenses**: Explicit constraint checking ensuring mathematical singularities and memory overflows cannot occur in production.

## Testing (Verification & Validation)
This codebase is subjected to strict **Verification and Validation (V&V)** testing via an aggressive 14-assertion suite. We approach testing with a pessimistic baseline: *we assume the codebase is intrinsically flawed, algebraically misaligned, or leaking memory.* Tests are designed such that a `PASS` strictly disproves a specific failure state.

### What Each Test Category Verifies
1. **Functional Correctness:** Asserts expected properties against empirical math (e.g., DC summation, Conjugate Symmetry).
2. **Error Handling & Safeties:** Intentionally pushes illicit parameters (e.g., odd composites, $N=0$) to ensure exceptions trigger, avoiding silent hardware fault traps.
3. **Edge Cases:** Evaluates extreme mathematical edge conditions, such as Delta impulses, to ensure no $1/0$ limits cause floating-point failure.
4. **Physical & Mathematical Conservation:** Validates Linearity (superposition applies cleanly) and Parseval's Theorem (time energy perfectly equates to frequency energy).

### Why These Tests Matter
In safety-critical avionics or heavy-machinery DSP, an FFT isn't just a math library—it forms the sensory input. A subtle floating point divergence or boundary alias can lead to catastrophic filter misinterpretation. By demanding proofs for Parseval's Theorem and superposition, we guarantee physical conservation laws rather than just matching a couple of happy-path outputs.

## Usage

### Compilation
Ensure your environment has `gnatmake` installed, then compile directly from the root directory:
```bash
make all
