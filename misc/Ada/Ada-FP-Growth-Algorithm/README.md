# FP-Growth Algorithm in Ada 2023

---

## Project Overview

This project is a complete, strictly typed Ada 2023 implementation of the **FP-Growth algorithm** for Association Rule Learning. Unlike generating algorithms (like Apriori) that suffer from heavy combinatorics during candidate generation, FP-Growth uses a compact, prefix-tree data structure (the FP-tree) and a divide-and-conquer approach. It works by scanning the dataset to count frequencies, compressing the transactions into an FP-Tree, and recursively generating conditional pattern bases to extract frequent itemsets.

---

## Features

- **FP-Tree Construction:** Highly efficient, in-memory pointerless prefix-tree mapping.
- **Conditional Pattern Base Mining:** Standard FP-Growth recursive traversal.
- **Association Rule Engine:** Extracts reliable `Antecedent => Consequent` rules with specified minimum confidence metrics.
- **Strong Safety Mechanisms:** Strict usage of Ada vectors, subsets, bounding, custom exceptions (`Empty_Database_Error`, `Invalid_Threshold_Error`), and pure index arrays guaranteeing zero heap-fragmentation memory leaks.

---

## Usage

The system interacts via the `Fp_Growth` package, which allows you to pass in transaction datasets and dynamically query itemsets or rules.

Run `make test` to automatically compile and observe the system through the included standalone integration and unit tests:

```bash
make test
```

**Expected Output:**

```plaintext
Running tests...
--- Starting FP-Growth Test Suite ---
TEST 1 - Frequent Itemset Mining (Standard Support)
  PASS - 1.1 Contains results (not empty)
...
===  39 passed,  0 failed ===
```

---

## Testing

The embedded standalone `tests.adb` validates algorithm execution with 39 strict assertions covering 13 individual scenarios.

- **Functional Correctness:** Validates proper node homonym linking, recursive prefix counting, exact floating-point confidence divisions, and subset combinatorial loops.
- **Edge Cases:** Validates single-item transactions, disconnected disparate transaction bases, duplicate input data masking, oversaturated support requirements.
- **Error Handling:** Defends gracefully against bounds violations (`Min_Confidence > 1.0`), blank data structures, and negative thresholds leveraging specific exceptions.

---

## Building

**Prerequisites:** GNAT Toolchain

The algorithm leverages modern standard functionality (via `-gnat2022`).

```bash
make all
```
