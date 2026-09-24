# Discrete-Event Simulation Engine

This project provides a complete, robust, and highly typed Discrete-Event Simulation (DES) engine implemented in Ada 2023. At its core, it manages the advancing of simulation time and the execution of state-altering events utilizing an efficient array-based Min-Heap priority queue.

## Features
* Event-Scheduling (Next-Event Time Advance): Instantly warp simulation time to the next scheduled event using Step_Next_Event.
* Activity-Scanning (Fixed-Increment Time Advance): Move the simulation forward in uniform time steps using Step_Fixed_Increment, executing any events that occur within the interval.
* Lazy Deletion / Preemption: Cancel events securely by ID without needing expensive heap rebuilding.
* Strong OOP Extensibility: Inherit from the abstract Event tagged type and override the Execute procedure to implement arbitrary discrete systems.
* Memory Ownership: The Simulator manages memory safety, automatically discarding and collecting objects when processed, cancelled, or cleared.
* Deep Ada Contracts: Protects system invariants utilizing strict subtyping and Pre/Post condition checking.

## Usage
Simply run the included test suite. Because this acts as a framework, the tests.adb runner demonstrates exactly how to derive custom test events and interact with the engine.

Expected test execution output includes explicit checks for capacities, constraints, temporal consistency, ordering, and lazy evaluation edge cases:

  PASS — 1.1 Clock is 0.0
  PASS — 1.2 Pending_Events is 0
  ...
  === 44 passed, 0 failed ===

## Testing
To test, compile and run the suite:

make test

The suite thoroughly verifies:
1. Data-structure invariant preservation (Min-Heap stability).
2. Proper detection of temporal anomalies (scheduling in the past).
3. Memory ownership boundaries and safety clears.
4. Edge cases: duplicate times, max capacity breach, empty queue processing.

## Building
Prerequisites: GNAT Toolchain
Standard: Ada 2022/2023 (-gnat2022)

make all
