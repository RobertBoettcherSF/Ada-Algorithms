# First-Order Logic Evaluator in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation for defining and evaluating expressions in First-Order Logic (FOL), as described in formal mathematical logic. It implements the abstract syntax representation of terms (variables, constants, functions) and formulas (predicates, equality, propositional connectives, and quantifiers). Semantic evaluation executes over a user-defined interpretation and a configurable finite domain (universe of discourse), making universal and existential quantifiers directly computable.

## Features
* **Propositional Connectives**: Full evaluation of negation (`Not`), conjunction (`And`), disjunction (`Or`), implication (`Implies`), and biconditional (`Iff`).
* **Quantifier Evaluation**: Direct computation of universal (`Forall`) and existential (`Exists`) quantifiers by exhaustive finite-domain iteration.
* **Terms & Functions**: AST modeling and recursive evaluation of constants, variables, and unary/binary functions.
* **Equality & Predicates**: Built-in term equality comparison alongside extensible unary and binary relation predicates via tagged abstract interpretations.
* **Syntactic Analysis**: Automated detection of free vs. bound variables and verification of Prenex Normal Form (PNF).
* **Variable Substitution**: Deep-copy substitution of terms into formulas with quantifier scope shadowing preservation.
* **Ada Contract Aspects**: Extensive precondition annotations enforcing non-null pointers and valid structural invariants.

## Usage
Run the test suite using the provided `Makefile`:

```bash
make test
```

Expected output:
```text
Running tests...
Starting First-Order Logic Tests...
TEST 1 - Term Evaluation
  PASS - 1.1 Evaluate Constant 'c' -> 2
  PASS - 1.2 Evaluate Variable 'x' -> 1
  PASS - 1.3 Evaluate Unary Func f(c) -> 3
  PASS - 1.4 Evaluate Binary Func g(c, x) -> 1
TEST 2 - Basic Formula Evaluation
  PASS - 2.1 Evaluate True Predicate
  PASS - 2.2 Evaluate False Predicate
  PASS - 2.3 Evaluate AND
  PASS - 2.4 Evaluate OR
  PASS - 2.5 Evaluate NOT
...
TEST 13 - Edge Cases and Robustness
  PASS - 13.1 Precondition catches null in Make_Not
  PASS - 13.2 Precondition catches null in Make_Function
  PASS - 13.3 Has_Quantifier on null

===  39 passed,  0 failed ===
```

To clean build artifacts:
```bash
make clean
```

## Testing
The test suite in `tests.adb` contains 13 test categories with 39 assertions, covering:
* **Functional Correctness**: Term evaluation, relational predicates, truth tables for standard Boolean connectives, and equality semantics.
* **Quantifier Semantics**: Domain-wide universal quantification, witness-finding existential quantification, and nested quantifier scopes.
* **Scope & Binding**: Identification of free and bound variables across complex compound formulas.
* **Normal Forms**: Structural inspection of formulas for Prenex Normal Form compliance.
* **Variable Substitution**: Correct substitution in open formulas and blocking substitution under bound variable shadowing.
* **Edge Cases & Error Handling**: Precondition assertion failures triggered by null pointer parameters to node constructors.

## Building
* **Compiler**: GNAT toolchain (`gnatmake` or `gprbuild`).
* **Language Standard**: Ada 2023 / Ada 2022 (`-gnat2022` flag enabled).
* **Compilation Flags**: Enforces strict warning hygiene (`-gnatwa`).
