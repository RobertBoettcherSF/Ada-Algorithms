# Linear-Feedback Shift Register (LFSR) in Ada

## Project Overview
This repository provides a complete, strongly-typed, and mathematically rigorous implementation of a Linear-Feedback Shift Register (LFSR) in Ada 2023. An LFSR is a shift register whose input bit is a linear function of its previous state. The implementation supports arbitrary register sizes between 2 and 64 bits and securely handles state encapsulation through Ada private types to preserve invariants.

## Features
* **Dual Variants:** Full support for both Fibonacci LFSR (standard feedback shifted into MSB) and Galois LFSR (in-place XORing, which offers parallel execution efficiency in hardware).
* **Strong Typing:** Utilizes strict, custom domain types for `Register_Value`, `Tap_Mask`, and `Register_Length` to eradicate arithmetic and boundary errors.
* **Ada Contracts:** Explicit `Pre`, `Post`, and `Global` annotations assert invariant compliance, guarding against zero-states and variant crossover.
* **Extraction Flexibility:** Obtain pseudorandom sequence values bit-by-bit or bundled as machine words via the `Next_Bits` routine.
* **Bounds Protection:** Secure initialization ensures starting seeds and masking taps never exceed the defined logical bit-length of the engine.

## Usage
No `main.adb` is required. The test suite, `tests.adb`, doubles as the API demonstration and usage executable. You interact with the package using the provided getters and stepper procedures:

```ada
with Linear_Feedback_Shift_Register; use Linear_Feedback_Shift_Register;
-- Create and seed Engine, then call Next_Bit or Next_Bits to generate output.
```

To run the built-in tests and execution demo:
`make test`

Expected output will be a stream of PASSED validations corresponding to constraints checking, expected states, parity calculations, and maximal length cycle counts.

## Testing
The `tests.adb` test suite achieves validation across four key categories:
1. **Functional Correctness:** Verifies expected sequence generation (state tracking step-by-step) and maximal cycle lengths ($2^n - 1$) for known polynomial constants.
2. **Edge Cases:** Proves correct handling of boundaries such as exactly 64-bit limits and extracting full 64-bit windows off much smaller internal cycles.
3. **Error Handling:** Actively expects exceptions and assertion failures on non-compliant initializations (e.g. `Seed = 0`, or taps extending beyond register length).
4. **Invariants:** Deliberately challenges type-contracts to guarantee that Fibonacci steps cannot run on Galois configurations (and vice-versa).

## Building
**Prerequisites:** GNAT Toolchain (Make, GNAT compiler)
**Standard:** Ada 2022/2023 (`-gnat2022` support).

Compile the project and run the standalone test executable via:
`make`
`make test`
`make clean` to remove artifacts.
