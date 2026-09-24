# Ada Lempel-Ziv-Welch (LZW) Implementation

## Project Overview
This repository contains a robust, highly modular implementation of the Lempel-Ziv-Welch (LZW) lossless data compression algorithm written entirely in Ada. The implementation focuses on strong typing, memory safety, and algorithmic variants derived from historical usage contexts (e.g., TIFF/GIF optimizations). 

## Features
- **Standard LZW Encoding/Decoding:** Dynamic building of sequence dictionaries without transmission overhead.
- **Variant 1 - Dictionary Freezing:** When the dictionary hits its maximum bit-width capacity, the algorithm stops adding new entries and efficiently utilizes the existing subset (often seen in embedded system telemetry).
- **Variant 2 - Dictionary Clearing:** Alternatively, when the dictionary is full, it seamlessly wipes memory and rebuilds from the base alphabet to adapt to new changing data patterns (similar to GIF dynamic encoding rules).
- **Variable Constraints:** Parameterized `Max_Bits` width control (supporting limits from 9 bits up to architecture maximums).
- **Robust Exception Handling:** Strict bounds checking against malicious or corrupted LZW code sequences via `LZW_Error`.

## Testing (Verification & Validation)
This project follows strict **Verification and Validation (V&V)** principles. The philosophy of our test suite assumes the code is faulty until proven correct under stress and edge-case observation. Tests `PASS` only when pessimistic assumptions about the code failing are systematically disproven.

### What the tests verify:
1. **Functional Correctness (Verification):** Ensures compression translates exact dictionary values predictably and strings can be round-tripped losslessly (Tests 1-4).
2. **Algorithm Variant Adherence (Validation):** Simulates dictionary capacity exhaustions to ensure `Freeze` and `Clear` state-machines behave precisely to specification without memory violations or infinite loops (Tests 5-6).
3. **Edge Case Safety:** Evaluates binary-data processing (`0x00`, `0xFF`) and sub-limit threshold scenarios (Test 7).
4. **Error Handling/Fault Tolerance:** Deliberately injects out-of-bounds codes and illegal configurations (like `Max_Bits < 9`) to ensure `LZW_Error` is correctly raised rather than resulting in segmentation faults (Tests 8-9).

### Why these tests matter:
In systems programming, data compression often sits at the I/O boundary. An undetected desynchronization between a compressor and decompressor can cause memory exhaustion or arbitrary code execution. These tests guarantee that our state constraints remain mathematically bound and safe for critical data streams.

## Usage

### Compilation
The codebase uses a standard `Makefile` backed by a GNAT Project file (`.gpr`). 
Everything resides in the root directory. To compile:

```bash
make all
