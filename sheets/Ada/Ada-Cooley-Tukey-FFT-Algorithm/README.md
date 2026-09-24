# Cooley-Tukey Fast Fourier Transform (FFT) in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Cooley-Tukey Fast Fourier Transform algorithm (Radix-2 Decimation-in-Time). The Cooley-Tukey algorithm is the most common FFT algorithm, drastically reducing the computational complexity of the Discrete Fourier Transform (DFT) from $O(N^2)$ to $O(N \log N)$. 

## Features
- **Radix-2 DIT FFT (Recursive):** A classic, top-down divide-and-conquer implementation.
- **Radix-2 DIT FFT (Iterative):** A high-performance, bottom-up implementation utilizing in-place butterfly operations to avoid function call overhead.
- **Bit-Reversal Permutation:** An optimized helper procedure for pre-sorting arrays in the iterative variant.
- **Inverse FFT (IFFT):** Computes the inverse transform safely returning signals from the frequency domain back to the time domain.
- **Strong Typing:** Utilizes native `Ada.Numerics.Complex_Types` to ensure numerical correctness.

## Testing (Verification and Validation)
Safety-critical systems built in Ada require stringent Verification & Validation (V&V). The testing philosophy assumes the code is *broken* and requires tests to definitively prove otherwise (Assumption Falsification).

### What the Tests Verify
Our 13+ assertion suite categorizes tests to ensure thorough coverage:
1. **Functional Correctness:** Verifies behavior of DC signals, single impulses, and Nyquist frequencies (Tests 4-9).
2. **Mathematical Constraints:** Asserts Parseval's Theorem—verifying energy conservation between time and frequency domains (Test 13).
3. **Data Pre-processing:** Ensures the bit-reversal algorithm swaps correct memory locations unconditionally (Test 3).
4. **Boundary & Error Handling:** Validates array sizing requirements (powers of two) and confirms that safe boundaries trigger predictable `Invalid_Size_Error` exceptions rather than buffer overflows (Tests 1, 2, 10, 11).
5. **Reversibility Validation:** Asserts that applying FFT followed by IFFT yields the exact original data structure (Test 12).

### Why These Tests Matter
In V&V, *Verification* checks that the code behaves per the specification (e.g., $O(N \log N)$ Radix-2 strict requirements). *Validation* checks that the implementation solves the real-world problem accurately (e.g., handling complex floating-point inaccuracies through epsilon tolerance). Proving safety boundaries ensures that system resources aren't corrupted by non-compliant arbitrary data input.

## Usage

### Compilation
The project requires a GNAT Ada compiler. It uses a flat directory structure.

To compile the primary application and the test suite:
```bash
make
