# Unicode Collation Algorithm (UCA) implementation in Ada

## Project Overview
This project is an Ada implementation of the core architecture of the [Unicode Collation Algorithm (UCA)](https://en.wikipedia.org/wiki/Unicode_collation_algorithm). UCA is a customizable algorithm used to compare two strings in a way that aligns with human linguistic expectations rather than raw binary/ASCII values. Because a full UCA engine requires parsing the massive Default Unicode Collation Element Table (DUCET), this implementation securely models the algorithmic logic using a strictly-typed, mocked subset of ASCII elements to demonstrate L1 (Base), L2 (Accent), and L3 (Case) multi-level collation.

## Features
* **Multi-Level Comparison Engine:** Compares strings based on Primary weights (characters), then Secondary (accents/diacritics), then Tertiary (case), compliant with UCA.
* **Standard Variant:** Full multi-level weight verification.
* **Variable Weighting Variant (Ignore Punctuation):** Shift-trims punctuation (like hyphens and spaces) at all comparison levels.
* **Tailoring Variant:** Supports custom, locale-specific weight modifications (e.g., altering the sort hierarchy of specific characters safely at runtime).

## Testing (Verification & Validation)
This codebase includes a pessimistic test suite (`tests.adb`) focused on stringent Verification and Validation (V&V) principles for critical systems. The test suite operates on the initial assumption that the code is *faulty and broken*. Tests only yield a `PASS` when that assumption is rigorously mathematically disproved. 

### What Each Test Category Verifies
1. **Functional Correctness (Tests 1, 2, 3):** Validates L1 and L3 hierarchy bindings. Proves that multi-level tie-breaking evaluates accurately according to UCA specification.
2. **Edge Cases (Tests 4, 5):** Validates memory/pointer boundaries by pushing mismatched array sizes and empty strings (`""`) to ensure no constraint errors or buffer over-reads occur.
3. **Data Overrides / Error Handling (Test 8):** Tailoring modifies immutable state via copy-overrides safely. This validates that localization changes do not corrupt the foundational weight table.
4. **Algorithmic State (Tests 6, 7, 9):** Ensures Variable Weighting correctly filters zero-weights dynamically without crashing the index counters of the strings.

### Why These Tests Matter
In safety-critical or infrastructure-level software (like database sorting indexing), a subtle collation flaw can result in catastrophic data corruption or un-retrievable database rows. By disproving failure conditions structurally, these tests guarantee reliability, strict adherence to the requirements, and type safety.

## Usage

### Compilation Instructions
The project is built around the GNAT toolchain and a provided Makefile.

Ensure GNAT is installed on your machine. To compile the environment and test suite:
```bash
make all
