# CHS Conversion Algorithm

## Project Overview
This project provides a robust, strongly-typed implementation of the **Cylinder-Head-Sector (CHS) conversion algorithm** in Ada. CHS addressing was an early method used to assign addresses to blocks of data on hard disk drives. As logical systems outgrew physical layouts, Logical Block Addressing (LBA) was created. 

This repository implements bidirectional mathematical conversions bridging LBA and CHS addressing schemes.

## Features
- **LBA to CHS Conversion**: Maps a 0-indexed logical block to a physical Cylinder, Head, and Sector combination.
- **CHS to LBA Conversion**: Aggregates a physical Cylinder, Head, and Sector tuple into an exact Logical Block Address.
- **Disk Geometry Abstraction**: Custom data types mapping full physical geometry limits (`C_Total`, `H_Total`, `S_Total`).
- **Preemptive Bounds Checking**: Automatically identifies out-of-bounds calculations, 0-indexed/1-indexed errors, and zero-value geometries.

## Testing
This project follows strict Verification and Validation (V&V) principles tailored for critical systems. 

Our testing philosophy assumes the code is **incorrect or non-functional** by default. Tests only output a "PASS" when they successfully disprove this assumption, proving the code meets reliability standards.

### Test Categories
1. **Functional Correctness (Tests 1-6)**: Validates that normal calculations for physical/logical endpoints behave accurately per the mathematical formulas defined on Wikipedia. Tests evaluate sector 0 endpoints, disk midpoints, and maximal block limits.
2. **Robustness & Data Integrity (Test 6)**: Employs round-trip calculations (`LBA -> CHS -> LBA`) to verify lossless 1:1 conversions with zero state mutations.
3. **Error Handling (Tests 7-8)**: Verifies that passing invalid disk geometries (e.g., zero heads or sectors) raises a highly specific `Invalid_Geometry` exception rather than triggering a low-level constraint/division error. 
4. **Edge Cases & Out-of-Bounds Handling (Tests 9-14)**: Guards against logic errors in boundary handling (e.g., trying to access sector 0, which is invalid since sectors are strictly 1-indexed), preventing out-of-bounds exceptions that could compromise hardware integrity.

*Why these tests matter:* In hardware-level computations, a single boundary error (like division by zero or off-by-one errors mapping incorrect sectors) can result in critical data corruption or physical hardware faults. These tests enforce mathematical safety properties independent of the specific drive geometry used.

## Usage

### Compilation
The project requires `gnatmake` (standard in the GNAT toolchain). From the root of the repository, execute:
```bash
make all
