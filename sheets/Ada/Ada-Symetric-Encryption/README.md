# Symmetric Ciphers in Ada 2023

## Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation of representative symmetric-key algorithms. Symmetric-key algorithms are cryptographic systems where the same key is utilized for both encryption and decryption. This package categorizes and implements the two primary variants of symmetric algorithms: Block Ciphers and Stream Ciphers. The **Tiny Encryption Algorithm (TEA)** serves as the block cipher (using 64-bit blocks and a 128-bit key) implementing both Electronic Codebook (ECB) and Cipher Block Chaining (CBC) modes of operation. **ARC4 (RC4-compatible)** serves as the byte-oriented stream cipher, featuring its standard Key-Scheduling Algorithm (KSA) and Pseudo-Random Generation Algorithm (PRGA).

## Features
*   **Block Cipher (TEA):** Core encryption and decryption for 64-bit blocks.
*   **ECB Mode:** Parallelizable, deterministic block array encryption (Electronic Codebook).
*   **CBC Mode:** Chained block encryption using an Initialization Vector (IV) for enhanced entropy.
*   **Stream Cipher (ARC4):** Continuous byte-stream encryption capable of preserving state across multiple data chunks.
*   **Strict Typing:** Replaces bare `Integer` usage with explicit `Word32` and `Byte` domain types to prohibit accidental implicit casting errors.
*   **Contract-Based Verification:** Extensive usage of standard Ada aspects (`Pre`, `Post`, `Global`) guaranteeing memory invariants and IO sizes.
*   **Exception Safety:** Predictable error handling leveraging named exceptions (`Invalid_Key_Length`, `Invalid_Input_Size`) for algorithmic constraints.

## Usage
To build and execute the system along with its verification framework, simply use the `Makefile`:

```bash
make test
```

**Expected Output:**
The system compiles cleanly via `gnatmake` (Zero warnings under `-gnatwa`) and immediately runs `tests.adb`. You will see sequential PASS output for 13 specific test suites comprising 39 distinct assertions, ending with:

```text
===  39 passed,  0 failed ===
```

## Testing
The test suite (`tests.adb`) operates as a dual-purpose demonstrator and validator. It is entirely standalone and does not rely on third-party test harnesses (`Ada.Assertions`). Coverage includes:

*   **Functional Correctness:** Assures primitives reliably encrypt and completely reverse back to original plaintexts for TEA and ARC4.
*   **Invariants & Cryptographic Properties:** Confirms avalanche effects in CBC mode, keystream continuity across boundaries in ARC4, and state preservation.
*   **Error Handling:** Forcefully injects size mismatch issues (buffer under/overruns) and bounds violations to guarantee named exceptions trigger gracefully.
*   **Edge Cases:** Verifies 0-length inputs return cleanly without looping, zeroed key structures evaluate correctly, and extreme value boundary integers function safely.

Thorough coverage disproves theoretical algorithm breakages and validates the implementation against the fundamental properties of symmetric cryptography.

## Building
**Prerequisites:**
*   GNAT toolchain (GCC Ada compiler)
*   Make

**Standards:**
The code is strictly validated against the **Ada 2023 (ISO/IEC 8652:2023)** standard using the `-gnat2022` backwards compatibility flag native to newer GNAT releases, paired with rigorous `-gnatwa` (all warnings) and `-gnata` (assertions enabled) checks.
