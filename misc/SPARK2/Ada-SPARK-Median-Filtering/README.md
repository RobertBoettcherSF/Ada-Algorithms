# Median Filtering in Ada/SPARK

Bounded educational sheet for [median filtering](https://en.wikipedia.org/wiki/Median_filter) on integer images. Ada 2022 + SPARK. Companion plain Ada: [Ada-Median-Filtering](https://github.com/RobertBoettcherSF/Ada-Median-Filtering).

Speckle-adjacent note: a fixed $3\times3$ median is a classical impulse/speckle *pre-filter* on SAR amplitude patches; this sheet is **not** a Lee or Frost adaptive despeckle filter.

## Design choices

- Fixed **$3\times3$** window; pixels are integers in $0 .. 255$.
- Grid bounded by `Max_Rows` / `Max_Cols` (= 8); no heap, no access types.
- **Edge handling**: replicate / clamp — out-of-bounds window samples snap to the nearest in-bounds row/column.
- Median is the 5th element after an in-place bubble sort of the nine samples.

## Proof bar

`make prove` → GNATprove **Level 2**, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on`.

## Usage

```sh
source /home/box/deps/spark/env.sh   # where GNATprove is installed
make test
make prove
```
