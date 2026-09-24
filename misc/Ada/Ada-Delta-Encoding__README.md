# Delta Encoding Algorithm in Ada

## Project Overview
This repository provides a strict, type-safe Ada implementation of the **Delta Encoding** algorithm. Delta encoding (or delta compression) is a data compression technique that stores or transmits data in the form of differences (deltas) between sequential data rather than complete files. This approach is highly effective in time-series data or sequential blocks with minor variations.

## Features
This package implements ALL primary variants of Delta encoding discussed in computing literature:
*   **Arithmetic Delta Encoding (Simple Differencing):** Calculates numerical sequences using subtraction ($x_i - x_{i-1}$).
*   **Arithmetic Delta Decoding:** Restores numerical sequences using addition.
*   **Logical XOR Delta Encoding:** Calculates deltas using bitwise XOR, frequently used in hardware pipelines and networking protocols where subtraction carries overhead.
*   **Logical XOR Delta Decoding:** Restores byte arrays using inverse XOR operations.
*   **Strong Typing:** Leverages Ada arrays and `Interfaces` library types to strictly differentiate integers from bytes.
*   **Edge Case Handling:** Contains specific routines and exceptions (`Empty_Input_Error`) designed to elegantly handle boundary data.

## Testing
This repository includes a rigorous Verification and Validation (V&V) test suite built into `tests.adb`. By V&V philosophy, the test assumes the code is *broken* under unexpected conditions. A test only achieves a **PASS** when it actively disproves failure assumptions.

### Test Categories
1.  **Functional Correctness:** Verifies normal integer differencing matches calculated expected arrays (e.g. `2,4,6,9,7` -> `2,2,2,3,-2`).
2.  **XOR Variant Functional Verification:** Ensures identical subsequent bytes return $0x00$ and inverse operations return the original sequence. 
3.  **Boundary & Edge Cases:** Tests single-element arrays and ensures logical stability when no "previous" element exists to diff against.
4.  **Error Handling (Negative Asserts):** Deliberately triggers empty array initializations to ensure the codebase intercepts invalid states with `Empty_Input_Error` rather than faulting the system stack.
5.  **Round-Trip Identity Verification (Safety):** Performs a complex encoding operation immediately followed by a decoding operation to ensure $Decode(Encode(x)) = x$. This proves memory bounds and data fidelity are conserved.

*Why these tests matter:* In critical systems processing continuous data streams, an off-by-one error or boundary violation when an array runs empty can cause cascading application crashes. Validating boundaries ensures long-term reliability.

## Usage

### Compilation
Everything is localized to the root directory for ease of access. You can compile the main executable and the tests using `make`:
```bash
make all
