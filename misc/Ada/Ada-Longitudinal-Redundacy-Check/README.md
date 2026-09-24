# Longitudinal Redundancy Check (LRC) - Ada Implementation

## Project Overview
This repository contains a robust, statically typed Ada implementation of the Longitudinal Redundancy Check (LRC) algorithm. LRC is an error-detection method applied independently to each parallel group of bit streams. By summing or XORing bytes in a transmission block, network receivers can reliably verify data integrity.

## Features
- **Standard XOR LRC (Even Parity):** The traditional form of LRC utilizing bitwise XORs to calculate parity across the byte sequence.
- **Modbus ASCII LRC (Arithmetic / 2's Complement):** A variant heavily used in industrial protocols (like Modbus), calculating the 2's complement of the arithmetic sum of bytes.
- **Odd Parity XOR LRC:** The exact bitwise complement of the standard XOR check.
- **Verification Helpers:** Built-in subprograms for each variant (`Verify_XOR_LRC`, etc.) to directly validate a byte stream against a received checksum.
- **Strong Typing & Safety:** Uses Ada's modular types (`mod 256`) explicitly mitigating arithmetic overflow errors by design, combined with strict exception handling for zero-length inputs.

## Testing
This codebase is governed by standard Validation and Verification (V&V) principles tailored for critical systems. We assume the system possesses failure points until execution strictly proves otherwise.

### What The Tests Verify
1. **Functional Correctness:** Verifies algorithmic outputs against established protocol norms (e.g., Modbus arithmetic wraparounds, XOR cancellations). 
2. **Edge Cases:** Evaluates processing of extremes (arrays of `0x00`, arrays of `0xFF`).
3. **Error Handling & Robustness:** Mandates that providing null/empty data throws a well-defined `Empty_Data_Error` exception rather than failing silently or causing memory segmentation faults.

### Why These Tests Matter
In communication systems (like smart cards, RFID, or SCADA/Modbus environments), silent data corruption or unchecked empty buffers can result in critical failure or security vulnerabilities. These 14 discrete tests guarantee that inputs meet strict boundaries and computational output is mathematically faultless per the defined standards. The tests intentionally assume the code is broken—when a test prints **PASS**, it fundamentally disproves an assumption of failure by confirming the expected result bounds.

## Usage
### Prerequisites
- GNAT Compiler (Ada 2012 compliant)
- GNU Make

### Compilation
The program is built using the provided `Makefile` which wraps GNAT's project file management:
```bash
make all
