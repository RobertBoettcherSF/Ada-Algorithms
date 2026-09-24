# Tomasulo Algorithm Implementation (Ada)

## Project Overview
This project implements the **Tomasulo Algorithm**, a dynamic hardware instruction scheduling algorithm that allows out-of-order execution in processors while preserving data dependencies. Written in Ada, it emphasizes strong typing and system verification constraints.

## Features
* **Register Renaming**: Eliminates Write-After-Write (WAW) and Write-After-Read (WAR) hazards using a Register Alias Table (RAT).
* **Reservation Stations (RS)**: Buffers for arithmetic logic units to process operands asynchronously as they arrive.
* **Common Data Bus (CDB)**: Broadcasts data dynamically across the pipeline back to dependent reservation stations.
* **Structural & Data Hazard Detection**: Fully stalls on RS saturation or gracefully delays dependent Read-After-Write (RAW) data.
* **Preemptive Variant Included**: Implements an explicit `Flush_Pipeline` command simulating dynamic branch misprediction cleanup.

## Testing
This project integrates stringent **Verification and Validation (V&V)** principles:
* **Verification**: Do we build the algorithm right? Strict testing for standard adherence to latency constraints, RS allocation, and correct mapping of RAT structures.
* **Validation**: Do we build the right algorithm? Safety limits tested against operational hazards, hardware deadlocking, and faulty execution states.

### What Each Category Verifies:
1. **Functional Correctness** (Tests 1, 2, 5, 6): Verifies renaming, instruction issuance, and data propagation over the simulated Common Data Bus. 
2. **Error Handling & Protection** (Test 8): Captures arithmetic faults (like Division by Zero) before propagating system-wide crashes.
3. **Edge Cases** (Tests 11, 13): Handling of empty data arrays, stalling at end-of-program arrays, and aggressive state purging (Preemptive Flush).
4. **Performance Limits & Hazards** (Tests 3, 4, 7, 9, 12): Enforces latency (ADD vs MUL limits), avoids structural hazards, and mitigates RAW, WAW hazards via cyclic delays.

**Why these tests matter:** 
In critical execution contexts (like Ada's traditional aerospace use case), assumptions that pipeline architecture is flawless lead to silent system degradation. Tests act defensively; assuming the algorithm will improperly map state, tests verify failure assertions natively, ensuring fault isolation constraints hold up despite pessimistic assumptions.

## Usage

### Compilation
The codebase is structured strictly in the root directory for ease of testing. Build it using GNU Make:
```bash
make
