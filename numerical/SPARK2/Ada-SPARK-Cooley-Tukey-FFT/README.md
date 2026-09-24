# Cooley–Tukey FFT in Ada/SPARK (fixed-point)

Bounded educational sheet for the [Cooley–Tukey FFT](https://en.wikipedia.org/wiki/Cooley%E2%80%93Tukey_FFT_algorithm) with a fixed-point (Q10) twiddle table — no IEEE floats. Ada 2022 + SPARK.

SAR-formation building block: a power-of-two DFT/FFT is the classical range/azimuth transform step inside synthetic-aperture radar image formation pipelines (educational core only; not a full focusing chain).

## Design choices

- $N = 8$ (power of two), in-place radix-2 decimation-in-time.
- Twiddles stored as integers with `Scale = 1024` ($\approx 2^{10}$); multiplies use 64-bit intermediates then clamp into `Sample`.
- Bit-reversal permutation + three fully unrolled butterfly stages (keeps Level-2 proofs tractable).
- Output is **unnormalized** (no $1/N$ factor).

## Proof bar

`make prove` → GNATprove **Level 2**, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on`.

## Usage

```sh
source /home/box/deps/spark/env.sh
make test
make prove
```
