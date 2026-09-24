# Ada Mersenne Twister Implementation

## Project Overview
This project implements the Mersenne Twister pseudo-random number generator (PRNG) algorithm in the Ada programming language. Introduced in 1997 by Makoto Matsumoto and Takuji Nishimura, the Mersenne Twister provides rapid generation of high-quality pseudo-random integers and boasts a colossal period of $2^{19937}-1$.

## Features
- **MT19937 Variant (32-bit):** Standard implementation producing 32-bit unsigned integers.
- **MT19937-64 Variant (64-bit):** Native 64-bit extension of the algorithm.
- **Strong Typing:** Leverages Ada's strictly typed architecture and `Interfaces` module (`Unsigned_32` and `Unsigned_64`).
- **State Encapsulation:** Instances isolate their state arrays securely within record types, allowing parallel use of multiple PRNGs without cross-contamination.
- **Auto-Initialization:** Intelligently seeds with the algorithmic standard `5489` if numbers are extracted without explicitly calling `Init`.

## Testing 
To ensure robustness, reliability, and algorithmic accuracy, we utilize rigorous Verification and Validation (V&V) principles. The embedded test suite initially assumes the codebase is fundamentally broken; every test that **PASSES** systematically disproves this negative assumption.

### What the Tests Verify
*   **Functional Correctness (Reproducibility & Independence):** Asserts that equal seeds strictly emit exact identical sequences, and independent seeds never collide on initialization.
*   **Edge Cases (Zero Seed Handling):** Asserts that providing a seed of `0` does not mathematically lock the generator into an inescapable array of zeroes.
*   **Boundary Execution (State Wrapping):** Automatically validates the `Twist` procedure trigger conditions. Exhausting the initial N-degree array forces a re-computation. Testing triggers this wrap-around to ensure no Out-Of-Bounds exceptions or segmentation faults occur. 
*   **State Integrity (Isolation):** Validates that mutating one generator instance does not leak state data into a parallel instance.

### Why these Tests Matter
In simulations, procedural generation, and non-cryptographic security applications, corrupted statistical distribution or lack of determinism introduces catastrophic data degradation. By fulfilling V&V standards, we scientifically prove the Ada implementation correctly reflects the formalized mathematical requirements established by the algorithm's authors.

## Usage

### Compilation
Ensure you have an Ada compiler (like GNAT) installed. Compile the program using the included Makefile:
```bash
make all
