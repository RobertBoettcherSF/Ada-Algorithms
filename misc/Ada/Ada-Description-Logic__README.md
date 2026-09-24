# Description Logic ALC Evaluator in Ada 2023

## Project Overview
This project provides a robust, strongly typed, and entirely self-contained Ada 2023 implementation of a Description Logic (DL) model checker, focusing on the foundational ALC (Attributive Language with Complements) formalism. It implements an explicit Knowledge Base semantic evaluator capable of processing Abstract Syntax Trees representing DL concepts. It includes variants for constructing ALC expressions (Top, Bottom, Atomic, Intersection, Union, Negation, Universal, and Existential restrictions) and reasoning variants for evaluating them against finite models. Included are both TBox (Terminology Box) operations—like Subsumption, Equivalence, and Disjointness checks—and ABox (Assertional Box) operations—such as Concept and Role assertions.

## Features
* ALC Concept Expressions: Supports Top, Bottom, Atomic concepts, Intersection, Union, Negation, Universal restriction, and Existential restriction.
* Finite Interpretation Model Checking: Evaluates semantic concept extensions directly against a defined domain model.
* TBox Reasoning Tasks: Implements Subsumption, Equivalence, and Disjointness checks.
* ABox Reasoning Tasks: Implements concept assertions and role assertions.
* Robust Arena Allocation: Manages AST nodes efficiently without dynamic memory pointers (eliminating memory leaks and dangling pointers) utilizing fixed-capacity expression pools.
* Zero Warnings: Highly compliant Ada 2023 code compiling cleanly under -gnatwa.

## Usage
To build and execute the test suite, which serves as both validation and usage reference:

make test

Expected Output:
The system executes 13 structured test suites comprising over 40 distinct assertions, verifying standard description logic semantics, corner cases like vacuous truth under universal quantification, and bounded memory exception handling. The run terminates with zero failures:

=== 40 passed, 0 failed ===

## Testing
The tests.adb suite exercises comprehensive verification and validation (V&V) across multiple dimensions:
* Functional Correctness: Validates model-checking results against formal set semantics (e.g., verifying that empty role constraints evaluate universal restrictions to true vacuously while existential restrictions evaluate to false).
* Edge Cases: Validates behavior across disjoint sets, empty concept interpretations, and overlapping domains.
* Invariants & Bounds: Asserts that expressions maintain structural integrity and properly check node bounds.
* Error Handling: Ensures controlled handling and raising of custom exceptions (Invalid_Node, Expression_Full) when invalid AST references or arena capacity overflows occur.

## Building
Prerequisites: GNAT compiler (GCC) supporting Ada 2022/2023.

Build and run using the provided Makefile:
* make: Compiles tests into bin/tests using -gnatwa and -gnat2022.
* make test: Compiles and runs the test suite.
* make clean: Removes compilation artifacts and binary directories.

Alternatively, compile directly with GNAT project manager:
gprbuild -P description_logic.gpr
