# LL Parser Implementation in Ada 2023

---

## Project Overview

This project provides a robust, complete implementation of **LL Parser algorithms** in Ada 2023 (ISO/IEC 8652:2023). It features multiple classical parsing variants discussed in formal language theory and compiler design literature, specifically focusing on top-down predictive parsing for an arithmetic expression language. The library includes lexical analysis (`Tokenize`), Table-Driven LL(1) parsing (`Parse_Table_Driven`), Recursive Descent LL(1) parsing (`Parse_Recursive_Descent`), and Lookahead LL(k) parsing (`Parse_Lookahead_K`).

---

## Features

- **Strong Typing &amp; Safety:** Custom enumerated token and symbol types, avoiding bare integers where domain concepts apply.
- **Contract-Based Programming:** Annotated public subprograms with `Pre` and `Post` aspects ensuring valid input constraints.
- **Multiple Parsing Variants:**
  - **Recursive Descent LL(1):** Directly encoded via mutually recursive functions.
  - **Table-Driven LL(1):** Explicit stack-based state machine driven by an LL(1) parse table.
  - **Lookahead LL(k):** Extended parser architecture supporting *k*-token lookahead preview buffers.
- **Robust Error Handling:** Distinct named exceptions (`Lexical_Error` and `Syntax_Error`) for invalid tokens and grammatical errors.
- **Clean Compilation:** Zero warnings under strict GNAT compiler flags (`-gnatwa -gnat2022`).

---

## Usage

To build and run the comprehensive test suite, use the provided Makefile:

```bash
make
make test
```

**Expected Output:**

```plaintext
Running tests...
  PASS — 1.1 First token is number 3
  PASS — 1.2 Second token is plus
  ...
===  45 passed,  0 failed ===
```

---

## Testing

The test suite (`tests.adb`) exercises 15 distinct test categories across functional correctness, operator precedence, parentheses nesting, identifiers, edge cases (single element), and error handling (lexical and syntax exceptions). Each test verifies at least 3 distinct assertions using built-in pragma `Assert`.

---

## Building

**Prerequisites:** GNAT compiler supporting Ada 2023 (e.g., GNAT 13+).

**Language Standard:** ISO/IEC 8652:2023 (Ada 2023).
