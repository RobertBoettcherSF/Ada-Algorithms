# Cristian's Algorithm in Ada

## Project Overview
This repository contains a robust, statically typed implementation of **Cristian's Algorithm** for clock synchronization in distributed systems. It allows a client to synchronize its clock with a time server while calculating and accounting for network propagation delays (Round-Trip Time).

## Features
The implementation comprehensively supports all mathematical bounds and variants identified in standard definitions of the algorithm:
*   **Basic Synchronization:** Approximates real time via `$T_{server} + (RTT / 2)$`.
*   **Threshold Outlier Rejection:** Discards synchronizations where network delay exceeds a defined threshold (`Synchronize_With_Threshold`), thereby minimizing severe network jitter errors.
*   **Multiple Sample Selection:** Aggregates multiple sequential queries and dynamically selects the one with the smallest RTT (`Synchronize_Multiple`), isolating the most accurate sample.
*   **Accuracy/Error Bound Checking:** Calculates the maximum clock error `$\pm (RTT - Min\_Delay)/2$` guaranteeing known deterministic margins.
*   **Strict Validations:** Prevents temporal/causality violations (receive time occurring before send time) and physics violations (minimum delays surpassing total RTT).

## Testing
This codebase embraces strict Verification and Validation (V&V) principles tailored for critical systems. The test suite operates on a pessimistic assumption: it presumes the codebase is functionally broken or handles memory/logic unsafely. A "PASS" status actively disproves this assumption.

### What Each Category Verifies:
1.  **Functional Correctness:** Tests 1, 4, 8, and 11 ensure the algorithm strictly adheres to the mathematical model for Cristian's offsets, RTT selection, and Error Bounds (Verification).
2.  **Error Handling:** Tests 3, 7, 10, and 13 attempt to force logic failures via invalid temporal states (e.g., negative time differentials), confirming the system gracefully halts via expected Exceptions instead of yielding corrupted time data (Safety/Validation).
3.  **Edge Cases & Boundaries:** Tests 2, 5, 6, 12, and 14 evaluate minimum/maximum boundary parameters (RTT exactly on threshold, length 1 arrays, simulated 0-delay environments).

### Why These Tests Matter:
In distributed infrastructures, desynchronized clocks can cause data corruption, failed cryptographic handshakes, or catastrophic sequencing errors. Validating both mathematical exactness and boundary stability guarantees the Ada clock agent will neither ingest poisoned network data nor output unsafe variables to the larger system.

## Usage

### Compilation
The codebase leverages the GNAT compiler. `make` relies on the GNAT Project File (`cristians.gpr`), ensuring Ada assertions (`-gnata`) are active.

```bash
# Compile the project and build the test runner
make all
