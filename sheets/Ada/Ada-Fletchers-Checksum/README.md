# Fletcher's Checksum (Ada Implementation)

## Project Overview
This repository contains a robust, statically typed Ada implementation of the **Fletcher's Checksum** algorithm. Originally developed by John G. Fletcher at Lawrence Livermore Labs in the late 1970s, this algorithm approaches the error-detection capabilities of a CRC while maintaining the minimal computational overhead of a simple summation. 

This repository implements exact bit-width structures representing Fletcher calculations over 8-bit, 16-bit, and 32-bit data streams.

## Features
* **Fletcher-16 Naive:** Byte-wise processing with immediate modulo-255 scaling.
* **Fletcher-16 Optimized:** Performance-focused routine that clusters calculations into 5000-byte chunks to avoid modulo arithmetic overhead, strictly avoiding integer overflow.
* **Fletcher-32:** Word-wise (16-bit) processing scaled against modulo-65535.
* **Fletcher-64:** Double-word (32-bit) processing scaled against modulo-4294967295.
* **Check Byte Generator:** A helper algorithm that generates two validation bytes. When appended to the raw data block, evaluating the new array will successfully equate to `0`.

## Testing 

This codebase follows rigorous **Verification and Validation (V&V)** principles. The testing philosophy actively attempts to disprove the baseline assumption that the code is non-functional or broken.

Tests evaluate:
1. **Functional Correctness (Equivalence Partitioning):** Validating the implementation logic accurately meets the Wikipedia algorithm definitions (e.g., verifying mathematical correctness against the 'abc' vector).
2. **Robustness & Edge Cases:** Defending against Boundary Value complications like passing completely empty arrays, and arrays entirely saturated with max modular limits (e.g., sequences of `255`, `65535`).
3. **Performance Optimization Correctness:** The tests algorithmically confirm that the optimized chunk-loop implementations output identical checksums as their slower mathematical counterparts regardless of array length.
4. **Validating Data Integrity Mechanics:** Dynamically appending check bytes and formally validating that it forces the final algorithmic output to evaluate strictly to 0, ensuring safety guarantees for checksummed data streams in communications systems.

## Usage

### Compilation
Ensure you have the GNAT Ada toolchain installed. To build the project, run:
```bash
make all
