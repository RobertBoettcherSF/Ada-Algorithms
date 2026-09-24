# Parity Bit Algorithm Implementation in Ada

## Project Overview
This repository contains a robust, defensively-programmed Ada implementation of the Parity Bit error-detecting code algorithm. A parity bit is a single bit added to a string of binary data to ensure the total number of 1-bits is either even or odd. It represents one of the simplest forms of error-detecting code, frequently used in serial communication and basic memory hardware.

## Features
Implemented with strong typing (`Bit` and `Bit_Array`), this software successfully implements all primary Parity Bit variants described on Wikipedia:
* **Even Parity:** Evaluates payload to ensure the total count of 1s (plus parity bit) is an even number.
* **Odd Parity:** Evaluates payload to ensure the total count of 1s (plus parity bit) is an odd number.
* **Mark Parity:** The parity bit is fixed to 1 (used in serial protocols for framing/stop bit testing).
* **Space Parity:** The parity bit is fixed to 0.

It includes three primary utilities per variant:
1. `Calculate_Parity`: Returns the expected parity bit for a payload.
2. `Add_Parity`: Generates a new framed transmission by appending the correct parity bit.
3. `Check_Parity`: Validates incoming data containing a payload and a parity bit.

## Testing
This project embraces a strict Verification and Validation (V&V) philosophy. The tests in `tests.adb` operate under the initial assumption that the code is *incorrect*. When a test outputs **PASS**, it means the failure assumption has been mathematically or logically disproven. 

### What The Tests Verify
* **Functional Correctness (Tests 1-9):** Validates that Even, Odd, Mark, and Space logic accurately matches their mathematical specifications. Confirms proper framing mechanics (data appending).
* **Error Handling (Tests 10-12):** Verifies the system actively refuses to compute impossible configurations (e.g., zero-length payloads, or frames too small to hold both data and parity). This proves robust isolation of system panic triggers.
* **Edge Cases (Tests 13-14):** Tests single-bit bounds and non-standard array indices (e.g., starting at array index 100 rather than 1) to ensure the logic relies on dynamic bounds (`'First` / `'Last`) rather than hardcoded assumptions.

### Why These Tests Matter
In critical systems (aerospace, medical, high-reliability embedded systems), undetected memory or transmission mutations cause catastrophic failure. By heavily testing bounds, indexes, and fault-injection (invalid frames), we ensure this implementation safely flags errors without crashing the broader system environment.

## Usage
### Compilation
The codebase can be compiled using either the GNAT project file or the included Makefile.

Using `make`:
```bash
make all
