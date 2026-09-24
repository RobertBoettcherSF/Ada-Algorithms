# Ada Semi-Space Garbage Collector

## Project Overview

This project provides a robust, strongly-typed implementation of a **two-space copying garbage collector** in Ada. It demonstrates classic memory management principles by splitting memory into a "From-Space" and a "To-Space." During collection, live objects are evacuated from the active space into the reserve space, simultaneously compacting memory and discarding unreferenced data.

This implementation is designed for educational purposes and demonstrates two classic garbage collection algorithms:
- **Cheney's Algorithm** (Iterative, Breadth-First)
- **Standard Recursive Collection** (Depth-First)

## Features

### Strong Typing
Utilizes safe array indices (`Object_Id`) rather than OS-level pointers, preventing segmentation faults and out-of-bounds pointer arithmetic. This makes the implementation memory-safe by design.

### Algorithm Variants

1. **Variant 1: Cheney's Algorithm (Iterative)**
   - The primary collection method
   - Uses the To-Space itself as a BFS queue to traverse the object graph
   - Completely eliminates the risk of stack overflow on deep object graphs
   - More efficient for large object graphs

2. **Variant 2: Standard Recursive Collection**
   - A secondary DFS variant implemented for comparative study
   - Simpler to understand but can cause stack overflow on deep graphs
   - Included for architectural completeness and educational purposes

### Cyclic Graph Safety
Both variants handle cyclical object references natively via immediately-placed forwarding pointers, ensuring no infinite loops or recursions occur.

## Architecture

### Memory Model
- **Space_A and Space_B**: Two equal-sized memory spaces (each 1024 nodes)
- **From-Space**: The currently active space where allocations occur
- **To-Space**: The reserve space that becomes active during collection
- **Alloc_Ptr**: Tracks the next available slot in the active space

### Node Structure
Each memory cell is a variant record that can be:
- **Active**: Contains user data (Value, Left pointer, Right pointer)
- **Forwarded**: Contains a forwarding pointer to the new location in To-Space

### Collection Process (Cheney's Algorithm)
1. Swap From-Space and To-Space
2. Copy all root references to To-Space (enqueuing them)
3. Scan To-Space using the alloc pointer as a queue head
4. For each node, copy its children to To-Space
5. Leave forwarding pointers in From-Space
6. Continue until all reachable objects are copied

## Testing (Verification & Validation)

Testing in critical software requires a pessimistic assumption: **the code is broken until proven otherwise**. The included test suite serves as our Verification and Validation (V&V) pipeline.

### Test Categories

- **Functional Correctness**: Tests verify that graphs (trees, linked lists) are perfectly mirrored into the new space. *Why it matters:* Proves the algorithm correctly follows memory references.

- **Error Handling & Boundaries**: Tests strictly enforce the `Space_Size = 1024` boundary. Allocating node 1025 must raise an `Out_Of_Memory` exception. *Why it matters:* Ensures the system fails safely and predictably rather than silently corrupting memory.

- **Edge Cases (Cycles & Shared Pointers)**: Tests deliberately create cycles (Node A -> Node B -> Node A) and duplicate root references. *Why it matters:* Proves the forwarding pointer mechanism works, preventing infinite loops and preventing memory duplication.

- **Assumption Disproven**: By forcing 13 distinct edge-case, boundary, and state-integrity failures, and having the code successfully navigate all of them, the suite validates that the garbage collector meets its intended design goals.

### Test Suite Results
All 13 tests pass, disproving the assumption that the code is broken:
- Initialization Integrity
- Basic Allocation
- OOM Boundary Condition
- GC with Empty Root Set
- Cheney GC with 1 Root
- Cheney GC on Linked List
- Cheney GC on Binary Tree
- Cheney GC on Cyclic Graph
- Shared Reference Forwarding
- Standard Recursive GC Variant
- Recursive GC on Cyclic Graph
- Null Root Handling
- Memory Full Survival / Defragmentation

## Usage

### Prerequisites

The project requires the **GNAT toolchain** (GNU Ada compiler):
- **Ubuntu/Debian**: `sudo apt-get install gnat`
- **Fedora**: `sudo dnf install gcc-gnat`
- **macOS (Homebrew)**: `brew install gnat`
- **Windows**: Download from [libre.adacore.com](https://libre.adacore.com/)

### Compilation

A Makefile is provided for convenience:

```bash
# Compile both the main executable and the test suite
make all

# Or compile individually
make bin/main      # Build the main demo executable
make bin/tests     # Build the test suite
```

### Running the Demo

```bash
# Run the main demonstration
./bin/main

# Output:
# Semi-Space Collector Initialized.
# Allocated node with value 42.
# Active usage before GC:  1
# Active usage after GC:  1
# Run 'make test' for full Verification & Validation.
```

### Running Tests

```bash
# Run the full V&V test suite
make test

# Or run directly
./bin/tests
```

### Cleaning

```bash
# Remove all build artifacts
make clean
```

## Project Structure

```
Ada-Semi-Space-Collectors/
├── README.md              # This file
├── Makefile              # Build configuration
├── semi_space.gpr        # GNAT Project file
├── main.adb              # Main demonstration program
├── tests.adb             # Verification & Validation test suite
├── semi_space_collector.ads  # Package specification
├── semi_space_collector.adb  # Package implementation
├── obj/                  # Object files (created by build)
└── bin/                  # Executables (created by build)
```

## Implementation Details

### semi_space_collector.ads

Defines the public API:
- `Object_Id`: Strongly-typed object reference
- `Null_Id`: Sentinel value for null references
- `Space_Selector`: Enumeration for Space_A/Space_B
- `Node`: Variant record for memory cells
- `Heap`: The garbage-collected heap structure
- `Out_Of_Memory`: Exception raised when space is full

Core operations:
- `Initialize`: Reset the heap
- `Allocate`: Allocate a new node
- `Collect_Cheney`: Run Cheney's iterative GC
- `Collect_Recursive`: Run recursive GC
- `Get_Node`: Retrieve a node by ID
- `Active_Space_Usage`: Get current space usage
- `Get_Current_Space`: Get active space

### semi_space_collector.adb

Implements both GC variants with detailed comments explaining each step.

## Performance Characteristics

| Aspect | Cheney's Algorithm | Recursive GC |
|--------|-------------------|--------------|
| Time Complexity | O(n) | O(n) |
| Space Complexity | O(1) auxiliary | O(d) stack depth |
| Stack Safety | Yes | No (deep graphs) |
| Implementation | More complex | Simpler |

## Educational Value

This project demonstrates:
- Semi-space garbage collection principles
- Forwarding pointer technique
- Variant records in Ada
- Strong typing for memory safety
- Iterative vs recursive algorithms
- Handling cyclic data structures
- Boundary condition testing

## License

This project is open source. See LICENSE file for details.

## Contributing

Contributions are welcome! Please ensure:
1. All existing tests continue to pass
2. New tests are added for new functionality
3. Code follows Ada best practices
4. Comments explain non-obvious design decisions
