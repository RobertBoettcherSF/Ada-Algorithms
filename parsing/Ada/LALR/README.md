# LALR Parser Implementation in Ada

---

## Project Overview

This repository implements core algorithms related to Look-Ahead LR (LALR) parsing, as formalized in compiler theory. LALR parsers are heavily utilized by parser generators (like Yacc and Bison) because they significantly reduce the number of states compared to canonical LR(1) parsers while maintaining deterministic, linear-time execution bounds. This Ada implementation demonstrates two pivotal facets of the algorithm: standard shift-reduce execution via Action and Goto tables, and the defining LALR state merging methodology which maps LR(1) state cores to consolidated LALR states.

---

## Features

- **Table-Driven Parser:** Executes deterministic shift-reduce parsing on input sequences based entirely on parameterized state machines (Action and Goto tables), isolating logic from syntax rules.
- **State Merging Demonstration:** Incorporates the foundational algorithm distinguishing LALR from LR(1)—iterating over LR(1) states, locating identical item cores, and generating the necessary associative mapping logic to consolidate them without destroying lookahead viability.
- **Strong Typing and Hardened Code:** Makes robust use of Ada invariants, utilizing custom type constraints for terminals and non-terminals, mitigating invalid state transitions before evaluation.
- **Safety &amp; Resilience:** Employs defensive mechanisms including extensive bounds checking, input condition assertions, and deliberate exceptions (`Parse_Error`, `Invalid_Table_Error`) to halt on corrupted states or stack anomalies dynamically.

---

## Usage

To evaluate the parser behavior and verify structural integrity, build and run the provided test suite.

```bash
make test
```

**Expected Output:**  
The test run will comprehensively validate 13 aspects of the implementation and emit passing signals for all 39 internal assertions:

```plaintext
Running tests...
TEST 1 — Valid Parsings
  PASS — 1.1 Base token single ID
  PASS — 1.2 Complex ID PLUS ID
  PASS — 1.3 Complex ID PLUS ID PLUS ID
... [Additional test passes] ...
===  39 passed,  0 failed ===
```

---

## Testing

The `tests.adb` program serves symmetrically as the main executable, an API usage example, and a stringent verification mechanism. Key validations include:

- **Functional Correctness:** Verifying the internal stack management successfully parses linear and heavily recursive hierarchical grammars.
- **Error Handling:** Supplying mangled token structures to trigger deterministic failure rather than hanging or underflowing, simulating real syntax errors.
- **Edge Cases &amp; Invariants:** Protecting against malformed configuration tables, out-of-bounds Goto transitions, incomplete input terminals, and ensuring mapping operations cleanly handle offsets and isolated edge-boundaries smoothly.

---

## Building

**Prerequisites:** A functioning GNAT toolchain (GCC-based Ada Compiler).

**Target standard:** Designed around standard ISO/IEC 8652:2023 constructs, verified under strictly pedantic constraints with `-gnatwa -gnat2022`.

**Commands:** Compile the system statically using standard invocation via `make all` or run and link iteratively via `make test`.
