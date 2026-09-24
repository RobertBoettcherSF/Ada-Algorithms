# Ada Deflate Algorithm Implementation

## Project Overview
This repository contains a clean-room, robust Ada implementation of the core concepts of the **Deflate** lossless data compression algorithm (RFC 1951). Deflate is widely used in ZIP, GZIP, and PNG files. The implementation models the core components of the algorithm, combining LZ77 sliding-window dictionary matching with block-type architectural routing (Stored, Static Huffman, and Dynamic Huffman trees).

## Features
- **Strong Typing**: Uses `Ada.Streams.Stream_Element_Array` and custom records (`Token`, `Compression_Variant`) ensuring memory and type safety at compile time.
- **LZ77 Encoding**: Includes a functional sliding window match-finder that adheres to Deflate limits (Match caps at length 258, Distance caps at 32KB).
- **Variant 1: Stored Blocks**: Fully functional encoding and decoding for uncompressed blocks (respecting the 65,535-byte limit and exact header bit constraints).
- **Variant 2: Static Huffman Blocks**: Implementation framework routing LZ77 tokens to static bit-patterns.
- **Variant 3: Dynamic Huffman Blocks**: Implementation framework for generating optimal trees based on block data frequencies.

## Testing
This repository heavily emphasizes **Verification and Validation (V&V)** principles critical for safety and reliability in Ada systems. The testing suite operates on a "guilty until proven innocent" philosophy—it tests pessimistic assumptions (e.g., that bounds will be breached, inputs mishandled) and PASSES when the code proves these assumptions false.

### What the Tests Verify
- **Functional Correctness**: Validates that LZ77 accurately detects token repeats (`TEST 6`), length bounds (`TEST 12`), and correct byte sequences for Stored block headers (`TEST 3`, `TEST 10`).
- **Error Handling**: Confirms that undersized buffers (`TEST 4`) and corrupt or unsupported datastreams (`TEST 14`) immediately trigger trapped exceptions (`Buffer_Overflow`, `Deflate_Error`), preventing memory leaks or segmentation faults.
- **Edge Cases**: Empty input arrays into both compressor and decompressor (`TEST 1`, `TEST 2`) ensure zero-length logic is properly gated without raising array out-of-bounds exceptions. Data boundaries like maximum match lengths (`TEST 12`) and massive stored blocks (`TEST 13`) are heavily verified.

### Why these Tests Matter
For critical systems handling unverified incoming data streams, memory vulnerabilities (buffer overflows, off-by-one errors) are common vectors for crashes and security breaches. Testing absolute bounds mathematically proves the integrity of the byte manipulation routines. By aggressively asserting edge-case assumptions, we guarantee that the software behaves deterministically under standard constraints and fails safely when external constraints are violated.

## Usage

### Compilation Instructions
The project contains no sub-directories for source files, maximizing compatibility. To compile:
```bash
make
