# Ada 2023 Recursive Descent Parser

---

## Project Overview

This project implements a classic top-down, LL(1) Recursive Descent Parser based directly on the formal formalisms introduced in standard parser theory (specifically following the Wikipedia canonical example). It processes a mathematical expression grammar supporting `+`, `-`, `*`, `/`, parenthesis-driven precedence `()`, and arbitrary-length integer literals. The logic operates strictly without backtracking, validating correct left-associative bindings.

---

## Features

- **Evaluator Variant:** Intercepts tokens directly to resolve expressions dynamically (e.g., `Evaluate("2 + 3 * 4") = 14`).
- **Recognizer Variant (Predictive):** Executes a pure LL(1) validation check enforcing grammatical structure integrity without calculating value trees (`Is_Valid`).
- **Translator Variant:** Builds an implicit Abstract Syntax Tree and sequentially emits a Reverse Polish Notation (RPN) map.
- **Strong Typing:** Leverages a domain-specific `Value_Type` to completely eliminate "bare Integer" usage during computation steps, adhering strictly to Ada best practices.

---

## Usage

Run `make test` from the root directory. The standalone testing suite exercises the library on-the-fly and prints outputs to `stdout`.

**Expected output trace snippet:**

```text
Running tests...
TEST 1 — Evaluate Basic Addition and Subtraction
  PASS — 1.1 Single addition: 1 + 1
  PASS — 1.2 Left associativity: 10 - 5 - 2
  PASS — 1.3 Leading and trailing spaces: ' 0 + 42 '
...
===  42 passed,  0 failed ===
```

---

## Testing

The `tests.adb` program is highly comprehensive. Categories of tests include:

- **Functional Correctness**: Verifying standard math outputs, RPN outputs, and positive tree recognition.
- **Grammar/Precedence Validation**: Verifying operator hierarchy bounds mapping (forcing multiplication sub-trees beneath addition trees).
- **Left-associative Bound Validation**: Enforcing that `10 - 5 - 2` renders mathematically as `(10 - 5) - 2`, not `10 - (5 - 2)`.
- **Edge Cases &amp; Error Handling**: Checking rejection parameters for missing parenthesis offsets, unbalanced operators, invalid characters, truncation, and zero-divisions using native exception structures.

---

## Building

- **Prerequisites**: GNAT Toolchain
- **Standard**: Ada 2023 (ISO/IEC 8652:2023). Under GNAT, this is accomplished using the `-gnat2022` flag alongside the `-gnatwa` warning flag requirements.
