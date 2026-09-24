# Uniform-Cost Search (UCS) in Ada

## Project Overview
This project implements the **Uniform-cost search (UCS)** scheduling/pathfinding algorithm in Ada. UCS is a traversing algorithmic strategy used on weighted trees or graphs. It progressively expands the node with the lowest path cost $g(n)$ from the root. This project guarantees correctness via strong static typing and thorough verification & validation test suites.

## Features
- **Strong Typing:** Customized numeric and record types to avoid generic data faults.
- **Priority Queue Implementation:** Built-in dynamic minimum-heap structure handling edge-weights and frontier expansions seamlessly.
- **Variant 1 - Graph Search (Explored Set):** Standard version. Stores visited nodes to prevent redundant expansions and completely removes infinite loop scenarios on cyclic topologies.
- **Variant 2 - Tree Search (No Explored Set):** Blind variant that allows traversing overlapping state spaces. Integrates a hard expansion limit constraint (`Max_Expansions`) to guard against catastrophic cyclic hardware locking.
- **Encapsulated Error Handling:** Precise algorithmic exceptions, such as unreachable state limits and disconnected edge invocations (`Graph_Error`, `Search_Limit_Exceeded`).

## Testing

Adhering to rigorous Verification and Validation (V&V) principles standard in critical systems, the internal test suite uses the "Guilty until proven innocent" methodology: the underlying hypothesis strictly assumes the code is **incorrect or non-functional**. A test `PASS` evaluates directly as *disproving* that hypothesis.

Tests encompass the following Verification methodologies:
1. **Functional Correctness:** Verifies logic maps appropriately (e.g., bypassing direct expensive paths for cheaper indirect routes, correct length generation).
2. **Error Handling:** Validates that API misuse cleanly isolates and throws (`Graph_Error` raised for invalid root nodes without triggering segmentation faults).
3. **Edge Cases:** Validates mathematical zeros and empty structures (Zero-cost cyclic bounds, Start=Goal zero-distance logic).
4. **Performance Bounds:** Confirms complexity scales effectively by resolving large iterative loops (Stress Test linear deep chains).

These tests matter because they simulate unpredictable environment interactions (like blind cycles or dead paths in routing hardware) to guarantee reliability and algorithmic safety.

## Usage

### Compilation
The codebase utilizes a `Makefile` bound to a GNAT project file for streamlined environment management. Note that the codebase assumes execution strictly in the root repo directory.

```bash
# Compile and build the executable locally
make
