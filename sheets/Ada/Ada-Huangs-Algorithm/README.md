# Distributed Termination Detection: Huang's Algorithm in Ada

## Project Overview
This repository provides an industrial-grade, strongly typed Ada implementation of **Huang's Algorithm** (Credit-Recovery / Weight-Throwing). It is a mathematical protocol utilized in distributed computing architectures to safely determine when a distributed task, spanned across multiple parallel worker nodes, has definitively terminated.

## Features
- **Strong Typing & Precision Guarantee**: Built-in constants (`Epsilon`) and custom types protect the weight fractions from floating point underflow anomalies.
- **Variant 1: Static Splitting**: Nodes cleanly partition their weight by exactly 50% when delegating a task to another node.
- **Variant 2: Dynamic Splitting**: Allows a configurable mathematical fraction of the parent node's weight to be delegated, giving fine-grained control over extensive spanning trees.
- **Direct Return Mechanism**: Safely pipelines returning weights specifically to the designated controlling agent (Initiator).
- **V&V Suite Included**: Extensive testing framework asserting state isolation, edge conditions, and valid execution paths.

## Testing (Verification & Validation)
The testing suite relies on strict V&V methodologies applied to critical systems. We begin with a **pessimistic assumption**: *Assume the code is broken or fundamentally flawed*. A test PASS means this assumption has been successfully disproven for that vector. 

Our suite guarantees reliability through 4 distinct assertion vectors:
1. **Functional Correctness (Tests 1-8)**: Verifies the standard state machines. Asserts that weight perfectly sums to `1.0` and proves the algorithm successfully deduces termination dynamically.
2. **Robustness & Error Handling (Tests 9-11)**: Protects against illegal state transitions (e.g., Idle nodes attempting to spawn tasks or accept malicious negative weights).
3. **Edge Cases (Test 12)**: Handles improper dynamic splits (>= 1.0 or <= 0.0), maintaining systemic integrity.
4. **Performance & Safety (Test 13)**: Validates floating-point stability by explicitly triggering underflow bounds (`1.0e-12`), ensuring the protocol catches mathematical degradation before corrupting distributed state.

## Usage

### Compilation
The codebase uses a GNAT project file mapped directly to the root directory. To compile all binaries:
```bash
make all
