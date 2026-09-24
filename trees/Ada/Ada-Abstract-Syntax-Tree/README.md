# Abstract Syntax Tree (AST) in Ada 2023

Project Overview:
This project provides a robust, strongly typed, and memory-safe Ada 2023 implementation of an Abstract Syntax Tree (AST). It models dynamic construction, traversal, unparsing (stringification), evaluation (interpretation), and metrics analysis (node count, depth calculation). The AST accommodates integers, unary/binary expressions, and environment-bound variables while safeguarding memory via proper traversal deallocation.

Features:
* AST Construction: Dynamic allocation of variant records (Literals, Variables, Unary/Binary Operations).
* AST Interpreter Variant: Recursive context evaluation mapped against runtime environments resolving variables to integer values.
* AST Code Generation Variant: Pre-order/In-order textual unparsing to reconstruct formatted source expressions from the tree.
* AST Metrics Variants: Computes the structural complexity (node counts) and depth mappings of arbitrary abstract syntaxes.
* Robust Contracts: Utilizes strictly enforced Ada 2023 Preconditions and Postconditions across tree boundaries.
* Zero Warnings: Carefully written to bypass any issues under GNAT `-gnatwa`.

Usage:
To compile and immediately execute the test suite displaying all operations:
`make test`
You should see a detailed PASS list for all 13 tests, checking literals, recursive formulas, depth boundaries, error states, and unparsing output. 

Testing:
The self-contained `tests.adb` acts simultaneously as documentation and a rigorous validation suite. It covers:
* Functional Correctness: Asserts correct mathematical translations.
* Error Handling: Bounds checks and runtime trap validations against illegal mathematical actions (e.g. Division by Zero evaluation mapping).
* Edge Cases: Processing singleton trees, deeply nested trees (11+ nodes), and tracking variable environments mid-evaluation.
* Invariants checks: Postconditions ensure dynamic heap segments correctly deallocate nullifying dangling pointer risks.

Building:
Prerequisites: A GNAT compiler supporting Ada 2023 specifications (`gnatmake`). 
Execute `make all` to build standard binaries into the `/bin` directory or `make clean` to scrub artifacts.
