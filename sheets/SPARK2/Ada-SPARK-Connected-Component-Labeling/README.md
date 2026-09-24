# Connected-Component Labeling in Ada/SPARK

Bounded educational sheet for [connected-component labeling](https://en.wikipedia.org/wiki/Connected-component_labeling) (CCL) on binary grids. Ada 2022 + SPARK. Companion plain Ada: [Ada-Connected-Component-Labeling](https://github.com/RobertBoettcherSF/Ada-Connected-Component-Labeling).

ICEYE-adjacent use: labeling flood-extent blobs in a binary water mask so each contiguous inundation region gets a stable component id.

## Design choices

- **4-connectivity** only (von Neumann neighborhood: north/east/south/west). Diagonally touching cells are separate components.
- Bounded `Max_Rows` / `Max_Cols` (= 2) fixed arrays — no heap, no access types.
- Multi-pass seed propagation (same style as the flood-fill sheet) instead of union-find, to keep Level-2 proofs tractable.
- `Label` returns compact ids $1 \ldots Count$; background stays $0$. Postcondition: $Count \le Max\_Rows \times Max\_Cols$.

## Proof bar

`make prove` → GNATprove **Level 2**, prover `cvc5`, `--warnings=error`, `--checks-as-errors=on`.

## Usage

```sh
source /home/box/deps/spark/env.sh   # where GNATprove is installed
make test
make prove
```
