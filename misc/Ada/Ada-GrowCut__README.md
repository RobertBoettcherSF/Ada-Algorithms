# GrowCut Algorithm in Ada

## Project Overview
This project implements the GrowCut algorithm, an interactive image segmentation method based on Cellular Automata, in the Ada programming language. It propagates labels (Foreground/Background) based on neighbor competition.

## Features
- **Core Algorithm**: Iterative cellular automaton evolution.
- **Variants**:
    - **Synchronous Update**: All cells compute updates based on the previous global state.
    - **Asynchronous Update**: Cells update sequentially, allowing faster propagation of information.
- **Strong Typing**: Ada-specific safety for grid and label management.

## Testing
The test suite in `tests.adb` validates the system using V&V principles:
- **Functional Correctness**: Ensures labels propagate correctly.
- **Error Handling**: Verifies behavior with edge cases (empty grids, boundary conditions).
- **Validation**: Confirms that the algorithm behaves deterministically under known conditions.

Tests are designed to assume failure; a `PASS` indicates the implementation correctly handled the inputs.

## Usage
### Compilation
Ensure you have GNAT installed.
```bash
make
