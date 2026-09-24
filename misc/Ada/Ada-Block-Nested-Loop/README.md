# Block Nested Loop (BNL) Join Algorithm

## Project Overview
This project implements the Block Nested Loop Join algorithm in Ada 2012. BNL is a robust relational database algorithm used to join two relations. By reading an entire "block" (or chunk) of the outer relation into memory before scanning the inner relation, the algorithm drastically minimizes the I/O costs of repeated reads compared to a naive tuple-by-tuple nested loop.

## Features
* **Nested_Loop_Join:** The baseline standard naive algorithm (Block Size conceptually = 1).
* **Block_Nested_Loop_Join:** Processes the outer table in definable batches (`Block_Size`) while keeping scanning logic efficient.
* **Strong Typing:** Implementation utilizes strict custom types (`Key_Type`, `Data_Type`) guaranteeing data validity and relational logic at compile time.
* **Automatic Scaling:** Gracefully handles dynamic arrays, automatically calculating and mapping block offsets against array boundaries.

## Testing
This codebase is shipped with a comprehensive Verification & Validation (V&V) test suite assuming the codebase defaults to non-functional, leveraging 14 standalone assertions to prove operational correctness.

### What the tests verify:
1. **Functional Correctness (Tests 1-2, 6, 8, 10):** Ensures the standard join and blocked joins produce mathematically identical sets regardless of block sizing.
2. **Edge Cases (Tests 3-5, 7, 9):** Ensures disjoint arrays, empty arrays, and aggressively large block configurations are computed safely without memory boundary faults.
3. **Data Integrity (Tests 11-12):** Validates outer and inner relation duplication behaviors (acting identically to SQL `JOIN` cartesian expansion logic).
4. **Error Handling (Tests 13-14):** Verifies deterministic failsafes (raising `Invalid_Block_Size`) against physically impossible memory configurations (like zero/negative page frames).

### Why these tests matter:
In critical systems and database logic, unexpected edge cases (like zero-length relations or miss-matched page sizes) can lead to infinite loops or memory boundary overflow (`Constraint_Error`). These V&V tests provide mathematical confidence that the implementation perfectly bounds memory scans regardless of external inputs, meeting strict reliability standards. 

## Usage
### Compilation
The project utilizes `gprbuild` alongside a unified Makefile. Run the following command from the root directory:
```bash
make all
