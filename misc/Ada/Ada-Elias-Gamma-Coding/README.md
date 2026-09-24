# Elias Gamma Coding Algorithm in Ada

## Project Overview
This project implements the **Elias Gamma Coding** algorithm in Ada. It is a universal code primarily used to encode strictly positive integers whose upper bound cannot be determined beforehand. 

In addition to the standard positive-integer coding algorithm, this library implements all common extensions mentioned in the formal definition to encode non-negative integers (zero-inclusive) and all integers (negative and positive) using safe bijective mapping.

## Features
* **Standard Elias Gamma Coding:** Encodes/Decodes strictly positive integers ($x \ge 1$).
* **Zero-Extended Variant:** Encodes/Decodes non-negative integers ($x \ge 0$) by implicitly shifting the value by +1.
* **Full Integer Variant:** Encodes/Decodes all integers by utilizing a safe bijection: mapping $0 \to 1$, positive numbers to even integers ($2x$), and negative numbers to odd integers ($-2x + 1$).
* **Strong Typing:** Utilizes an opaque, strongly-typed `Elias_Bit_Stream` record wrapper. This guarantees type safety—preventing developers from accidentally passing an arbitrary `String` of binary data directly into the decoder without passing through the constructor's validation routines.

## Testing (V&V Principles)
The test suite (`tests.adb`) takes a strictly pessimistic approach by assuming the code is broken or error-prone. Tests **PASS only when they disprove this assumption** by demonstrating expected correct behavior or intentional safe-failure (exceptions) during boundary conditions.

The suite contains over 15 distinct assertions focused on standard software Verification and Validation (V&V) standards:
* **Verification (Does the code match requirements?):** Tests strictly follow the mathematical definitions of the Elias Gamma transformations. (e.g., verifying that $9$ correctly translates to bits `"0001001"`, matching the specific equation $N = \lfloor\log_2(X)\rfloor$).
* **Validation (Does the code meet its intended use safely?):** Tests ensure the library will gracefully fail and reject corrupted bitstreams in production instead of causing memory corruption or infinite loops.

### Test Categories
1. **Functional Correctness (Base Cases):** Proves encoding and decoding mathematically match for values like $1$, $9$, and $512$ using standard formulas.
2. **Bijection / Variant Integrity:** Ensures that mapping negative constraints ($0$, $-1$, $1$) strictly produces the correct intermediary integers required to sustain the bounds without data loss.
3. **Robustness & Error Handling (Negative Tests):** Specifically injects broken, truncated, empty, and illegal bit streams. These tests verify the code protects the system by safely triggering an explicit `Invalid_Bit_Stream` exception rather than attempting out-of-bounds array reads.

## Usage

### Compilation
The codebase uses a simple Makefile to wrapper GNAT compilation commands. Run:
```bash
make all
