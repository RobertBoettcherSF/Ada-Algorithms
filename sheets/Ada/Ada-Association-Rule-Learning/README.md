# Association Rules Learning (Ada 2023)

---

## Project Overview

This project provides an Ada 2023 implementation of **Association Rule Learning** algorithms for data mining. It is designed to discover interesting relations between variables in large databases by extracting frequent itemsets and calculating strong relational metrics like support, confidence, lift, leverage, and conviction. It includes standard pruned approaches (Apriori) alongside naive brute-force fallback generation for robust algorithmic validation.

---

## Features

- **Apriori Algorithm Variant:** Efficiently extracts frequent itemsets using classical bottom-up breadth-first search and subset pruning logic.
- **Brute-Force Variant:** Provides a secondary baseline algorithm that leverages combinatorial power sets for full database verification.
- **Rule Generation Engine:** Isolates strong association rules (`Antecedent -> Consequent`) from frequent datasets bounded by a minimum confidence threshold.
- **Full Metric Suite:** Calculates standard relational strengths natively: Support, Confidence, Lift, Leverage, and Conviction.
- **Strong Typing and Safeguards:** Employs explicit Ada constraint aspects, custom subtypes (`Support_Value`, `Item_ID`), rigorous generic vectors/sets, and robust edge-case exception handling (division-by-zero, perfect confidence boundaries).

---

## Usage

To build and run the provided test suite, simply use the `make test` command at the repository root. The test suite automatically doubles as a demonstration file (`tests.adb`) calling every subprogram variant with real inputs:

```bash
make test
```

**Expected Output:**  
The terminal will build the target without warnings (enforced strictly via `-gnatwa`) and immediately output test confirmations:

```plaintext
Running tests...
TEST 1 - Database Preconditions (Empty DB handling)
  PASS - 1.1 Empty DB Support throws Precondition
...
===  42 passed,  0 failed ===
```

---

## Testing

The package bundles a standalone validation harness encompassing 14 different testing configurations and 42 individual invariant assertions. Testing encompasses:

- **Functional Correctness:** Explicit numeric comparisons mapping manual statistical calculations to the implementations of Lift, Conviction, and Confidence.
- **Variant Consensus:** Verifies that both Apriori and Brute-Force algorithms extract identically consistent results under identical support conditions.
- **Edge Cases &amp; Error Handling:** Validates behavior upon hitting mathematical anomalies, including 1.0 confidence bounds (conviction infinity checks), null antecedents, empty item requests, zero-support scenarios, and 100% support boundary limits.

---

## Building

**Prerequisites:** GNAT compiler supporting the Ada 2022/2023 language specification (`-gnat2022`). Standard POSIX make tool.
