# Entropy Encoding Systems (Ada implementation)

## Project Overview
This Ada project implements core theoretical **Entropy Encoding** algorithms used heavily in data compression. Entropy encoding aims to represent data with the minimum number of bits possible based on the frequency (or probability) of symbols. The system supports full analysis pipelines: mapping data arrays to symbol frequencies, generating optimal prefix trees, building encoding dictionaries, and producing binary bitstreams.

## Features
- **Frequency Analysis (`Calculate_Frequencies`)**: Performs string inspection to map character distributions automatically.
- **Huffman Coding Variant**: Bottom-up algorithm utilizing a min-frequency merging approach to build a guaranteed optimal, prefix-free binary tree.
- **Shannon-Fano Coding Variant**: Top-down divide-and-conquer approach that sorts arrays and optimally partitions probabilities.
- **Encoder**: Converts strings into uninterrupted binary string representations ("1001011...") checking constraints dynamically. 
- **Robust Typing**: Custom Ada bounds and specific dictionary data models prevent misuse.
- **Memory Safety**: Manual tree deallocation procedures using `Ada.Unchecked_Deallocation` to ensure zero-leak operations.

## Testing
This project strictly enforces Verification & Validation (V&V) methodologies. The test framework adopts a cynical baseline: *it inherently assumes the code is faulty, and only passes if the software explicitly proves correctness.*

### What each test category verifies:
- **Functional Correctness**: Ensures mathematical logic—such as characters with high frequency getting shorter bit lengths—is strictly enforced. 
- **Error Handling**: Verifies that custom exceptions (`Empty_Input_Error`, `Invalid_Data_Error`) safely trap illegal states (empty maps, unknown payload symbols) instead of propagating system faults.
- **Edge Cases**: Validates functionality on isolated limits—single-symbol alphabets, empty data blocks, and heavily skewed vs. perfectly balanced data sets.
- **Performance/Memory (Integrity)**: Verifies the application dynamically allocates and rapidly de-allocates tree nodes over massive datasets without dropping records.

### Why these tests matter:
In critical infrastructure implementations, encoding engines frequently interface with networking layers and storage protocols. Failures here corrupt system memory or irreparably destroy payload integrity. These tests lock down system state behavior. By designing tests that try to aggressively disprove the stability of the system, a "PASS" definitively asserts specification requirements are functionally sound.

## Usage

### Compilation
The build system relies on standard Ada tools (`gprbuild`) wrapped via `Makefile`. All outputs are properly isolated.

```bash
make build
