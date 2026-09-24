# Ukkonen's Algorithm in Ada

## Project Overview
This repository contains an Ada implementation of [Ukkonen's Algorithm](https://en.wikipedia.org/wiki/Ukkonen%27s_algorithm), a linear-time, online algorithm for constructing a suffix tree. Originally conceptualized for rapidly indexing strings for fast substring queries, this implementation provides a robust and memory-safe approach utilizing Ada's strong typing mechanics.

## Features
- **Online Suffix Tree Construction:** Employs the standard Ukkonen approach (Rules 1, 2, 3), scaling through strings character-by-character.
- **Strongly Typed Nodes & Vectors:** Bounded nodes mapped strictly within safe constraints avoiding memory leaks or out-of-bound errors.
- **Implicit Edge Tracking:** Handles string remainders and active points to guarantee conceptually accurate time complexity.
- **Substring Verifier Variant:** Provides an optimized $O(m)$ substring checker (`Contains_Substring`) utilizing the built explicit suffix tree structures. 

*(Note: CPU Scheduling variants like preemptive/non-preemptive processes do not technically apply to String processing algorithms. We implement the "Online" string algorithm variants and fallback explicit terminal structures instead).*

## Testing

Software reliability mandates rigorous Verification and Validation (V&V). This repository includes a terminal-executable test suite running **13 strict tests**.

**Philosophy:** The test suite operates on the pessimistic assumption that the code is *broken* or highly brittle. A test is considered `PASS` only when the code functions cleanly under pressure, mathematically disproving the broken assumption. 

Tests verify:
- **Functional Correctness:** Ascertains if foundational operations (finding prefixes, sub-strings, suffixes) function correctly based on established requirements.
- **Edge Cases & Error Handling:** Validates behavior upon empty strings (`""`), bounds violations, non-existent characters, and case sensitivities (`"A"` vs `"a"`).
- **Suffix Link Integration:** Complex patterns (like `abacabadabacaba`) evaluate internal data structures, verifying split-nodes and suffix chains traverse without cyclic crashes.
- **Performance/Memory Boundaries:** Subjects the tree builder to continuous repeating patterns (stress loads) confirming variables do not overflow and `Infinity` leaf constraints remain accurate.

These proofs ensure system correctness, preventing regressions during code modifications, which is a core tenant of safety-critical development standards.

## Usage

### Compilation Instructions
The software relies on the GNAT Ada compiler. A `Makefile` orchestrates compilation.
To compile the suite, run:

```bash
make
