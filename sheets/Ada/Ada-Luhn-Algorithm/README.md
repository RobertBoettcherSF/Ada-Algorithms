# Ada Luhn Algorithm Implementation

## Project Overview
This repository contains a robust, strongly typed Ada implementation of the **Luhn Algorithm** (also known as the "modulus 10" or "mod 10" algorithm). Originally created by Hans Peter Luhn, it is widely used to validate identification numbers such as credit card numbers, IMEI numbers, and Canadian Social Insurance Numbers.

## Features
- **Strict Strong Typing:** Uses custom types (`Luhn_Sequence` and `Check_Digit`) to enforce data integrity at compile-time.
- **Payload Validation:** Instantly verify if a complete sequence (payload + check digit) conforms to the mod-10 requirements.
- **Check Digit Calculation:** Automatically calculate the required check digit for a given partial number.
- **Sequence Generation:** Seamlessly append the required check digit to a partial payload to generate a complete, valid number.
- **Whitespace Tolerance:** Safely ignores spacing inside the strings (e.g., `"7992 7398 713"`), making it practical for real-world user inputs.
- **Robust Exception Handling:** Implements `Invalid_Format` for strict rejection of alphabetic and special characters.

## Testing
This project follows strict **Verification and Validation (V&V)** principles. The test suite operates on a "pessimistic assumption" model: we assume the code is fundamentally broken, and the tests only `PASS` when that assumption is provably disproven by the executing code. 

**What the tests verify:**
1. **Functional Correctness (Verification):** Ensures the right-to-left doubling parity alternates correctly for both odd and even string lengths, and that digit-summation strictly follows the $>9 \rightarrow -9$ rule.
2. **Edge Cases:** Proves safe handling of absolute boundary conditions: zero-padded data (`"0000"`), minimal length payloads (single characters), empty strings, and whitespace-only inputs.
3. **Error Handling (Robustness):** Ensures mathematical integrity is never compromised by hidden letters/symbols by verifying that `Invalid_Format` halts execution exactly when needed.

**Why these tests matter:**
In systems validating financial or identifier data, false positives can lead to catastrophic downstream failures. Validation proves that the software meets its intended design behavior without unexpected regressions under stress. Disproving our initial pessimistic assumptions guarantees reliability.

## Usage

### Compilation
The codebase uses a simple Makefile acting as a wrapper for the GNAT build toolchain. To compile the executable:
```bash
make
