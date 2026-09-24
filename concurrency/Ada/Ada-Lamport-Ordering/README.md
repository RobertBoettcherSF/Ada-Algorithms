# Lamport Logical Ordering in Ada

## Project Overview
This codebase provides a strict, fault-tolerant implementation of **Lamport Ordering (Lamport Timestamps)** in Ada. It facilitates the determination of event ordering in distributed computer systems where physical clocks cannot be perfectly synchronized. The implementation translates partial ordering mechanisms into a strict total order using process IDs.

## Features
- **Strong Typing Validation**: Distinct types for `Logical_Clock` and `Process_Identifier` to prevent cross-type assignment errors.
- **Local Events**: Internal process progression tracking.
- **Send Events**: Message preparation with integrated timestamp tagging.
- **Receive Events**: Timestamp synchronization enforcing the `max(local, message) + 1` algorithm.
- **Total Ordering Extension**: Ensures deterministic tie-breaking of concurrent events based on static Process IDs.
- **Overflow Protection**: Built-in boundary exception handling (`Clock_Overflow`) guarding against memory wrapping faults.

## Testing
This project embraces rigorous **Verification & Validation (V&V)** principles. The overarching philosophy of our testing suite is pessimistic assumption: we assert the code is broken until proven otherwise. Tests only PASS when an assumption of failure is successfully disproved.

### What Each Test Category Verifies
1. **Functional Correctness (Tests 1-7)**: Validates that initializations and basic logical increments strictly adhere to Lamport's definitions. Proves that clocks synchronize accurately over `Send` and `Receive` events.
2. **Edge Cases (Tests 8-11)**: Verifies the Total Ordering mechanism under the edge condition where timestamps are identical. It validates deterministic tie-breaking logic.
3. **Error Handling & Robustness (Test 12)**: Forces boundary violations (clock integer overflow) to ensure the system fails gracefully by raising safe, trappable exceptions rather than causing undefined behavior.
4. **Performance & Math Properties (Tests 13-14)**: Validates required mathematical principles—namely *transitivity* ($a \rightarrow b$ and $b \rightarrow c \implies a \rightarrow c$) and *causality constraint* (a send event strictly precedes its own receive event in the logical order).

### Why These Tests Matter
In distributed mission-critical systems, inaccurate event ordering leads to data races, causality violations, and corrupted state machines. These tests prove correctness by aligning code behavior directly with logical algorithm requirements, mitigating the risk of silent concurrency faults.

## Usage

### Compilation Instructions
To build the executable test suite, simply use `make`. The GNAT compiler will handle dependencies and place outputs in isolated directories.

```bash
make all
