# Hindley-Milner Type System (Ada 2023)

## Project Overview
This repository contains a complete, robust implementation of the Hindley–Milner (HM) type system in Ada 2023 (ISO/IEC 8652:2023). Hindley–Milner is the foundational type inference algorithm utilized by statically typed functional languages such as ML, OCaml, and Haskell. The implementation models an extended lambda calculus supporting variables, function application, abstractions, and let-polymorphism. It features complete implementations of both canonical HM algorithms: the bottom-up Damas–Milner Algorithm W and the top-down checking Algorithm M, backed by Robinson's first-order syntactic unification algorithm with a strict occurs check.

## Features
* **Full Syntax Support**: Complete AST constructs for lambda calculus terms (`Expr_Var`, `Expr_App`, `Expr_Abs`, `Expr_Let`).
* **Strong Type Hierarchy**: Discriminated union representation supporting type variables (`Var_Id`), base/constant types, and arrow types (`->`).
* **Type Schemes & Polymorphism**: Full support for polytypes (universal quantification), free type variable computation, contextual generalization, and fresh instantiation.
* **Variant 1 — Algorithm W**: Classic bottom-up synthesis returning the most general unifier substitution alongside the inferred type.
* **Variant 2 — Algorithm M**: Top-down syntax-directed checking algorithm that pushes expected types down AST branches, identifying typing conflicts earlier.
* **Robust Soundness Guarantees**: Complete first-order unification with circularity detection (occurs check) raising strongly-typed `Unification_Error` exceptions.
* **Zero Warnings**: Fully compliant with `-gnatwa` under Ada 2022/2023 compilation standards.

## Usage
Execute the test suite directly via the provided Makefile:

```sh
make test
```

Expected output:
```text
Running tests...
bin/tests
TEST 1 — Constructors & Basic Types
  PASS — 1.1 Make_Var_Type is Kind_Var
  PASS — 1.2 Make_Arrow_Type left is Int
  PASS — 1.3 Equality identifies identical structure
TEST 2 — Free Type Variables
  PASS — 2.1 FTV count is 2
  PASS — 2.2 Contains Var 1
  PASS — 2.3 Contains Var 2
TEST 3 — Apply Substitution
  PASS — 3.1 Applied subst is Bool
  PASS — 3.2 Unmapped var remains var
  PASS — 3.3 Substitution over const type does nothing
TEST 4 — Compose Substitutions
  PASS — 4.1 Composed contains 2
  PASS — 4.2 S1(S2(2)) yields Bool
  PASS — 4.3 Composed maintains 1 -> Bool
TEST 5 — Unification Success
  PASS — 5.1 Unify resolved two variables
  PASS — 5.2 Var 1 bound to Bool
  PASS — 5.3 Var 2 bound to Int
TEST 6 — Unification Mismatch
  PASS — 6.1 Caught Unification_Error for Int != Bool
  PASS — 6.2 Int_Type is not Bool_Type
  PASS — 6.3 Kind constants match but names differ
TEST 7 — Unification Occurs Check
  PASS — 7.1 Caught Occurs Check
  PASS — 7.2 Var 1 is in Arrow FTVs
  PASS — 7.3 Var kind matches
TEST 8 — Algorithm W (Variable)
  PASS — 8.1 W inferred correctly for var
  PASS — 8.2 Subst is empty
  PASS — 8.3 Unbound var raises exception
TEST 9 — Algorithm W (Abstraction)
  PASS — 9.1 Identity inferred as Arrow
  PASS — 9.2 Arrow left is a variable
  PASS — 9.3 Arrow left equals right
TEST 10 — Algorithm W (Application)
  PASS — 10.1 Application result is Int
  PASS — 10.2 Context incremented correctly
  PASS — 10.3 Left child of app is Iden
TEST 11 — Algorithm W (Let Polymorphism)
  PASS — 11.1 Let bound id application returns Arrow
  PASS — 11.2 Result left is variable
  PASS — 11.3 Result right is matching variable
TEST 12 — Algorithm M (Top-Down Success)
  PASS — 12.1 M inferred identity against Int -> Int
  PASS — 12.2 M returns valid substitution
  PASS — 12.3 Context advanced
TEST 13 — Algorithm M (Top-Down Mismatch)
  PASS — 13.1 M failed correctly for identity vs Int -> Bool
  PASS — 13.2 Expected left is Int
  PASS — 13.3 Expected right is Bool

=== 39 passed, 0 failed ===
```

To clean build artifacts:
```sh
make clean
```

## Testing
The standalone verification runner `tests.adb` exercises all public subprograms across four essential verification and validation categories:
* **Structural Correctness & AST Invariants**: Tests 1 and 2 validate type constructors, equality predicates, and recursive free-variable extraction across complex arrow types.
* **Substitution Algebra**: Tests 3 and 4 verify substitution identity, idempotency, and associative composition invariants ($S_1 \circ S_2$).
* **Unification & Soundness Bounds**: Tests 5, 6, and 7 exercise bidirectional unification, base type mismatches, and the occurs check to prevent unsound recursive types like $\alpha = \alpha \to \text{Int}$.
* **Inference Algorithm Verification (W & M)**: Tests 8 through 13 validate bottom-up and top-down type inference on variable lookups, lambda abstractions ($\lambda x.\,x$), function application, and non-trivial let-polymorphism ($\mathbf{let}\ id = \lambda x.\,x\ \mathbf{in}\ id\ id$).

## Building
* **Prerequisites**: GNAT compiler distribution (e.g., GNAT FSF or Alire toolchain).
* **Ada Standard**: Ada 2022/2023 (`-gnat2022` flag enabled in Makefile).
* **Compiler Directives**: Built under `-gnatwa` to guarantee zero warnings.
