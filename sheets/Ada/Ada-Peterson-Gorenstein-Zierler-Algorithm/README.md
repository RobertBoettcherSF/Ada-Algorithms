# Peterson–Gorenstein–Zierler (PGZ) Algorithm over GF(11)

A self-contained Ada implementation of the **PGZ algorithm** for finding the error locator polynomial in BCH and Reed-Solomon decoding. Operates strictly over **Galois Field 11 (Prime Field modulo 11)** with strong domain typing.

---

## Features

- **Static &amp; Dynamic Locator Inference**: Matrix-based static assumptions (fails fast on zeroes) and dynamic stepping down of assumed errors if matrices are singular.
- **Chien Search**: Locates exact error positions from the locator polynomial's roots.
- **Dual Value Approaches**: Implements both literature-specified variants for resolving error magnitudes:
  1. **Forney Algorithm**: Uses formal derivative and error evaluator polynomial *Ω(x)*.
  2. **Direct Linear Solving**: Solves linear equation systems directly.
- **Strong Type Checking**: Uses **Ada SPARK** aspects and rigorous contracts (`Pre`/`Global`) to enforce polynomial indexing and parameter assumptions.

---

## Building &amp; Usage

**Prerequisites**: `gnatmake` (Ada 2022 compatible).

```bash
make test
```

**Expected Output**:  
Runs `tests.adb` with **13 suites** and **39+ assertions** for full behavioral coverage. No failures should appear.

---

## Testing Strategy

- **Algebraic Constraints**: Validates modular identities in `Inverse` and polynomial evaluation bounds.
- **Edge Cases**: Ensures graceful handling of zero-error cases (prevents zero-division errors).
- **Invariant Verification**: Tests named exceptions (`Matrix_Singular_Error`, `No_Roots_Error`) for uncorrectable syndromes.
