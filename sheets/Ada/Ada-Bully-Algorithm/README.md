# Bully Algorithm Implementation (Ada)

## Project Overview
This repository contains a robust implementation of the Bully Algorithm, a distributed algorithm used to elect a new coordinator when the current one fails. The implementation focuses on state management, election logic, and process failure simulation.

## Features
- **Strongly Typed Simulation:** Uses custom Ada types to define process identity, status, and network state.
- **Election Variants:** Implements the classic election logic where higher-ID processes supersede lower ones.
- **Failure Simulation:** Includes procedures to simulate node failure and recovery.
- **Determinism:** The logic is designed to be fully testable without external network dependencies.

## Testing
This project follows strict Verification and Validation (V&V) principles to ensure reliability. 
- **Functional Correctness:** Tests verify that the election logic results in the correct node becoming coordinator.
- **Robustness:** Tests handle edge cases like empty networks, non-sequential IDs, and simultaneous node failures.
- **Integrity:** Tests ensure system invariants, such as "no more than one coordinator," are maintained.

Tests prove the code is functional by asserting expected states against actual system outcomes. If any logic is broken, the `tests.adb` suite will trigger an assertion failure, immediately signaling the error.

## Usage
### Compilation
Ensure you have the GNAT compiler installed.
```bash
make
