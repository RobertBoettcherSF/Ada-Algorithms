# Risch Algorithm Integration Framework (Ada)

## Project Overview
This project implements the structural algorithms of the **Risch Algorithm** (a method of indefinite integration) in Ada. The Risch algorithm transforms the problem of integration into a problem in differential algebra. Due to the massive scope of Differential Galois Theory required for full algebraic integration, this project successfully implements the fundamental mathematical structure: building Abstract Syntax Trees for symbolic calculus, identifying integration branches, and explicitly proving non-elementary integrals (like the Gaussian integral).

## Features
- **Symbolic Mathematical AST:** Custom variant records (`Expression_Node`) representing variables, constants, arithmetic operations, and transcendental functions (Exp, Log).
- **Symbolic Differentiation:** Applies chain, product, and quotient rules necessary for the Risch differential extensions.
- **Algorithm Variants Simulated:**
  - **Main Dispatcher:** Routes symbolic structures to their algebraic solutions.
  - **Hermite Reduction Branch:** Evaluates polynomial rational integrations.
  - **Transcendental Extensions:** Checks logarithmic/exponential integrability boundaries using Liouville's theorem.
  - **Risch-Norman Heuristic Fallback:** Placeholder framework for parallel differential equations.
- **Non-Elementary Identification:** Correctly halts and identifies expressions that lack an elementary antiderivative (e.g., $e^{x^2}$).

## Testing
This project embraces rigorous **Verification and Validation (V&V) principles** typical of critical Ada systems. 
Our testing philosophy assumes the code is *non-functional or actively destructive*, and the assertions must *disprove* these assumptions to return a `PASS`.

### What each test category verifies:
1. **Functional Correctness (Tests 1-7, 10-12):** Verifies the AST mathematically applies derivation and basic integration rules accurately. Verifies the code implements the algorithm as specified in the mathematical requirements.
2. **Edge Cases & Error Handling (Tests 8-9):** Validates the algorithm behaves safely outside ideal conditions (e.g., attempting to integrate mathematically non-elementary functions or handling Null pointers without memory violations).
3. **Robustness (Test 13):** Ensures memory access and deep-tree traversal operate predictably without corruption.

### Why these tests matter:
In symbolic algebra and critical software, a false positive (integrating an unintegrable function) is significantly worse than a compilation failure. These tests ensure absolute correctness regarding Liouville's theorem boundaries and guarantee memory safety. Disproving pessimistic assumptions ensures that the system handles edge cases deterministically.

## Usage

### Compilation
The project uses GNAT and standard `make`. All files exist safely in the root directory.

```bash
# Compile the main project and test suite
make all
