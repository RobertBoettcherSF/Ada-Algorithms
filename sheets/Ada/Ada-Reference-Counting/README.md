# Ada Reference Counting

A complete Ada implementation of **Reference Counting** and all its variants as described in the [Wikipedia article](https://en.wikipedia.org/wiki/Reference_counting). This project includes:

- Core reference counting (increment/decrement, deallocation).
- Weighted reference counting.
- Indirect reference counting (Dijkstra–Scholten).
- Deferred increment (Henry Baker).
- Update coalescing (Levanoni & Petrank).
- Cycle handling (weak references, Bacon's algorithm).
- Deutsch-Bobrow method.
- Ulterior reference counting (Blackburn & McKinley).

---

## Project Overview

This project implements **Reference Counting**, a memory management technique that tracks the number of references to an object and deallocates it when the count reaches zero. The implementation covers all major variants of reference counting, including:

- **Basic Reference Counting**: Core functionality for tracking references and deallocating objects.
- **Weighted Reference Counting**: Assigns weights to references; objects are deallocated when the total weight reaches zero.
- **Indirect Reference Counting**: Tracks reference sources (e.g., Dijkstra–Scholten algorithm) to prevent premature deallocation.
- **Deferred Increment**: Delays incrementing reference counts for local variables to reduce overhead.
- **Update Coalescing**: Batches redundant reference count updates to improve performance.
- **Cycle Handling**: Detects and collects reference cycles using weak references and Bacon's algorithm.
- **Deutsch-Bobrow Method**: Ignores local variable references and scans the stack/registers before deletion.
- **Ulterior Reference Counting**: Combines deferred counting with a copying nursery for young objects.

The implementation is designed for **critical systems** where correctness, reliability, and safety are paramount. It uses **strong typing**, **modular design**, and **detailed comments** to ensure clarity and maintainability.

---

## Features

### Core Functionality
- **Reference Counting**: Track references to objects and deallocate when the count reaches zero.
- **Custom Types**: Strongly typed `Reference_Count`, `Weight`, and `Object_ID` for clarity and safety.
- **Error Handling**: Exceptions for invalid references, underflow, and cycles.

### Variants Implemented
1. **Weighted Reference Counting**: Supports splitting and merging weights for distributed or parallel systems.
2. **Indirect Reference Counting**: Implements the Dijkstra–Scholten algorithm for diffusion trees.
3. **Deferred Increment**: Henry Baker's method for reducing overhead from short-lived references.
4. **Update Coalescing**: Levanoni & Petrank's method for batching redundant updates.
5. **Cycle Handling**: Weak references and Bacon's algorithm for detecting and collecting cycles.
6. **Deutsch-Bobrow Method**: Ignores local references and scans the stack before deletion.
7. **Ulterior Reference Counting**: Combines deferred counting with a copying nursery (Blackburn & McKinley).

### Edge Cases Handled
- Null/dangling references.
- Reference count underflow/overflow.
- Circular references (via weak references or cycle detection).
- Concurrent updates (atomicity simulated).
- Weight underflow in weighted counting.

---

## Testing

### Test Philosophy
The test suite assumes the code is **broken or non-functional** and aims to **disprove this assumption**. Each test verifies a specific aspect of the implementation, and a **PASS** result means the code behaves correctly despite the initial pessimistic assumption.

### Test Categories
The 15+ tests are organized into the following categories:

1. **Functional Correctness**: Verify that core operations (increment, decrement, deallocation) work as expected.
   - Example: `TEST 1 - Basic Reference Counting` verifies that reference counts are updated correctly.

2. **Error Handling**: Verify that the code raises appropriate exceptions for invalid inputs (e.g., null references, underflow).
   - Example: `TEST 2 - Edge Cases` checks that null references raise `Invalid_Reference`.

3. **Edge Cases**: Verify behavior at boundaries (e.g., zero weights, empty inputs).
   - Example: `TEST 12 - Weighted Edge Cases` tests creating objects with zero or max weight.

4. **Variant-Specific Logic**: Verify that each variant of reference counting works correctly.
   - Example: `TEST 4 - Indirect Reference Counting` tests the Dijkstra–Scholten algorithm.

5. **Concurrency**: Verify that the code handles concurrent updates (simulated).
   - Example: `TEST 11 - Concurrent Reference Counting` tests atomicity of reference updates.

### Why These Tests Matter
- **Verification**: Ensures the code matches the requirements (e.g., reference counts are updated correctly).
- **Validation**: Ensures the code meets its intended use (e.g., deallocating objects when no longer referenced).
- **Reliability**: Catches edge cases and invalid inputs that could cause crashes or memory leaks.
- **Safety**: Ensures the code behaves predictably in critical systems (e.g., no dangling pointers, no underflow).

### How Tests Prove the Code Works
Each test starts with the assumption that the code is broken. For example:
- **Assumption**: "Incrementing a null reference does not raise an exception."
- **Test**: Attempt to increment a null reference and check if `Invalid_Reference` is raised.
- **Result**: If the exception is raised, the assumption is **disproven**, and the test **PASSes**.

This approach ensures that the code is **thoroughly validated** under pessimistic conditions.

---

## Usage

### Compilation
To compile the project, use either `gnatmake` or `make`:

#### Using `gnatmake`:
```bash
# Compile the package
cd /workspace/RobertBoettcherSF__Ada-Reference-Counting
gnatmake -o bin/reference_counting reference_counting.gpr

# Compile the tests
cd /workspace/RobertBoettcherSF__Ada-Reference-Counting
gnatmake -o bin/tests tests.adb
```

#### Using `make`:
```bash
# Compile and run tests
cd /workspace/RobertBoettcherSF__Ada-Reference-Counting
make test
```

### Execution
To run the tests:
```bash
cd /workspace/RobertBoettcherSF__Ada-Reference-Counting
./bin/tests
```

### Output
The test output will show **PASS/FAIL** for each assertion. Example:
```
TEST 1 - Basic Reference Counting
  PASS: 1.1: New object has reference count of 1
  PASS: 1.2: Incrementing increases reference count
  PASS: 1.3: Decrementing decreases reference count
  PASS: 1.4: Decrementing to zero deallocates object
```

---

## Test Execution

### Running Tests
1. **Compile the tests**:
   ```bash
   make test
   ```
   or
   ```bash
   gnatmake -o bin/tests tests.adb
   ```

2. **Run the tests**:
   ```bash
   ./bin/tests
   ```

### Interpreting Results
- **PASS**: The assumption that the code is broken was **disproven** (the code works correctly).
- **FAIL**: The assumption that the code is broken was **proven** (the code does not work as expected).

If all tests **PASS**, the implementation is correct and meets the requirements. If any test **FAILs**, the code needs to be fixed.

---

## File Structure

```
RobertBoettcherSF__Ada-Reference-Counting/
├── reference_counting.ads    # Package specification (types, exceptions, declarations)
├── reference_counting.adb    # Package body (implementations)
├── reference_counting.gpr    # GNAT Project File
├── tests.adb                 # 15+ terminal-executable tests
├── Makefile                  # Compilation and testing rules
├── obj/                      # Directory for object files
├── bin/                      # Directory for executables
└── README.md                 # Project documentation
```

---

## Dependencies

- **GNAT (GNU Ada Translator)**: Required to compile Ada code. Install via:
  - Ubuntu/Debian: `sudo apt-get install gnat`
  - macOS: `brew install gnat`
  - Windows: Download from [GNAT Community](https://www.adacore.com/community).

---

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for:
- Bug fixes.
- New features or variants.
- Improved test coverage.
- Documentation updates.

---

## References

- [Wikipedia: Reference Counting](https://en.wikipedia.org/wiki/Reference_counting)
- [Ada Programming Language](https://www.adaic.org/)
- [GNAT User Guide](https://docs.adacore.com/gnat_ugn-docs/html/gnat_ugn.html)
