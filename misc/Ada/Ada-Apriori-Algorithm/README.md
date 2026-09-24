# Ada 2023 Apriori Algorithm Implementation

---

## Project Overview

An expert-level, highly robust implementation of the **Apriori Algorithm** in Ada 2023 (ISO/IEC 8652:2023). This package accurately models the Apriori pattern mining workflow, generating initial frequent item sets and distilling them into high-confidence association rules. It prioritizes strong static typing via generic bounded structures and rigorously utilizes Ada contracts (`Pre`, `Post`, `Global`) for compile-time/run-time correctness checks.

---

## Features

- **Frequent Item Sets:** Dynamically constructs *Lk* sets iteratively utilizing internal combinations (Apriori-Gen approach). Overloads accommodate absolute (`Support_Count`) or fractional (`Support_Ratio`) definitions.
- **Association Rules Generation:** Seamlessly deduces Antecedent ⇒ Consequent pairs filtered by rigorous fractional Confidence.
- **Maximal Item Sets Variant:** Built-in routine rejecting sets exhibiting frequent supersets.
- **Closed Item Sets Variant:** Extracts sets structurally unconstrained by equifrequent parent domains.
- **Safety Contexts:** Robust type guarantees and distinct named exceptions (`Invalid_Min_Support`, `Empty_Database`, `Empty_Item_Sets`) to trap edge-cases naturally.

---

## Usage

Run `make test` to automatically compile all components without warnings (`-gnatwa`) and immediately execute the test coverage suite.

**Expected Output:**

```text
Running tests...
TEST 1 — Frequent Item Sets (Absolute)
  PASS — 1.1 Total identified frequent sets is 8
  PASS — 1.2 Contains {1, 2} with exactly support count 3
  PASS — 1.3 Excludes pruned candidate {1, 3}
...
===  39 passed,  0 failed ===
```

---

## Testing

The comprehensive validation suite inside `tests.adb` guarantees invariant adherence:

- **Functional Correctness:** Verifies L-counts, relative support ceiling behavior, combinatorics resolution, and Apriori-Gen accuracy constraints.
- **Edge Cases:** Single elements, disjoint collections, uniform databases, and large single-line transactions verify iteration logic under pressure.
- **Error Handling:** Empty dataset exceptions ensure runtime defensive operations don't leak unchecked vectors or arithmetic by zero.

---

## Building

**Prerequisites:** GNAT Toolchain compatible with Ada 2022/2023 standard revisions.

Compilation employs explicit flags (`-gnatwa` for all warnings, `-gnat2022` enabling modern container extensions/aspect behaviors bridging to '23 features) leveraging standard Makefile architecture. No `main.adb` is required; GNAT builds direct towards `tests.adb` as primary executable payload.
