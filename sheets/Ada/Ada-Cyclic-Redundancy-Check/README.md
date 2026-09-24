# Cyclic Redundancy Check (CRC) in Ada

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Cyclic Redundancy Check (CRC) error-detecting code algorithm. As outlined on Wikipedia, CRC implementations vary heavily across ecosystems. This package serves as a universal CRC builder by decoupling the algorithm from its configuration parameters, allowing users to define industry standards (e.g., CRC-32 Ethernet, BZIP2) natively.

## Features
- **Algorithm Variants:**
  - **Bit-by-Bit Calculation:** Emulates hardware shift registers (low memory, slower).
  - **Table-Driven Calculation:** Byte-by-byte processing utilizing precomputed 256-entry lookup tables (higher memory, incredibly fast).
- **Polynomial Formats:**
  - **Normal:** Shifting Left (MSB first processing).
  - **Reversed:** Shifting Right (LSB first processing).
- **Helper Utilities:** Included bit-reflection (`Reflect_8`, `Reflect_32`) and Table Generation routines.
- **Configurability:** Fully customizable Polys, Initial Values, and Xor_Out values via a unified `CRC_Config` record.

## Testing (Verification & Validation Focus)
In safety-critical development environments, code is assumed guilty (non-functional, vulnerable, or incorrectly translating requirements) until proven innocent via Verification & Validation (V&V). This suite employs a pessimistic baseline, explicitly disproving faults.

- **Functional Correctness:** Tests compare algorithm outputs of a known data string (`"123456789"`) directly against hardcoded, industry-standard expectations (`0xFC891918` for BZIP2, `0xCBF43926` for Ethernet). This proves the bitwise math matches real-world specifications.
- **Variant Equivalence:** We execute asserts that mathematically guarantee Table-Driven results are 100% equivalent to Bit-by-Bit outputs across thousands of permutations.
- **Edge Cases & Error Handling:** Validating empty buffers (0-length arrays) and single-byte edge limits ensures no out-of-bounds exceptions or underflow errors crash the system. 
- **Reliability Importance:** For communication protocols and firmware, a faulty CRC implies corrupted data is deemed valid. Strict testing prevents silent corruption in the communication layer.

## Usage
### Compilation
The codebase can be compiled dynamically using `gnatmake` via the GNAT project file or GNU Make.
```bash
make all
# Alternatively: gnatmake -P crc.gpr
