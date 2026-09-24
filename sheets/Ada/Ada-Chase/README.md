# Chase Algorithm Implementation in Ada

Implementation of the Chase algorithm for database functional dependencies and its variants, written in Ada.

## Project Overview

This project implements the **Chase algorithm**, a fundamental algorithm in database theory used for testing and enforcing implication of data dependencies. The chase determines whether the projection of a relation schema constrained by functional dependencies onto a given decomposition can be recovered by rejoining the projections (lossless join property).

The implementation includes:

- Standard Chase algorithm for functional dependencies
- Oblivious (Naive) Chase variant
- Core Chase variant
- Restricted Chase for Tuple-Generating Dependencies (TGDs)

## Features

### Implemented Variants

1. **Standard Chase**: The classic algorithm that applies functional dependencies to equate symbols in a tableau
2. **Oblivious Chase**: Eager variant that always adds new witnesses
3. **Core Chase**: Variant that tries to minimize the tableau by keeping only necessary tuples
4. **Restricted Chase for TGDs**: Generalization for tuple-generating dependencies

### Key Components

- **Tableau creation**: Initializes the tableau from a relation schema and decomposition
- **FD application**: Applies functional dependencies to equate symbols
- **Termination detection**: Checks when the tableau stabilizes
- **Result verification**: Determines if the original tuple is recovered

## Usage

### Compilation

To compile the project:

```bash
make
```

Or manually with GNAT:

```bash
gnatmake -o bin/tests tests.adb
```

### Execution

To run the test suite:

```bash
make test
```

Or directly:

```bash
./bin/tests
```

### Input/Output

The test suite outputs:

- Test number and description
- Individual assertion results
- Summary of passed/failed tests

## Testing

### Test Philosophy

The test suite assumes the code is **broken or non-functional** and aims to disprove this assumption. Each test verifies that the code behaves correctly, with **PASS** indicating the pessimistic assumption was disproven (code works correctly).

### Test Categories

The 14 tests cover:

1. **Functional Correctness** (Tests 1-5)
  - Standard Chase with Wikipedia example
  - Oblivious Chase variant
  - Core Chase variant
  - TGD Chase variant
  - Lossy vs. lossless decomposition detection
2. **Edge Cases** (Tests 6, 12)
  - Empty inputs (empty FD set, empty decomposition)
  - Single attribute tuples
  - Minimal configurations
3. **Error Handling** (Tests 7-8)
  - Value equality checks
  - Tableau creation validation
  - Attribute indexing
4. **Algorithm Verification** (Tests 9-11)
  - FD application correctness
  - Original tuple detection
  - Validation functions
5. **Variant Comparison** (Test 13)
  - All variants produce consistent results
  - All variants handle edge cases
6. **Performance &amp; Termination** (Test 14)
  - Larger tuples
  - Cyclic FDs
  - Many FDs

### Why These Tests Matter

- **Verification**: Ensures the implementation matches the algorithm specification
- **Validation**: Confirms the code meets its intended use in database theory
- **Reliability**: Tests edge cases and error conditions for robustness
- **Correctness**: Validates against known examples (Wikipedia case)
- **Consistency**: Ensures all variants produce compatible results

### How Tests Prove the Code Works

Despite starting with the pessimistic assumption that the code is broken:

- Each **PASS** result disproves this assumption for a specific case
- Multiple independent tests covering different aspects increase confidence
- Edge case testing ensures robustness
- Variant comparison ensures consistency across implementations

## File Structure

```
.
├── chase.ads          # Package specification
├── chase.adb          # Package implementation
├── chase.gpr          # GNAT Project File
├── tests.adb          # Test suite
├── Makefile           # Build configuration
├── README.md          # This file
├── obj/               # Object files (created by build)
└── bin/               # Executables (created by build)
```

## References

- [Chase (algorithm) - Wikipedia](https://en.wikipedia.org/wiki/Chase_(algorithm))
