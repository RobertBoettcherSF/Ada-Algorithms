# Yarrow PRNG Implementation in Ada 2023

## Project Overview
This project provides a fully functioning, highly strict software simulation of the cryptographic Yarrow algorithmic design by Schneier, Kelsey, and Ferguson. It encapsulates the core state-machine and cryptographic control logic required to maintain the entropy accumulator, two-tier (fast/slow) reseed mechanism, and key-rolling generator loop.

## Features
* Strong Typing constraints preventing entropy spillage.
* Fast Pool Reseeding mechanism triggered at 100-bit estimates.
* Slow Pool Reseeding mechanism guaranteeing thorough recovery at 160-bit estimates.
* Reseed Gatekeeper limits continuous key extraction without rollover.
* Graceful runtime exception isolation for parameter boundary failures.

## Usage
The standalone test executable operates both as the verification tool and example program. To observe its behavior on your system run:
```bash
make test
```

**Expected Output:**
Sequential reporting of 14 system tests proving accumulator limits, boundary conditions, and cryptographic mechanisms, ending with `===  42 passed,  0 failed ===`.

## Testing
The test suite spans 14 targeted scenarios utilizing 42 dynamic assertions to prove functional correctness, edge case resilience, error handling via `Yarrow_Error`, and internal state invariants. Testing categorizes verify:

1. Operational Initialization boundaries
2. Output fragmentation and buffer tracking
3. Entropy accumulation state distribution (Alternator Verification)
4. Trigger safety limits and exception compliance.

## Building
**Prerequisites:** GNAT Toolchain
**Standard:** Ada 2023 (ISO/IEC 8652:2023)

Build dynamically handled via standardized GPR configurations leveraging `make test`.
