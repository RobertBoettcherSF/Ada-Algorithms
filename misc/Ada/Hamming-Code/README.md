# Ada 2012 Hamming Code Implementation

## Project Overview
This repository provides a generalized, highly-typed Ada 2012 implementation of Hamming error-correcting codes. It implements both standard linear block error correction—using the equation $ 2^m \geq k + m + 1 $—and Extended Hamming codes featuring SECDED (Single Error Correction, Double Error Detection) by establishing an extra overall parity bit. While traditional fixed variants like Hamming(7,4) and Hamming(15,11) are naturally supported, the package intelligently calculates parity dependencies dynamically, supporting data blocks of arbitrary sizes.

## Features
* **Generic Array Size Support:** Automatically determines parity constraints via mathematical Hamming bounds rather than hardcoding static variant sizes.
* **Standard Hamming (Correction):** Procedural and functional encoding/decoding enabling Single Error Correction.
* **Extended SECDED (Detection & Correction):** The `Extended` variant includes absolute block parity ensuring any Double Error is flagged safely, preventing false positive data manipulation.
* **Strict Typing & Contracts:** Fully integrates Ada 2012 `Pre` and `Post` contracts for buffer constraint verification and domain logic accuracy. Does not utilize bare primitive integers where specialized subtypes apply.

## Usage
To test the implementation and see it in action, utilize the provided Makefile:
```sh
make test
