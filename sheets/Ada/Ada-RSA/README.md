# Ada 2023 RSA Cryptosystem

Project Overview: This is a robust, complete implementation of the RSA cryptosystem utilizing Ada 2023's `Ada.Numerics.Big_Numbers.Big_Integers` package. It implements mathematical prime-based generation, safe key extraction (using Carmichael's totient function and the extended Euclidean algorithm), textbook encryption/decryption routines, digital signing/verifying functions, and a secure RSA Blinding variant developed to defeat timing attacks as outlined on Wikipedia. 

Features:
* Complete "Textbook RSA" End-to-End: Implements strict key generation, robust encryption, precise decryption, and secure signing/verification methodologies.
* RSA Blinding Variant: Employs a random unblinding factor during exponentiation ensuring uniform compute time to eliminate cryptographic timing leaks.
* Unbounded Precision: Built firmly upon Ada 2022/2023 Big_Integers, fully supporting massive number lengths inherently required by real-world cryptographic keys.
* High Integrity Contracts: Features robust Pre and Post annotations across mathematical domains preventing modulus overreach, zero boundaries, and strict non-coprime failures.

Usage:
Compile and execute the bundled test suite which demonstrates end-to-end functionality acting as the main run sequence. 
Expect clean output detailing checks across bounds:
Expected output summarizes passing assertions (e.g., `PASS — 8.1 Encryption matches Wikipedia exact example` ... `=== 40 passed, 0 failed ===`). 

Testing:
Verification checks 13 thorough test categories covering the complete Wikipedia protocol boundaries. Coverage validates underlying modular mathematics (Exponentiation, Mod Inverse, Extended GCD, LCM). Edge cases vigorously vet fixed limits (Zero, One, N-1 inputs) and assert boundaries dynamically testing the message limits `(M >= N)`. Negative testing ensures forged signatures instantly fail and incorrect non-coprime key parameters abort flawlessly ensuring robust error prevention.

Building: 
* Prerequisites: GNAT compiler compatible with Ada 2022/2023 syntax. 
* Command Line Run: Utilizes GNU Make targeting `tests.adb` directly avoiding boilerplate dependencies, strictly adhering to the ISO/IEC 8652:2023 specification.
