# Amplitude Amplification in Ada 2023

## Project Overview
This repository provides a purely classical, strongly-typed simulator for the Amplitude Amplification quantum algorithm in Ada 2023 (ISO/IEC 8652:2023). It generalizes Grover's algorithm by abstracting out the initial state preparation and diffusion operators over mathematical probability amplitudes, effectively determining marked states in a search space.

## Features
* **Standard Amplitude Amplification:** Implements standard predefined Grover-like iteration structures mapped to an exact, continuous target probability function.
* **Exponential Search:** Integrates Brassard et al.'s dynamic approach to amplitude amplification where the initial success probability (or the number of marked states) is unknown, incrementally building iterations using random geometric intervals.
* **Strong Typing:** Fully enforces custom numerical/indexing subtypes limiting array allocations and state constraints.
* **Ada 2023 Contracts:** Full suite of `Pre`, `Post`, and `Global` conditions guarantees norm preservation, bound isolation, and execution predictability without requiring debug harnesses.

## Usage
The standalone test executable demonstrates how to initialize, modify, and amplify classical state vectors utilizing Oracles. 

Run the test suite directly utilizing the supplied GNU make setup:
```sh
make test
```

**Expected Output:**
Output prints test suite progression marking `PASS` statuses across exactly 14 operational scenarios covering array bounds, norm preservation, iteration schedules, exceptions, and Oracle handling.

## Testing
The embedded test structure (`tests.adb`) doubles as the execution environment API documentation. It covers:

* **Functional Correctness:** Verifies mathematical behavior against known geometric solutions (e.g., verifying probability shifts in Grover iterations).
* **Edge Cases:** Single element limits, 0 iteration behavior, and 100% initialized probability bypass logic.
* **Error Handling:** Intentionally fails deterministic boundaries invoking Ada exception catching behaviors (e.g., `No_Solution_Error`).
* **Invariants:** Every mutation strictly verifies amplitude bounds and structural normalcy mathematically representing state cohesion natively inside the package boundary.

## Building
**Prerequisites:** GNAT compiler (GCC toolchain mapped to Ada).

* Verified against standard `-gnat2022` settings mapping to modern Ada behavior including preconditions and strong runtime assertion safety.
* Warnings are treated strictly via `-gnatwa`.
