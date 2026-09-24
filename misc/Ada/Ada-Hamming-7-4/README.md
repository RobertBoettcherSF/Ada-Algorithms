# Hamming(7,4) Error-Correcting Code in Ada

## Project Overview
This project provides a robust, strongly-typed implementation of the **Hamming(7,4)** error-correcting code algorithm in Ada. Based strictly on the definitions provided by [Wikipedia](https://en.wikipedia.org/wiki/Hamming(7,4)), it uses matrix multiplication to encode 4 bits of data into 7 bits of parity-protected code. It can automatically detect and correct any single-bit error that occurs during transmission.

## Features
- **Strong Typing:** Utilizes Ada's `mod 2` types instead of standard integers to mathematically enforce valid bitwise operations (XOR/AND) and prevent buffer/type overflows.
- **Variant 1 - Systematic Code:** Implements the standard `G = [I_4 | P]` matrix where the 4 data bits are placed strictly at the beginning, followed by 3 parity bits.
- **Variant 2 - Interleaved Code:** Implements the classic Hamming sequence where parity bits are placed at indices matching powers of 2 (1, 2, 4).
- **Matrix-Driven Arithmetic:** Encoding and syndrome calculations rely on discrete dot-product matrix multiplication as mathematically defined by the generator ($G$) and parity ($H$) matrices.
- **Single Error Correction (SEC):** Detects and perfectly reconstructs 1-bit failures across all data and parity domains.

## Testing & Verification 
Testing follows strict **Verification and Validation (V&V)** principles. We assume the code is faulty until proven correct by the execution suite. 

### What the Tests Verify
- **Functional Correctness:** Tests 1-4 and 8 ensure the generated checksums match calculated, expected Wikipedia truths for arbitrary data blocks.
- **Error Handling & Robustness:** Tests 5-7 and 9-10 inject manual bit-flips (noise simulation) to ensure the decoding algorithm catches and fixes transmission faults correctly.
- **Edge Cases / Exhaustive Sweeps:** Tests 11 and 12 perform loops that attack every single bit index (1 through 7) for both Systematic and Interleaved variants to guarantee 100% SEC coverage.

### Why these Tests Matter
For critical systems (e.g., aerospace memory controllers, satellite telemetries), silently passing corrupted data is catastrophic. By simulating hardware faults (bit-flips) at every index, we validate that this software accurately mimics hardware SEC guarantees. Passing these tests forces the initial pessimistic assumption (that the matrix math is misaligned) to be proven false.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. Compile the project using the provided Makefile:
```bash
make
