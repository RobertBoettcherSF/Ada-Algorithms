# Red-Black Tree (Ada 2023)

This project provides a robust, zero-warning (under `-gnatwa`) Ada 2023 implementation of a classic Red-Black Tree, an advanced self-balancing binary search tree. The package provides O(log n) time complexity guarantees for insertion, deletion, and search operations, following the gold-standard algorithm defined in classical computing literature (like CLRS). It strongly types data, separating internal structural nodes from external Keys and Values.

## Features
* Standard balanced structural logic ensuring maximum height of 2 * log(n+1).
* Insert, Delete, Search, and check (Contains) operations.
* Successor, Predecessor, Minimum, and Maximum querying operations.
* Defensive programming with strictly defined exceptions: `Empty_Tree_Error`, `Key_Not_Found_Error`, and `Duplicate_Key_Error`.
* A deep structural integrity validation function (`Is_Valid_Red_Black_Tree`) to rigorously confirm that all Red-Black and BST constraints hold after mutations.
* Explicit memory management using `Ada.Unchecked_Deallocation` without dangling pointers or leaks.

## Usage
To use the test suite:
1. Run `make test`.
2. Expected output includes passing results for all 15 tests, printing sequential "PASS" assertions.

## Testing
The test suite encompasses 15 test categories, covering invariant enforcement, bounds, edge cases, exceptions, and random-like mutation resilience. Ensuring every branch logically processes edge cases (like leaf node deletion, deletion with one child, two children, root deletions, and empty trees) is critical for structural validation. The standalone test doubles as a direct utilization example, showcasing all API operations and exception catching.

## Building
Requires a GNAT compiler capable of compiling Ada 2022/2023 constructs. Build artifacts and binary objects can be discarded cleanly via `make clean`.

## Checking the validator
`Is_Valid_Red_Black_Tree` is itself tested (TEST 15): the test-only child package `Red_Black_Tree.Test_Support` builds arbitrary node layouts, including invalid ones, and gives an independent reference definition (`Reference_Valid`, an in-order walk). The judge must agree with it on every layout of 1 to 4 nodes with keys 1 to 4 and both colours at every node, and on trees with a broken parent link or a wrong count. The library itself never uses `Test_Support`.
