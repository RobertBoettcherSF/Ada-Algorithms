Project Overview: 
This project provides an Ada 2023 (ISO/IEC 8652:2023) implementation of Cryptographically Secure Pseudo-Random Number Generator (CSPRNG) designs based on the concepts detailed in the Wikipedia article. The package contains a polymorphic, strongly-typed architecture featuring three distinct generator variants: a stream cipher-based generator using ChaCha20, a number-theoretic generator using Blum Blum Shub (BBS), and an implementation of the historically significant (but now broken) RC4 stream cipher to demonstrate comparative algorithm design as mentioned in the literature.

Features:
* Abstract Root Type: `Abstract_Csprng` enforces a unified `Generate` API and checks initialization states securely via class-wide preconditions.
* ChaCha20 Variant: Implements modern cryptographic primitive design, utilizing a 32-byte key, 8-byte nonce, and producing buffered deterministic byte blocks.
* Blum Blum Shub Variant: Provably secure number-theoretic design, verifying preconditions (P mod 4 = 3, Q mod 4 = 3) and calculating bits via modular arithmetic.
* RC4 Variant: Historical reference cipher design, included for complete demonstration of the Wikipedia article's noted architectures, operating over a permuted 256-byte state.
* Built-in Contracts: Heavy usage of Ada 2022/2023 `Pre`, `Post`, and `Pre'Class` checks alongside `pragma Assertion_Policy` for strict correctness guarantees.

Usage: 
To build and execute the demonstration test suite, run the command `make test`. The suite will output a continuous log of PASS/FAIL metrics for each functional correctness check. Expect all 13 tests encompassing 39+ assertions to pass seamlessly, concluding with "0 failed".

Testing: 
Testing includes basic determinism (generating identical byte sequences from identical seeds), buffer boundary crossings, polymorphic object-oriented dispatch, and invalid precondition handling (such as invalid primes in BBS, empty keys in RC4, or unseeded initializations). These confirm the strong typing, boundary limits, and mathematical correctness mandated for rigorous software validation.

Building:
Ensure you have the GNAT compiler installed (GCC with Ada support). The Makefile is configured to compile against the Ada 2022/2023 standard (`-gnat2022`) using strict warnings (`-gnatwa`). Running `make all` builds the `tests` binary in the `bin/` directory, while `make clean` safely wipes the artifacts.
