# Shortest Common Supersequence (Ada Implementation)

## Project Overview
This repository contains a robust, strongly-typed Ada implementation of the Shortest Common Supersequence (SCS) problem. The problem attempts to find the shortest possible sequence `Z` such that both sequence `X` and sequence `Y` are subsequences of `Z`.

## Features
*   **Exact DP for 2 Strings (`SCS_Length`, `SCS_String`)**: Implements Dynamic Programming to perfectly calculate and trace the minimum layout for 2 strings in $O(nm)$ space and time.
*   **NP-Hard K-String Approximation (`SCS_Multiple`)**: Iterative greedy algorithm that handles $k > 2$ string variants by folding dynamic programming calculations consecutively.
*   **Strong Typing Constraints**: Exposes custom types (`Unbounded_String_Array`) restricting faulty runtime bounds and implements memory-safe exception handlers (`Empty_Array_Error`).

## Testing

Our testing philosophy utilizes **Pessimistic Verification & Validation**. We assume the codebase is broken or handles memory/logic incorrectly; a test `PASS` indicates that this negative assumption has been empirically disproven.

The suite verifies:
1.  **Functional Correctness**: Asserts that DP backtracking produces identical outputs to expected DNA mappings or discrete sequence graphs.
2.  **Boundary & Edge Cases**: Ensures disjoint relationships, completely empty strings, overlapping containment, and structural identity are flawlessly bypassed.
3.  **Error Handling**: Validates that domain invalidations (like $k=0$ bounded arrays) immediately trap into controlled `Empty_Array_Error` exceptions rather than resulting in segmentation/bounds faults.
4.  **Performance & V&V Safety**: The DP implementation validates that iterations safely step forward without dangling pointers, obeying DO-178C style rigid bounds requirements.

## Usage

### Compilation
The project utilizes `gnatmake` and a custom GPR file to map paths safely without a `src/` directory limit.
```bash
make all
