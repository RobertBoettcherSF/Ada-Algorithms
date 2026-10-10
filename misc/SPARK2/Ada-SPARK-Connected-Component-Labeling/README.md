# Connected-Component Labeling in Ada/SPARK

[Connected-component labeling](https://en.wikipedia.org/wiki/Connected-component_labeling) (CCL) of binary grids up to 100 x 100, 4-connectivity (north / east / south / west; diagonal neighbours are separate components). Ada 2022 + SPARK. Companion plain Ada: [Ada-Connected-Component-Labeling](https://github.com/RobertBoettcherSF/Ada-Connected-Component-Labeling).

ICEYE-adjacent use: labeling flood-extent blobs in a binary water mask so each contiguous inundation region gets a stable component id.

## Algorithm

`Label_Region (Input, Rows, Cols, Output, Count)` labels the top-left `Rows x Cols` part; `Label` the whole grid. Classic two-pass union-find: pass 1 gives each foreground cell a provisional label from its north / west neighbours (a new label when both are background) and joins the labels of touching neighbours (`Union`, the larger root points to the smaller, `Find` with path halving); pass 2 gives each root the next compact id in scan order. Ids are `1 .. Count`, background and cells outside the region are 0. Bounded fixed arrays, no heap.

## Proof

`make prove`: GNATprove level 2, cvc5 + z3, timeout 10 s, `--warnings=error`, `--checks-as-errors=on` (75 checks): no run-time error (at most one new label per cell, bounded linearly with `Max_Cols`; parents form a forest `Parent (L) <= L`, so `Find` terminates) and the Post: a cell is labelled 0 exactly when it is background or outside the region, and every label is at most `Count`. Partial: that two cells share a label exactly when they are 4-connected is not in the Post; it is checked by `own_checks.adb` only (`tools/vv/contract_scan.csv`). The loop invariants quantify over the whole grid, so `pragma Assertion_Policy (Loop_Invariant => Ignore)` skips them at run time (all proved; `tools/vv/proof_escapes.csv`, runtime_only); the spec Posts still run.

## Tests

`tests.adb` (original cases) and `own_checks.adb`: against an independent union-find reference (same component iff same label, compact ids, background 0) on every region up to 4 x 4, 300 random regions and 20 random full grids (seed 20261009).

```sh
make test
make prove
```
