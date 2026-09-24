# Luhn Mod N Algorithm in Ada

## Project Overview
This project implements the **Luhn mod N algorithm**, an extension of the standard Luhn algorithm designed to generate and validate check characters for strings in any custom alphabet (alphanumeric, hexadecimal, special symbols). It acts as a safety measure against accidental transcription errors (e.g., mistyping a single character).

## Features
- **All Variants Implemented**: Supports isolated Check Character Generation, string validation, and appending.
- **Customizable Codecs**: Map to any alphabet (e.g., Base-10, Hexadecimal, arbitrary custom symbols) easily.
- **Strong Typing**: Encapsulates lookup matrices within a `Codec` abstraction preventing improper data tampering.
- **Defensive Programming**: Complete protection against edge cases, missing data, and invalid states with explicit Ada Exception models.

## Testing
This repository relies heavily on **Verification and Validation (V&V)** testing principles suitable for critical systems. 

- **Functional Correctness Tests** verify the algorithm's math exactly aligns with Wikipedia's established pseudocode standard (e.g. standard numeric tests, hex logic paths).
- **Error Handling Tests** prove that the system gracefully handles unexpected system states (e.g., invalid mappings, missing inputs) by strictly evaluating Ada Exceptions instead of allowing silent failures.
- **Edge Case Tests** evaluate boundary conditions. For instance, tests push empty, small (size 1) alphabets and duplicates to aggressively attempt to break lookup logic. 

**Why this matters:** We start with the pessimistic assumption that our arithmetic and memory references are fundamentally broken or unsafe. Our test outputs will report **PASS** exclusively when an assertion proves the assumption false. This guarantees strict reliability and type safety per critical-systems V&V guidelines.

## Usage

### Compilation
The codebase is structured completely in the root directory without a separate `src` folder. Compile the code using the provided `Makefile`:

```bash
make all
