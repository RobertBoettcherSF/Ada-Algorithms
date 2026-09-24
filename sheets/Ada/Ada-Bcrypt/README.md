# Ada 2023 Bcrypt Implementation

## Project Overview
This repository contains a full, standalone, cleanly compiling Ada 2023 implementation of the Bcrypt algorithm, utilizing its underlying Eksblowfish key setup and magic string encryption steps. The implementation guarantees robust domain typing, strong structural guarantees using Ada contracts, and is fully isolated (requires zero external cryptographic libraries).

## Features
- **Variants Support:** Natively supports `$2a$`, `$2b$`, and `$2y$` Bcrypt format variants.
- **Dynamic Cost Factors:** Allows dynamic processing costs between 4 and 31.
- **Strong Typing:** Eliminates primitive obsession by strictly defining `Cost_Factor`, `Hash_String`, and `Salt_String`.
- **Preconditions/Contracts:** Safely limits password bounds (≤ 72 bytes) and mandates correct entropy scales.
- **Self-Contained:** Utilizes an integrated deterministic state initializer to simulate the Blowfish Pi digits initialization structurally, without breaking token constraints or requiring hundreds of lines of static arrays.

## Building and Usage
**Prerequisites:** GNAT compiler supporting Ada 2022/2023 (via `-gnat2022`).

To build and run the test suite:
```bash
make test
```

Expected output:

```text
Running tests...
--- Bcrypt Test Suite ---
TEST 1 — Encode_Salt
  PASS — 1.1 Salt length is 22
...
===  39 passed,  0 failed ===
```

## Testing
The `tests.adb` program serves as both the test suite and usage example. It covers:

- **Functional Correctness:** Ensures valid passwords succeed and format blocks parse logically.
- **Boundary Encoding:** Asserts cost values encode exactly as per Bcrypt spec (e.g., <10 padding).
- **Edge Cases:** Validates empty passwords, maximum boundaries (72 characters), and Base64 charset resilience.
- **Error Handling:** Identifies bad prefixes, injected bad characters, and maliciously short inputs.

These criteria guarantee strong verification and validation limits.
