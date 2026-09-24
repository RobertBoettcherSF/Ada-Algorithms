# Poly1305 MAC in Ada 2023

## Project Overview
This project provides a robust, standalone Ada 2023 implementation of the Poly1305 cryptographic Message Authentication Code (MAC) designed by Daniel J. Bernstein. Poly1305 calculates a 16-byte authentication tag for a message using a 32-byte one-time key. The underlying algorithm leverages high-speed polynomial arithmetic modulo 2^130 - 5. This implementation uses a base-2^26 limb representation within 64-bit unsigned integers, avoiding overflow and achieving clean, constant-time modular reduction entirely within standard Ada boundaries.

## Features
* **Variants Supported:**
  * **Static / Single-Shot (`Generate_MAC`):** Simplified API for verifying or authenticating a complete contiguous buffer of memory.
  * **Dynamic / Incremental Processing (`Init`, `Update`, `Final`):** Streaming API accommodating fragmented network packets or chunked data pipelines.
* **Strict Typing:** Ada standard types guarantee semantic distinction between keys (`Key_Type`), MACs (`MAC_Type`), and variable-length messaging (`Byte_Array`).
* **Zero Dependencies:** Fully encapsulated, requires only built-in `Interfaces` representations.
* **Security & Robustness:** Constant-time modular reductions. Post-computation context zeroization. Protected against state-machine violations via strict assertions (`State_Error`).

## Usage
The `tests.adb` test suite serves both as the primary validation testbench and a demonstration of usage. 

To build and execute:
```bash
make test
```

Expected output will display all passing assertions, including functionality checks against established standards:

```text
Running tests...
TEST 1 — Generate_MAC: Single-shot RFC 8439 Vector
  PASS — 1.1 First byte correctness
  PASS — 1.2 Last byte correctness
  PASS — 1.3 Full array equality
...
===  39 passed,  0 failed ===
```

## Testing
The validation covers multiple execution categories:

* **Functional Correctness:** Vectors mapped exactly to the RFC 8439 definitions of Poly1305 outputs (IETF validation).
* **Edge Cases:** Single blocks, boundary chunk sizes (e.g., 7-byte updates), zero keys, empty messages, 1-byte overflow boundaries.
* **Error Handling & Invariants:** State-enforcement to ensure calls strictly follow `Init` -> `Update` (0+ times) -> `Final`. Asserts that cryptographic material inside the context is completely zeroed upon MAC finalization.

## Building
* **Prerequisites:** GNAT compiler (tested cleanly with `-gnatwa`).
* **Standard:** Ada 2023 (ISO/IEC 8652:2023), enforced dynamically via `-gnat2022` compiler flag in the provided Makefile context.
