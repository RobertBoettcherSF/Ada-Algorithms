# Network Time Protocol (NTP) Intersection Algorithm

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Intersection Algorithm**. Designed as an agreement mechanism for modern time synchronization networks, it estimates accurate time ranges from noisy inputs by isolating valid time sources and actively predicting/identifying "falsetickers" (sources in error).

## Features
- **Intersection Algorithm (NTP Specification)**: Evaluates tuples to identify upper and lower endpoints spanning valid sensor sources, expanding optimally to capture system center points.
- **Marzullo's Algorithm**: Included as the fundamental precursor variant, finding optimal time sub-intervals strictly based on maximal intersections.
- **System Exception Control**: Defends explicitly against mathematically impossible conditions (e.g., negative timeline radii) utilizing custom Exceptions (`Invalid_Data_Error`).

## Testing
The embedded test suite uses **Verification & Validation (V&V)** models specifically aimed at disproving pessimistic runtime assumptions:
- **Functional Correctness Verification**: Asserts that canonical examples (like Wikipedia's NTP illustrations) strictly map to mathematical resolutions despite potential internal rounding. 
- **Error Handling Proofs**: Actively tries to crash the engine through illegal radii input (`Radius < 0`)—validating the system safely triggers custom exceptions rather than fatal segmentation faults.
- **Edge & Boundary Validation**: Tests extreme cases heavily reliant on stability (M=0 arrays, Zero-width intervals, Negative coordinates), proving reliable execution flow without bounds-checks crashing the host thread.
- By starting with the assumption that the code is *functionally broken*, these explicit bounds tests strictly disprove faults, qualifying the package for highly reliable systems where falsetickers are a standard reality.

## Usage

### Compilation
The codebase can be compiled using traditional `gnatmake` through the `Makefile`:
```bash
make all
