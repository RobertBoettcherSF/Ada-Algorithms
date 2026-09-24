# Sequitur Ada Implementation

## Project Overview
This project implements the Sequitur algorithm in Ada, a loss-less compression algorithm that infers a context-free grammar from a sequence of symbols.

## Features
- Hierarchical grammar inference.
- Constraints implementation: Digram Uniqueness and Rule Utility.
- Memory-safe pointer management using Ada access types.

## Testing
The test suite consists of 13+ test cases covering functional correctness, edge cases (empty strings), and rule constraint verification. 
- **Functional Correctness:** Verifying the grammar construction logic.
- **Edge Cases:** Testing empty inputs, single characters, and long repetitive sequences.
- **V&V:** We assume the implementation may be flawed and use `pragma Assert` to prove properties of the grammar (e.g., uniqueness) hold true.

## Usage
### Compilation
Ensure GNAT is installed.
```bash
make
