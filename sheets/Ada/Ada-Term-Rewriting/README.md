# Ada 2023 Term Rewriting System

This project provides an implementation of a Term Rewriting System (TRS) adhering to the Ada 2023 (ISO/IEC 8652:2023) standard. Term rewriting is a foundational model of symbolic computation where terms are progressively transformed by directed equations (rewrite rules) until a normal form is reached. The library supports abstract syntax tree generation via Ada indefinite multiway trees, non-linear syntactic pattern matching, variable substitution, single-step rewriting under both leftmost-outermost and leftmost-innermost evaluation strategies, and bounded full normalization.

## Features
- Tree-Structured Terms: Distinction between variable terminals and n-ary function symbols.
- Non-Linear Pattern Matching: Left-hand sides can enforce structural equality across multiple occurrences of the same variable.
- Rule Validation: Enforces syntactic validity so variables on the right-hand side must be bound on the left-hand side, and forbids standalone variable left-hand sides.
- Multiple Rewriting Strategies: Supports both Outermost (normal-order / lazy) and Innermost (applicative-order / strict) single-step reductions.
- Normalization Engine: Iterative rewriting to normal form with an execution limit to prevent infinite substitution cycles.

## Usage
Run the automated test suite and demo runner using make:

```bash
make test
```

Expected output:

```text
=== Term Rewriting Test Suite ===
TEST 1 — Variable Creation
  PASS — 1.1 X = X
  PASS — 1.2 X /= Y
  PASS — 1.3 X = Z structurally
  PASS — 1.4 Formatting
TEST 2 — Constant Creation
  PASS — 2.1 A /= X
  PASS — 2.2 A = C structurally
  PASS — 2.3 Formatting constant
TEST 3 — Function Creation
  PASS — 3.1 Formatting F
  PASS — 3.2 Formatting G
  PASS — 3.3 F /= G
TEST 4 — Rule Validation (LHS Variable)
  PASS — 4.1 LHS Variable caught successfully
  PASS — 4.2 Still operating correctly
  PASS — 4.3 System uncorrupted
TEST 5 — Rule Validation (RHS Unbound Variable)
  PASS — 5.1 RHS unbound variable caught successfully
  PASS — 5.2 Still operating correctly
  PASS — 5.3 System uncorrupted
TEST 6 — Valid Rule Creation
  PASS — 6.1 Valid rule creation succeeded
  PASS — 6.2 Valid rule does not crash
  PASS — 6.3 Valid rule structure
TEST 7 — Single Rewrite Step (Root Match)
  PASS — 7.1 Root rewrites to A
  PASS — 7.2 Original term untouched
  PASS — 7.3 Step result is deterministic
TEST 8 — Single Rewrite Step (No Match)
  PASS — 8.1 Unknown function no-op
  PASS — 8.2 Output matches input
  PASS — 8.3 Structure intact
TEST 9 — Rewriting Strategy Distinctions
  PASS — 9.1 Outermost rewrites root to C
  PASS — 9.2 Innermost evaluates arg first to f(A)
  PASS — 9.3 They are functionally distinct
TEST 10 — Non-Linear Pattern Matching
  PASS — 10.1 Pattern requires equality
  PASS — 10.2 Did not rewrite
  PASS — 10.3 Identical arguments match
TEST 11 — Normalization (Exhaustive)
  PASS — 11.1 Reached Normal form
  PASS — 11.2 Result differs from input
  PASS — 11.3 Normal form verified
TEST 12 — Normalization Max Steps Exception
  PASS — 12.1 Limit exception raised successfully
  PASS — 12.2 Handled infinite rewrites safely
  PASS — 12.3 Environment untouched
TEST 13 — Complex Nested Replacements
  PASS — 13.1 Variables swapped
  PASS — 13.2 Preservation of subtrees
  PASS — 13.3 Immutable AST inputs

=== 40 passed, 0 failed ===
```

## Testing
The standalone executable `tests.adb` exercises the public interface across four verification and validation dimensions:
- Functional Correctness: Validates term creation, string serialization, tree comparison, and root/subterm substitution steps.
- Strategy Differences: Verifies divergent intermediate terms produced by leftmost-outermost versus leftmost-innermost order on nested reductions.
- Edge Cases: Tests non-linear patterns (e.g., duplicate argument matching), terms with no matching rules, and identity functions.
- Error Handling and Invariants: Asserts that invalid rules (such as free variables in the right-hand side or variable roots on the left-hand side) trigger `Invalid_Rule_Error`, and infinite reduction loops raise `Limit_Exceeded_Error` without modifying external state.

## Building
- Prerequisites: GNAT compiler supporting `-gnat2022` / `-gnat2023` flags (GCC 12+ or GNAT Community/FSF).
- Standard: Ada 2023 (ISO/IEC 8652:2023).
- Build system: GNAT Project files (`.gpr`) driven by GNU Make.
