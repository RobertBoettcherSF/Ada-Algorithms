# Ada Garbage Collection Simulator (Mark & Sweep)

[![Ada](https://img.shields.io/badge/Ada-2012-blue.svg)](https://www.adaic.org/ada-resources/standards/ada12/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Project Overview

This repository implements a robust memory simulation and tracing garbage collector based on the [Mark and Sweep](https://en.wikipedia.org/wiki/Mark_and_sweep) algorithm in **Ada 2012**. Given Ada's native manual/RAII memory management, this project builds a managed heap ecosystem with custom nodes and references to accurately model GC behavior.

The implementation is designed for:
- **Educational purposes** - Understanding garbage collection algorithms
- **Testing and verification** - Rigorous V&V for critical systems
- **Research** - Experimenting with GC variants in a controlled environment

## Features

The project implements all primary variants of the Mark and Sweep algorithm:

### 1. Naive Recursive Mark and Sweep
- **Approach**: Standard depth-first search (DFS) using the call stack
- **Pros**: Simple, clean implementation
- **Cons**: Susceptible to stack overflow on deeply nested object graphs
- **Use Case**: Educational, small-scale testing

### 2. Iterative Mark and Sweep
- **Approach**: Uses an explicit work-stack array instead of the call stack
- **Pros**: Bounded memory guarantees, prevents stack overflow
- **Cons**: Slightly more complex implementation
- **Use Case**: Real-time/embedded systems where stack overflow must be prevented

### 3. Tri-Color Mark and Sweep (Dijkstra's Variant)
- **Approach**: Categorizes objects into White (condemned), Gray (pending), and Black (survived) sets
- **Pros**: Foundation for concurrent garbage collection
- **Cons**: More complex state management
- **Use Case**: Research into concurrent GC, understanding tri-color invariant

## Architecture

### Data Structures

```
+------------------+
|    Heap_Array    |  -- Array of GC_Object (1..Max_Objects)
+------------------+
        |
        v
+------------------+
|    GC_Object     |  -- Individual heap object
+------------------+
| Is_Allocated: B  |  -- Allocation status
| Marked: B        |  -- Mark flag (naive/iterative)
| Color: Color_Type|  -- White/Gray/Black (tri-color)
| Refs: Reference_Array  -- Child references (max 2 per object)
+------------------+
```

### Algorithm Flow

All three variants follow the same basic pattern:

1. **Mark Phase**: Traverse from root objects, identifying all reachable objects
2. **Sweep Phase**: Reclaim objects not identified as reachable

The key difference is in the Mark Phase implementation:
- **Recursive**: Uses call stack for DFS
- **Iterative**: Uses explicit stack array for DFS
- **Tri-Color**: Uses color states with explicit stack

## Installation

### Prerequisites

- **GNAT Ada Compiler** (part of GCC)
  - Debian/Ubuntu: `sudo apt-get install gnat gprbuild`
  - Fedora: `sudo dnf install gcc-ada gprbuild`
  - macOS (Homebrew): `brew install gnat`
  - Windows: [GNAT Community Edition](https://www.adacore.com/community)

- **GPRBuild** (GNAT Project Manager)
  - Typically installed with GNAT

- **Make** (for the provided Makefile)

### Verification

Check your installation:
```bash
# Check GNAT version
gnat --version

# Check GPRBuild version  
gprbuild --version

# Check Make
make --version
```

## Usage

### Compilation

#### Using Make (Recommended)

```bash
# Build the project
make

# Or explicitly
make all

# Clean build artifacts
make clean

# Run tests
make test
```

#### Using GPRBuild Directly

```bash
# Build using the project file
gprbuild -P mark_sweep.gpr

# Clean
rm -rf obj/ bin/
```

### Running Tests

```bash
# Build and run all tests
make test

# Or manually
./bin/tests
```

### Using the Library in Your Code

To use this GC simulation in your own Ada program:

1. Add the `src/` directory to your GPR project's source path
2. With the package in your code:

```ada
with Mark_And_Sweep; use Mark_And_Sweep;

procedure My_Program is
   My_Heap : Heap_Array;
   Root1, Root2 : Object_Index;
   Roots : Root_Set := (1 => Root1, 2 => Root2);
begin
   -- Initialize heap
   Reset_Heap(My_Heap);

   -- Allocate some objects
   Allocate(My_Heap, Root1);
   Allocate(My_Heap, Root2);

   -- Create references between objects
   Add_Reference(My_Heap, Root1, Root2, 1);

   -- Run garbage collection
   Iterative_Mark_And_Sweep(My_Heap, Roots);

   -- Count surviving objects
   Put_Line("Objects remaining: " & Count_Allocated(My_Heap)'Image);
end My_Program;
```

## Testing (Verification & Validation)

This project adheres to rigorous **Verification and Validation (V&V)** principles tailored for critical systems.

### Test Philosophy

> *Assume the code is completely broken.*

A test is considered a **"PASS"** only when it actively disproves a pessimistic assumption (e.g., assuming a cycle will cause a stack overflow, and proving it doesn't).

### Test Categories

| Category | Tests | Purpose |
|----------|-------|---------|
| **Functional Correctness** | 1-3, 6-9, 10 | Verifies live roots protect child nodes from reclamation |
| **Edge Cases & Cycles** | 4, 5, 8, 11, 12 | Validates against infinite loops and memory leaks |
| **Error Handling** | 13-15 | Ensures integrity under adverse conditions |

### Test Descriptions

#### Functional Correctness Tests
- **Test 1**: Empty & Unrooted Memory - Verifies unrooted objects are freed
- **Test 2**: Simple Root Preservation - Single root preserves one object
- **Test 3**: Deep Chain Preservation - Linked chain of objects survives
- **Test 6**: Iterative Basic - Iterative algorithm preserves root and child
- **Test 7**: Null Roots Tolerance - Null in root set handled safely
- **Test 8**: Self-Referential - Self-referencing objects don't crash
- **Test 9**: Multiple Disjoint Roots - Multiple independent root trees preserved
- **Test 10**: Tri-color Basic - Tri-color preserves linked nodes

#### Edge Cases & Cycles Tests
- **Test 4**: Cycle Handling - Cyclic references (A->B, B->A) don't cause infinite loops
- **Test 5**: Unreachable Cycle Destruction - Unrooted cycles are reclaimed
- **Test 11**: Complex Graph with Cycles - Dense cycles handled correctly
- **Test 12**: Color Reset Verification - Colors reset properly after sweep

#### Error Handling Tests
- **Test 13**: Out of Memory - Exception raised when heap is full
- **Test 14**: Invalid Reference Slots - Exception for invalid slot index
- **Test 15**: Reference to Unallocated - Exception for references from unallocated objects

### Why These Tests Matter

In critical systems, unpredictable memory growth or dangling pointers are fatal. By systematically testing:
- The limits of stack depth
- Graph cycles (notoriously difficult for tracing GC)
- Invalid states

We transition the GC from *"it seems to work"* to a **mathematically verifiable mechanism**.

## API Documentation

### Types

| Type | Description |
|------|-------------|
| `Object_Index` | Index for heap objects (0 .. Max_Objects) |
| `Null_Ptr` | Constant representing null/invalid reference |
| `Reference_Array` | Array of object references (size: Max_Refs_Per_Object) |
| `Color_Type` | Enumeration: White, Gray, Black |
| `GC_Object` | Record type for heap objects |
| `Heap_Array` | Array of all heap objects |
| `Root_Set` | Dynamic array of root indices |

### Exceptions

| Exception | Raised When |
|-----------|-------------|
| `Out_Of_Memory` | No free slots in heap during Allocate |
| `Invalid_Reference` | Invalid source, slot, or unallocated object in Add_Reference |

### Core Operations

| Procedure/Function | Description |
|-------------------|-------------|
| `Allocate(Heap, Idx)` | Allocates a new object, returns its index |
| `Add_Reference(Heap, From, To, Slot)` | Adds reference from From to To at Slot |
| `Count_Allocated(Heap)` | Returns count of allocated objects |
| `Reset_Heap(Heap)` | Resets entire heap to initial state |

### Garbage Collection Algorithms

| Procedure | Algorithm | Stack Safety |
|-----------|-----------|--------------|
| `Recursive_Mark_And_Sweep(Heap, Roots)` | Naive DFS | ❌ No (uses call stack) |
| `Iterative_Mark_And_Sweep(Heap, Roots)` | Explicit stack | ✅ Yes |
| `Tricolor_Mark_And_Sweep(Heap, Roots)` | Dijkstra's tri-color | ✅ Yes |

## Project Structure

```
Ada-Mark-and-Sweep/
├── README.md           # This file
├── LICENSE             # MIT License
├── Makefile            # Build configuration
├── mark_sweep.gpr      # GNAT Project file
├── tests.adb           # Test suite
├── src/
│   ├── mark_and_sweep.ads  # Package specification
│   └── mark_and_sweep.adb  # Package body
├── obj/                # Object files (generated)
└── bin/                # Executables (generated)
```

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository** and create a feature branch
2. **Write tests** for any new functionality
3. **Follow Ada style** - Use consistent indentation, add documentation comments
4. **Use the `-- %` format** for package-level documentation (compatible with gnatdoc)
5. **Keep commits atomic** - One logical change per commit
6. **Submit a Pull Request** with a clear description

### Code Style Guidelines

- Use 3 spaces for indentation (Ada standard)
- Add documentation comments for all public types and procedures
- Use `-- @param`, `-- @return`, `-- @raises` for API documentation
- Keep line length under 80 characters where practical
- Use descriptive names for types and variables

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the classic [Mark and Sweep algorithm](https://en.wikipedia.org/wiki/Mark_and_sweep)
- Dijkstra's [Tri-color marking](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Tri-color_marking) for concurrent GC
- Ada programming language and the GNAT compiler

## References

- [Mark and Sweep - Wikipedia](https://en.wikipedia.org/wiki/Mark_and_sweep)
- [Tracing Garbage Collection - Wikipedia](https://en.wikipedia.org/wiki/Tracing_garbage_collection)
- [Ada Programming Language](https://www.adaic.org/)
- [GNAT User's Guide](https://docs.adacore.com/gnat_ugn-docs/html/gnat_ugn.html)
