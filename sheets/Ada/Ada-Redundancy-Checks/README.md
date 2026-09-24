# Ada Redundancy Checks Library

## Project Overview
This codebase provides a strict, strongly-typed Ada implementation of standard [Redundancy Check](https://en.wikipedia.org/wiki/Redundancy_check) algorithms. Redundancy checks are extra sets of data added to digital messages to provide verification of data integrity, enabling the detection of corruption or accidental data alteration during transmission or storage.

## Features
The `Redundancy_Checks` package implements several variants of integrity algorithms, ranging from basic parity to complex cyclic functions:
* **Parity Bits:** `Calculate_Even_Parity` and `Calculate_Odd_Parity` (applies to individual bytes).
* **Longitudinal Redundancy Check (LRC):** Calculates the XOR accumulation of a byte array.
* **Modular Checksum-8:** Evaluates an 8-bit modular sum with graceful rollover/wrapping.
* **Cyclic Redundancy Check (CRC-32):** Standard IEEE 802.3 implementation using the `0xEDB88320` reversed polynomial.
* **Adler-32:** A high-speed checksum algorithm used broadly in modern compression (e.g., zlib).

## Testing

Software correctness requires rigorous Verification and Validation (V&V). To adhere to critical systems standards, the included test suite evaluates the codebase against a "pessimistic" baseline assumption: **we assume the code is broken until proven otherwise**. 

The tests disprove these failure assumptions across multiple categories:
1. **Functional Correctness (Standard Compliance):** CRC-32 and Adler-32 are subjected to industry-standard test vectors (like the string `"123456789"`). By matching the well-known expected cryptographic outputs, we validate the logic functions as intended.
2. **Edge Cases:** What happens when an empty array is provided? Standard behaviors dictate that CRC-32 should yield `0`, while Adler-32 yields `1`. Tests verify these exact boundaries so no undefined states are entered.
3. **Error Handling:** For basic checks like LRC and Checksum-8 where an empty array makes no mathematical sense, the tests assert that a strict `Empty_Data_Error` exception is reliably raised to prevent silent corruption propagation.
4. **Data Boundaries:** Modular checksum tests push integers over the `256` maximum limit to ensure our modular arithmetic prevents runtime overflow exceptions.

Proving these strict assertions passing ensures reliability and safety in environments where corrupted data processing is unacceptable.

## Usage

### Compilation
The project requires the GNAT toolchain. A standard `Makefile` is provided for compilation.
To compile both the main application and the test suite:
```bash
make all
