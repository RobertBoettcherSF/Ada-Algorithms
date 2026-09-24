# Mark-Compact Garbage Collection in Ada

## Project Overview

This repository implements the fundamental **Mark-Compact** garbage collection algorithm in Ada. It models heap memory as a strongly-typed block array and executes memory collection to reclaim space taken up by dead (unreachable) objects.

## Features

- **Strong Typing**: Dedicated integer range bindings to prevent pointer corruption out of bounds.
- **Mark Phase**: DFS-based algorithm handling disjoint object graphs and cyclic dependencies to isolate reachable objects.
- **Variant 1: LISP 2 Algorithm (Sliding)**: Uses 3 passes over the heap to slide live objects linearly to the beginning, preserving their historical instantiation order.
- **Variant 2: Two-Finger Algorithm (Swapping)**: Uses 2 passes for high-efficiency compaction by swapping live objects from the end of the heap into dead "holes" at the front. (Applicable here because our block structure models fixed-size allocation).

## Architecture

### Data Structures

- **Address**: A strongly-typed integer range (0 .. Max_Heap_Size + 1) representing memory locations
- **Object_Record**: Represents a single heap object with:
  - `Allocated`: Boolean flag indicating if the slot contains a valid object
  - `Marked`: Boolean flag for mark phase (reachable objects)
  - `Forwarding_Address`: Used during compaction to track new locations
  - `Refs`: Array of up to 4 references to other objects (object graph)
  - `Data_Value`: Integer value stored in the object
- **Heap_Array**: Array of Object_Records, indexed by Address (1 .. Address'Last)
- **Root_Array**: Array of Addresses representing root references (e.g., stack variables)

### Algorithm Phases

1. **Mark Phase**: Starting from root references, traverse the object graph using DFS to mark all reachable objects
2. **Compact Phase**: Move all marked (live) objects to eliminate fragmentation

## Testing

To assure maximum confidence in memory-critical operations, this project employs rigorous **Verification and Validation (V&V)** paradigms.

**The Test Philosophy**: We assume the code is intrinsically *incorrect* or handles edge-cases *dangerously*. The suite is constructed of assertions explicitly designed to disprove these assumptions. A `PASS` means our pessimistic assumption about the codebase was empirically proven false.

The test categories verify:

1. **Functional Correctness (Tests 2, 5, 7)**: V&V check that reachable graphs are logically marked, orphaned memory is truly recycled, and forwarding addresses update seamlessly across LISP2 and Two-Finger algorithms. 
2. **Cycle & Graph Safety (Test 3)**: Disproves the assumption that circular references lock the process into infinite loops, guaranteeing execution safety.
3. **Edge Case Guarding (Tests 1, 4, 6)**: Validates the system against mathematical limits (zero elements, max elements), proving the heap operations survive initialization boundaries.
4. **Error Handling (Test 8)**: Guarantees constraints are enforced at runtime (e.g., stopping execution on spoofed root pointers).
5. **Stress Testing (Test 9)**: Validates the algorithm works correctly at 100% heap capacity.

These tests matter because critical embedded systems written in Ada require undeniable proof of reliability and memory safety. Verification proves the algorithm matches mathematical literature specs; Validation proves the GC operates perfectly within the simulation sandbox.

## Usage

### Prerequisites

- **GNAT Ada Compiler**: Part of the GCC toolchain
  - On Ubuntu/Debian: `sudo apt-get install gnat`
  - On Fedora: `sudo dnf install gcc-gnat`
  - On macOS (with Homebrew): `brew install gnat`

### Compilation

A standard `Makefile` is provided with the following targets:

```bash
# Build everything (main demo and test suite)
make all

# Build only the main demo
make

# Build and run the test suite
make test

# Clean build artifacts
make clean
```

### Running the Demo

```bash
# Build and run the main demonstration
make
./bin/main
```

### Running Tests

```bash
# Build and run all tests
make test
```

All tests should pass with output showing "100% PASS".

## Implementation Details

### LISP 2 Algorithm (Sliding Compaction)

The LISP 2 algorithm performs compaction in three passes:

1. **Pass 1 - Compute Forwarding Addresses**: Traverse the heap and assign each live object a new address at the front of the heap. Maintains a `Free_Ptr` that points to the next available slot.
2. **Pass 2 - Update References**: For each live object, update all its references to point to the new locations (using forwarding addresses).
3. **Pass 3 - Move Objects**: Copy each live object to its new location and clear metadata.

**Time Complexity**: O(n) where n is the number of heap objects
**Space Complexity**: O(1) additional space (in-place compaction)
**Order Preservation**: Yes, maintains original allocation order

### Two-Finger Algorithm (Swapping Compaction)

The Two-Finger algorithm uses two pointers:

1. **Free**: Starts at the beginning of the heap, points to the next hole (unallocated slot)
2. **Scan**: Starts at the end of the heap, searches backward for live objects

The algorithm swaps live objects found by `Scan` into holes found by `Free`, effectively compacting the heap from both ends.

**Time Complexity**: O(n) where n is the number of heap objects
**Space Complexity**: O(1) additional space
**Order Preservation**: No, does not maintain original order
**Requirement**: Works only with fixed-size objects

## Directory Structure

```
Ada-Mark-Compact-Algorithm/
├── src/
│   ├── main.adb              # Main demonstration program
│   ├── mark_compact.ads      # Package specification (types and interfaces)
│   └── mark_compact.adb      # Package body (algorithm implementations)
├── tests.adb                 # Test suite
├── mark_compact.gpr          # GNAT project file
├── Makefile                  # Build configuration
├── README.md                 # This file
└── LICENSE                   # License information
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## References

- [Garbage Collection: Algorithms for Automatic Dynamic Memory Management](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) - Wikipedia
- [Mark Compact Algorithm (Wikipedia)](https://en.wikipedia.org/wiki/Mark-compact_algorithm)
- LISP 2 Algorithm: Originally described in "LISP 1.5 Programmer's Manual" by John McCarthy et al.
- Two-Finger Algorithm: A classic compaction technique for fixed-size objects
