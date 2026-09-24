Project Overview: 
This project provides a robust, native Ada 2023 implementation of the RIPEMD-160 cryptographic hash function. RIPEMD-160 produces a 160-bit (20-byte) message digest and was developed as an open alternative to SHA-1 and MD5. The module covers the fundamental variants and concepts of data scheduling applied to cryptographic data feeds, bridging the gap between single-shot bulk processing and incremental/dynamic chunk streaming.

Features:
- Single-shot hashing variants for simple, one-call bulk processing of Strings and Byte_Arrays.
- Dynamic/Incremental hashing API (Init/Update/Finalize) supporting chunked processing for data streams or massive files.
- Strong typing architecture ensuring absolute safety by preventing bare Integer/Float domain overlaps.
- Integrated runtime bounds tracking mapped to formal Ada Contracts (Pre, Post).
- Native handling of alignment offsets, bounds anomalies, and slice subsets safely.
- Verified test suites against all canonical test vectors spanning permutations, bit paddings, and multi-block buffers.

Usage: 
To test the functionality locally, run:
    make test
This generates and executes the suite in `bin/tests`. Expect terminal output demonstrating 14 separate test routines with PASSED status for chunked buffering, state resets, exception barriers, standard hash vectors (e.g. empty string, 80-byte repeating sequence, 1 million repeated characters). A 100% pass concludes with "42 passed, 0 failed".

Testing: 
The `tests.adb` acts simultaneously as the functional verification suite and the API usage guide. It covers the following key categories required for V&V:
1. Standard Functionality: Direct matching against canonical RIPEMD-160 specifications (Test 1-5, 9, 14).
2. Block boundaries: Validating buffer rotation and padding offsets accurately on block lengths exactly at, below, and above 64-byte/512-bit thresholds (Tests 6-8).
3. Contract Assertions/Exceptions: Affirming state-tracking correctly terminates processing of uninitialized or incorrectly finalized environments (Test 10 & 12).
4. Edge conditions: Validating empty array bounds (10..9) and string slicing to guarantee data structures translate safely regardless of memory alignment index (Test 11 & 13).

Building:
Prerequisites: A standard GNU Ada Toolchain (GNAT).
Requirements: Make and gnatmake. Compatible specifically with the latest Ada ISO Standard 2023 constructs, operating firmly under `-gnatwa` (all warnings treated robustly) and explicit `-gnat2022` formatting directives.
