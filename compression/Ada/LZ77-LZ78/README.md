# LZ77 and LZ78 Data Compression Algorithm (Ada)

## Project Overview
This repository implements the canonical **LZ77** (Sliding Window) and **LZ78** (Dictionary-based) lossless data compression algorithms in Ada. Designed according to mission-critical principles, the project ensures strict constraint boundary handling, avoids memory leaks, and demonstrates full structural verification.

## Features
- **LZ77 Sliding Window Variant:** Configurable sliding search window and lookahead buffers limit resource usages predictably.
- **LZ78 Dynamic Dictionary Variant:** Protects systems against unbounded dictionary allocations via explicit upper bound limits (Default: 4096 elements).
- **Strong Typing & Constraints:** Custom ADA datatypes, tokens, and index-bound handling to prevent memory overreach.
- **Null-Allocation Decoder Strategy:** Reconstructs complex dictionaries dynamically avoiding recursive call stack overloads on extensive buffers.

## Testing
This repository includes a strict Verification & Validation (V&V) suite engineered under pessimistic operational assumptions. Our testing methodology forces the assumption that **the code is entirely broken/malfunctioning until explicitly disproven** by the pass-state of the assertions.

### What the Tests Verify
- **Functional Correctness:** Verifies perfectly identical payloads natively through Encodes and Lossless Decodes across multiple payload sizes. (Tests 1-2, 7-8, 14).
- **Edge Cases & Data Anomalies:** Extreme scenarios are thrown into the pipeline (Tests 4, 10, 13) including pure redundancy sets ("ZZZZZZZZ"), zero-redundancy data ("123456"), and precise truncation bounds.
- **Error & Safety Handling:** Validates robust and graceful degradation properties rather than unchecked crash behavior. Explicit bounds check anomalies, such as out-of-index dictionary injections or array under-lengths, raise correctly implemented, typed exceptions. (Tests 3, 6, 9, 12).

### Why these Tests Matter
Per rigorous V&V principles, verifying correct logic limits systemic faults in production usage environments. 
- *Verification:* Ensures algorithms faithfully execute mathematically to the Lempel-Ziv principles.
- *Validation:* Ensures the final output correctly interfaces with the end-user (i.e. decoding restores exact state). By rejecting malicious dictionaries securely (Tests 6, 12), the software achieves standard data safety compliance.

## Usage
### Requirements
- GNAT / Ada compiler (`gnatmake`)
- Standard POSIX `make` tool

### Compilation
Build both the principal executable and the test suite natively via the Make wrapper:
```bash
make all
