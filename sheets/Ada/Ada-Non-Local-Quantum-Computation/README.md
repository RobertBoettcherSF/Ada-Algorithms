# Non-Local Quantum Computation (NLQC) Analysis Package in Ada 2023

## Project Overview
This project provides a robust, strongly-typed Ada 2023 implementation modeling non-local quantum computation (NLQC) entanglement cost bounds, port-teleportation protocols, and f-routing / conditional disclosure of secrets (CDS) protocols. Based on theoretical formulations of distributed quantum computing and circuit complexity upper bounds, this library computes and validates resource requirements across multiple algorithmic variants.

## Features
- **T-Gate Count Upper Bound**: Computes the entanglement cost $E(U) = O(n 2^k)$ based on qubit count and minimal T-gate decomposition count.
- **T-Depth Upper Bound**: Evaluates the entanglement cost $E(U) = O((68n)^d)$ based on T-depth layers.
- **Port-Teleportation Entanglement Cost**: Models single-exponential and double-exponential entanglement scaling for general non-local unitaries.
- **f-Routing and CDS Entanglement Cost**: Evaluates entanglement upper bounds relating cryptographic conditional disclosure of secrets and private simultaneous messages to quantum routing protocols.
- **Circuit Validation & Safety**: Strong typing with domain-specific subtypes (`Qubit_Count`, `Gate_Count`, `T_Depth`, `Entanglement_Cost`), comprehensive contract aspects (`Pre`, `Post`), and robust overflow protection.

## Building
Prerequisites:
- GNAT compiler with Ada 2023 support (`-gnat2022`).

Build the test executable using the Makefile:
```bash
make
```

## Usage
Run the comprehensive test suite and demonstration:
```bash
make test
```

Expected output format:
```text
Running tests...
TEST 1 — T-Gate Bound Basic Calculation
  PASS — T-gate bound n=2, k=0 is 2
  ...
=== 39 passed, 0 failed ===
```

To clean build artifacts:
```bash
make clean
```

## Testing
The test suite (`tests.adb`) contains 13 comprehensive tests covering over 39 assertions, verifying:
- **Functional Correctness**: Exact mathematical evaluations of T-gate bounds, T-depth bounds, port-teleportation scaling, and routing costs.
- **Edge Cases**: Minimum boundaries ($n=1, k=0, d=0$), zero inputs, and limit validations.
- **Error Handling**: Verification that `Invalid_Parameters` and `Constraint_Error` are correctly raised and caught under invalid configurations or overflow conditions.
- **Invariants**: Monotonicity, additive properties, and API integration workflows ensuring all public subprograms are fully exercised.
