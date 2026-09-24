# Topological Sorting in Ada

## Project Overview
This repository contains an implementation of the **Topological Sorting** algorithm for Directed Acyclic Graphs (DAGs) in Ada 2012. A topological sort provides a linear ordering of vertices such that for every directed edge $uv$ from vertex $u$ to vertex $v$, $u$ comes before $v$ in the ordering. This is essential for job scheduling, data serialization, and dependency resolution systems.

## Features
The codebase implements the primary variants mentioned in the [Wikipedia article on Topological Sorting](https://en.wikipedia.org/wiki/Topological_sorting):

- **Kahn's Algorithm:** An iterative, queue-based approach evaluating in-degrees (incoming edges). Ideal for preemptive / static DAG parsing.
- **Depth-First Search (DFS) Algorithm:** A recursive algorithm determining permanent and temporary visitation marks, capturing constraints via backwards inclusion.
- **Robust Cycle Detection:** Both algorithms identify and flag cyclic dependencies safely, averting infinite loops. 

## Testing (Verification & Validation)
The testing suite explicitly implements **Verification and Validation (V&V)** principles required for critical systems. 
*Assumption for tests:* The code is fundamentally flawed. Tests output a **PASS** status only when this pessimistic assumption is provably disproven by factual execution.

### What the test categories verify:
- **Functional Correctness:** Tests structural variations (linear, branching, inverted nodes) ensuring the emitted topological sequence intrinsically matches the prerequisite dependency tree via automated `Is_Valid_Sort` validation.
- **Error Handling:** Validates proper detection of unresolvable constraints (cyclic dependencies), ensuring system stability.
- **Edge Cases:** Proves correctness under stress (empty graphs, singular nodes, standalone self-loops, and entirely disconnected components).
- **Performance / Memory Safety:** DFS validates bounds safely without stack-overflow on self-loops; Kahn evaluates empty queues dynamically without null-dereferences.

### Why these tests matter:
In systems programming, unvalidated dependency schedules can lead to deadlocks, race conditions, or unhandled exceptions. By aggressively testing bounds and negative criteria (cycles), we assure reliability, safety, and strict alignment to theoretical algorithm specifications. 

## Usage

### Compilation Instructions
This project can be compiled directly via `make` or using the provided GNAT project file.

```bash
# Compile using Make
make

# Alternatively, compile using GPRbuild
gprbuild -P topological_sorting.gpr
