# Ada Secant Method Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Secant Method** for root-finding, alongside its closely related variant, the **False Position Method (Regula Falsi)**. The Secant algorithm iterates using the secant line between initial points to approximate roots, while False Position maintains a valid sign bracket to guarantee convergence.

## Features
*   **Standard Secant Method:** Open method for fast iteration without bracket requirements.
*   **False Position Method (Regula Falsi):** Bracketed variant ensuring absolute convergence by maintaining points with opposite function signs.
*   **Strong Typing Implementation:** Uses custom `Real` digits constraint and access types (`Objective_Function`).
*   **Advanced State Handling:** Returns a cohesive `Root_Result` record encompassing numerical roots, iteration counts, and deterministic `Status_Type` enums (No silent failures).
*   **Resilience:** Native Division_By_Zero and Infinite Loop (Max_Iter) preventions.

## Testing
This codebase adopts a strict Verification and Validation (V&V) philosophy. The overarching test assumption is pessimistic: **we assume the code is broken or non-functional**. A test only PASSES when it actively disproves a failure assumption.

### Verification (Did we build the system right?)
*   **Edge Case Handling:** Verifies that division by zero (flat functions or equal inputs) escapes safely without raising OS-level exceptions.
*   **Error Handling:** Ensures `Invalid_Bracket` catches missing opposite signs in Regula Falsi, rejecting mathematically impossible states. 
*   **Functional Boundaries:** Confirms iteration limiters properly eject from infinite loops if convergence bounds are impossible.

### Validation (Did we build the right system?)
*   **Functional Correctness:** Verifies that the implementation resolves mathematical truths (e.g., matching known quadratic and cubic roots to $1.0E^{-7}$ and $1.0E^{-12}$ precision). 
*   These rigorous criteria ensure reliability, safety, and strict alignment with critical systems requirements typical of Ada deployments. 

## Usage

### Compilation
The codebase uses a GNAT project file standard and can be compiled natively using `make` from the root directory.
```bash
# Compile all files
make
