# Paxos Algorithm Implementation (Ada)

## Project Overview
This repository contains a robust, strongly-typed implementation of the **Paxos Distributed Consensus Algorithm** written in Ada. Paxos is designed to achieve consensus in a network of unreliable processors. This package implements the core state machine logic for an Acceptor node, modeling the phase transitions without requiring an actual distributed network stack. 

## Features
The codebase provides implementations for the core protocol and multiple academic variants described in distributed systems literature:
*   **Basic Paxos:** Full implementation of Phase 1 (Prepare/Promise) and Phase 2 (Accept/Accepted) ensuring no conflicting values are chosen.
*   **Multi-Paxos:** An extension supporting arrays of consensus instances (logs) for continuous operation.
*   **Fast Paxos:** Implementations bypassing the Phase 1 Proposer cycle directly to Acceptors using default "Any" proposals to reduce latency.
*   **Cheap Paxos:** Role-based consensus separating Main Quorums from Auxiliary Quorums, demonstrating fallback mechanism states.

## Testing (Verification & Validation)
Testing is treated as a paramount requirement in line with critical systems V&V standards. The test suite is designed under the assumption that the code is *incorrect*. A `PASS` dictates that a specific assumption of failure was rigorously disproven.

### What the tests verify:
1.  **Functional Correctness:** Verifies logic rules (e.g., higher Proposal IDs correctly overwrite earlier states, Promises accurately report previously accepted values).
2.  **Robustness & Error Handling:** Proves the system handles edge cases gracefully (e.g., Array out-of-bounds `Constraint_Error` trapping in Multi-Paxos).
3.  **Variant Isolation:** Ensures that optimization variants (like Cheap Paxos and Fast Paxos) conform precisely to their restricted constraints (e.g., Auxiliary nodes remain dormant unless Main nodes fail).

### Why these tests matter:
In distributed systems, data corruption occurs subtly through race conditions and stale network packets. By asserting state machine constraints strictly (such as never accepting an older Proposal ID after promising a newer one), these tests validate that the Ada package strictly upholds the Safety constraints of Paxos. This mathematical correctness ensures system reliability and prevents split-brain scenarios.

## Usage

### Compilation
The project requires the GNAT Ada compiler. You can compile the project using standard Make or the GNAT Project file.

Using `make` (Recommended):
```bash
make all
