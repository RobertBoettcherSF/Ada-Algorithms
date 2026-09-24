# Sieve of Sundaram (Ada Implementation)

## Project Overview
This repository contains an optimized Ada implementation of the **Sieve of Sundaram**, an algorithm originally developed by S.P. Sundaram in 1934 to iteratively map and discover prime numbers. Unlike the Sieve of Eratosthenes which eliminates multiples of primes directly, the Sundaram algorithm eliminates numbers of the form `i + j + 2ij`, yielding all odd primes up to a boundary based on `2K + 1`.

## Features
- **Standard Array Extraction (`Standard_Sundaram`)**: Dynamically allocates and returns an array of all primes up to `N`.
- **Memory Efficient Count (`Count_Primes_Sundaram`)**: Sifts through primes sequentially returning the strict total count without requiring heap array allocation.
- **Single Target Query (`Is_Prime_Sundaram`)**: A variant implementation using the core theorem structure (`i + j + 2ij = K`) uniquely transformed into a specific integer primality tester.

## Testing
This software is built adhering to strict **Verification and Validation (V&V)** principles. The default assumption for testing is that the underlying logic fails. Tests are written to definitively **disprove this assumption**.

### What Each Test Category Verifies:
1. **Functional Correctness**: Validates mathematical baselines (e.g., verifying `[2, 3, 5, 7]` correlates precisely with limits of 10). Proves the fundamental algorithm accurately replicates S.P. Sundaram's equations.
2. **Error Handling**: Inputs inherently impossible integers (`N = -17`, `N = 1`). Tests verify the system falls gracefully to empty states instead of crashing (`Constraint_Error`), preventing system-wide application termination.
3. **Edge Cases**: Evaluates boundaries adjacent to strict logic pivots (`N = 2`). Because Sundaram's algorithm *only* calculates odd primes (offsetting results by `2K + 1`), handling the first even prime (`2`) is an essential architectural edge case.
4. **Performance Bounds Verification**: Ensures scaling states map correctly to known theorems (e.g., Exactly 168 primes up to 1000).

### Why These Tests Matter:
For critical systems developed in Ada, correctness is paramount. The rigorous 13+ state checks demonstrate reliability by aggressively pursuing boundaries where off-by-one errors (OBOE), memory allocation leaks, or constraint failures traditionally present themselves. By disproving code failure, we guarantee the software operates safely according to requirement specs.

## Usage

### Compilation
The project utilizes `gnatmake` combined with GNAT project files (`.gpr`). A standardized `Makefile` drives the setup. Ensure you are in the project root containing all `.adb` and `.ads` files.

```bash
# Compile everything (Main application and tests)
make all
