# Powerset Construction

An **Ada 2023** implementation of the **Powerset Construction algorithm**, converting **Non-Deterministic Finite Automata (NFA)**—including **ε-NFAs**—into equivalent **Deterministic Finite Automata (DFA)**. Foundational for automata theory and compiler design.

---

## Features

- **Basic Powerset Construction**: Converts standard NFAs to DFAs.
- **ε-NFA Support**: Handles epsilon transitions via ε-closure computation.
- **Strong Typing**: Custom types for states, symbols, and state sets ensure type safety.
- **Ada 2023 Compliance**: Uses modern features, including contracts (`Pre`, `Post`).
- **Comprehensive Testing**: 13+ test cases for functional correctness, edge cases, and error handling.

---

## Usage

### Building

```sh
make
```

### Testing

```sh
make test
```

**Expected Output**: All tests pass, with a summary of passed/failed assertions.

---

## Testing

The `tests.adb` suite verifies:

- **Functional Correctness**: DFA correctly simulates NFA for all inputs.
- **Edge Cases**: Empty NFAs, single-state NFAs, invalid transitions.
- **Error Handling**: Proper exceptions for invalid inputs (e.g., empty NFA).
- **Invariants**: DFA states, transitions, and accepting states match the NFA's language.

---

## Building

### Prerequisites

- **GNAT (GNU Ada Translator)**: Ensure `gnatmake` is installed with Ada 2023 support (`-gnat2022` flag).
- **Ada 2023**: Uses **ISO/IEC 8652:2023** features (e.g., contracts).

### Build Commands

- `make`: Compiles the project and builds the test executable.
- `make test`: Runs the test suite.
- `make clean`: Removes build artifacts (`obj/`, `bin/`).

---

## File Structure

```
.
├── powerset_construction.ads    # Package specification
├── powerset_construction.adb    # Package implementation
├── powerset_construction.gpr    # GNAT project file
├── tests.adb                     # Test suite (main executable)
├── Makefile                      # Build system
└── README.md                     # Project documentation
```
