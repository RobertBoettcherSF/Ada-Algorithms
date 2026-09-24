# Ada SipHash

## Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation of the SipHash cryptographic pseudorandom function. SipHash is an add-rotate-xor (ARX) based family of hash functions optimized for short inputs, designed primarily to defend against hash-flooding denial-of-service attacks. The implementation includes all primary variants: the standard 64-bit MAC (SipHash-c-d) and the extended 128-bit MAC (SipHash128-c-d), fully parameterized to allow dynamic scaling of both compression (C) and finalization (D) rounds.

## Features
* **Full Variant Support:** Implements standard SipHash-2-4 and SipHash-4-8, alongside their 128-bit counterparts (SipHash128-2-4, SipHash128-4-8).
* **Parameterized Rounds:** Flexible `C` (compression) and `D` (finalization) round arguments.
* **Strong Typing:** Eliminates bare scalars in favor of distinct domain subtypes (`Key_Type`, `Byte`, `Word64`), actively leveraging the Ada compiler's constraint checks to guarantee length safety.
* **Array Agnosticism:** Securely handles dynamically bound array slices natively through robust range evaluations, averting index faults regardless of the unconstrained source bounds.

## Usage
Compile and execute the exhaustive internal test suite using `make test`:

```bash
make test
```

Expected output implies all invariant, collision, slice integrity, and deterministic properties check out positively with zero failed assertions:

```text
  PASS — 1.1 Empty message is deterministic
...
===  39 passed,  0 failed ===
```

## Testing
The `tests.adb` module acts as both the executable build target and the canonical usage reference. It validates the following categories:

* **Functional Correctness:** Verifies absolute determinism across all provided variants against standardized length progressions.
* **Avalanche Effect:** Guarantees severe diffusion properties; altering a single bit in either the key or message dramatically transforms the resultant MAC.
* **Algorithmic Divergence:** Validates output independence between different round parameters (e.g., `Hash_64(C=2, D=4)` vs `Hash_64(C=4, D=8)`) and between output widths (64-bit vs 128-bit).
* **Edge Cases & Error Handling:** Explicitly tests behavior against large payloads, high-bit length modulos (256-byte inputs), constrained invalid array types (`Constraint_Error`), and non-zero-indexed array slices.

These categories comprehensively prove mathematical adherence to the specification while simultaneously validating structural bounds memory-safety under load.

## Building
**Prerequisites:** GNAT Toolchain

The project is configured for Ada 2023 (ISO/IEC 8652:2023) enforcing `-gnat2022` and strictly zero-warning tolerance via `-gnatwa`. Make guarantees automatic resolution of intermediate artifacts.

```bash
make       # Builds bin/tests
make clean # Removes obj and bin directories
```
