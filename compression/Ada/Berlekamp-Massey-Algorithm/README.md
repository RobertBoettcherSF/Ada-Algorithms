# Berlekamp-Massey Algorithm in Ada 2023

A strict **Ada 2023** implementation of the Berlekamp-Massey algorithm, synthesizing the shortest **Linear Feedback Shift Register (LFSR)** for a given finite sequence. Supports **GF(2)** (binary) and **arbitrary real fields** (floating-point).

---

## Features

- **GF(2) Variant**: Bitwise implementation (`Compute_LFSR_GF2`) for boolean sequences.
- **Real/Arbitrary Field Variant**: Handles floating-point coefficients (`Compute_LFSR_Real`).
- **Self-Validating Helpers**: Includes `Is_Valid_LFSR_GF2` and `Is_Valid_LFSR_Real` to verify polynomial generators.
- **Strict Safety**: Enforces array bounds via named exceptions (`Size_Error`), preventing out-of-bounds access. Zero compilation warnings.

---

## Usage

### Example (GF(2))

```ada
with Berlekamp_Massey; use Berlekamp_Massey;

Seq   : Bit_Array (1 .. 4) := (1, 1, 1, 1);
Poly  : Bit_Array (1 .. 10);
L     : Natural;

Compute_LFSR_GF2 (Seq, Poly, L);
-- Yields length L = 1 and Poly(1..2) = (1, 1)
```

### Testing

```bash
make test
```

**Expected Output**:

```
Running tests...
TEST 1 - GF2 All Zeros
  PASS - 1.1 L is 0
  PASS - 1.2 Valid LFSR
  PASS - 1.3 C_0 is 1
...
===  42 passed,  0 failed ===
```

---

## Testing Strategy

The `tests.adb` suite validates:

- **Functional Correctness**: Tests textbook sequences (all-zeros, ones, alternating bits) and real-valued sequences (Fibonacci, powers of 2).
- **Edge Cases**: Handles impulses (single `1` + zeros) and max-length sequences.
- **Error Handling**: Validates `Size_Error` for empty sequences or improper output bounds.
- **Invariants**: Cross-checks results against mathematical validation implementations.

---

## Building

- **Prerequisites**: GNAT Ada compiler (Ada 2022/2023 support).
- **Language Standard**: **ISO/IEC 8652:2023 (Ada 2023)**. Uses `pragma Assert`.
- **Compilation**: Makefile configures `-gnat2022` and `-gnatwa` (all warnings). Run `make`.
