# Fast Fourier Transform (FFT) in Ada

## Project Overview
This repository contains a robust, type-safe implementation of the Cooley-Tukey Radix-2 Fast Fourier Transform (FFT) algorithm written in Ada. Built with critical system requirements in mind, it provides robust conversions of discrete signals between time and frequency domains.

## Features
Implemented variants of the FFT algorithm include:
- **Variant 1:** Recursive Cooley-Tukey Decimation-in-Time (DIT).
- **Variant 2:** Recursive Cooley-Tukey Decimation-in-Frequency (DIF).
- **Variant 3:** Iterative DIT featuring in-place Bit-Reversal.
- **Variant 4:** Inverse FFT (IFFT) derived accurately through signal conjugation.
- Helper functions to assert and handle Radix-2 constraint compliance safely.

## Testing & V&V Principles
We apply stringent Verification and Validation (V&V) principles. The initial pessimistic assumption is that the code is broken; the test suite is designed strictly to DISPROVE this assumption by forcing the logic through aggressive boundary scenarios, invariant checking, and mathematical proofs. 

### What The Tests Verify
1. **Edge Cases (Verification):** Checking 0-length and 1-length sequences to prevent runtime crashes and unnecessary computation.
2. **Error Handling (Verification):** Enforcing strict Radix-2 rules and validating that invalid array lengths gracefully raise the intended `FFT_Error` exception without causing hard crashes or segment faults.
3. **Functional Correctness (Validation):** Known input/output mapping (Impulse signals, DC, Nyquist waves) validating mathematical alignment.
4. **Consistency & Properties (Validation):** Proving that different implementations (Iterative vs DIF vs DIT) produce identical bitwise answers within float tolerance. Validates properties like Linearity and Parseval's Theorem (energy conservation).
5. **Performance / Scalability (Verification):** Verifying loss of precision does not cascade out of bounds for larger transforms (N=256).

### Why These Tests Matter
In critical or aerospace systems (where Ada heavily features), a malfunctioning signal processing algorithm could lead to systemic failures. Guaranteeing mathematical invariants (like IFFT(FFT(x)) == x and Parseval's Energy Theorem) proves the algorithm strictly aligns with physics and mathematical law, ensuring absolute reliability.

## Usage

### Compilation
The codebase provides both a GNAT project file (`fft_project.gpr`) and a `Makefile`. Everything builds seamlessly in the root directory.
```bash
make all
