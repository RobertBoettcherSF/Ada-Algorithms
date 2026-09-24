# DFA Minimization (Moore's Algorithm)

---

## Project Overview

This Ada 2023 project implements **DFA minimization using Moore's algorithm**. The algorithm transforms a given Deterministic Finite Automaton (DFA) into an equivalent DFA with the minimum number of states by merging nondistinguishable states. The implementation covers the core steps: initial partition creation, iterative refinement, and construction of the minimized DFA. It adheres to strong typing, Ada 2023 contract aspects, and comprehensive error handling.

---

## Features

- **Moore's Algorithm**: Full implementation of the classic partition refinement approach.
- **Strong Typing**: Custom types for states, symbols, transitions, and partitions.
- **Ada 2023 Compliance**: Uses `Pre`, `Post`, and `Global` aspects for subprogram contracts.
- **Edge Case Handling**: Robust handling of empty inputs, single-state DFAs, and invalid transitions.
- **Test Suite**: Standalone `tests.adb` with 13+ tests, each with 3+ assertions, covering functional correctness, edge cases, and error handling.

---

## Usage

### Building and Running Tests

1. **Build the project:**
  ```sh
   make
  ```
2. **Run the test suite:**
  ```sh
   make test
  ```
3. **Clean build artifacts:**
  ```sh
   make clean
  ```

### Expected Output

The test suite will print `PASS` or `FAIL` for each assertion, followed by a summary of passed/failed tests. All tests are designed to verify the correctness of the DFA minimization process, including edge cases like empty DFAs, single-state DFAs, and DFAs with no transitions.

---

## Testing

The test suite covers:

- **Functional Correctness**: Verifies that the minimized DFA accepts the same language as the original.
- **Edge Cases**: Tests for empty inputs, single-state DFAs, and DFAs with no transitions.
- **Error Handling**: Ensures exceptions are raised for invalid inputs (e.g., undefined transitions).
- **Invariants**: Checks that the minimized DFA has no unreachable or nondistinguishable states.

---

## Building

### Prerequisites

- **GNAT (GNU Ada Translator)**: Ensure `gnatmake` is installed and available in your `PATH`.
- **Ada 2023 Support**: The project uses Ada 2023 features (e.g., contract aspects). Ensure your compiler supports the `-gnat2022` flag or equivalent.

### Build Commands

- **Default Build**: `make` compiles the project with `-gnatwa` (all warnings enabled).
- **Custom Flags**: Modify the `FLAGS` variable in the `Makefile` to add/remove compiler flags.

---

## File Structure


| File                   | Purpose                                                                |
| ---------------------- | ---------------------------------------------------------------------- |
| `dfa_minimization.ads` | Package specification: types, exceptions, and subprogram declarations. |
| `dfa_minimization.adb` | Package body: full implementation of Moore's algorithm.                |
| `dfa_minimization.gpr` | GNAT project file for building `tests.adb`.                            |
| `Makefile`             | Build automation: `make`, `make test`, `make clean`.                   |
| `tests.adb`            | Standalone test suite and usage example.                               |
| `README.md`            | Project documentation.                                                 |


---

## Algorithm Notes

Moore's algorithm works as follows:

1. **Initial Partition**: Split states into accepting and non-accepting sets.
2. **Refinement**: For each symbol, refine the partition by grouping states that transition to the same partition set.
3. **Termination**: Repeat refinement until the partition stabilizes (no further splits).
4. **Result Construction**: Build the minimized DFA from the final partition.

The implementation includes helper functions for:

- Partition creation and refinement.
- Transition validation.
- Equality checks for partitions and DFAs.

---

## License

This project is provided as-is for educational and research purposes. Feel free to adapt it for your needs.
