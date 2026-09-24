# Message Authentication Code (Ada 2023)

## Project Overview
A Message Authentication Code (MAC) is a cryptographic checksum that verifies both the integrity and authenticity of a message using a shared secret key. This repository provides an Ada 2023 implementation of three fundamental MAC constructions: HMAC (Hash-based), CBC-MAC (Cipher Block Chaining), and Prefix-MAC. To eliminate external dependencies and focus purely on the architectural flow of these algorithms, the package utilizes internally defined, simplified cryptographic primitives (a 16-byte custom hash and a 10-round block cipher).

## Features
- **HMAC (Hash-based MAC):** Implements the robust RFC 2104 structure, safely processing keys of any length and preventing length-extension attacks using `inner` and `outer` padding.
- **CBC-MAC:** Validates message integrity by streaming blocks through a block cipher via Cipher Block Chaining. Includes ISO/IEC 9797-1 padding to handle non-block-aligned messages securely.
- **Prefix-MAC:** A rudimentary `Hash(Key || Message)` implementation, provided to illustrate historical constructions and demonstrate strong typing.
- **Strong Typing & Contracts:** Uses Ada 2023 preconditions (`with Global`, `Post`) and typed `Byte_Arrays` rather than bare standard types.

## Usage
The package acts as a standalone cryptographic utility. To compile and verify the API usage via the test suite, run:

```bash
make test
```

**Expected Output:**

```text
Message Authentication Code Test Suite
======================================
TEST 1 — Simple Hash Functionality
  PASS — 1.1 Hash determinism (same input = same output)
  PASS — 1.2 Hash avalanche (diff input = diff output)
  PASS — 1.3 Hash output strict size boundary
...
===  39 passed,  0 failed ===
```

## Testing
The test suite (`tests.adb`) doubles as the operational example, housing 13 distinct unit tests ensuring zero-failure execution and robust edge-case handling:

- **Functional Verification:** Asserts that identical Key+Message inputs yield deterministic output MACs.
- **Padding Bounds:** Confirms that exact block alignments and disparate length arrays pad safely without overrun errors.
- **Error Handling:** Validates that named exceptions (`Invalid_Key_Error`, `Invalid_Message_Error`) correctly halt invalid states like empty key submissions.
- **Cryptographic Avalanche Tests:** Validates that single bit flips propagate completely to entirely alter the resultant MAC, avoiding partial collisions.

## Building
**Prerequisites:**

- GNAT compiler toolkit.
- Target language runtime: Ada 2023 (ISO/IEC 8652:2023), enforced via the `-gnat2022` flag in the `Message_Authentication_Code.gpr` project configurations.
- All files are completely clean of warnings compiled strictly under `-gnatwa`.
