# Ada-SPARK-Path-Sum

Bounded Ada/SPARK implementation of the Path Sum algorithm.

## Verification

```sh
make test
make prove
```

The implementation uses `pragma SPARK_Mode (On)` and fixed-size bounded storage.

## Notes (V&V sweep, 2026-10-09)

`make test` now builds with `-gnatwa -gnata` (contracts checked, zero
warnings on GNAT 14.2.0 and 12.2.0). A path is root-to-leaf, a leaf is a
used node with no children. Two guards in the walk never fire on a tree
(at most 15 nodes): `Subtract_Value` saturates at +-4000, but a path sum
differs from `Wanted` (|Wanted| <= 1000) by at most 15 * 100; and the
stack never holds more than 15 entries of its 256. Linked lists that are
not trees (a cycle, a shared child) are outside the problem: the walk stops
after 256 steps. Own checks: `own_checks.adb`, sources in
`tests/SOURCES.txt`.
