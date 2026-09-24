# Advanced Encryption Standard (AES) - Ada 2023

## Project Overview
This repository contains a full Ada 2023 implementation of the Advanced Encryption Standard (AES), based on FIPS 197 and mathematically identical to the algorithms described in its Wikipedia article (https://en.wikipedia.org/wiki/Advanced_Encryption_Standard). It relies strictly on finite field arithmetic (Galois Field 2^8) to algorithmically compute its tables at package elaboration, meaning there are no hundreds of magic numbers hardcoded in the codebase for S-Boxes or Rcon tables.

## Features
- All AES Key Sizes: Full support for AES-128, AES-192, and AES-256.
- Zero Magic Numbers: S-Box, Inverse S-Box, and Rcon constants are rigorously calculated through dynamic algebraic transformations at program initialization.
- Strongly Typed Domains: Extensive use of strict static types (Block, Key_128, etc.) ensures length-safety.
- Multi-Block Extensions: Out-of-the-box support for multiple blocks via an ECB wrapper function handling unbound variable length Arrays (Byte_Array).
- Ada 2023 Contracts: Protected execution flows backed by Pre conditions and strict explicit Global => null contract configurations to enforce state safety.

## Usage
The standalone usage suite is bound directly into tests.adb. A main.adb is not required, as the test runner evaluates and effectively executes all public-facing variants of the AES package interface.

To build and run, execute:
make test

Expected Output:
You should see output describing the 13 comprehensive structural tests evaluating standard FIPS 197 inputs, decryption roundtripping, zero-state behaviors, overflow safeguards, and algorithmic avalanche evaluations, culminating in:
===  39 passed,  0 failed ===

## Testing
The test suite spans robust verification mechanisms covering the following categories:
- Functional Correctness: Exact comparisons against NIST FIPS-197 standard test vectors directly from Appendices B and C for all three AES sizes.
- Edge Cases: Validation of behavior when empty (0-length) buffers are provided to variable length ECB processing subprograms.
- Error Handling: Safe rejection (with specific exceptions named) when provided improperly-padded sizes or undersized output buffers.
- Invariants / Properties: Validation of the non-linear "Avalanche Effect", enforcing that a single altered bit fundamentally morphs the ciphertext layout.

## Building
Prerequisites: GNAT Toolchain (tested with GNAT Community / GCC 12+)
This project leverages the native gnatmake integration and is structured utilizing Ada 2022/2023 dialect parameters (-gnat2022).
