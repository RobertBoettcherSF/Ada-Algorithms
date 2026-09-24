# Package-Merge Algorithm in Ada

## Project Overview
This repository contains a robust, expert-level implementation of the Package-Merge algorithm, an $O(nL)$-time algorithm used to compute optimal length-limited Huffman codes. The framework utilizes strong Ada typing mechanisms and implements variants resolving the underlying binary coin collector problem while enforcing deterministic bounds and deterministic memory allocations.

## Features
- **Variant 1 (Binary Coin Collector):** Implements the foundational dynamic merging logic required to optimize subset selection given discrete numismatic values across geometric denominations.
- **Variant 2 (Length-Limited Huffman via Reduction):** Strictly mimics the algorithmic reduction where a symbol's probabilistic frequencies are structured dynamically as arbitrary 'coins' iterating through depth representations.
- **Variant 3 (Space-Efficient Length-Limited Huffman):** Executes $O(nL)$ logic but with highly deterministic memory pooling and active-list pruning. It binds allocated nodes dynamically limiting overhead heavily relative to naive tree generation schemas.
- **Variant 4 (Alphabetic Length-Limited Coding):** Resolves height-limited encoding that demands sequence tracking (Lexicographical ordering) mimicking bounds introduced by Larmore and Przytycka (adapted equivalently utilizing $O(N^3 L)$ dynamic programming bounds to strictly maintain sequence validity).

## Testing
The embedded test suite employs rigorous Verification & Validation (V&V) methodologies to guarantee mission-critical constraints aren't bypassed:
- **Functional Correctness:** Ensures accurate algorithmic derivation and compares outputs between iterative mechanisms (Standard vs Space-Efficient equivalence tests).
- **Error Handling Validation:** Rejects mathematical inconsistencies natively (e.g., trying to generate a tree constraint with length restrictions unable to carry the underlying node count).
- **Edge Cases:** Validates extreme scenarios ($N=2$, Target totals equivalent to $0$) proving assumption disproof.
- **Assumption Overrides:** Initial assertions assume the framework is prone to standard tree-depth overflows and memory leaks. The tests `PASS` natively proving data validity, accurate pointer tracebacks, and functional memory pruning.

## Usage
### Compilation
The project supports compilation seamlessly via native `gnatmake` implementations utilizing GNAT project standards:
```bash
make all
