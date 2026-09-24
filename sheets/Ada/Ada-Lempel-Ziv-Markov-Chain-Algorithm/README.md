# Ada LZMA Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the core Lempel-Ziv-Markov chain algorithm (LZMA). LZMA is renowned for high compression ratios, achieved by combining a sliding-window LZ77 dictionary matching system with a complex, 12-state Markov chain to model probability distributions. This repository abstracts the bit-level range encoder into Tokens to provide a clean, testable representation of the algorithmic logic and state machines.

## Features
- **Strict 12-State Markov Machine**: Implements the exact state transition rules (LIT, MATCH, SHORTREP, LONGREP) defined in the LZMA specification.
- **LZ77 Tokenizer**: Provides a greedy pattern-matching engine that slides over a history dictionary.
- **Bi-directional Engine**: Features both `Compress` and `Decompress` functions utilizing `Token_Array` variants.
- **Property Validation**: Types accurately bounds limits for structural configuration (`Lc`, `Lp`, `Pb`).
- **Memory Safety**: Enforces unconstrained array paradigms over unbounded pointers.

## Testing
This project embraces standard Verification and Validation (V&V) principles for critical systems. 
A pessimistic approach is taken—the code is assumed flawed until the extensive test suite runs.

**What is verified?**
1. **State Transistions (Tests 1-7):** Validates that all Markov transitions comply with algorithmic requirements. Proves that state updates behave correctly regardless of the origin state.
2. **Functional Correctness (Tests 8-11):** Verifies empty-string processing, literal generation, string duplication dictionary usage, and full round-trip encoding/decoding. 
3. **Error Handling & Edge Cases (Tests 12-13):** Supplies corrupted matching references (out-of-bounds distances and zero-length matches) ensuring exceptions (`LZMA_Error`) isolate the failures safely without memory violations.

**Why it matters:**
In critical applications, corrupted data streams pose severe security and stability risks (e.g., buffer overruns). By validating negative paths alongside standard functionality, we ensure safety and correctness per V&V standards.

## Usage

### Compilation
The codebase is structured without a distinct `src` folder as per layout rules. Ensure `gnat` and `make` are installed.
```bash
make all
