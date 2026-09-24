# Ada 2023 Simple Precedence Parser

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of a Simple Precedence Parser (a bottom-up context-free grammar parsing algorithm based on the Wirth-Weber precedence relations). The provided package accepts user-supplied precedence matrices and grammars, and evaluates input strings using a Shift-Reduce algorithm. It cleanly delineates edge cases, invalid matrix configurations, and stack invariants via Ada 2022's advanced contract mechanisms and aspect verification.

---

## Features

- **Static Grammar Validation**: A variant component checks simple precedence grammars for strict adherence to unique right-hand side properties.
- **Dynamic Matrix Parsing**: Standard algorithm evaluates expressions strictly according to `<` (Takes), `=` (Equal), and `>` (Yields) precedence logic.
- **Trace/Diagnostic Variant**: Allows logging of all parser decision loops, generating a full diagnostic breakdown of Shift, Reduce, and handle extraction for inspection.
- **Strongly-Typed Implementation**: Relies solely on native records and stack management without error-prone heap manipulation.
- **Ada 2022 Contracts**: Validates subprogram conditions using `Pre` preconditions and explicitly marked `Global => null` pure functions.

---

## Usage

Simply clone the repository and execute `make`.

```bash
make test
```

**Expected Output:**

```text
Running tests...
TEST 1 - Grammar Validation (Positive)
  PASS - 1.1 Valid simple precedence grammar recognized
  PASS - 1.2 Valid rules count is correct
  PASS - 1.3 Start symbol validity via direct bounds check
TEST 2 - Grammar Validation (Duplicate RHS)
  PASS - 2.1 Duplicate grammar rejected
  PASS - 2.2 Invalid duplicate RHS check A
  PASS - 2.3 Invalid duplicate RHS check B
...
===  45 passed,  0 failed ===
```

---

## Testing

The test suite spans 14 distinct test groups and over 40 assertions, encompassing:

- **Functional Correctness**: Demonstrates multi-level string parsing based on a classical recursive simple precedence grammar (`S -> aSb | c`).
- **Validation Rules**: Disproves broken configurations (such as grammars with duplicate or empty right-hand derivations).
- **Edge Cases**: Proves resilience against empty strings, unmapped characters, malformed terminal combinations, and non-terminating stack configurations.
- **Error Handling**: Exercises code paths validating handle boundaries and isolating syntactic failures at runtime. These tests are essential for ensuring system integrity under adversarial or malformed string states, verifying both `Parse` and `Parse_With_Trace` behaviors.

---

## Building

- **Prerequisites**: GNAT Community / FSF GCC Ada toolchain.
- **Requirements**: Requires standard Ada environment (configured automatically via the Makefile).
- **Standard**: Code leverages Ada 2022 (`-gnat2022`) standard properties and complies with strict zero-warning (`-gnatwa`) stylistic constraints.
