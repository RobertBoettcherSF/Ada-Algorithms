# Sethi-Ullman Algorithm Implementation in Ada

## Project Overview
This repository contains an Ada implementation of the **Sethi-Ullman algorithm**. The algorithm translates abstract syntax trees (ASTs) into machine code that guarantees the use of the minimum possible number of registers. This implementation evaluates instruction order, assigns weights to subtrees, and emits intermediate instruction representations.

## Features
This robust implementation supports all major variants of the algorithm described in computational literature:
- **Standard Labeling**: Computes minimum register needs via bottom-up (post-order) traversal.
- **Machine Model Asymmetry (Memory-Operand)**: Allows right-child leaf nodes to require 0 registers for architectures that can fetch directly from memory.
- **Commutative Optimization**: Analyzes algebraic properties of operators (`+`, `*`) and dynamically swaps left/right children if doing so reduces register pressure.
- **Register Spilling**: Monitors target machine limits. If register demand exceeds the available limit (`Available_Reg`), the algorithm injects `STORE` and `LOAD_MEM` instructions to safely spill to memory.

## Testing
This codebase is governed by rigorous Verification & Validation (V&V) principles to assure correctness and safety for critical system usage. We assume a pessimistic approach: code is assumed broken until assertions explicitly disprove failure modes.

### Verification Categories
1. **Functional Correctness**: Validates that labels (weights) are assigned accurately based on L=R and L/=R constraints (Tests 2, 4, 5).
2. **Edge Cases**: Validates algorithm behavior in asymmetric conditions and nil inputs (Tests 1, 9).
3. **Variant Integrations**: Confirms that Memory Operands and Commutative Swaps trigger successfully and only when mathematically legal (Tests 3, 12, 13).
4. **Error Handling & Limits**: Asserts that exceeding register thresholds successfully triggers the fallback Spilling logic without data loss (Tests 10, 11).

### Why V&V Matters Here
In compiler design, register misallocation leads to silent data corruption (overwriting live variables). These 14+ tests verify that the execution order adheres to bounds, non-commutative operations (`-`, `/`) remain intact, and memory is strictly freed to prevent leaks in long-running processes.

## Usage

### Compilation
The project requires the GNAT toolchain. Code is structured strictly in the root directory.

To build the executable test suite, run:
```bash
make
