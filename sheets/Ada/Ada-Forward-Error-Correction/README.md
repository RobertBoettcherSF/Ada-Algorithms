# Forward Error Correction (FEC)

## Project Overview
This project provides a complete Ada 2012 implementation of Forward Error Correction (FEC) techniques as described in the [Wikipedia article on Forward Error Correction](https://en.wikipedia.org/wiki/Forward_error_correction). FEC allows a receiver to detect and correct errors in transmitted data without needing a reverse channel to request retransmission. This implementation demonstrates block coding, repetition coding, and the mitigation of burst errors through interleaving.

## Features
* **Repetition Code (Rate 1/N)**: A simple algorithm where each bit is transmitted `N` times. Decoding is performed via majority voting, successfully correcting errors as long as the majority of repeated bits remain intact.
* **Hamming(7,4) Block Code**: A classic linear error-correcting code that encodes 4 bits of data into 7 bits. It guarantees detection and correction of any single-bit error within the block using mathematically calculated parity syndromes.
* **Bulk Data Processing**: Convenience subprograms to process arbitrary-length data streams matching the modulo requirements of the underlying block codes.
* **Interleaving / Deinterleaving**: A matrix-transposition technique to combat burst errors. By interleaving data prior to transmission, continuous burst errors are physically scattered across multiple blocks upon receipt. When combined with a single-error correcting code like Hamming(7,4), the system can fully recover from multi-bit burst corruption.
* **Strong Typing and Contracts**: Employs Ada 2012 `Pre` and `Post` contract aspects to ensure block alignments, odd-sized repetition constraints, and data integrity at the type system level.

## Usage
The package acts as a library. The usage and execution examples are fully enclosed within the test suite, which doubles as the executable target. To compile and run:

```bash
make test

Expected output includes the successful passing of all assertions:

Running tests...
TEST 1 - Repetition Encode
  PASS - 1.1 Encode x3 length correct
  PASS - 1.2 Encode x3 data correct
...
===  42 passed,  0 failed ===

Testing
The tests.adb test suite exercises the implementation heavily through functional, edge-case, and negative tests. This provides essential verification and validation:

Functional Correctness: Validates that encoded data transforms exactly to known mathematical vectors (e.g. Hamming(7,4) 0000 -> 0000000).

Error Correction Verification: Validates that manually injected single-bit data/parity errors (for Hamming) and multi-bit errors (for Repetition) are flawlessly auto-corrected during decoding.

Invariant & Precondition Checks: Actively verifies that Constraint_Error or System.Assertions.Assert_Failure bounds are respected for misaligned data arrays.

System Integration: A dedicated burst-error simulation (Test 14) proves that Hamming(7,4) fails to correct consecutive errors in a single block natively, but perfectly corrects consecutive burst errors when coupled with interleaving.

Building
Prerequisites:

GNAT Ada Compiler (gnatmake)

Support for Ada 2012 (-gnat2022 or -gnat2012)

The codebase compiles with zero warnings under -gnatwa. Simply invoke make or explicitly build with the GNAT project tool:

bash
gnatmake -gnatwa -gnat2022 -P
forward_error_correction.gpr
