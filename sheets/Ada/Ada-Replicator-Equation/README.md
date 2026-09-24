# Replicator Equation (Ada Implementation)

## Project Overview
This codebase provides a strict-typed, robust Ada implementation of the **Replicator Equation**, a fundamental deterministic monotonic non-linear mechanism from evolutionary game theory. It calculates how the frequency of strategies (or species) changes dynamically within a population proportional to their fitness compared to the average fitness of the overall population. 

## Features
The algorithm suite implements ALL major variations described in the standard literature:
*   **Discrete Replicator Equation:** Generation-by-generation updates.
*   **Continuous Replicator Equation:** Differential rate updates integrated via the Euler method.
*   **Replicator-Mutator Equation:** Continuous equation injecting a probabilistic mutation matrix $Q$, accounting for strategy alteration.
*   **Asymmetric (Two-Population) Replicator:** Bipartite graph game theory (e.g., males vs females, Hawks vs Doves in separate geographical groups) applying different payoff structures across populations.
*   **Automatic Population Normalization:** Eliminates floating-point sum drift intrinsically.

## Testing (Verification & Validation)

This project adopts a pessimistic V&V (Verification and Validation) approach: **The code is assumed broken until explicitly proven otherwise through automated testing.** 

### What the test categories verify:
1. **Functional Correctness:** Verifies the matrix multiplications, fitness scores ($f_i(x)$), and average fitness limits ($\phi(x)$) resolve exactly to mathematically derived constants. 
2. **Edge Cases:** Evaluates what happens at the mathematical boundaries:
   * *Extinction Check:* An extinct species ($0.0$) must not spontaneously respawn via basic reproduction dynamics.
   * *Equilibrium Checks:* Uniform matrices must perfectly preserve pre-existing bounds.
3. **Robustness & Error Handling:** Explicitly forces catastrophic conditions (e.g., negative populations, array dimension mismatches between matrices and vectors) to prove that standard exception handling (`Constraint_Error`, `Dimension_Mismatch`) securely prevents unpredictable runtime states.
4. **Safety (Performance Bounds):** Proves that massive integrations (large `Delta_T`) correctly bottom out at $0.0$ bounds, guaranteeing the system never outputs biologically impossible negative population percentages.

### Why these tests matter:
In rigorous and critical systems, equations running continuous game-theoretic topologies are deeply vulnerable to cascading float deviations. By exhaustively verifying dimension enforcement, bounds safety, and identity-equivalency (e.g., ensuring standard continuous results exactly match mutator-continuous results when given an Identity mutation matrix), we ensure the reliability and integrity mandated by standard critical safety heuristics. *Passing these tests disproves the assumption that our arrays bleed memory or distort state variables.*

## Usage

### Compilation
The codebase uses a GNAT Project File (`.gpr`). To compile the executable and its libraries, ensure GNAT is installed and run:
```bash
make
