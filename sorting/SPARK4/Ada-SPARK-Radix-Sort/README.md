# Radix Sort Algorithm in Ada/SPARK

## Project Overview
Formally verified [LSD radix sort](https://en.wikipedia.org/wiki/Radix_sort) (least-significant digit first; Knuth TAOCP vol. 3, 5.2.5) of up to `Max_N = 64` keys in `0 .. 255`, written in Ada 2022 and verified with SPARK (GNATprove level 4). Keys are two base-16 digits, so the sort is `Pass_Count = 2` stable passes: `Pass (A, 1, ..)` distributes by the low digit, `Pass (.., 2, ..)` by the high digit. Each pass sweeps its input once per digit value 0 .. 15 and appends the keys with that digit in input order, so equal digits keep their order from the previous pass; that stability is what lets the second pass finish the sort. Time O(Base * n) per pass.

SPARK level-4 port of the companion package [Ada-Radix-Sort](https://github.com/RobertBoettcherSF/Ada-Radix-Sort) (which takes unbounded nonnegative `Integer` keys and a chosen base 2 .. 256): hard `Max_N` bound, keys `0 .. Max_Key`, any `A'First` in `1 .. Max_N`, no exceptions (`Pre => In_Bounds (A)`).

## Contracts (all proved, 261 checks, `make prove`)
* **`Pass (A, P, B, Src)`**: `B (J) = A (Src (J))`; digit `P` is nondecreasing along `B` (pairwise); **stability**: two keys of `B` with equal digit `P` have increasing sources `Src`; and `B` holds the same keys as `A`, each equally often (`Occ` for every key).
* **`Sort (A)`**: `Is_Sorted (A)` and `Is_Perm (A, A'Old)`, from pass-2 digit order and stability over the pass-1 low-digit order.
* Ghost counts of the keys with a digit below / equal to D (`Cnt_Less`, `Cnt_Eq`, induction lemmas) show every write stays inside `B` and the passes fill it. No Assume / Annotate. The ghost lemmas, loop invariants and assertions range over all 256 keys, so the body's `Assertion_Policy (Ghost => Ignore, Loop_Invariant => Ignore, Assert => Ignore)` skips them at run time (all proved; `tools/vv/proof_escapes.csv`, runtime_only); the spec Posts of `Pass` and `Sort` still run in the tests.

## Tests
* `tests.adb` (original): 240 checks (empty / singleton, Wikipedia-style example, tagged and encoded pairs, shifted origins, `Max_N`, permutation against an independent sorted-copy comparison).
* `own_checks.adb`: each pass equals an own stable insertion sort by that digit, the source maps, `Sort` = pass 1 then pass 2, two passes for 8-bit keys; hand cases `16#21#, 16#31#` (equal low digit keep input order), `16#22#, 16#21#` (equal high digit come out in pass-1 order), `16#12#, 16#21#` (one pass alone does not sort); every array of length 0 .. 4 over six keys with shared digits and 3,000 random arrays (seed 20261010). Sources: `tests/SOURCES.txt`.

## Usage
```sh
make test
make prove
```
