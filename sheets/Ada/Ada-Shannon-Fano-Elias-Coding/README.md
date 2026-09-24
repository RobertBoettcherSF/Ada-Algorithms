# README.md

## Project Overview
This repository contains a robust, statically typed Ada implementation of the **Shannon-Fano-Elias (SFE) scheduling/coding algorithm**. 

Unlike standard Shannon-Fano or Huffman coding, Shannon-Fano-Elias uses a modified cumulative distribution function ($\bar{F}(x)$) to evaluate prefix-free binary representation. This algorithm guarantees prefix-free decodability by allocating code lengths equal to $\lceil -\log_2 p(x) \rceil + 1$ and extracting binary fractions from $\bar{F}(x)$. 

## Features
- **Strong Typing Protocol:** Custom probability types (`0.0 .. 1.0` constraints) preventing memory overflows.
- **Strict Adherence to SFE Variants:** 
  - Standard Cumulative Distribution Function ($F(x)$) mappings.
  - Modified Cumulative Distribution Function ($\bar{F}(x)$) shift alignments.
  - Code length boundary estimations.
  - Sub-string fractional binary translation routines.
- **Modular and Isolated Design:** Procedures are cleanly decoupled for reusability in data compression or queuing implementations.

## Testing
This repository adopts a rigorous **Verification & Validation (V&V)** protocol. The testing philosophy is pessimistic: *We assume the codebase is entirely broken or fundamentally flawed. A test only PASSES when it actively disproves one of these assumptions.*

### What the test categories verify:
1. **Functional Correctness:** Verifies binary conversions, correct log calculations for lengths, and expected theoretical CDF values against Wikipedia standard inputs.
2. **Error Handling & Edge Cases:** Validates robustness against empty inputs, zero probabilities, negative limits, and probability mass arrays that violate fundamental probability axioms (sum $\neq 1.0$).
3. **Information Theory Boundaries (V&V specifics):** 
   - **Prefix-Free Integrity:** A brute-force quadratic loop ensures no single code acts as a prefix to another, validating decoding non-ambiguity.
   - **Kraft-McMillan Inequality:** Mathematically guarantees the generated lengths $l(x)$ adhere strictly to $\sum 2^{-l_i} \le 1$.

### Why these tests matter:
In critical systems, assumption of function is a liability. By ensuring failure modes (like sum constraints) correctly throw typed exceptions (`Invalid_Distribution`, `Empty_Input`), and by mathematically validating the output against structural theorems (Kraft), we guarantee reliability and state safety. Proving the code operates cleanly across all bounds ensures that future integrations won't face silent data corruption.

## Usage

### Compilation
Ensure `gnatmake` (GNAT Ada compiler) is installed. The repository operates entirely from the root directory utilizing `sfe.gpr`.

To compile the binaries and layout object files natively:
```bash
make all
