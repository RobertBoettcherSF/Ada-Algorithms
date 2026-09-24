# Marzullo's Algorithm Implementation in Ada

## Project Overview
This repository contains an Ada implementation of **Marzullo's Algorithm**, an agreement algorithm traditionally used in distributed systems (like NTP) to select an optimal, accurate time interval from a set of noisy, overlapping time intervals. The algorithm finds the interval that intersects the highest number of provided source intervals.

## Features
- **Basic Marzullo's Algorithm**: Efficiently calculates the single optimal interval of maximum intersection.
- **Extended Marzullo's Algorithm**: Handles disjointed data sources by returning an array of *all* optimal interval peaks if a tie for maximum intersections exists.
- **Strong Typing**: Implements specific records (`Time_Interval`) and floating-point logic (`Time_Point`) strictly to capture continuous times safely.
- **Memory/Fault Safe**: Protected by explicit boundaries. Includes raised exceptions for invalid data configurations (e.g., boundaries going backwards in time) or empty inputs.

## Testing
This project embraces rigorous Verification and Validation (V&V) principles required for mission-critical and systems programming environments. 

The embedded test suite operates on a "guilty until proven innocent" assumption—assuming the code is broken and demanding proof of edge-case compliance before tests yield a `PASS`. 

### What The Test Categories Verify
- **Functional Correctness (Tests 1-4, 9, 13):** Verifies the fundamental algorithm logic matches the Wikipedia specification correctly incrementing overlapping tuples. 
- **Error & Exception Handling (Tests 5-6):** Ensures the system fails gracefully (`Empty_Input_Error`, `Invalid_Interval_Error`) preventing uncontrolled behavior in edge conditions.
- **Edge Cases (Tests 7, 8, 12):** Validates reliability outside standard parameters—verifying behavior against zero-length point-intervals, negative coordinate mapping, and solitary array inputs.
- **Performance & Constraints (Tests 10, 11):** Assesses the Extended version's capacity safety, guaranteeing no out-of-bounds memory writes occur even if input peaks exceed reserved output buffers.

### Why these tests matter
Through comprehensive V&V, this suite proves algorithmic reliability for temporal calculations where a fault could desynchronize a distributed network.

## Usage

### Compilation Instructions
The software relies on the GNAT compiler. From the root directory, simply run:
```bash
make all
