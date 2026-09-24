# BCJR Algorithm in Ada 2012

This project provides a complete, robust implementation of the Bahl-Cocke-Jelinek-Raviv (BCJR) algorithm in Ada 2012. It calculates a posteriori probabilities (APPs) for bits passing through a convolutional channel or hidden Markov model. By operating on a generic user-defined Trellis structure, this module separates the fundamental recursive algorithm from specific code architectures.

---

## Features

- **Standard MAP**: Probability domain implementation using per-stage normalizations to avoid underflow.
- **Log-MAP**: Logarithmic domain with a Jacobian logarithm (`max*`) correction to maintain optimality without sacrificing numerical stability.
- **Max-Log-MAP**: Logarithmic domain using standard `max` approximation; provides faster execution at a marginal cost to decoding accuracy.
- **Strongly Typed**: Adheres strictly to Ada 2012 safety guidelines, utilizing sub-typing for structural definitions, probabilities, and bits.
- **Turbo-ready**: Built-in support for generic Extrinsic LLR outputs alongside systemic and *a priori* soft inputs.
- **Trellis Termination Mode**: Supports bounded (terminated to 0) or un-terminated tail modes.

---

## Building

**Prerequisites:** GNAT Toolchain (supports Ada 2012)

You can compile the module and the test suite using `make`:

```bash
make
```

---

## Usage

Run the compiled test suite (which also serves as usage examples) directly using the Makefile:

```bash
make test
```

Expected output includes the successful passing of all 39 assertions spread across 13 unique test scenarios:

```
--- BCJR Algorithm Test Suite ---
TEST 1 — Max_Log_MAP Functional (All Zeros)
  PASS — 1.1 Ext(1) is negative
  ...
=== 39 passed, 0 failed ===
```

---

## Testing

The standalone `tests.adb` test suite exercises the implementation heavily across four primary categories:

- **Functional Correctness**: Validates error correction capacities on a simulated Rate 1/2 trellis across the standard, Log, and Max-Log variants.
- **Edge Cases**: Validates proper functionality when testing extreme bounds with huge Log-Likelihoods or un-terminated input streams.
- **Error Handling**: Implements strict mismatch boundary tests mapping directly to Ada Pre-conditions protecting matrix alignment.
- **Invariant Protections**: Proves mathematically sound behaviors (e.g., verifying Log\_MAP versus Max\_Log\_MAP residual outputs).
