# Hindley-Milner Type Inference (Algorithm W) in Ada 2023

## Project Overview
This project provides a robust, strictly-typed implementation of Hindley-Milner Type Inference written in Ada 2023 (ISO/IEC 8652:2023). It primarily implements **Algorithm W**, a purely functional approach to deriving principal types for expressions in a lambda-calculus like language. The implementation supports variables, applications, abstractions, and polymorphic `let`-bindings. It strictly ensures memory safety handling recursive types through safe pointers, handles cyclical type structures using occurs checks, and avoids unbound parameter shadowing.

## Features
*   **Strong Typing:** Custom sum types (`Type_Node`, `Expr_Node`) with distinct node kinds mapping directly to theoretical constructs.
*   **Polymorphic Let (Algorithm W):** Features true parametric polymorphism. Includes type generalization and fresh type variable instantiation for generic abstractions.
*   **Monomorphic Let Variant:** Includes a constrained mode (`Infer_Type_Monomorphic`) simulating environments without `let`-generalization to contrast against full polymorphism.
*   **Contracts-Driven Safety:** Leverages Ada 2023 aspects (`Pre`, `Post`) dynamically verified at runtime.
*   **Robust Edge Case Handling:** Protects against occurs check cyclic references (`Unification_Error`) and undefined bindings (`Unbound_Variable_Error`).

## Usage
The API interacts primarily through `Infer_Type` and `Infer_Type_Monomorphic` using abstract syntax tree inputs. Usage is modeled comprehensively in `tests.adb`.

```bash
make test
```

**Expected Output:**

```text
Running tests...
TEST 1 — Type Constructors
  PASS — 1.1 Type_Var created
  PASS — 1.2 Type_Base created
  PASS — 1.3 Type_Arrow created properly
...
TEST 14 — Infer Monomorphic Let
  PASS — 14.1 Mono let self-application caught by occurs check
  PASS — 14.2 Mono let id applied to Int yields Int
  PASS — 14.3 Variant correctly exposes Algorithm W mono mode

=== 42 passed, 0 failed ===
```

## Testing
The embedded test suite uses unit assertions mapping exactly to discrete steps of type inference to support Verification and Validation (V&V). Testing categories include:

* **Functional Correctness:** Verifies correct inference outcomes (e.g., `let id = \x -> x in id` safely inferring polymorphic `a -> a`).
* **Invariants:** Validates rules like correct composition order, free-type variable extraction, and variable capture protection during substitution.
* **Error Handling:** Intentionally breaches unification rules (e.g., self-application without types yielding unification cyclic fails) validating standard exception boundaries.

## Building
**Prerequisites:** GNAT Toolchain (GCC-based Ada compiler).

**Standard:** Ada 2023 (`-gnat2022` flag handles the most recent iteration).

Execute the build system using the `Makefile` provided, which will build directly into `bin/` cleanly warning-free (`-gnatwa`).
