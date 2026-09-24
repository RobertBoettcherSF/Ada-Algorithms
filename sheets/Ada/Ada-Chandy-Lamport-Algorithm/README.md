# Chandy-Lamport Distributed Snapshot Algorithm

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Chandy-Lamport algorithm, used to record a consistent global state (snapshot) of an asynchronous distributed system. The algorithm assumes FIFO channels and no message failures. 

## Features
- **Strong Typing**: Enforces `Node_ID`, `Snapshot_ID`, and `Message_Kind` explicitly to prevent logic intersections.
- **Variant 1 - Single Initiator**: A discrete process can trigger a topology-wide state capture cleanly.
- **Variant 2 - Concurrent Multi-Initiator**: Overlapping, concurrent snapshots are natively supported through multiplexed `Snapshot_ID` arrays. State recording channels isolate queues perfectly per snapshot.
- **Strict V&V Enforcement**: Includes 13+ assertions testing logic constraints, queue boundaries, and exception handling.

## Testing: Verification & Validation (V&V)
The included test suite (`tests.adb`) operates under a **pessimistic assumption**: the codebase is presumed broken. The tests execute strictly to disprove this by verifying safety, correctness, and edge-case handling required for critical systems. 

**What the categories verify:**
- **Functional Correctness:** Asserts that snapshot triggers correctly freeze local state, close active channels, and accurately queue in-transit messages sent prior to closure (Tests 3, 4, 5). 
- **Concurrency Support:** Proves multiple snapshots can record distinct global states simultaneously without overlapping memory or corrupting message queues (Test 9).
- **Error Handling & Boundaries:** Validates that attempting to allocate out-of-bounds nodes or invalid snapshots triggers `Constraint_Error`, adhering to Ada's strict memory safety bounds (Test 10).
- **Edge Cases:** Guarantees that late-arriving messages on definitively closed channels update the global node state but are correctly excluded from the historical snapshot queue (Test 8).

**Why these tests matter:** 
In distributed systems, inconsistent global states cause irrecoverable data loss. These tests act as safety proofs—ensuring the algorithm respects the Conservation of Mass (in-transit messages + recorded states = total state) and operates precisely to technical specifications.

## Usage
### Compilation
The project uses the GNAT compiler. To build all executables:
```bash
make all
