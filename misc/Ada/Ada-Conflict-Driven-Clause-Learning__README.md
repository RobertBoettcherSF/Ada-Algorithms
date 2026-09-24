# Conflict-Driven Clause Learning (CDCL) in Ada 2023

## Project Overview
This repository provides a complete, strongly-typed implementation of the Conflict-Driven Clause Learning (CDCL) algorithm for solving the Boolean Satisfiability (SAT) problem. The CDCL algorithm systematically assigns truth values to variables, uses Boolean Constraint Propagation (BCP) to infer mandatory assignments, builds implication graphs, and analyzes conflicts using the First Unique Implication Point (1UIP) technique to derive learned clauses. Non-chronological backtracking (backjumping) prunes the search space far more effectively than classical DPLL.

---

## Features
* `Solve_Basic` — Core CDCL implementation utilizing 1UIP conflict analysis and non-chronological backjumping.
* `Solve_With_Restarts` — Periodically resets the decision tree to level 0 while retaining learned clauses to avoid heavy-tailed runtimes.
* `Solve_With_Clause_Deletion` — Prunes learned clauses once capacity exceeds configured bounds to avoid unbounded memory growth.
* Strong Type Safety — Dedicated types for variables, literals, truth values, and clauses instead of raw integers.

---

## Usage
Run the comprehensive standalone test suite directly via make:

$ make test

Expected output verifies every assertion step-by-step and ends with a confirmation that all suites succeeded:

  PASS — 1.1 Status Satisfiable
  PASS — 1.2 Validation passes
  ...
  === 45 passed, 0 failed ===

To use CDCL in code, initialize a Formula, add clauses, and invoke one of the solver variants:
* `Init_Formula (F, Vars => 2);`
* `Add_Clause (F, C);`
* `Status := Solve_Basic (F, Assignments);`
* `Valid  := Is_Satisfied (F, Assignments);`

---

## Testing
The test suite in `tests.adb` covers multiple verification and validation layers:
* Functional Correctness: Proves correct identification of SAT and UNSAT instances across all algorithm variants.
* Edge Cases: Exercises formulas with no clauses, single variables, and immediate unit propagations.
* Error Handling: Confirms that `Bad_Literal` and `Invalid_Formula` exceptions are raised for zero-literals and out-of-range variable IDs.
* Invariants: Cross-checks all generated assignments against the original formula clauses with `Is_Satisfied`.

---

## Building
* Prerequisites: GNAT compiler supporting Ada 2022/2023 (`-gnat2022` or `-gnat2023`).
* Build executable: `make all`
* Execute test suite: `make test`
* Clean build tree: `make clean`
