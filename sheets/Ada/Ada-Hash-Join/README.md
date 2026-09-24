# Ada Hash Join Implementation

## Project Overview
This repository implements the **Hash Join** algorithm natively in Ada, conforming to strict typing and reliability principles. Hash joins are used extensively in relational database management systems to join two un-indexed datasets based on a common key.

## Features
- **Classic Hash Join:** Standard in-memory algorithm. Builds an internal hash map for the smaller (Build) relation, then sequentially probes using the larger (Probe) relation.
- **Grace Hash Join:** A partitioning algorithm designed to handle datasets larger than memory. Spills disjoint partitions to simulated "disk" space using modular hash arithmetic, then joins bounds individually.
- **Hybrid Hash Join:** An optimization of the Grace variant. Maintains the $0^{th}$ partition strictly in memory during the split phase to reduce disk I/O, dynamically building and probing against it immediately.
- **Support for M:N relationships:** Dynamically handles multiple equivalent keys correctly (Cartesian resolution).
- **Strong Typing:** Distinguishes mathematically between Left Tuples, Right Tuples, Joined Tuples, and safely manages Unbounded Strings and hashed Keys. 

---

## Testing (Verification & Validation)
This codebase assumes all logic is inherently broken and systematically proves reliability through pessimistic testing via `tests.adb`.

**Categories Monitored:**
1. **Functional Correctness (Tests 1-5, 6, 9):**
   * *What it verifies:* That outputs conform strictly to Expected Relational Algebra outputs (Matches occur properly, no false positives, N:M tuples multiply cleanly).
2. **Edge Cases (Tests 2, 3, 7, 11, 13, 14):**
   * *What it verifies:* Negative keys, empty collections, and disproportionately large partition assignments.
3. **Error Handling (Tests 8, 12):**
   * *What it verifies:* Boundary violations trigger proper defensive exceptions (e.g., partitioning datasets into 0 blocks reliably raises `Invalid_Partition_Count`).
4. **Performance Logic (Test 10):**
   * *What it verifies:* The memory optimization track for Hybrid partition 0 operates functionally and distinctly from disk paths.

**Why these tests matter:** 
In critical and data-intensive systems, silent failures (like losing tuples during a Grace boundary partition or mishandling negative memory addresses in Hash modular arithmetic) propagate system collapse. Our tests actively attempt to throw standard `Constraint_Error` bounds, verifying that native implementations meet exact V&V standards. 

## Usage

### Structure
All implementation code exists strictly in the root directory to simplify pipeline management. 

### Compilation
The codebase leverages GNAT (GNU NYU Ada Translator). 
To compile the test executable, simply run:
```bash
make
