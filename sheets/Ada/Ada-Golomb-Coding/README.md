# Ada Golomb Coding Algorithm

## Project Overview
This repository provides a strongly-typed, standalone Ada implementation of the **Golomb Coding algorithm**, a lossless data compression technique based on entropy coding. The program splits input integers into a quotient (encoded using unary coding) and a remainder (encoded using truncated binary encoding) using a tunable parameter *M*.

## Features
*   **Standard Golomb Coding**: Fully implements handling of parameter $M$, utilizing truncated binary logic for non-power-of-two parameters.
*   **Rice Coding Variant**: Implements the special case where $M = 2^K$, allowing high-performance fallback to standard bit-packing for the remainder.
*   **Signed Integer Variant**: Implements Zig-Zag mapping to compress negative integer bounds seamlessly ($0\to0$, $-1\to1$, $1\to2$, etc.).
*   **Safety Thresholds**: Enforces strong types, throwing clear `Invalid_Bit_String` exceptions to avoid arbitrary undefined behavior.

## Testing
This software is built around robust **Verification & Validation (V&V)** principles. The test suite is authored under the assumption that the implementation is fundamentally flawed. Tests passing disprove these assumptions, proving empirical system safety.

### What is verified:
1.  **Functional Correctness**: Ensures equations mathematically translate (e.g., $M=10, N=42 \to 11110010$). Proves mathematical translation from theoretical constraints (Verification).
2.  **Boundary & Edge Cases**: Evaluates extreme states like $N=0$ or $M=1$ (pure unary encoding) and verifies Zig-Zag boundaries (-1 and positive limits). Proves operational limits handle extremes without data loss (Validation).
3.  **Error Handling (Negative Testing)**: Checks resilience by intentionally supplying garbage strings, padded bit-streams, and cleanly missing stop-bits. Validates `Invalid_Bit_String` captures state faults to prevent application panics.
4.  **Buffer Exhaustion**: Tracks bit consumption accurately ensuring payload chunking ignores padded binary headers effectively.

### Why these tests matter:
In critical systems written in Ada, memory corruption or silent decoding mutations are unacceptable. The suite confirms that unhandled bit conditions deterministically abort rather than silently failing, satisfying reliability and safety standards critical to mission-ready code. 

## Usage
The system utilizes the GNAT toolchain. The layout is flattened into a root directory architecture.

### Compilation
Compile the project using the provided Makefile:
```bash
make
