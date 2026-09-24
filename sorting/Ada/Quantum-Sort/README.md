# Quantum Sort in Ada 2023

## Overview

Production-grade Ada 2023 implementation modeling quantum sorting paradigms. Implements quantum comparison, parallel sorting networks, frequency distribution counting, and space-bounded sorting mechanics.

## Features

- **Strong Typing**: `Element_Value`, unconstrained `Index_Type`, unconstrained `Element_Array`
- **Ada 2023 Contracts**: Postconditions (`Post => Is_Sorted (Arr)`) on public subprograms
- **Algorithm Variants**:
  - `Sort_Comparison`: Quantum comparison model (optimized insertion sort)
  - `Sort_Parallel_Network`: Quantum circuit/parallel sorting network (Shell sort)
  - `Sort_Frequency`: Quantum frequency/counting sort (selection sort)
  - `Sort_Space_Bounded`: Space-bounded quantum sorting (cocktail shaker sort)
- **Test Suite**: 13 test cases covering functional correctness, edge cases, and multi-variant consistency

## Usage

### Building

**Prerequisites:**

- GNAT compiler supporting Ada 2022/2023 (`gnatmake`)
- GNU Make

**Build Commands:**

```bash
make        # Compiles project and tests
make all    # Same as 'make'
make test   # Compiles and runs test suite
make clean  # Removes object files and binaries
```

### Testing

Run the test suite:

```bash
make test
```

**Expected output:**

```
Running tests...
  PASS — 1.1 Empty array is recognized as sorted
...
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (sorting randomized arrays with positive/negative integers)
- Edge cases (empty arrays, single-element arrays)
- Invariants (already sorted, reverse-sorted arrays)
- Robustness &amp; consistency (cross-verifying all four algorithm variants)
