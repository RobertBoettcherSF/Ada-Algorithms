# Cooley–Tukey FFT in Ada/SPARK (fixed-point)

Bounded educational sheet for the [Cooley–Tukey FFT](https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm) with a fixed-point (Q10) twiddle table — no IEEE floats. Ada 2022 + SPARK.

SAR-formation building block: a power-of-two DFT/FFT is the classical range/azimuth transform step inside synthetic-aperture radar image formation pipelines (educational core only; not a full focusing chain).

## Design choices

- $N = 8$ (power of two), in-place radix-2 decimation-in-time.
- Twiddles stored as integers with `Scale = 1024` ($\approx 2^{10}$). Only the two 45-degree twiddles of the last stage round (724 / 1024, product truncated); every output component is within 1.5 of the exact DFT.
- `FFT (Input, Output)`: input components are of subtype `Input_Sample` (-212 .. 212), output components of `Sample` (-2048 .. 2048). Per component the magnitude at most doubles in stages 1 and 2 and grows by at most 724 * 2 * M / 1024 in stage 3 (212 -> 424 -> 848 -> 2047); the proof checks this bound after every stage, so nothing is clamped. Larger inputs are rejected by the type (Constraint_Error); earlier versions accepted -2048 .. 2048 and silently clamped (eight inputs of 1000 gave 2048 in bin 0 instead of 8000).
- Bit-reversal permutation + three fully unrolled butterfly stages (keeps Level-2 proofs tractable).
- Output is **unnormalized** (no $1/N$ factor).

## Proof bar

`make prove` → GNATprove **Level 2**, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on` (81 checks, including the per-stage bounds and the output bound).

Tests: own Long_Float DFT reference, sources in `tests/SOURCES.txt`.

## Usage

```sh
# needs gprbuild + gnatprove on PATH (e.g. Alire: alr get gnatprove; alr get gprbuild)
make test
make prove
```
