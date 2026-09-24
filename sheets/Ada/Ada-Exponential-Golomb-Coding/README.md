# Exponential-Golomb Coding in Ada

## Project Overview
This repository provides a strict, type-safe Ada implementation of the Exponential-Golomb coding algorithm. It is a universal code used primarily for compressing parameters in data streams, and serves as the backbone for entropy coding in video codecs like H.264/AVC and Dirac.

## Features
The codebase encompasses all primary mathematical variants of the algorithm as specified by its standard structural definitions:
- **Order-0 Unsigned (`ue(v)`)**: The base exponential-Golomb encoding format.
- **Order-k Unsigned**: A variant incorporating a configurable shift remainder for specialized distributions.
- **Order-0 Signed (`se(v)`)**: Contains a zigzag mapping step that allows negative numbers to be natively encoded using the unsigned foundation.
- **Order-k Signed**: Combines both the order-k shift behavior with signed zigzag mapping.

## Testing
The test suite utilizes rigorous Validation & Verification (V&V) methodologies, ensuring correctness against a strictly pessimistic assumption model (i.e. we start by assuming the logic is structurally flawed, and every passing test forces a falsification of that assumption).

### What Each Category Verifies
1. **Functional Correctness (Tests 1-11):** Ensures standard behavior perfectly matches expected output streams. It validates mathematical transformations natively against edge numbers (0, positive bounds, negative mapping logic).
2. **Boundary/Edge Cases (Test 5):** Ensures behavioral uniformity (e.g., verifying that computing an Order-K parameter where K=0 mathematically defaults back to an Order-0 state flawlessly).
3. **Robustness & Error Handling (Tests 12-14):** Verifies state machine safety when parsing corrupt streams. If fed malformed data (truncated bytes, missing termination bits, empty buffers), it accurately halts and raises a defined `Decoding_Error` exception instead of producing undefined behavior or memory access faults.

### Why These Tests Matter
In critical systems (such as high-reliability embedded platforms parsing remote data streams), invalid binary parsing commonly creates out-of-bounds reads or infinite loops. By rigorously proving that error states are instantly caught and safely handled via exceptions, this test suite verifies runtime safety and compliance with high-integrity software standards.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. Compile everything directly via the provided Makefile:
```bash
make all
