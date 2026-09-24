# Entropy Encoding Algorithms in Ada

## Project Overview
This repository implements core **Entropy Encoding** algorithms, which are lossless data compression schemes that assign code lengths matching the probabilities of symbols. Written in Ada, this project guarantees strong typing, memory safety, and stringent validation protocols suitable for mission-critical integration. 

## Features
- **Huffman Coding**: An optimal prefix code algorithm building trees bottom-up.
- **Shannon-Fano Coding**: A suboptimal, top-down recursive splitting prefix code variant.
- **Arithmetic Coding**: A continuous interval probability encoder (implemented via floating-point variables to demonstrate theoretical structure).
- **Core Engine**: Lossless `Encode` and `Decode` pipelines designed strictly for binary strings.
- Robust boundary guards to block buffer underflows/overflows.

## Testing (Verification and Validation - V&V)
Adhering to strict V&V principles, the test suite operates on the **assumption that the codebase is completely broken**. A test passes *only* when it mathematically disproves this negative assumption.

### What We Verify
1. **Functional Correctness**: Asserting encoding pipelines (`Encode()` -> `Decode()`) are 100% lossless for discrete Prefix variations (Huffman, Shannon-Fano). Proves the fundamental logic meets algorithm specification.
2. **Error Handling**: Feeding broken or truncated bitstreams (`1021`, missing tails) to verify the decoder isolates failures rather than succumbing to runtime crashes.
3. **Edge Cases**: Inputting single-symbol arrays (e.g., `"AAAA"`) verifying the mathematical graphs handle extreme lack of variance cleanly.
4. **Precision/Performance Limits**: Overloading the Arithmetic encoder with high-entropy long-strings explicitly to trigger and catch `Arithmetic_Overflow`, ensuring floating-point precision constraints are safely bounded.

### Why Tests Matter
In safety-critical systems, it isn't enough that a program "usually compresses" data. The system must fundamentally guarantee that corrupt bitstreams will not exploit memory, and that decoded payloads match the exact byte-structure of the original data. These tests guarantee reliability and safety, proving the module is deterministic.

## Usage
The system does not rely on a source directory (`src/`). All components compile securely from the root filesystem.

### Compilation
Ensure you have the GNAT compiler installed, then use the provided Makefile:
```bash
# Compiles both main execution program and the test suite
make all
