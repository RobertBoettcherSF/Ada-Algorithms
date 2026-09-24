# Adaptive Huffman Coding

## Project Overview
This repository provides a robust Ada implementation of the Adaptive Huffman Coding algorithm. It operates dynamically, allowing the compression tree to be built on-the-fly as symbols are transmitted, without requiring prior knowledge of the source's frequency distribution. The solution supports both encoding and decoding natively.

## Features
- **Adaptive Encoding and Decoding**: Stream-based adaptation requiring no pre-shared frequency dictionary.
- **FGK Algorithm**: Implementation of the Faller-Gallager-Knuth dynamic Huffman tree updates.
- **Vitter Algorithm**: Implementation of Vitter's variation which maintains strict leaf-precedence implicit numbering to continuously minimize tree depth.
- **Strong Typing**: Built in Ada leveraging precise constraints, bounded types, and enumerated variants to isolate data strictly.
- **Graceful Error Handling**: Actively guards against memory leaks/infinite loops by gracefully returning exceptions on invalid or corrupted bitstreams.

## Testing
The repository employs a pessimistic testing philosophy based on strict Verification & Validation (V&V) standards. We inherently assume the codebase fails under edge conditions. The tests only PASS when they empirically disprove this assumption on every run. 

### What Each Test Category Verifies
- **Functional Correctness (Tests 1-4)**: Ensures encoding properly translates plaintext into bitstrings and correctly decodes back to the original text without fidelity loss, validating algorithmic state tracking.
- **Edge Cases (Tests 5.1 - 5.2)**: Verifies the pipeline survives pathologically empty bounds without throwing null pointer exceptions.
- **Error Handling (Tests 5.3 - 5.4)**: Feeds deliberately truncated, garbled, or undefined bit sequences directly to the engine to confirm `Invalid_Bit_Stream` acts as a fail-safe against infinite buffer polling loops.
- **Performance (Test 5.5)**: Verifies full continuous capability against the complete ASCII spectrum (chars 0-255), asserting node-depth structures process optimally without exceeding typical stack sizes.

### Why These Tests Matter
In critical systems, algorithmic flaws in decompression trees inevitably lead to buffer overflows or denial-of-service hangs. By aligning tests directly with V&V standards, we systematically confirm that the system isolates bad data safely and reliably, delivering on exactly what the algorithm specifications promise. 

## Usage
Ensure you have the GNAT Ada compiler installed. All code resides in the root directory (no `src` structures), meaning configuration targets immediately against relative paths.

### Compilation
Compile the project safely using `make` or `gnatmake`:
```bash
# Using Make (preferred wrapper)
make

# Or using GNAT directly
gnatmake -P adaptive_huffman.gpr
