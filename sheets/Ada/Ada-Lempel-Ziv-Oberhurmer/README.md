# Lempel–Ziv–Oberhumer (LZO) Compression Library in Ada

A standalone, pure Ada implementation of the **Lempel–Ziv–Oberhumer (LZO)** lossless data compression algorithm family. LZO prioritizes decompression speed over maximum compression ratio, making it an ideal choice for embedded systems, real-time networking protocols (e.g., OpenVPN), file systems (SquashFS), and kernel swap spaces (zram/zswap).

---

## Project Overview

This repository provides a strongly-typed Ada implementation of LZO. It features modular subprograms for each variant of the algorithm, safety bounds checking to guard against buffer overruns, and explicit exception handling for malformed compressed streams.

---

## Features

- **Full Variant Support**:
  - `LZO1`: Standard byte-oriented variant utilizing 12-bit sliding dictionary offsets.
  - `LZO1X`: Industry-standard variant with 16-bit lookback offsets (Linux kernel/zram format).
  - `LZO1Y`: High-ratio variant optimized for larger sequential byte blocks.
  - `LZO1Z`: Modified offset encoding variant with stateful offset recycling (`Last_Offset`).
  - `LZO_RLE`: Hybrid variant featuring a Run-Length Encoding pre-filter for highly uniform byte runs.
- **Strong Typing & Safety**: Custom types (`Byte`, `Byte_Array`, `LZO_Variant`) with range constraints and bounds verification on input/output buffers.
- **Robust Exception Handling**: Custom exceptions (`Corrupt_Input_Error`, `Buffer_Overrun_Error`, `Invalid_Data_Error`).
- **Zero Third-Party Dependencies**: Compiles with standard GNAT Ada compiler suites.

---

## Testing (Verification & Validation)

### V&V Philosophy
Testing follows a **pessimistic Verification & Validation approach**:
1. **Pessimistic Assumption**: The codebase is initially assumed to contain subtle index errors, overrun flaws, or decompression corruption.
2. **Disproval by Assertions**: Tests pass only when assertions prove these pessimistic assumptions false.
3. **Verification**: Assures that the code adheres strictly to LZO token format rules and lossless byte recovery requirements.
4. **Validation**: Assures that the software safely handles edge cases, zero-length streams, boundary offsets, and malicious or corrupt inputs without crashing or leaking memory.

### Test Categories & Coverage (14 Standalone Test Suites)

| Category | Tests | Description & V&V Objective |
| :--- | :--- | :--- |
| **Functional Correctness** | TEST 1, 2, 3, 4, 5 | Verifies lossless roundtrip restoration ($D(C(X)) = X$) across all 5 algorithm variants. |
| **Edge Cases** | TEST 6, 7, 8, 14 | Validates zero-length inputs, single-byte inputs, non-compressible bytes, and arbitrary slice index bounds (`10..25`). |
| **Error Handling & Robustness** | TEST 9, 10 | Verifies proper raising of `Buffer_Overrun_Error` on tiny buffers and `Corrupt_Input_Error` on bad streams. |
| **Unified Dispatch & Utilities** | TEST 11, 12 | Validates polymorphic dispatch by `LZO_Variant` enum and mathematical precision of helper calculations. |
| **Boundary Scaling** | TEST 13 | Verifies sliding window offset calculations across large byte boundaries. |

---

## Usage

### Prerequisites
- GNAT Compiler Toolchain (`gnatmake` or `gprbuild`)
- GNU Make

### Compilation Instructions

To build both the demonstration executable and the test executable:
```bash
make all
