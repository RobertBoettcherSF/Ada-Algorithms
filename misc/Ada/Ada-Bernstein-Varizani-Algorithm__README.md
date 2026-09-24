# Bernstein–Vazirani Algorithm in Ada

## Project Overview
This repository implements the [Bernstein–Vazirani Algorithm](https://en.wikipedia.org/wiki/Bernstein%E2%80%93Vazirani_algorithm) in Ada 2023. The algorithm resolves a hidden string problem using an oracle $f(x) = x \cdot s \pmod 2$. The package demonstrates the fundamental query complexity gap between the classical deterministic approach (requiring exactly $n$ queries) and a fully simulated quantum state vector execution, showing how the problem can be theoretically solved in exactly $1$ query.

## Features
* **Strict Typing:** Defines rigid constraint types like `Bit`, `Bit_String`, and custom interface designs avoiding bare types.
* **Classical Deterministic Variant (`Solve_Classical`):** Recovers the hidden string bit-by-bit using standard single-bit dot products.
* **Quantum Simulated Variant (`Solve_Quantum_Simulated`):** Initializes an $O(2^{N+1})$ state vector, applies multi-qubit Hadamard transformations ($H^{\otimes N}$), phases the state using the provided oracle via phase kickback, and measures the maximal probability collapse to read the hidden string instantly.
* **Contract-based Robustness:** Utilizes strict Ada 2023 `Pre` conditions protecting resource allocation limits in the state vector matrix (limits $N \le 10$).
* **Standalone Interface Validation:** Leverages purely object-oriented interfaces (`Oracle_Interface`) preventing side effects.

## Building
**Prerequisites:** GNAT toolchain supporting Ada 2023 (`gnatmake`).
1. Make sure you are in the directory containing the project source.
2. The `Makefile` configures all strict warnings (`-gnatwa`), contract enablement (`-gnata`), and the Ada 2022/2023 standard (`-gnat2022`).

## Usage
Simply invoke the test runner via the Makefile. No standalone `main.adb` is needed as `tests.adb` demonstrates the full lifecycle, API layout, and execution paths interactively:

```bash
make test
```

**Expected Output:**
```text
Running tests...
TEST 1 — Classical BV, Secret '0'
  PASS — 1.1 Result length is 1
  PASS — 1.2 Result string is correct
  PASS — 1.3 Bit value is zero
...
===  42 passed,  0 failed ===
```

## Testing
The test suite spans 14 tests, tracking over 40 distinct assertions checking:
* **Functional Correctness:** Asserts deterministic matches for multi-bit sequences (101, 1111) across classical vs quantum variations.
* **Edge Cases:** Covers extreme sizes (e.g., $N=10$) spanning alternating patterns (1010101010) and lowest dimensions ($N=1$).
* **Error Handling:** Validates `Constraint_Error` for unsupported conversion characters, and verifies that `Assert_Failure` traps exponential memory allocation boundaries if users demand $N > 10$ from the simulation.
* **Internal Invariants:** Bypasses solvers to directly audit the Oracle's mathematical dot-product logic.
