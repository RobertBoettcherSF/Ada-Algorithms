# Proof-of-Work System (Ada Implementation)

## Project Overview
This repository provides a strongly-typed, modular implementation of cryptographic Proof-of-Work (PoW) algorithms in Ada. PoW systems deter denial-of-service attacks, network spam, and form the consensus basis for decentralized blockchain networks by requiring a feasible, easily verifiable amount of computational effort from a service requester. 

## Features
The codebase implements the three primary categorizations of PoW architectures detailed in computer science literature:
1. **CPU-Bound (Hashcash Variant):** Requires inverting a partial SHA-256 hash by finding a nonce that produces a predefined number of leading zeros.
2. **Time-Bound (Hash Chain Variant):** Cannot be parallelized. Verifies sequential computation time by repeatedly hashing a seed over $N$ consecutive iterations.
3. **Space/Memory-Bound (Client Puzzle Variant):** Requires interacting with a deterministic pseudo-random lookup pool, verifying memory allocation and index capability.

## Testing
This project embraces a strict Verification and Validation (V&V) doctrine. The test suite operates on a pessimistic **"Assume broken until proven functional"** philosophy. A test only marks as `PASS` when it successfully disproves a hypothesis of failure (e.g., *Assume the code accepts invalid nonces* -> *Code rejects invalid nonce* -> *Assumption False -> PASS*).

### What Each Category Verifies:
*   **Functional Correctness:** Ensures PoW generation returns results satisfying mathematical requirements (e.g., Tests 1, 6, 10).
*   **Safety & Error Handling:** Validates that exceptions (`PoW_Error`, `Constraint_Error`) are accurately raised during mathematical impossibility or overflow states, preventing unhandled runtime crashes (e.g., Tests 13, 14).
*   **Negative Path / Tamper-Resistance:** Proves that verifiers reject altered payloads, protecting the integrity of the data being hashed (e.g., Tests 3, 8, 12).
*   **Edge Cases:** Boundary evaluation for inputs like zero-length strings, `Difficulty = 0`, and boundary iterations limits `Size = 1` (e.g., Tests 4, 5, 9).

### Why These Tests Matter:
In critical systems (like consensus mechanisms or anti-DDoS throttles), a bypassed PoW check compromises network integrity. By strictly aligning with V&V standards, these tests ensure:
1. **Reliability:** Expected inputs consistently produce deterministic answers.
2. **Security:** Modifying the data even slightly (tampering) triggers immediate validation failure.
3. **Correctness:** The actual implementation satisfies the abstract requirements laid out in protocol definitions.

## Usage

### Compilation
The build environment is fully managed by GNAT and `make`. Ensure `gnatmake` is installed on your system.
```bash
# Compiles both the main executable and the test suite
make all
