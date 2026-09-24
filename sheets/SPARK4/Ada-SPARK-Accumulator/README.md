# Bounded Fixed-Point Moving Accumulator

## Project Overview
This repository contains a provable Bounded Fixed-Point Moving Accumulator implemented in Ada 2023 with SPARK formal verification (GNATProve Level 4). The algorithm maintains a running sum and observation count, allowing the current mean to be calculated dynamically while remaining highly optimized for headless, low-latency, and sandboxed WebAssembly execution.

## Features
* **Zero Footprint Operations:** Operates entirely without dynamic allocation, heap memory, or POSIX secondary stacks.
* **Bounded Safety:** Hard mathematical bounds placed on counts (0 .. 1_000), single sample values (-10_000 .. 10_000), and running totals (-10_000_000 .. 10_000_000).
* **Fully Provable:** Analyzed under GNATProve Level 4 to guarantee total Absence of Run-Time Errors (AoRTE) and strictly verified domain logic.
* **Strict Contracts:** Enforced `Pre` and `Post` SPARK assertions on every state mutation.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:** `make test` will print `PASS` for all assertions and return an exit code of 0. `make prove` will report zero unproved checks and no warnings.

## Testing
* **Functional correctness:** Asserts positive accumulations, negative accumulations, zero constraints, and mathematical truncation rules.
* **Contract verification:** Exercises and intentionally trips `Pre` conditions (e.g., pulling a mean from an empty sequence, or exceeding the 1000-count array size bounds) to ensure robust boundary defense.
* **Proof obligations:** All GNATProve Level 4 obligations are fully discharged with no manual proof gaps.

## Building
**Prerequisites:** GNAT Community (or GNAT Pro) with SPARK support, Ada 2023 (ISO/IEC 8652:2023).

**Commands:**
* `make` — Builds the project.
* `make test` — Runs the complete 13-test suite.
* `make prove` — Runs GNATProve Level 4 strict formal verification.
* `make clean` — Removes build artifacts (objects and binaries).

## Proof Status
* All subprograms are rigorously annotated with SPARK contracts.
* The formal verifier mathematically guarantees no division-by-zero or integer overflows are possible under the declared `Engine` types.
* No `pragma Annotate (GNATprove, Intentional, ...)` overrides are utilized. The mathematical domain is fully closed and verified.
