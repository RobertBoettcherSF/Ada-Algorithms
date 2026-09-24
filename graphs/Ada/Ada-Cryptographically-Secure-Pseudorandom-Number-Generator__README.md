Project Overview:
This repository contains a robust Ada 2023 implementation of a Cryptographically Secure Pseudorandom Number Generator (CSPRNG) package. It includes two distinct variants common in CSPRNG design as per the literature: a high-speed Stream Cipher based generator using the ChaCha20 algorithm, and a Number-Theoretic generator utilizing the Blum Blum Shub (BBS) algorithm. These algorithms enforce security by relying on deterministic cryptographic primitives and the mathematical hardness of integer factorization respectively.

Features:
* Stream Cipher CSPRNG (ChaCha20): Highly optimized stream cipher, block-based keystream generation, state isolation, and support for on-demand reseeding without state compromise.
* Number-Theoretic CSPRNG (Blum Blum Shub): Strict theoretical implementation relying on the quadratic residuosity problem, including parameter validation for primes congruent to 3 mod 4, and coprimality seed validation.
* Robust Typing: Strong custom domain types ensure word sizes (Byte, Word, Long_Word) remain strictly bound to their hardware-level mathematical profiles.
* Contract-Based Engineering: Leveraging Ada 2022/2023 Pre, Post, and Global aspects to ensure subprograms do not trigger unseen side effects.
* Zero Warnings: Compiled cleanly with strict `gnatwa` flag enforced, removing unreachable/unused ambiguities.

Usage:
The provided `tests.adb` test suite acts as both the verification system and the definitive usage example.
To run the system, simply execute:
$ make test
Expected Output: A sequence of test logs verifying correct algorithmic output, testing boundary conditions, raising expected exceptions, and yielding a finalized pass rate output (e.g., "===  39 passed,  0 failed ===").

Testing:
Verification handles functional correctness (comparing deterministic output), boundary cases (buffer lengths spanning multiple generated cryptographic blocks vs. empty buffers), and explicit error handling via raised exceptions for unsafe mathematical parameters (invalid primes, seeds with shared factors). These assure the cryptographic state machine correctly transitions dynamically.

Building:
Requirements: GNAT Toolchain configured for Ada 2022/2023 capabilities (`-gnat2022`).
Execute `make all` to build the standalone binary into the `bin/` directory.
