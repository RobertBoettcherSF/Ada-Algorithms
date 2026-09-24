# Earley Parser in Ada 2023

---

## Project Overview

This project provides a robust, strongly typed Ada 2023 implementation of the **Earley parser algorithm**. The Earley parser is a highly versatile parsing algorithm capable of processing all context-free grammars (CFGs). It gracefully handles edge cases that easily crash simpler parsers, notably ambiguous grammars, left-recursive rules, right-recursive rules, and nullable (epsilon) rules.

---

## Features

- **Variant 1: Recognizer (`Recognize`)** — Given a grammar and an input stream, determines if the string belongs to the language.
- **Variant 2: Parser Chart (`Parse_Chart`)** — Generates and returns the complete set of Earley Items (`Chart`). This exposes the parse forest, allowing users to extract and rebuild abstract syntax trees (AST).
- **Complex CFG Handling** — Implicitly supports nullable (epsilon) productions, ambiguous rule pathways, and deep recursions without infinitely looping.
- **Strong Typing** — Built leveraging Ada 2023 constructs, segregating Terminal and Non-Terminal logic safely behind strict records and dynamic predicates.
- **Safe Mutation** — Carefully sidesteps `Tampering_With_Cursors` errors when mutating charts during algorithmic prediction, scanning, and completion phases.

---

## Usage

To execute the tests (which act as a live usage example):

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
=== Earley Parser Test Suite ===
TEST 1 — Symbol Handling
  PASS — 1.1 Terminals with same name are equal
  PASS — 1.2 Terminals with different names are not equal
...
===  39 passed,  0 failed ===
```

---

## Testing

The accompanying `tests.adb` test suite acts as both a validation harness and an API tutorial.

**Testing covers:**

- **Functional Correctness** — Recognition of valid strings against custom, dynamically defined grammars.
- **Left and Right Recursion** — Ensuring the Predict/Complete loops terminate gracefully despite cyclic rules.
- **Ambiguity Verification** — Evaluating expressions (like `A -> A A | x`) yielding deep parsing charts without crashing.
- **Error Handling** — Rejection of improperly formed token sequences and adherence to function preconditions via Ada Contracts.
- **Edge Cases** — Empty (epsilon) rules gracefully evaluating to `True` for zero-token inputs.

---

## Building

**Prerequisites:**

- GNAT compiler with Ada 2022/2023 support.
- Make

To compile manually via the GPR project:

```bash
gnatmake -gnatwa -gnat2022 -Pearley_parser.gpr
```
