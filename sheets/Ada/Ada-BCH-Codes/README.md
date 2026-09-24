# BCH Code (15, 7, 2) in Ada 2023

A production-grade **Ada 2023** implementation of a binary **Bose–Chaudhuri–Hocquenghem (BCH) code** over **GF(2⁴)** with parameters *(n=15, k=7, t=2)*. Corrects up to **2 bit errors per block** for communications and storage applications.

---

## Features

- **Systematic Encoding**: Encodes 7-bit messages into 15-bit codewords.
- **Syndrome Computation**: Evaluates received polynomials over *GF(2⁴)* to calculate syndrome components.
- **Error Correction**: Detects and corrects up to 2 bit errors per block.
- **Strong Typing**: Uses strict domain types (`Bit`, `Message_Type`, `Codeword_Type`, `GF_Element`) to prevent abstraction mixing.
- **Ada 2023 Contracts**: Leverages postconditions and purity annotations.

---

## Usage

### Building &amp; Testing

```bash
make test
```

**Expected Output**:

```
Running tests...
=== Starting BCH Code Test Suite ===
  PASS — 1.1 Codeword length is N
  ...
=== 39 passed, 0 failed ===
```

---

## Testing

The `tests.adb` suite includes **13 test cases** covering:

- **Functional Correctness**: Encoding/decoding (all zeros, all ones, alternating bits).
- **Edge Cases**: Single-bit and double-bit errors at various positions (including boundaries like positions 1 and 15).
- **Error Handling**: Verifies `Decoding_Failed_Error` for uncorrectable patterns (*&gt; t=2*).
- **Invariants**: Codeword validity and syndrome properties.

---

## Building

- **Prerequisites**: GNAT compiler with Ada 2023 support (`-gnat2022`).
- **Compilation**: Clean compilation under `-gnatwa` (all warnings).

```bash
make all
make clean
```
