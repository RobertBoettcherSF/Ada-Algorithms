# Shunting-yard Algorithm in Ada 2023

---

## Project Overview

This project provides a robust, strongly-typed Ada 2023 implementation of Edsger Dijkstra's Shunting-yard algorithm. It translates mathematical infix expressions into Reverse Polish Notation (RPN) arrays and provides utilities for structural mapping. It accurately models operator precedence, left/right associativity nuances, explicit parenthesis overrides, and multi-variable arithmetic functions with comma delimiters.

---

## Features

- **Infix to Reverse Polish Notation (RPN)**: Core `To_Reverse_Polish_Notation` parser handling operators, parenthesis matching, functions, and variadic delimiters.
- **Abstract Syntax Tree (AST)**: A `To_AST` builder to instantiate a fully queryable binary structure directly from the RPN output stream.
- **Direct Execute Variants**: 
  - Executable `Evaluate_RPN` virtual machine using a continuous flow stack.
  - Executable `Evaluate_AST` virtual machine using deep recursion logic mapping.
- **Memory Security**: Built-in AST release mechanism (`Free_AST`) preventing access-type leaks, coupled with completely stack-allocated internal parsing logic using strictly bounded data formats.
- **Strict Verification**: Compile checks enforcing zero warnings on GNAT `-gnatwa` constraints. Defensive boundary conditions map all invalid edge cases (unmatched parentheses, syntax underflow, division-by-zero) to strictly named exceptions.

---

## Usage

The algorithm uses a `tests.adb` test suite acting as the main executable and usage demonstration format. Execute using make:

```bash
make test
```

### Expected Output

The system will run through 14 distinct testing sequences enforcing the algorithm's guarantees over different structural forms (i.e. Left vs Right operator bias validation), dumping PASS traces for each sub-check before concluding with **42 passed, 0 failed**.

---

## Testing

To verify functionality, the package implements validation via `tests.adb`, exercising these categories:

- **Functional Correctness**: Operator resolution, mathematical verification, associativity proofs.
- **Edge Cases**: Unbalanced functions, extraneous scopes, compound multi-variable execution states.
- **Error Handling**: Hard limits for `Capacity_Exceeded`, syntax-related `Invalid_Expression` interrupts, topological errors yielding `Mismatched_Parentheses`, and computation restrictions for `Math_Error` handling.
- **Invariants**: Testing explicitly asserts that evaluation through sequential RPN queue streams natively balances and mimics identical results compared to an intermediate deep-tree `AST_Node` hierarchy parsing.

---

## Building

To compile, ensure the GNAT compilation suite is installed.

- **Prerequisites**: GNAT (tested with FSF GNAT or GNAT Pro).
- **Ada Standard**: Specifically compiled for Ada 2023 standard behaviors (`-gnat2022`).

Build by simply typing `make` or `make all` inside the directory containing the file. Artifacts are emitted cleanly inside `obj/` and `bin/`.
