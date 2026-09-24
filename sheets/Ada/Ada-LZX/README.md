# LZX Algorithm Implementation

## Project Overview
This project implements the core dictionary-matching engine of the **LZX Compression Algorithm**. Originally developed for the Amiga, LZX is heavily utilized by Microsoft for Cabinet files (.CAB), HTML Help files (.CHM), Xbox executables (.XBE), and Windows Update (LZX DELTA). 

This Ada implementation abstracts the bit-level Huffman encoding into a verifiable byte-sequence format, allowing us to strictly model, execute, and validate the algorithm's unique sliding-window constraints and its signature 3-element Repeated Offset queues (R0, R1, R2).

## Features
* **Configurable Variants:** Handles constraints for `Amiga_LZX`, `CAB_LZX`, `CHM_LZX`, `Xbox_LZX`, and `DELTA_LZX`.
* **Sliding Window Dictionary:** Implements LZ77 backward referencing.
* **Repeated Offset Queues (R0, R1, R2):** Implements LZX's specialized optimization that tracks the last 3 match offsets to heavily compress repeating structural data.
* **Strong Typing:** Leverages Ada's safety features to ensure type-safe indexing and bounds handling.

## Testing
This project follows strict **Verification and Validation (V&V)** principles. The test suite operates on a "guilty until proven innocent" philosophy, explicitly assuming the code is broken. A test only PASSES when assertions actively disprove this assumption.

### What the Tests Verify:
1. **Functional Correctness:** Cycle tests ensure that data passed through `Compress()` and then `Decompress()` yields the exact original byte array bit-for-bit.
2. **Error Handling & Robustness:** Corrupted decompression streams and undersized output buffers are artificially injected to ensure exceptions (`LZX_Error`, `Buffer_Overflow`) are safely raised rather than causing memory faults.
3. **Edge Cases:** Empty arrays, 1-byte arrays, and highly uncompressible data are tested to ensure math doesn't underflow.
4. **Variant Rules Verification:** Ensures constraints (like Xbox's strict 32KB window limit and CAB's 2MB window cap) are securely enforced regardless of input.

### Why these Tests Matter:
In critical systems, data integrity is paramount. Compression algorithms are highly susceptible to out-of-bounds memory reading during decompression if backward-references are manipulated. By proving that the software catches out-of-bounds references and maintains flawless data integrity through R0/1/2 offset shifting, these tests guarantee safety and correctness under V&V standards.

## Usage

### Compilation
The codebase utilizes GNAT project files and a standard Makefile. Ensure you have the `gnat` toolchain installed.

To compile the project:
```bash
make all
