# GLR Parser Variations (Ada 2023)

---

## Project Overview

This project is a strongly-typed, dependency-free Ada 2023 implementation of **Tomita's Generalized LR (GLR) parsing algorithm** and its modern variants. GLR extends standard LR parsing by exploring multiple possible parse paths non-deterministically when a grammar contains shift/reduce or reduce/reduce conflicts. This allows it to parse ambiguous and non-deterministic grammars without backtracking, acting as a linear-time parser for deterministic inputs while scaling gracefully for ambiguity.

---

## Features

- **Standard GLR:** The core multi-path parsing engine utilizing a simulated Graph-Structured Stack (GSS) abstraction to explore parallel state paths.
- **RNGLR (Right Nulled GLR):** Optimizes the engine to handle grammars containing epsilon/nullable rules (RHS length = 0 reductions) efficiently without infinite looping.
- **BRNGLR (Binary Right Nulled GLR):** A variant that enforces a strictly binarized grammar structure (maximum RHS length of 2) for performance bounding.
- **SGLR (Scannerless GLR):** Bypasses external tokenization completely, running the parse matrix directly against the raw character stream.
- **RIGLR (Reduction Incorporated GLR):** Provides the logical endpoint for simulated embedded reduction state processing.

---

## Usage

To execute the suite:

```bash
make test
```

The program will build via `gnatmake` and execute `bin/tests`.

**Expected Output:**

```plaintext
Running tests...
--- Starting GLR Parser Tests ---
TEST 1 — Deterministic standard GLR
  PASS — 1.1 Parse Success
  PASS — 1.2 Parse syntax error on unexpected token
...
===  30 passed,  0 failed ===
```

---

## Testing

The embedded standalone test suite (`tests.adb`) tests every public API variant utilizing programmatic grammar table construction. Testing categories cover:

- **Functional Correctness:** Deterministic successes, standard conflict resolution, and deterministic failure states.
- **Ambiguity Handling:** Multi-path split evaluations (Shift/Reduce conflicts) that gracefully return `Parse_Ambiguous`.
- **Variant Specifics:** BRNGLR length validations, RNGLR 0-length right-nulled passes, and SGLR byte-to-token map translations.
- **Edge Cases:** Unmapped tokens, empty inputs, token/state exhaustion, stack boundaries.

These tests act as **Verification** (the implementation fulfills the variants as described) and **Validation** (demonstrating safe Ada bounded limits are active).

---

## Building

**Prerequisites:** Requires GNAT (GCC Ada Compiler) supporting the Ada 2022/2023 standard (`-gnat2022`).

Runs strictly out-of-the-box utilizing built-in functionality; completely independent of external dependencies (`Ada.Text_IO` only).
