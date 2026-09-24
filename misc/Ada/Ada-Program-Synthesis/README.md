# Program Synthesis in Ada 2023

This project provides a complete, strongly-typed implementation of Program Synthesis techniques as formalized in modern software engineering and formal methods. It synthesizes Abstract Syntax Tree (AST) programs from higher-level specifications via inductive enumerative search (Programming by Example), sketching (template-driven constraint resolution), and deductive synthesis (constructive proof via algebraic term rewriting). By modeling a clean domain-specific language (DSL) for mathematical operations over custom value types, the library demonstrates automated program discovery and verification natively in Ada 2023 (ISO/IEC 8652:2023).

## Features

* **Inductive Synthesis (Programming by Example)**: Employs a bottom-up enumerative search algorithm exploring AST spaces by increasing node budgets to find minimal programs satisfying given input/output examples.
* **Sketching**: Resolves partially specified programs containing holes (`?1`, `?2`) by searching a bounded constant space to complete the template against behavioral specifications.
* **Deductive Synthesis**: Implements constructive proof synthesis by systematically applying algebraic rewrite rules across equation trees (`Left = Right`) to isolate the target output variable and produce an explicit program.
* **Robust Typing and Contract Aspects**: Employs dedicated domain types (`Value_Type`, `Example`, `Node_Kind`, `AST_Node`) with explicit Ada contract aspects (`Pre`, `Post`).
* **Deterministic Memory Management**: Clean AST cloning, recursive destruction via `Ada.Unchecked_Deallocation`, and isolated exception handling with zero memory leakage.

## Usage

Build and run the test suite directly from the command line:

```bash
make test
```

Expected output:

```text
--- Starting Program Synthesis Tests ---
TEST 1 — Evaluate Constants and Variables
  PASS — 1.1 Evaluate Constant C=42
  PASS — 1.2 Evaluate Variable X=5
  PASS — 1.3 Evaluate Variable X=-10
TEST 2 — Evaluate Operators
  PASS — 2.1 Evaluate Addition (10+5=15)
  PASS — 2.2 Evaluate Subtraction (10+5-2=13)
  PASS — 2.3 String Representation
TEST 3 — Evaluate with Holes
  PASS — 3.1 Evaluate Holes (10-4=6)
  PASS — 3.2 Missing Holes handled
  PASS — 3.3 To_String with holes
TEST 4 — Satisfies Contract
  PASS — 4.1 Satisfies returns True for correct program
  PASS — 4.2 Satisfies returns False for wrong program
  PASS — 4.3 Clone retains behavior
TEST 5 — Inductive Synthesis (Constant)
  PASS — 5.1 Result is not null
  PASS — 5.2 Target constant found
  PASS — 5.3 Program satisfies examples
TEST 6 — Inductive Synthesis (Variable)
  PASS — 6.1 Result is not null
  PASS — 6.2 Target variable found
  PASS — 6.3 Program satisfies examples
TEST 7 — Inductive Synthesis (Operation)
  PASS — 7.1 Result is not null
  PASS — 7.2 Expression synthesizes X+1 or 1+X
  PASS — 7.3 Satisfies execution logic
TEST 8 — Inductive Synthesis (Failure)
  PASS — 8.1 Failed correctly (exception)
  PASS — 8.2 State remains clean
  PASS — 8.3 Synthesis boundaries respected
TEST 9 — Sketching Synthesis (1 Hole)
  PASS — 9.1 Found completion
  PASS — 9.2 Program string check
  PASS — 9.3 Validates successfully
TEST 10 — Sketching Synthesis (2 Holes)
  PASS — 10.1 Synthesized 2 holes
  PASS — 10.2 Final AST contains no holes
  PASS — 10.3 Native evaluation pass
TEST 11 — Sketching Synthesis (Failure)
  PASS — 11.1 Raised Synthesis_Failed safely
  PASS — 11.2 Memory isolated
  PASS — 11.3 Search limits respected
TEST 12 — Deductive Synthesis (Isolate Out)
  PASS — 12.1 Deduction successful
  PASS — 12.2 Rewrote to X + 3
  PASS — 12.3 Extracted program valid
TEST 13 — Deductive Synthesis (Nested Isolate)
  PASS — 13.1 Complex deduction resolved
  PASS — 13.2 Rewriting sequence correct
  PASS — 13.3 Value correctness
TEST 14 — Deductive Synthesis (Right Subtraction)
  PASS — 14.1 Deduction completed
  PASS — 14.2 Reverse subtraction handled
  PASS — 14.3 Output validation
TEST 15 — Deductive Synthesis (Failure)
  PASS — 15.1 Raised failure successfully
  PASS — 15.2 Avoided infinite loops
  PASS — 15.3 Graceful exit

=== 45 passed, 0 failed ===
```

## Testing

The test suite (`tests.adb`) serves as an automated verification and validation framework as well as an executable reference for the package API:

* **Functional Correctness**: Confirms that synthesized programs accurately mirror mathematical specifications and evaluate reliably across positive, negative, and zero values.
* **Edge Cases**: Tests evaluation boundaries, single-node AST structures, nested expression chains, and asymmetric algebraic equations.
* **Invariants**: Verifies that AST cloning maintains structural semantics and that synthesis engines preserve input trees without unintended mutations.
* **Error Handling**: Exercises deliberate failure paths where synthesis budgets are exceeded, sketches are unsatisfiable, or term rewriting cannot eliminate terms, validating that `Synthesis_Failed` and `Evaluation_Error` are raised predictably.

## Building

* **Prerequisites**: GNAT compiler toolchain (`gnatmake`, `gprbuild`).
* **Language Standard**: Ada 2023 (ISO/IEC 8652:2023) enabled via `-gnat2022`.
* **Compilation Profile**: Strict warning enforcement using `-gnatwa` with clean zero-warning builds.
