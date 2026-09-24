# Mu-Law Companding Algorithm (Ada Implementation)

## Project Overview
This project provides a robust, strongly-typed Ada implementation of the $\mu$-law (Mu-law) companding algorithm. It is primarily used in 8-bit PCM digital telecommunication systems in North America and Japan to reduce the dynamic range of audio signals, prioritizing human speech frequencies.

The codebase strictly adheres to the standard ITU formulas and maps continuous math to discrete digital domain applications. 

## Features
*   **Analog/Continuous Variants:** Implementation of continuous encoding $F(x)$ and expansion $F^{-1}(y)$ formulas.
*   **Digital/Discrete Variants:** Mapping of 14-bit linear PCM signals to 8-bit quantized representations and vice versa.
*   **Robust Type Safety:** Custom types (`Normalized_Signal`, `PCM_14_Bit`) prevent invalid signal processing implicitly.
*   **Edge Case Hardening:** Mathematical zero-division mitigation, domain constraint boundary handling, and clipping algorithms.

## Testing
This codebase utilizes strict **Verification and Validation (V&V)** principles crucial for reliability and safety in critical systems. The test suite operates on a pessimistic assumption: *The code is broken until proven otherwise.*

### Test Categories
1.  **Functional Correctness (Tests 1-6, 10-13):** Proves the code matches ITU mathematical specifications (Verification). Validates that baseline, max, and min voltages result in exactly mapped bit-outputs.
2.  **Error Handling (Tests 7-8):** Ensures the system gracefully throws predefined exceptions (rather than crashing) if a malicious or broken external system passes invalid parameters, like a $\mu$ (Mu) of $0.0$ or a negative number.
3.  **Edge Cases (Test 9):** Uses Ada's constraint types to mathematically prove that signal overloads (inputs $> 1.0$) are blocked before execution can proceed, maintaining memory and logic safety.
4.  **Performance & Tolerances (Test 14-15):** Validates the code's practical applicability (Validation) by verifying that quantization noise during digital conversions falls within acceptable limits for a compander. 

### Why These Tests Matter
In a telecommunications routing environment, an unhandled exception or phase-inverted signal (due to an edge case) can cause total sub-system crashes or deafening audio artifacts. By applying V&V testing paradigms natively, we *prove* mathematically that our endpoints gracefully clamp and manage out-of-band noise. Disproving the assumption that the "code is broken" ensures high-reliability.

## Usage

### Compilation
The codebase uses the standard GNAT compilation ecosystem. Everything resides in the root directory. To compile:

```bash
make
# Alternatively: gnatmake -P mu_law_project.gpr
