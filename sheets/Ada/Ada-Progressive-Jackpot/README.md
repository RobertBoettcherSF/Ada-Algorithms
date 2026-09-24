# Progressive Jackpot Model (Ada 2023)

This project is a highly robust, strictly typed Ada 2023 implementation modeling various progressive jackpot architectures found in modern gaming systems. The library supports calculations and state modifications corresponding exactly to standalone progressive terminals, "must-hit-by" mystery architectures, wide area/local area networking systems, and qualifying-bet constraints to manage pool contributions and hits efficiently.

### Features
* Standalone Jackpot: Singular machine mapping increment logic per qualifying bet.
* Mystery "Must-Hit-By" Jackpot: Safely increments pools up to a designated ceiling, forcing a secure internal reset whenever the hit occurs.
* Network & WAN Jackpots: Maps bet batches from arrays across different topologies. Wide Area architectures automatically ingest and extract simulated administrative operating fees.
* Qualifying Bets: Effectively tracks whether a user matches max-coin requirements without halting their statistical contribution to the running pool.

### Usage
Build and test the system utilizing the provided Makefile. The build will output a singular, standalone executable `tests.adb` wrapping all components.
1. Run `make` to compile.
2. Run `make test` to automatically initiate execution.

Expected output logs 48 individual component test criteria covering every public API surface of the `Progressive_Jackpot` spec, ending in `Failed :  0`. 

### Testing 
The 16 individual sub-test suites verify functionality across multiple distinct validation vectors:
* Functional Correctness: Ensures contribution mathematics correctly cascade to pool totals.
* Edge Cases: Handles 0.0 value rates, empty array arrays in network batching logic, and partial bet thresholds accurately without state corruption.
* Error Handling & Invariants: Validates internal safety checks such that no subprogram permits negative bets, negative baseline parameters, or invalid administrator fees that supersede contribution rates directly via defined Exceptions instead of random compilation crashes. 

### Building
The project strictly implements ISO/IEC 8652:2023 (Ada 2022/2023). It leverages modern syntaxes such as `@` (LHS assignment reduction), and private typing for maximal architectural encapsulation. Requires `gnatmake` and standard tools utilizing `-gnat2022` and `-gnatwa` (zero-warning policy enforcement).
