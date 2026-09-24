# DFA Minimization in Ada 2023 (Hopcroft's algorithm)

## Overview

This project provides a production-ready Ada 2023 implementation of deterministic finite automaton (DFA) minimization algorithms. It includes Hopcroft’s, Moore’s, and Brzozowski’s algorithms.

## Features

- **Algorithms**: Hopcroft’s (*O(n log n)*), Moore’s (*O(n²)*), and Brzozowski’s (reversal + powerset construction).
- **Strong Typing**: Domain-specific types (`State_Id`, `Symbol_Id`, `State_Set`, `Transition_Table`).
- **Ada Contracts**: Pre- and post-conditions for correctness and invariants.
- **Test Suite**: 13 test categories in `tests.adb` verifying functional correctness, edge cases, and robustness.

## Usage

### Building

**Prerequisites:**

- GNAT compiler with Ada 2023 support (`-gnat2022`)
- GNU Make

**Build:**

```bash
make all
```

### Testing

Run the test suite:

```bash
make test
```

**Expected output:**

```
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (redundant/equivalent states)
- Edge cases (single-state, all-accepting/rejecting DFAs, unreachable states)
- Error handling (invalid DFAs, out-of-bounds transitions)
- Invariants (language recognition equivalence, structural validity)
