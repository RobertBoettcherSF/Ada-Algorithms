# LZWL Syllable-Based Data Compression Toolkit (Ada)

## Project Overview
This repository provides a fully typed, critical-system-ready Ada implementation of the LZWL algorithm. LZWL operates strictly as a syllable-based variant of the Lempel-Ziv-Welch (LZW) data compression protocol, utilizing discrete strings/syllables rather than static individual characters. It is uniquely engineered for datasets comprising a closed set of recurring words or prefixes.

## Features
* **Strong Typing**: Exclusively enforces `Code_Array` and `Syllable_Array` types to eliminate primitive assignment corruption.
* **Variant 1 (Syllable-based Adaptation)**: Implements standard LZWL dictionary appending (syllables encoded recursively as sequences).
* **Variant 2 (Dictionary Expansion)**: Mitigates single-occurrence syllables from diluting processing efficiency by selectively concatenating sub-syllable strings dynamically according to LZWL specifications.
* **Memory Constrained Operation**: Bounded constraint validation prevents unchecked slice overrides inherently protecting bounds.

## Testing (Verification & Validation Strategy)
Our V&V suite revolves around **Pessimistic Defense Testing**. Every assertion mathematically assumes an internal failure (such as dict corruption or memory violation), passing ONLY when the algorithm proves that assumption false safely.

**What Test Categories Verify & Why:**
1. **Functional Correctness (Tests 3, 4, 8, 10):** Validates deterministic operation. It's critical for LZW variants that dictionary synchronization matches byte-for-byte; otherwise, downstream decoding acts as random corruption.
2. **Error Handling & Robustness (Tests 5, 6):** Validates the system's defenses against injected, corrupted, or unsanctioned syllables. This ensures system uptime reliability and fault containment.
3. **Safety Boundaries (Tests 1, 2, 11, 12):** Validates boundary condition checking (e.g., zero-length streams or micro-buffers). Prevents Buffer Overflows completely (Critical standard metric for secure systems).
4. **Performance Validity (Test 7):** Validates that redundancy in arrays translates natively into fewer code expressions. 
5. **Edge Cases (Test 13 - kwkwk scenario):** Disproves the assumption that reading dictionary variables defined on the immediately preceding frame crashes out processing.

## Usage
### Compilation 
Everything compiles directly in the root directory via the unified Makefile wrapper utilizing `gnatmake`.

```bash
make
