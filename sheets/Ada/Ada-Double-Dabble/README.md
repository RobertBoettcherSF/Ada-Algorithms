# Double Dabble Algorithm in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the **Double Dabble** (also known as shift-and-add-3) algorithm. The algorithm is used to convert binary representations of integers into Binary-Coded Decimal (BCD). 

This package supports both unbounded arrays for arbitrary precision and hardware-optimized data lengths up to 32 bits. 

## Features
In accordance with the variations documented natively in the algorithm's specifications, this codebase implements ALL major variants:
* **Forward Double Dabble:** Converts Binary arrays/integers into BCD arrays (left-shift and add 3).
* **Reverse Double Dabble:** Converts BCD arrays back into Binary arrays/integers (right-shift and subtract 3).
* **Hardware Combinational Logic:** Exposes the atomic `Add_3_Module` representing the logic gates used in physical FPGA/ASIC hardware implementations.
* **Standard Integer Overloads:** Ready-to-use variants for `Unsigned_8`, `Unsigned_16`, and `Unsigned_32`.

## Testing
The test suite (`tests.adb`) is built strictly on Verification and Validation (V&V) principles for mission-critical logic, assuming initially that the code behaves incorrectly. The suite requires the codebase to continuously prove its safety and accuracy.

**What the tests verify:**
1. **Functional Correctness:** Asserts that the core Shift-and-Add-3 (and Reverse Right-Shift-Sub-3) math computes correct digits and safely executes round-trips (`Bit -> BCD -> Bit`).
2. **Error Handling:** Validates that exceptions (`Invalid_Input`, `Conversion_Error`) correctly capture illegal states (e.g. `BCD(N) > 9`) instead of producing silent calculation corruption. 
3. **Edge Cases:** Evaluates absolute extremes, including hardware limits on 8/16/32 bit registers, zero-states, and empty unconstrained array parameters.
4. **Performance Bounds:** Confirms loop conditions correctly terminate and successfully parse max 32-bit sequences (4,294,967,295) with proper dynamic digit-trimming (normalization).

**Why these tests matter:** 
In domains where Ada is prevalent (aerospace, medical), BCD formatting translates directly to display interfaces or system controllers. A corrupt BCD translation sequence represents a critical hazard. The suite mathematically proves reliability by checking that failure states are gracefully aborted.

## Usage

### Compilation
The project requires an Ada compiler (`gnat`). You can compile the program and test executables via the provided Makefile:

```bash
# Compile everything
make all
