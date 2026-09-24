# Quantum Walk Search in Ada 2023

## Overview

Production-grade Ada 2023 implementation and simulation framework for Quantum Walk Search algorithms. Models discrete-time coined quantum walks, continuous-time Hamiltonian evolution, and classical random walk baselines for comparative analysis across graph topologies.

## Features

- **Discrete-Time Quantum Walk Search**: Coined quantum walk with oracle reflection and graph adjacency diffusion mixing
- **Continuous-Time Quantum Walk Search**: Schrödinger-like Hamiltonian evolution over graph structures
- **Classical Random Walk Search**: Stochastic classical baseline for performance comparison
- **Strong Typing &amp; Contract-Based Design**: `Vertex_Index`, `Step_Count`, `Probability`, `Success_Probability` with `Pre`/`Post` conditions
- **Error Handling**: `Invalid_Graph_Error`, `No_Marked_Vertex_Error`, `Vertex_Out_Of_Bounds`, `Invalid_Parameters_Error`
- **Test Suite**: 13 test categories, 39 assertions

## Usage

### Building

**Prerequisites:**

- GNAT compiler with Ada 2023 support (ISO/IEC 8652:2023)
- GNU Make

**Build:**

```bash
make
```

### Testing

Run the test suite:

```bash
make test
```

**Clean:**

```bash
make clean
```

**Expected output:**

```
=== Quantum_Walk_Search Test Suite ===
TEST 1 — Graph Validation Helper
  PASS — 1.1 Symmetric graph is recognized as valid
  PASS — 1.2 Asymmetric graph is recognized as invalid
  PASS — 1.3 Graph validity function is deterministic
...
=== 39 passed, 0 failed ===
```

**Test Coverage:**

- Functional correctness (discrete-time/continuous-time quantum amplitude evolution, probability calculations)
- Edge cases (single-node, multi-node marked sets, zero steps, zero evolution time)
- Error handling (`Invalid_Graph_Error`, `No_Marked_Vertex_Error`)
- Invariants (success probabilities in range $$0.0, 1.0$$)
