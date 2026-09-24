# Hash Functions Library in Ada

## Project Overview
This repository provides a strictly typed, robust Ada implementation of various Hash Function algorithms as described in computer science literature (e.g., Wikipedia's Hash Functions). Hash functions map data of arbitrary size to fixed-size values. This library guarantees type safety, mathematical bounds-checking, and strong encapsulation.

## Features
The `Hash_Functions` package implements the following variants:
1. **Identity Hash**: Trivial mapping (maps a small unique integer to itself).
2. **Division Hash (Modulo)**: Constrains an integer into a specific bin range with zero-division safety.
3. **Mid-Square Hash**: Non-linear integer hashing utilizing 64-bit mathematical intermediate spaces to prevent overflow.
4. **DJB2 Hash**: Extremely fast and widely utilized string hashing by Dan Bernstein.
5. **FNV-1a Hash**: Fowler–Noll–Vo algorithm optimized for avalanche characteristics on strings/bytes.
6. **Pearson Hash**: Strictly 8-bit hash function relying on a 256-byte permutation table, perfect for microcontrollers.
7. **Folding Hash**: Divides string data into sequential 32-bit chunks, mathematically folding them into a unified hash.

## Testing
This project strictly follows software Verification and Validation (V&V) principles:
* **Verification (Does it match the math?):** Tests assert that constants (e.g., offset basis strings, primes, initialization vectors) strictly match algorithm specifications.
* **Validation (Does it meet intended use?):** Tests assert that edge cases (like zero inputs, empty strings) process cleanly rather than crashing the runtime.

### What the test categories verify:
* **Functional Correctness:** Verifies basic algorithm arithmetic (e.g., Modulo division accurately mapping ranges).
* **Error Handling:** Validates that division by zero gracefully surfaces custom exceptions (`Hash_Error`) instead of raw OS runtime faults.
* **Edge Cases:** Proves that algorithms relying on data length loops correctly handle 0-length datasets (empty strings).
* **Performance/Safety:** Checks that 32-bit squarings in Mid-Square accurately cast to 64-bit types internally to bypass Ada's strict mathematical overflow boundaries.

**Why these tests matter:**
In mission-critical Ada environments, unhandled constraint errors represent catastrophic failure. By applying a pessimistic V&V approach (assuming the code is broken and demanding the assertion *disprove* it), we guarantee behavioral reliability under hostile inputs. 

## Usage

### Compilation
The project requires the GNAT toolchain. To compile the main program and the test suite:
```bash
make
