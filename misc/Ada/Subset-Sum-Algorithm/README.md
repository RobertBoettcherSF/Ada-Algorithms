# Subset Sum Algorithms in Ada (V&V Tested)

## Project Overview
This project implements the **Subset Sum Problem**—a classic problem in computer science—in the Ada programming language. Given a set of integers, the algorithms determine whether any non-empty subset sums perfectly to a specified target. 

## Features
The codebase encompasses all primary variants discussed in theoretical computer science, fully leveraging Ada's strong typing system (`new Integer` arrays):
1. **Exponential Time (Recursive Backtracking):** `O(2^N)` solution. Supports all integers.
2. **Pseudo-Polynomial Time (Dynamic Programming):** `O(N * Target)` solution utilizing a boolean array state matrix. Extremely fast but requires non-negative integers.
3. **Meet-In-The-Middle:** `O(2^(N/2) * N)` solution. Halves the exponent penalty by splitting the set, generating subset combinations, and performing binary searches. Supports all integers.
4. **FPTAS (Fully Polynomial Time Approximation Scheme):** Trims search lists proportionally using a `Delta` bound (`C / N`) to calculate the maximum subset sum mathematically closest to (but never exceeding) the target in strictly polynomial time.

## Testing (Verification and Validation)
Adhering to strict V&V principles required for high-reliability systems, this project utilizes a pessimistic testing suite (`tests.adb`). 

* **The Philosophy:** The suite assumes the implementation is logically flawed, leaky, or non-functional. An assertion **PASSES** only when it explicitly disproves the initial pessimistic assumption (e.g., *Assume code hallucinates invalid subsets* -> Code correctly rejects invalid subsets -> `PASS`).

### What Each Category Verifies:
* **Functional Correctness:** Ensures base mathematical properties are sound (finding exact subsets, returning `False` when mathematically impossible). Proves algorithm adheres to its respective Big-O design.
* **Robustness & Error Handling:** Validates that `Constraint_Error` triggers safely when boundaries are breached (e.g., negative integers entering the DP variant).
* **Edge Cases:** Analyzes algorithm resilience against extreme states: subsets with 0 length, single-item subsets (`N=1`), and subsets exceeding predefined capacity limits.
* **Performance Bound Constraints:** Ensures approximation thresholds drop elements precisely when bounds exceed `Target * (1+Delta)` without returning items that exceed the target cap.

**Why these tests matter:** 
Ada is built for critical embedded software. Guaranteeing safety means proving the logic will not suffer state corruption or buffer overflows regardless of how adversarial the inputs are.

## Usage 

### Compilation
The codebase requires no dependencies outside standard Ada 2012 libraries. You can compile the project via GNAT or Make:

**Using Make (Recommended):**
```bash
make all
