# Burrows-Wheeler Transform (BWT) in Ada

## Project Overview
This repository contains a robust, strongly-typed Ada 2012 implementation of the Burrows-Wheeler Transform (BWT), a block-sorting text transformation algorithm fundamentally used in data compression systems like `bzip2`. 

BWT rearranges a character string into runs of similar characters, creating a highly compressible format. This implementation handles both standard mathematical configurations of the algorithm directly at the root level space.

## Features
* **Index-Based BWT Variant**: Operates without injecting synthetic markers into strings. Returns the transformed string along with the mathematical primary integer index representing the row of the original string.
* **EOF Marker Variant**: The traditional implementation where a unique End-Of-File (`EOF`) character (e.g., `$`) is appended to designate the rotation bounds.
* **Lexicographical Cyclic Sort Engine**: Implements a native, memory-safe Hoare-partition QuickSort to rapidly compute cyclic suffix tables.
* **Inverse LF (Last-First) Mapping**: Highly optimized `O(N)` recovery utilizing occurrence/rank counting tables.
* **Strong Error Resilience**: Hardened against malicious or corrupt payloads (duplicate markers, out-of-bound indices, missing tokens).

## Testing
This codebase is subjected to strict **Verification and Validation (V&V)** testing standards, assuming out of the gate that the logic is broken until mathematically proven otherwise. 

**What each test category verifies:**
1. **Functional Correctness (Tests 1, 2, 7, 8, 13):** Proves that both variations of the algorithms construct the expected mathematical permutation arrays and accurately traverse the Inverse LF Map matrix backwards to reconstruct source text exactly.
2. **Edge Cases (Tests 3, 4, 5, 6):** Stresses the algorithm by analyzing behavior limits (Empty Strings, `""`) and arrays of identical characters (`"AAAA"`) ensuring bounds don't overrun or cause infinite quicksort loops. 
3. **Error Handling (Tests 9, 10, 11, 12):** Validates exception raising. It verifies the pipeline intercepts missing EOF markers, bounds overflow on arbitrary indices, and multi-marker pollution natively without faulting standard I/O streams.
4. **Performance & Scale (Test 14):** Ingests long payloads full of punctuation and spaces leveraging unprintable system chars (`ASCII.ETX`) to prove the core matrix scales without destructive data loss.

**Why these tests matter:**
In critical systems architecture, silently corrupting data compression pipelines is catastrophic. By proving boundaries, mathematical bounds, and exceptions, we satisfy both *Verification* ("Did we code the algorithm accurately per mathematical literature?") and *Validation* ("Can this securely and losslessly decompress data in reality?"). Disproving 14 deliberate failure assumptions guarantees production readiness. 

## Usage

### Compilation
The codebase uses a `Makefile` linked to a native GNAT project (`.gpr`). To compile everything, simply run:
```bash
make all
