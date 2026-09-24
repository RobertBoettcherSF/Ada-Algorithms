# Ada 2023 Pratt Parser

---

## Project Overview

This project implements a Top-Down Operator Precedence (Pratt) parser in strict Ada 2023. A Pratt parser assigns a "binding power" (precedence) to tokens, seamlessly managing complex rules for mathematical operations without deep, complicated grammar recursion. It separates operators into "nud" (null denotation, for prefix operators and atoms) and "led" (left denotation, for infix operators), allowing for a highly extensible, robust evaluation structure.

---

## Features

- **Infix Operators:** Support for `+`, `-`, `*`, `/`.
- **Prefix Operators:** Support for unary `+` and `-`.
- **Right Associativity:** Supports the exponentiation `^` operator, evaluating `2^3^2` as `2^(3^2)`.
- **Mathematical Binding Precedence:** Properly prioritizes exponentiation over unary prefix signs (e.g., `-2^2` cleanly maps to `-(2^2) = -4`).
- **Grouping:** Full support for `( )` sub-expressions.
- **Resilient Evaluation:** Hand-written integrated lexer skipping control characters and whitespace.
- **Safe Memory Management:** Dynamically allocated Abstract Syntax Tree (AST) that enforces manual, leak-free deallocation.

---

## Usage

The code is standalone. Compilation creates an executable suite that acts as both regression testing and real-time API demonstration.

To verify the parser:

```bash
make test
```

**Expected Output Snippet:**

```text
TEST 1 — Numbers and Whitespaces
  PASS — 1.1 Single digit
  PASS — 1.2 Multiple digits
  PASS — 1.3 Leading/trailing whitespaces
...
===  39 passed,  0 failed ===
```

---

## Testing

The test suite spans 13 categories (39 robust assertions) exploring:

- **Functional Correctness**: Verifying complex mixed-precedence arithmetic yields correct integer equivalents.
- **Edge Cases**: Assuring correct mapping for right-associativity, blank inputs, single digits, and nested boundaries.
- **Error Handling / Verification and Validation**: Supplying intentionally mangled structures (divide by zero, unclosed parentheses, missing operands, unparseable characters) guarantees the `Parse_Error` and `Evaluation_Error` exceptions are correctly, exclusively triggered without crashing or leaking memory.

---

## Building

- **Prerequisites**: GNAT compiler (part of GCC or Alire).
- **Standard**: This project targets the Ada 2022/2023 (`-gnat2022`) standard constraint and utilizes aspects like `Pre`, `Post`, strict variable hygiene, and `Unbounded_String`. It guarantees flawless compilation with absolute zero warnings under GNAT's stringent `-gnatwa` flag.
