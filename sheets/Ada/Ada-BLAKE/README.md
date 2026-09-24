Project Overview:
This project provides a complete, strongly-typed Ada 2023 implementation of the BLAKE cryptographic hash function, one of the SHA-3 finalists. It strictly adheres to the specifications described in the Wikipedia article, implementing all core variants including the internal compression function, block processing, message padding, and counter tracking correctly.

Features:
* Implements BLAKE-224 and BLAKE-256 (32-bit word size, 512-bit block size).
* Implements BLAKE-384 and BLAKE-512 (64-bit word size, 1024-bit block size).
* Provides a clean, purely functional API without global state.
* Strong typing using Ada 2023 contracts (Pre, Post, Global) to ensure safe memory access and expected digest lengths.
* Gracefully handles complex message padding boundaries and correctly manages the internal bit-counter logic for final unpadded message length injection.

Usage:
To build and run the test suite, simply run: `make test`.
The test suite doubles as API demonstration and execution framework. Upon executing, you will see output indicating assertions passed for all functional and edge case verifications, ending with a summary like "=== 39 passed, 0 failed ===".

Testing:
The standalone `tests.adb` test suite performs rigorous Verification and Validation. It covers:
* Functional correctness: Checks the length, execution stability, and deterministic nature of the hash outputs.
* Avalanche effect: Ensures single-byte input changes cause massive output shifts (>50% byte disruption), demonstrating collision resistance properties.
* Edge cases: Tests hashing empty inputs, multi-block inputs, and inputs with lengths matching exact padding boundaries that trigger edge-case branching logic in the compression padders.
* Cross-variant properties: Validates cryptographic domain separation by proving that 224/384 hashes are distinct operations governed by specific IVs and not merely raw truncations of unrelated digests.

Building:
Prerequisites include a GNAT Ada compiler supporting Ada 2023 (ISO/IEC 8652:2023). Make sure `gnatmake` is available in your PATH. The project compiles with the highest warning level `-gnatwa` to guarantee zero-warning, semantically robust code.
