# Fibonacci Coding Ada Implementation

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the Fibonacci coding algorithm. Fibonacci coding is a universal code used in data compression and computing which encodes positive integers into self-synchronizing binary words. 

## Features
The package implements ALL variants detailed in the universal encoding methodology:
* **Standard Fibonacci Coding (Order 2):** Follows Zeckendorf's theorem. Maps an integer to a binary string terminating in `"11"` and lacking any `"11"` substrings elsewhere.
* **Generalized Fibonacci Coding (Order N):** Supports Tribonacci (Order 3), Tetranacci (Order 4), etc. Produces a sequence of strings that end with $N$ consecutive 1s (e.g., `"111"`) and contains no prior occurrences of that string.
* Bi-directional capabilities (`Encode` and `Decode`) for all variants.

## Testing
This project integrates stringent **Verification and Validation (V&V)** practices designed for high-integrity systems:

* **Pessimistic Testing Philosophy:** Tests are written assuming the code is broken. A `PASS` rating is only granted when the test explicitly disproves a failure assumption.
* **Functional Correctness:** Verifies mathematical alignment with Zeckendorf's algorithm and lexicographical constraints (e.g., proving `Encode(65)` safely outputs the validated Wikipedia string `"0100100011"`). 
* **Robustness & Error Handling:** Explicit exceptions (`Invalid_Code`) are aggressively tested by feeding the decoders malformed strings, proving the code won't silently corrupt data.
* **Edge Cases:** Includes boundary tests validating exactly matched base Fibonacci integers (like `144`) where bit manipulation mistakes frequently manifest. 
* **Why this matters:** In universal compression and self-synchronizing telemetric data streams, a single unhandled parsing error cascades into fatal synchronization loss. Disproving these test assumptions verifies mission reliability.

## Usage

### Compilation
The codebase strictly relies on the standard Ada runtime. You can compile the project smoothly using the provided Makefile or `gnatmake`.

```bash
make all
# or manually via GNAT
gnatmake -P fibonacci_coding.gpr
