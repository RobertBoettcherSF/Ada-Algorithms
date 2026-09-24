# Ada 2023 LR Parser Engine

---

## Project Overview

This project provides a robust, strongly typed, pure Ada 2023 (ISO/IEC 8652:2023) implementation of a **table-driven LR parser engine**. Based on standard LR(k) algorithms, the engine consumes static Action and Goto tables alongside grammar productions. It supports both traditional batch processing (non-preemptive execution) and modern resumable token-by-token processing (preemptive execution) essential for asynchronous environments like language servers.

---

## Features

- **Table-Driven Core:** Works cleanly with arbitrary LR(0), SLR(1), LALR(1), or Canonical LR(1) parsed tables without requiring table-generation recompilation.
- **Variant 1 (Static Analysis):** Pre-flight validation (`Validate_Engine`) ensures state tables have valid Goto routes and reachable Accept conditions.
- **Variant 2 (Preemptive Parsing):** Stepwise API (`Feed_Token`) enables asynchronous, suspended token feeding ideal for IO-bound or concurrent streams.
- **Variant 3 (Non-Preemptive Parsing):** Batch execution (`Parse`) processes an entire stream immediately, natively checking constraints like trailing garbage.
- **Strongly Typed Architecture:** Leverages Ada's contract aspects (`Pre`/`Post`), distinct subtype ranges, and generic collections to enforce state and type safety at compile time.

---

## Usage

To test the implementation and view runtime validations:

```bash
make test
```

**Expected Output:**  
The system runs 13 isolated test suites verifying the integrity of bounds checking, reduction mechanics, and stepwise states. The console will report:

```plaintext
--- LR Parser Test Suite ---
TEST 1 - Engine Structure Validation
  PASS - 1.1 Valid engine returns True
  PASS - 1.2 Max State matches specification
  ...
===  39 passed,  0 failed ===
```

---

## Testing

The test framework (`tests.adb`) doubles as both regression validation and API documentation. Categories specifically targeted:

- **Functional Correctness:** Batch resolving recursive and minimal rightmost-derivation token strings.
- **Invariant &amp; Validation:** Detecting table malformations (e.g., missing Accepted states, broken Goto indices, out-of-bounds rule pointers).
- **Edge Cases &amp; Memory Safety:** Premature End-of-File errors, dangling trailing garbage, and rejecting unauthorized token IDs.
- **State Resiliency:** Ensuring that stepwise (`Feed_Token`) parser execution halts predictably and tracks asynchronous Derivations independently.

---

## Building

**Prerequisites:** GNAT compiler.

**Compatibility:** Ada 2022/2023 standard (`-gnat2022`).

Run `make` to compile objects to the `obj/` folder and output the executable to `bin/tests`. Clean environment using `make clean`.
