# Berkeley Clock Synchronization Algorithm

## Project Overview
This repository provides a robust, strongly-typed Ada implementation of the **Berkeley Algorithm**, a deterministic method for synchronizing clocks in distributed systems. Unlike algorithms where the master broadcasts its time, the Berkeley algorithm calculates an average time based on slave polling and issues *offsets* to prevent further network-latency drift. 

## Features
- **Standard Variant:** Averages all clock times to achieve a unified system time.
- **Fault-Tolerant Variant:** Incorporates bounds-checking to ignore faulty nodes (outliers) whose reported times exceed a maximum safe tolerance compared to the Master.
- **RTT Compensation:** Automatically estimates the true time of a node upon arrival by accounting for `Round_Trip_Time / 2`.
- **Strong Typing:** Leverages Ada types (`Time_Value`, `Time_Offset`, `Node_ID`) to prevent erroneous cross-assignment of system states.
- **Overflow Protection:** Handles large time-deltas natively using 64-bit bounds (`Long_Long_Integer`).

## Testing

This project employs rigorous Validation and Verification (V&V) methodologies to ensure safe behavior in distributed systems. Tests operate on the pessimistic assumption that the code is non-functional; passing a test successfully disproves this assumption for that specific assertion.

### Test Categories
1. **Functional Correctness (Tests 2, 3, 4, 11):** Verifies the core mathematical averaging and latency (RTT/2) calculations meet the strict requirements of the standard algorithm.
2. **Error Handling (Tests 5, 9):** Ensures that mathematically impossible inputs (like negative Round-Trip Times) are caught cleanly with an `Invalid_Data_Error` exception rather than silently corrupting system time.
3. **Edge Cases (Tests 1, 8, 10, 12):** Tests logical bounds, including empty node networks (0 slaves), exact boundary matches for Max Tolerances, 0-time masters, and massive timestamps representing high uptimes.
4. **Resilience & Validation (Tests 6, 7, 13):** Proves the Fault-Tolerant variant safely protects the master clock against extreme outliers, highlighting why the Standard variant is vulnerable in unstable networks.

Why do these tests matter? In distributed critical systems (e.g., aerospace, banking), a time delta of a few milliseconds can invalidate a transaction or sensor reading. Validating these boundaries guarantees deterministic system integrity.

## Usage

### Compilation
The project utilizes `gprbuild` mapped through a standard `Makefile`. To compile the project:
```bash
make all
