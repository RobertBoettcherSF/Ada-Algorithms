# Naimi-Trehel's Log(n) Mutual Exclusion Algorithm

## Project Overview
This project provides a pure Ada implementation of Naimi-Trehel's Distributed Mutual Exclusion algorithm. Unlike standard token-ring or broadcast-based consensus algorithms, Naimi-Trehel uses a dynamic, logical tree structure managed strictly through distributed pointer updates ("Owners") without relying on logical clocks. This yields an average message complexity of `O(log n)` per critical section request, dramatically improving network performance in distributed systems.

## Features
- **Dynamic Tree Structure:** Nodes dynamically update their "Owner" pointers during requests to form compressed paths.
- **Preemptive Message Queueing:** Simulates an asynchronous distributed network using event-driven message parsing.
- **Deferred Token Passing:** Critical sections execute completely before token yields. 
- **Strongly Typed Architecture:** Built with Ada's strict typing to prevent out-of-bounds node references and enforce queue limits.
- **Self-contained Simulator:** Capable of deterministic algorithmic execution in a standalone application.

## Testing (V&V Principles)
The testing suite emphasizes strict Verification and Validation (V&V) protocols designed for mission-critical distributed logic. The philosophy assumes the baseline code is non-functional, and each test must strictly disprove this assumption via targeted assertions.

* **Functional Correctness:** Verifies the logical path compression and correct handoff of tokens (e.g., ensuring nodes become their own owners upon requesting, and tokens eventually arrive). 
* **Error Handling:** Validates that attempting to release a token the node does not own correctly isolates the failure and raises a `Critical_Section_Violation`.
* **Edge Cases:** Validates simultaneous saturation requests. By simulating all nodes requesting at once, tests prove the dynamic tree flattens safely into a functional linear queue without deadlocks.
* **Performance / Path Optimization:** Checks `O(log n)` path optimizations by asserting that intermediate nodes transparently forward requests directly to updated owners rather than traversing stale graphs.

**Why these tests matter:** In distributed applications, race conditions or stale pointers lead to catastrophic deadlocks. Applying V&V ensures that safety (only one node holds the token) and liveness (requesting nodes eventually get the token) are categorically guaranteed under any message arrival order. Our pessimistic tests prove the code survives the most strenuous constraints.

## Usage

### Compilation
The project supports compilation via GNAT project files or standard make. 

Using Make:
```bash
make all
