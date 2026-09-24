# Büchi Automaton (Ada 2023)

## Project Overview
This project provides a complete, strictly typed Ada 2023 implementation of a Büchi Automaton, simulating machines capable of processing infinite words over finite alphabets. It fully encompasses the three core variants: Deterministic Büchi Automata (DBA), Nondeterministic Büchi Automata (NBA), and Generalized Büchi Automata (GBA). The package implements periodic word acceptance via lasso detection, emptiness checking via Nested Depth-First Search (NDFS), and structural transformations between automata classes.

## Features
* Strong typing: Explicit state and transition types using standard Ada containers (`Ordered_Sets`, `Ordered_Maps`, and `Vectors`).
* Full variant coverage: Native representation of DBA, NBA, and GBA structures.
* Periodic word simulation: Evaluates infinite words of the form U * (V^omega) for DBAs using cycle/lasso detection.
* Emptiness checking: Nested Depth-First Search (NDFS) to detect reachable cycles intersecting accepting states for DBAs and NBAs.
* Automata transformations: Deterministic conversion from DBA to NBA, and layered product construction from GBA to equivalent NBA.
* Formal contracts and defensive validation: Preconditions, postconditions, and structural invariant validators (`Is_Valid`) across all variants.

## Usage
Run the test suite using the provided Makefile:

make test

Expected output:
TEST 1 — DBA Validation
  PASS — 1.1 Valid DBA is Valid
  PASS — 1.2 Bad Initial State makes Invalid
  PASS — 1.3 Bad Accepting State makes Invalid
...
=== 39 passed, 0 failed ===

## Testing
The standalone test runner (`tests.adb`) verifies correctness across four primary areas:
* Invariant validation: Rejection of disconnected states, missing initial states, and out-of-bounds transitions.
* Functional verification: Acceptance and rejection of periodic words, including multi-state lasso cycles.
* Language emptiness: NDFS detection of reachable versus unreachable accepting cycles and dead-end paths.
* Structural conversion: State multiplication and transition-layer correctness when lowering GBAs to equivalent NBAs.

## Building
* Prerequisites: GNAT compiler supporting Ada 2022/2023 (ISO/IEC 8652:2023).
* Build command: `make all` builds the executable at `bin/tests`.
* Clean artifacts: `make clean` removes generated object and binary directories.
