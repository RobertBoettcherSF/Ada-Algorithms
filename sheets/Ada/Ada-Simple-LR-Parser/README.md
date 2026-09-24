# Simple LR Parser (SLR) in Ada 2023

---

## Project Overview

This project implements a complete, strongly-typed **Simple LR (SLR) Parser** in Ada 2023 (ISO/IEC 8652:2023). An SLR parser is an efficient bottom-up shift-reduce parser for deterministic context-free grammars. It utilizes LR(0) parsing states combined with FOLLOW sets to resolve shift-reduce and reduce-reduce conflicts. The implementation features a robust arithmetic expression grammar engine supporting operator precedence, parentheses, lexical tokenization, semantic evaluation, step-by-step parsing traces, and static grammar conflict checking.

---

## Features

- **Strong Typing**: Domain-specific types and subtypes (`Token_Kind`, `State_ID`, `Rule_ID`, `Parse_Action`, `Parse_Result`) enforce compile-time safety.
- **Ada 2023 Contracts**: Public subprograms annotated with preconditions (`Pre`) to guarantee valid inputs.
- **Multiple Variants**:
  - Standard non-preemptive SLR parsing with semantic evaluation.
  - Traced SLR parsing capturing detailed state transitions and stack operations.
  - Static grammar conflict analysis (`Has_Conflicts`).
  - Lexical tokenization of expressions with variable and numeric support.
- **Robust Error Handling**: Distinct named exceptions (`Parse_Error`, `Invalid_Token_Error`) for malformed syntax and lexical errors.
- **Comprehensive Test Suite**: 13 rigorous test categories with multiple assertions covering functional correctness, edge cases, and exception paths.

---

## Usage

To build and run the test suite, use the provided `Makefile`:

```bash
make test
```

This will compile the project and execute `tests.adb`, verifying all public APIs and displaying PASS/FAIL results for each assertion.

To clean build artifacts:

```bash
make clean
```

---

## Testing

The standalone test suite (`tests.adb`) exercises all public APIs and covers:

- **Functional Correctness**: Validating tokenization, arithmetic evaluation, operator precedence (`+` vs `*`), and parentheses nesting.
- **Execution Variants**: Testing both standard parsing and traced parse buffer generation.
- **Static Analysis**: Verifying grammar conflict detection.
- **Edge Cases**: Single numbers, single variables, and default semantic evaluation.
- **Error Handling**: Expecting and catching `Invalid_Token_Error` for illegal characters and `Parse_Error` for syntax violations.

---

## Building

- **Prerequisites**: GNAT compiler supporting Ada 2022/2023 (e.g., GNAT 12+).
- **Project File**: `simple_lr_parser.gpr`.
- **Compilation Flags**: `-gnatwa -gnat2022`.
