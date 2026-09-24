# Arithmetic Coding (Ada Implementation)

## Project Overview
This repository contains a robust Ada 2012 implementation of the **Arithmetic Coding** algorithm for lossless data compression, as described in theoretical and practical literature (e.g., Witten, Neal, and Cleary 1987). It represents messages as sub-intervals in $[0, 1)$ rather than separating them into distinct bits.

## Features
- **Static Arithmetic Coding:** Compresses data using a pre-computed frequency model that must be provided to both the encoder and decoder.
- **Adaptive (Dynamic) Arithmetic Coding:** Dynamically updates symbol frequencies as the data stream is processed, requiring no prior knowledge of the data distribution.
- **Robust Integer Rescaling:** Uses 32-bit state registers with 64-bit intermediate calculations. This prevents overflow/underflow precision issues inherent to standard floating-point implementations, allowing encoding of arbitrarily long files.
- **Dynamic Capacity Management:** Adaptive models automatically halve frequencies when approaching integer limits to guarantee mathematical stability.
- **Strong Typing & Edge Case Handling:** Custom discrete types for streams, with strictly enforced exception handling for empty inputs and unmodeled data limits.

## Testing (Validation & Verification)

This project adopts a rigorous **Validation and Verification (V&V)** testing philosophy. Our baseline assumption is that *the code is non-functional, insecure, and fails at critical boundaries*. The test suite is designed to aggressively attempt to prove this assumption. A test "PASS" explicitly means that the negative assumption was mathematically or logically disproven.

### What the test categories verify:
1. **Functional Correctness:** Asserts that `decode(encode(data)) = data`. Verifies algorithm state behaves deterministically, proving data is not lost or corrupted during transit.
2. **Error Handling:** Asserts that passing unmodeled symbols or malformed structures explicitly raises anticipated, handled Exceptions (e.g., `Invalid_Symbol_Error`) rather than causing invisible state corruption or buffer overflows.
3. **Edge Cases:** Asserts algorithm stability on limits like homogeneous strings (interval collapse), 0-length strings, and truncated bit-streams. 
4. **Performance & Boundaries:** Asserts frequency bounds halving. Standard adaptive models overflow basic integer limits on long data streams. The test suite aggressively pushes strings of sizes meant to trigger these limits, disproving the assumption that the memory constraints are poorly scaled.

### Why these tests matter:
In critical systems architecture (where Ada excels), mathematical compression cannot fail silently. Validating state scales safely and verifying the correct rejection of bad data ensures safety, reliability, and correctness per rigorous software V&V standards.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. Compile the project using `gnatmake` and the included GPR file, or simply use `make`:

```bash
make
