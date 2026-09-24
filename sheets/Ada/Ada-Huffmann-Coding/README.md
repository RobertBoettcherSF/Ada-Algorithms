# Ada Huffman Coding Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Huffman coding algorithm, a lossless data compression technique. The implementation takes a raw text input, analyzes frequency distributions, constructs a minimal-prefix binary tree, and facilitates compression (encoding) and decompression (decoding). 

## Features
- **Standard (Static) Huffman Coding:** Full support for building the prefix tree, generating optimal character codes, and safely encoding/decoding character data.
- **Canonical Huffman Coding (Variant):** Includes generation of Canonical codes, wherein code lengths are extracted from the standard tree and assigned sequentially. This avoids the necessity of sending the entire tree structure over a network, requiring only length distributions.
- **Adaptive Huffman (Stub Variant):** Includes architectural placeholders highlighting how Vitter/FGK algorithms structurally integrate into the package interface.
- **Strict Memory Management:** Includes recursive `Unchecked_Deallocation` procedures to guarantee no memory leakage during tree destruction.

## Testing

Verification and Validation (V&V) are paramount in critical systems engineering. The provided test suite operates on a pessimistic paradigm: *It assumes the code is broken or improperly handles edge cases.* Tests PASS only when they mathematically disprove this assumption.

**What the tests verify:**
1. **Functional Correctness:** Asserts frequency allocations, tree node summations, prefix property rules, and absolute input/output symmetry (what goes in must exactly match what comes out).
2. **Error Handling:** Intentionally injects bad data (e.g., bitstreams containing '2', prematurely terminating strings) to verify graceful failure via `Data_Error`. 
3. **Edge Cases:** Simulates edge conditions like single-unique-character strings (which mathematically break traditional standard trees) and empty inputs. 
4. **Performance & Memory:** Verifies that sequential deallocation properly sanitizes memory without triggering segmentation faults on null bounds.

**Why these tests matter:** 
In high-integrity domains (such as aerospace or embedded systems where Ada is prevalent), compression must not corrupt data state nor panic ungracefully. Testing validates that the component strictly meets intended use constraints and rejects malformed external data (safety requirements).

## Usage

### Compilation
Ensure you have the GNAT Ada compiler installed. The project does not use a `src` folder; all files reside in the root environment. 

To compile the test executable, use the provided `Makefile`:
```bash
make all
