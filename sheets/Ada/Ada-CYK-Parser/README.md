# Cocke-Younger-Kasami (CYK) Algorithm in Ada 2023

---

## Project Overview

This project provides a robust, production-grade implementation of the **Cocke-Younger-Kasami (CYK) algorithm** in Ada 2023 (ISO/IEC 8652:2023). The CYK algorithm is a classic bottom-up parsing and recognition algorithm for context-free grammars (CFGs) rendered in Chomsky Normal Form (CNF) utilizing dynamic programming with an asymptotic time complexity of *O(n³ · |G|)*.

---

## Features &amp; Variants

The package `Cyk_Algorithm` implements three primary algorithm variants corresponding to the theoretical formulations in literature:

1. **Standard CYK Recognition (`Recognize`):** Determines membership of an input string in a given context-free grammar in CNF.
2. **Parse Tree Generation (`Parse`):** Extends recognition into a full parser, constructing and returning a structural derivation tree (`Parse_Node`) for accepted strings.
3. **Weighted / Probabilistic CYK Parsing (`Parse_Weighted`):** Supports stochastic/weighted context-free grammars, computing optimal (maximum log probability) derivations and parse trees.
4. **Validation &amp; Utility Helpers:** Includes grammar CNF validation (`Is_In_CNF`), recursive memory deallocation (`Free_Parse_Tree`), and tree serialization (`Tree_To_String`).

---

## Strong Typing &amp; Contracts

- Strict domain types (`Nonterminal`, `Terminal`, `Input_String`, `Log_Probability`, discriminated `Production` and `Parse_Node` records).
- Ada contract aspects (`Pre`, `Post`, `Global`) ensuring safe state pre-conditions and post-conditions.

---

## Building and Testing

### Prerequisites

- GNAT compiler supporting Ada 2023 (`-gnat2022`).
- Make utility.

### Commands

- **Build test executable:**
  ```bash
  make
  ```
- **Run test suite:**
  ```bash
  make test
  ```
- **Clean build artifacts:**
  ```bash
  make clean
  ```

---

## Testing &amp; Verification

The test suite (`tests.adb`) implements 13 comprehensive test categories exercising functional correctness, edge cases, weighted grammar parsing, memory management, and contract verification. Each test contains multiple assertions verified at runtime using built-in pragma `Assert`.
