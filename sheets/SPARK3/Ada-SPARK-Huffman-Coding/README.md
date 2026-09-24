# Huffman Coding (frequency core) in Ada/SPARK

## Project Overview
Bounded educational sheet for the frequency-analysis core used by [Huffman coding](https://en.wikipedia.org/wiki/Huffman_coding). Ada 2022 + SPARK. Companion plain Ada: [Ada-Huffmann-Coding](https://github.com/RobertBoettcherSF/Ada-Huffmann-Coding).

## Proof bar (Pareto)
- Default `make prove` → **Level 3**, all 16 checks proved (`--warnings=error`, `--checks-as-errors=on`).
- `make prove-l4` available for the strict max settings (can stall when the shared prove queue is congested).
- `make prove-l2` remains as a faster fallback.

## Usage
`make` · `make test` · `make prove`
