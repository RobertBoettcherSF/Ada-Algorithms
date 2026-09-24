# DPLL Algorithm in Ada 2023

## Project Overview
The Davis-Putnam-Logemann-Loveland (DPLL) algorithm is a complete, backtracking-based search algorithm for deciding the satisfiability of propositional logic formulas in conjunctive normal form (CNF-SAT). This library provides a clean, strongly typed implementation in Ada 2023 (ISO/IEC 8652:2023), including the core backtracking engine, unit propagation (Boolean constraint propagation), pure literal elimination, and multiple branching heuristics.

## Features
- **Standard DPLL**: Full backtracking search combining recursive assignment, unit propagation, and pure literal elimination.
- **Variant Without Pure Literal Rule**: Modern SAT solvers often omit pure literal elimination due to data structure overhead; this variant isolates unit propagation with backtracking.
- **Standalone Unit Propagation**: Subprogram to evaluate formulas exclusively through deterministic unit clause deduction without non-deterministic branching.
- **Standalone Pure Literal Rule**: Subprogram to iteratively detect and satisfy pure literals.
- **Configurable Branching Heuristics**:
  - `First_Unassigned`: Default static variable ordering.
  - `Max_Occurrences`: Dynamic variable selection based on unassigned literal frequency across remaining clauses.
  - `MOMS`: Maximum Occurrences in clauses of Minimum Size, targeting high-impact resolution early.
- **Strong Typing and Formal Contracts**: Custom domain types (`Variable_Id`, `Clause`, `Formula`, `Valuation`), contract aspects (`Pre`, `Post`, `Inline`), and zero bare arithmetic types.
- **Validation**: Independent model checker (`Is_Model`) guaranteeing verification of solver results against original clauses.

## Building
Prerequisites:
- GNAT compiler supporting Ada 2023 (or Ada 2022 compatibility mode `-gnat2022`)
- GNAT project manager (`gnatmake` or `gprbuild`)
- Make utility

Compile the test runner:
```bash
make
```

## Usage
Run the test suite using `make test`:
```bash
make test
```

Expected output:
```text
Running tests...
TEST 1 - Literal Manipulation and Invariants
  PASS - 1.1 Make_Pos produces positive sign
  PASS - 1.2 Make_Neg produces negative sign
  PASS - 1.3 Double negation identity
TEST 2 - Empty Formula (Trivially Satisfiable)
  PASS - 2.1 Empty formula is valid
  PASS - 2.2 Status is Satisfiable
  PASS - 2.3 Model verification on empty formula
TEST 3 - Single Unit Clause (Satisfiable)
  PASS - 3.1 Single unit clause is valid
  PASS - 3.2 Status is Satisfiable
  PASS - 3.3 Assigned model sets Var 1 to True
TEST 4 - Immediate Contradiction (Unsatisfiable)
  PASS - 4.1 Formula is valid
  PASS - 4.2 Contradiction status is Unsatisfiable
  PASS - 4.3 Unit propagation alone detects contradiction
TEST 5 - Cascading Unit Propagation
  PASS - 5.1 Resolved via Unit Propagation Only
  PASS - 5.2 DPLL also returns Satisfiable
  PASS - 5.3 Correct model deduction (A=T, B=T, C=T)
TEST 6 - Pure Literal Elimination
  PASS - 6.1 Pure literal resolves formula
  PASS - 6.2 Pure literal assigned True for A
  PASS - 6.3 DPLL verifies model
TEST 7 - Variant Without Pure Literal Elimination
  PASS - 7.1 Formula is Satisfiable
  PASS - 7.2 Model verified
  PASS - 7.3 Both A and B are True in unique solution
TEST 8 - All Four 2-Variable Combinations (Unsatisfiable)
  PASS - 8.1 Default heuristic detects unsat
  PASS - 8.2 MOMS heuristic detects unsat
  PASS - 8.3 No-pure variant detects unsat
TEST 9 - Branching Heuristic: Max Occurrences
  PASS - 9.1 Solver returns Satisfiable
  PASS - 9.2 Model is verified
  PASS - 9.3 Formula remains valid under heuristic
TEST 10 - Branching Heuristic: MOMS
  PASS - 10.1 Solved via MOMS
  PASS - 10.2 Resulting model satisfies formula
  PASS - 10.3 Solution model assigns valid states
TEST 11 - Pigeonhole Principle (PHP 3 to 2, UNSAT)
  PASS - 11.1 PHP 3 into 2 is Unsatisfiable (DPLL)
  PASS - 11.2 PHP 3 into 2 is Unsatisfiable (Max_Occurrences)
  PASS - 11.3 PHP 3 into 2 is Unsatisfiable (Without Pure Literal)
TEST 12 - Error Handling & Precondition Validation
  PASS - 12.1 Is_Valid_Formula detects out-of-bounds variable
  PASS - 12.2 Solve_DPLL raises Invalid_Formula_Error
  PASS - 12.3 Unit_Propagation_Only raises Invalid_Formula_Error
TEST 13 - Model Evaluation and Invariant Checking
  PASS - 13.1 Unassigned model does not satisfy formula
  PASS - 13.2 Conflicting model evaluated as false
  PASS - 13.3 Satisfying valuation returns true in Is_Model

===  39 passed,  0 failed ===
```

To clean build artifacts:
```bash
make clean
```

## Testing
The test runner in `tests.adb` contains 13 test cases and 39 assertions covering:
- **Literal and Invariant Arithmetic**: Double negation and identity integrity.
- **Edge Cases**: Empty formulas (trivially SAT) and single unit literals.
- **Deduction Mechanisms**: Independent validation of cascading unit propagation chains and pure literal elimination.
- **Solver Combinations**: Evaluating standard DPLL vs. modern variant without pure literals.
- **Heuristic Exploration**: `First_Unassigned`, `Max_Occurrences`, and `MOMS` branching behavior on identical CNF inputs.
- **Known UNSAT Instances**: Full truth table contradictions (2-SAT cycles) and Pigeonhole Principle instances (PHP 3 pigeons into 2 holes).
- **Defensive Error Handling**: Detecting malformed formulas and raising `Invalid_Formula_Error`.
