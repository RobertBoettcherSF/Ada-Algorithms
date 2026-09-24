# XOR Swap Algorithm Implementation in Ada

## Project Overview
This project provides a robust, strongly-typed implementation of the **XOR Swap Algorithm** in Ada. The algorithm is a bitwise technique used to swap the values of two variables without the use of a temporary variable. Because Ada's standard integer types do not support bitwise operations directly, this project utilizes `Interfaces.Unsigned_32` mapped to a custom `Data_Type` for safe bitwise manipulation.

## Features
- **Standard Preemptive Swap:** A direct `X = X xor Y` swapping method for distinct variables.
- **Safe Element Swap (Aliasing Protected):** Checks for address/index aliasing before swapping. If identical indices are passed, the swap is bypassed, preventing the classic "Zero-Out" vulnerability inherent to the XOR swap.
- **Array Reversal Algorithm:** Demonstrates practical usage of the XOR swap by reversing arrays in place. Safely handles odd-length arrays by leveraging the Safe Swap to protect the median element from zeroing.

## Testing
This project embraces rigorous Verification and Validation (V&V) principles. The testing philosophy is pessimistic: **we assume the code is broken or non-functional, and the tests only PASS when this assumption is explicitly disproven.** 

The test suite consists of 14 assertions categorized as follows:
- **Functional Correctness:** Verifies normal swapping mechanics, ensuring the algorithm fundamentally achieves its goal.
- **Edge Cases:** Tests behaviors against boundary boundaries like `0`, `Data_Type'Last`, empty arrays, and single-element arrays.
- **Vulnerability / Error Handling:** Specifically tests the XOR swap "aliasing" bug (swapping a memory location with itself). The Safe Swap tests prove that the system intercepts the collision and prevents memory corruption (zeroing out).
- **Mathematical Validation:** Confirms the core properties of involution and bitwise identity upon which the system relies.

These tests are crucial for critical systems, as they prove the code behaves deterministically not just under ideal conditions, but also under maximum stress and boundary limits.

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. You can compile the project using the provided `Makefile`. All source code operates directly from the root directory.

```bash
make all
