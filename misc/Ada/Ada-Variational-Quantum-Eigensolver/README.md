# Variational Quantum Eigensolver (VQE) Simulator in Ada

## Project Overview
This repository contains a robust, classically-simulated implementation of the **Variational Quantum Eigensolver (VQE)** algorithm written in Ada. VQE is a hybrid quantum-classical algorithm utilized to find the upper bound of the lowest eigenvalue of a given Hamiltonian. This implementation simulates the quantum circuits using classical multi-dimensional cost landscapes, allowing the classical optimization loops to be tested in a purely classical Ada environment.

## Features
The codebase encompasses all standard VQE variants as detailed in leading literature:
*   **Multiple Ansätze Supported:**
    *   `Hardware_Efficient`: Simulates shallow, parameterized quantum circuits tailored to specific hardware topologies.
    *   `Unitary_Coupled_Cluster` (UCC): Simulates the highly structured fermionic ansatz frequently used in quantum chemistry.
    *   `QAOA`: Incorporates structures resembling the Quantum Approximate Optimization Algorithm.
*   **Classical Optimizers:**
    *   `Gradient_Descent`: Utilizes finite-difference methods for deterministic convergence.
    *   `SPSA` (Simultaneous Perturbation Stochastic Approximation): A gradient-free stochastic approach specifically effective in noisy quantum environments.
*   **Strong Typing & Constraints:** Utilizes Ada's static type system to ensure physical and mathematical bounds (e.g., forbidding zero-iteration optimizations, preventing dimension mismatches).

## Testing
This project embraces rigorous **Verification and Validation (V&V)** principles. The test suite operates on an aggressive, pessimistic assumption: *The code is assumed to be broken, vulnerable, or incorrectly implemented until the tests actively disprove it.*

### Test Categories and Their V&V Purpose:
1.  **Functional Correctness (Tests 2-7, 12-13):** Verifies that expected mathematical landscapes are generated for each Ansatz, and that the classical optimizers successfully navigate these landscapes to find the minimum energy state.
2.  **Error Handling (Tests 1, 11):** Validates that invalid states (like empty Hilbert spaces or 0-dimension parameter vectors) are safely caught via Ada Exceptions, preventing segmentation faults or undefined behavior.
3.  **Edge Cases (Tests 8-9):** Assesses boundary conditions, such as providing unreachable optimization tolerances or testing iteration limits. Proves the code will not infinite-loop under extreme conditions.
4.  **Performance & Scaling (Test 10):** Ensures the `Hamiltonian` struct dynamically scales the complexity of the energy landscape without breaking the mathematical logic.

**Why these tests matter:** 
In critical scientific computing, algorithms must gracefully handle unexpected state injections without producing silently incorrect data. By framing tests as "assumptions of failure" that the code must successfully defeat (e.g., *Assume optimizer crashes when Max_Iter is 0* -> *PASS: Strong typing restricts iteration domain securely*), we validate the code against its intended operational limits and verify its alignment with strict mathematical requirements.

## Usage

### Compilation
The project requires an Ada compiler (`gnatmake` or GPRbuild). A `Makefile` is provided for simplicity. To compile the executable:

```bash
make
