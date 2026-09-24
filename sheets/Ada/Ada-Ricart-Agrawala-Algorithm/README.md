# Ricart-Agrawala Algorithm Implementation (Ada)

## Project Overview
This repository contains a robust, strongly-typed implementation of the Ricart\u2013Agrawala algorithm for achieving mutual exclusion in a distributed computing environment. It simulates the node-state logic, Lamport logical clocks, and tie-breaking mechanics required to safely enter a Critical Section (CS) without requiring a central coordinator.

## Architecture

### Core Components
- **`ricart_agrawala.ads`**: Package specification defining types, constants, and procedure signatures
- **`ricart_agrawala.adb`**: Package body implementing the algorithm logic
- **`tests.adb`**: Comprehensive test suite with 19 assertions across 13 test cases
- **`main.adb`**: Simple entry point demonstrating initialization

### Key Types
- `Node_ID`: Strongly-typed node identifier (1..Max_Nodes)
- `Sequence_Number`: Lamport logical clock based on Natural numbers
- `Node_State`: Enumeration (Released, Wanted, Held) representing CS entry states
- `Algorithm_Variant`: Enumeration (Standard, Roucairol_Carvalho) for algorithm variants
- `Node_Set`: Boolean array for tracking requests, replies, and permissions

## Features
* **Standard Variant**: Fully models the `2(N-1)` messaging requirement per CS entry.
* **Roucairol-Carvalho Optimization**: Implements implicit permission caching. Once a node receives a reply from another, it assumes permission is held until it must explicitly reply to a request from that same node, drastically reducing network overhead.
* **Safe Priority Tie-Breaking**: Resolves simultaneous requests deterministically using Lamport sequence numbers, falling back to unique Node IDs if sequence numbers match.
* **Strong Typing**: Uses strict custom Ada types (`Node_ID`, `Sequence_Number`, `Node_Set`) to prevent logic overlaps and arithmetic errors standard in integer-heavy C implementations.

## Testing
This project follows strict Verification & Validation (V&V) principles tailored for critical systems. The test suite operates on the pessimistic assumption that the code is non-functional, and tests only `PASS` when that assumption is provably disproved. 

### What the test categories verify:
* **Functional Correctness (Tests 1, 2, 4-6, 12-13)**: Verifies that the internal state machine accurately mirrors the algorithm's standard rules (Released -> Wanted -> Held -> Released) and that barriers to entry correctly block execution.
* **Edge Cases & Tie Breaking (Tests 7, 8)**: Verifies the resolution of simultaneous distributed requests, validating that the node correctly interprets sequence numbers and Node IDs as arbitration keys.
* **Algorithm Optimizations (Tests 9-11)**: Verifies the stateful memory of the Roucairol-Carvalho variant, ensuring permissions are accurately cached and rigorously yielded when requested.

### Why these tests matter:
In distributed systems, deadlocks and starvation are catastrophic failure states. Validating that tie-breakers perfectly adhere to the deterministic logic ensures that mutual exclusion properties are maintained. By utilizing Ada's built-in `pragma Assert` capability during tests, we guarantee runtime safety bounds against these failure modes.

## Usage
Ensure you have the GNAT Ada compiler installed.

### Compilation
To compile both the main stub and the test suite:
```bash
make all
```

### Running Tests
To compile and execute the test suite:
```bash
make test
```

### Cleaning Build Artifacts
To remove compiled objects and binaries:
```bash
make clean
```

## Algorithm Background

The Ricart-Agrawala algorithm is a tokenless mutual exclusion algorithm for distributed systems. Unlike centralized approaches (e.g., Lamport's algorithm), it does not require a central coordinator. Instead, each node maintains:

1. **Lamport Logical Clock**: Sequence numbers to establish happens-before relationships
2. **State Tracking**: Current state (Released, Wanted, Held)
3. **Request/Reply Tracking**: Which nodes have been contacted and which replies are outstanding

### Standard Variant
- Node broadcasts REQUEST to all other nodes before entering CS
- Waits for REPLY from all nodes
- Total: 2(N-1) messages per CS entry

### Roucairol-Carvalho Optimization
- Caches implicit permissions after receiving REPLY
- Only re-requests from nodes that have explicitly requested since last grant
- Significantly reduces message count in steady-state operation
