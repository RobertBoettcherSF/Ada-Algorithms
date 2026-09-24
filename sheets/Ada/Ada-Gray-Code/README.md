# Gray Code Implementation (Ada 2012)

## Project Overview
This repository contains a full Ada 2012 implementation of the Gray code algorithm based on its definition from [Wikipedia](https://en.wikipedia.org/wiki/Gray_code). A Gray code is an ordering of the binary numeral system such that two successive values differ in only one bit. This package implements standard Binary Reflected Gray Code (BRGC) for machine words, BRGC conversion for strings, sequence generation up to a parametric bit depth, Gray code sequence validation, and generalized N-ary (non-Boolean) Gray code sequence transformations.

## Features
*   **Word Conversion**: Highly optimized `Binary_To_Gray` and `Gray_To_Binary` operating on 32-bit modular unsigned integers.
*   **String Processing**: String representations of bits can directly be cast to and from their corresponding Gray codes (`Binary_String_To_Gray` and `Gray_String_To_Binary`).
*   **Sequence Generation**: Constructs full cycles of Gray Code combinations for *N* bits via `Generate_BRGC`.
*   **N-Ary Gray Code**: Implements non-Boolean Gray Code transformations across generalized bases via configurable arrays of base-n digits (`N_Ary_To_Gray` and `Gray_To_N_Ary`).
*   **Safety Constraints**: Ada 2012 functional contracts natively describe behavioral invariants across round trips. Boundary edge cases raise named domain-specific exceptions.

## Usage
The testing module doubles as an execution example demonstrating all variations of the package logic. Build and run it with standard make targets.

Expected execution output will show sequential validation tests tracking passing states:

$ make test
Running tests...
TEST 1 — Binary_To_Gray (Basic)
PASS — 1.1 B2G(0)=0
PASS — 1.2 B2G(1)=1
PASS — 1.3 B2G(2)=3
...
===  42 passed,  0 failed ===

## Testing
This repository opts to include an internal verification suite inside `tests.adb` functioning both as documentation and TDD safety-nets. The tests check assertions spanning:
1.  **Functional Correctness**: Mathematical correctness of single bit flips, matching sequence limits.
2.  **Inverses and Round-Trips**: Enforcing $F^{-1}(F(X)) = X$ integrity checks on machine-word routines.
3.  **Boundary & Edge Cases**: Behavior on strings and arrays bounded at zero size.
4.  **Error Handling**: Confirms expected named exceptions natively fire on corrupt input elements out of expected base domains or non-Boolean binary bit strings.

## Building
To build and verify this code, you will need the GNAT Ada compiler natively configured.
The library strictly targets **Ada 2012** language rules. 
Ensure `make` is present on your local system path.

*   Build tests: `make all`
*   Run tests: `make test`
*   Clean binaries: `make clean`
