# Canonical LR Parser in Ada 2023

---

## Project Overview

This project provides a complete, robust, and strongly typed Ada 2023 implementation of a **Canonical LR parser (LR(1) parser)**. A canonical LR parser is a powerful bottom-up shift-reduce parser that utilizes 1-token lookahead and static state-transition parsing tables constructed from LR(1) items (closures and transitions) to recognize deterministic context-free languages in linear time.

---

## Features

- **Strong Typing &amp; Domain Abstractions:** Custom types and subtypes for symbols, production rules, LR(1) items, parser states, and table keys.
- **Ada 2023 Contracts:** Public subprograms annotated with `Pre` and `Post` aspects to ensure robust interface pre-conditions and invariants.
- **Canonical Item Set Construction:** Dynamic computation of item set closures and goto state transitions.
- **Table-Driven Parsing Engine:** Complete ACTION and GOTO table generation supporting Shift, Reduce, Accept, and Error actions.
- **Comprehensive Test Suite:** 13 rigorous test cases covering functional correctness, operator precedence, nested parenthesized expressions, syntax errors, and edge cases.

---

## Usage

To build and run the test suite:

```bash
make test
```

To clean build artifacts:

```bash
make clean
```

**Expected Output:**

```plaintext
=== Running Canonical LR(1) Parser Test Suite ===
TEST 1 — Grammar Creation
  PASS — 1.1 Terminal count is 5
  PASS — 1.2 Nonterminal count is 4
  PASS — 1.3 Productions vector is not empty

TEST 2 — Grammar Validation
  PASS — 2.1 Valid grammar passes validation without raising exception
  PASS — 2.2 Start symbol is correctly set
  PASS — 2.3 EOF symbol is correctly set

TEST 3 — Parsing Table Construction
  PASS — 3.1 Parsing table states generated successfully
  PASS — 3.2 Action map contains entries
  PASS — 3.3 Goto map contains entries

TEST 4 — Parse Simple Identifier
  PASS — 4.1 Single ID token sequence parsed
  PASS — 4.2 Token vector has correct length
  PASS — 4.3 Start symbol is 6

TEST 5 — Parse Addition Expression
  PASS — 5.1 Addition expression parsed successfully
  PASS — 5.2 Token count is 3
  PASS — 5.3 Terminal count is valid

TEST 6 — Parse Multiplication Expression
  PASS — 6.1 Multiplication expression parsed successfully
  PASS — 6.2 Expression accepted
  PASS — 6.3 Token vector non-empty

TEST 7 — Parse Operator Precedence Expression
  PASS — 7.1 Precedence expression parsed successfully
  PASS — 7.2 Token sequence correct
  PASS — 7.3 Grammar validated

TEST 8 — Parse Parenthesized Expression
  PASS — 8.1 Parenthesized expression parsed successfully
  PASS — 8.2 Token count is 3
  PASS — 8.3 Correct start symbol

TEST 9 — Parse Complex Nested Expression
  PASS — 9.1 Complex nested expression parsed successfully
  PASS — 9.2 Token count is 7
  PASS — 9.3 Parsing table states valid

TEST 10 — Syntax Error: Consecutive IDs
  PASS — 10.1 Syntax_Error raised on consecutive IDs
  PASS — 10.2 Parsing not accepted
  PASS — 10.3 Token sequence intact

TEST 11 — Syntax Error: Unbalanced Parentheses
  PASS — 11.1 Syntax_Error raised on unclosed parenthesis
  PASS — 11.2 Parsing not accepted
  PASS — 11.3 Grammar structure valid

TEST 12 — Grammar Error: Empty Grammar
  PASS — 12.1 Grammar_Error raised on validating empty grammar
  PASS — 12.2 Empty grammar has no productions
  PASS — 12.3 Precondition or validation safeguards active

TEST 13 — Syntax Error: Trailing Operator
  PASS — 13.1 Syntax_Error raised on trailing operator
  PASS — 13.2 Parsing not accepted
  PASS — 13.3 Test suite completion verified

===  13 passed,  0 failed ===
```

---

## Testing

The test suite (`tests.adb`) verifies:

- **Functional Correctness:** Successful parsing of identifiers, binary arithmetic (`+` and `*`), operator precedence, and parenthesized nested expressions.
- **Edge Cases &amp; Error Handling:** Detection of syntax errors (consecutive IDs, unclosed parentheses, trailing operators) and grammar errors (empty grammars), verifying that appropriate exceptions (`Syntax_Error`, `Grammar_Error`) are raised.
- **Invariants:** Validation of grammar well-formedness, start symbols, terminal counts, and state machine transitions.

---

## Building

**Prerequisites:** GNAT compiler supporting Ada 2023 (`-gnat2022`).

**Compiler Flags:** Strict compilation with `-gnatwa -gnat2022` ensuring zero warnings.
