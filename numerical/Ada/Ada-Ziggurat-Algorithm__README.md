# Ada Ziggurat Algorithm Engine

## Project Overview
This repository contains a high-performance Ada implementation of the **Ziggurat Algorithm**, a mathematically exact rejection sampling method invented by George Marsaglia. This engine handles the generation of non-uniform random numbers from fundamentally robust geometric distributions. 

## Features
- **Strictly Typed Architecture**: Evaluated natively under a `digits 15` high-precision `Real` type constraint.
- **Normal Distribution Variant**: Calculates exact Normal distributions (mean 0.0, sigma 1.0) using 256 rectangular layers.
- **Exponential Distribution Variant**: Calculates exact Exponential distributions using an adapted 256-layered array.
- **Internal PRNG State**: Implements a dedicated lightweight `XorShift64` integer generator to ensure platform-agnostic bit determinism, crucial for testing and simulation reproducibility.
- **Automated Tables**: Generates boundary limits dynamically upon elaboration.

## Testing & V&V (Verification and Validation)
Our test suite executes from a pessimistic stance: **We assume the engine is broken.** 

To prove correctness, the tests implement rigid statistical and boundary boundaries spanning functional logic, error handling, performance bounds, and extreme mathematical limits.
- **Functional Correctness**: Assertions evaluate statistical outputs matching true Mean and Variance metrics (e.g. Normal mean `0.0`, Variance `1.0`) ensuring the math mirrors the theoretical specifications.
- **Edge Cases & Error Handling**: Traces limit behavior. A faulty engine would fail generation at the Marsaglia Tail bounds; we mandate proof of continuous boundary generation beyond threshold lines like `x > 3.654`. 
- **Robustness**: Verifies the internal PRNG prevents divide-by-zero occurrences and does not trigger exceptions under extreme, continuous loads (Tested via `1,000,000` immediate continuous computations).

By successfully printing `PASS`, the 13-test array mathematically invalidates our initial assumption, providing empirical Verification (the code meets math specifications) and Validation (the codebase is safe for end-system deployment).

## Usage

### Compilation
The project requires a GNAT Ada compiler. It uses a standalone `Makefile` routing output seamlessly to separated `/bin` and `/obj` directories without complicating the root filesystem. 

Compile everything utilizing:
```bash
make
