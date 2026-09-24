# Burstsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [burstsort](https://en.wikipedia.org/wiki/Burstsort) on a bounded-string array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it is a cache-friendly MSD radix / burst-trie *hybrid* for strings: shared prefixes are refined by character depth; unsorted suffixes live in buckets; buckets larger than $\mathrm{Burst\_Threshold}$ are **burst** (redistributed at the next depth). Small buckets are finished with insertion sort. A final gap-$1$ bubble finish proves $\mathrm{Is\_Sorted}$.

$$
O(w n),\quad n \le \mathrm{Max\_N} = 32,\quad w \le \mathrm{Max\_String\_Len} = 16
$$

This is the SPARK Level 4 port of the companion package [Ada-Burstsort](https://github.com/RobertBoettcherSF/Ada-Burstsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a heap node pool (`Unchecked_Deallocation`), $\mathrm{Max\_N} = 256$, $\mathrm{Max\_String\_Len} = 64$, $\mathrm{Burst\_Threshold} = 8$, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for hard classroom bounds, `In_Bounds` / `Is_Sorted` contracts, static work buffers only (no heap trie pointers), an educational MSD-bucket approximation of the burst trie, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same proof split: [Ada-SPARK-Strand-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Strand-Sort).

## Features
* **`Sort (A)`**: Lexicographic ascending educational burstsort via static buffers, then a gap-$1$ bubble finish.
* **`Make` / `To_String` / `"<"` / `"<="` / `">"`**: Bounded-string construction and lexicographic order (Ada `String` rules).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; burst / insert / collect prove `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays / strings are `Pre` violations rather than `Invalid_Argument`.
* **Static buffers only**: No `Unchecked_Deallocation`; all work arrays are `1 .. Max_N`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 32`, `Max_String_Len = 16`, `Burst_Threshold = 4` (sibling uses $256$ / $64$ / $8$) so array / string VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`; `Make` uses `Pre => S'Length <= Max_String_Len`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **No heap trie / `Unchecked_Deallocation`**: educational **MSD-bucket approximation** of the burst trie — in-place Ended partition, sort active region by character at depth, then burst or insertion-finish equal-character runs (same emit order as a burst-trie walk: Ended, then ascending character buckets). Documented as Wikipedia burstsort / burst-trie idea without a 256-wide child-slot node pool that fights Level-4 SMT.
* Burst / insert / collect prove only `In_Bounds` / RTE; the final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Strand / Comb / Odd_Even). Lexicographic `"<="` transitivity is a ghost lemma discharged from the expression-function definition of `"<"`.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
1. If $n \le 1$, return.
2. Copy $A$ into a fixed `Work` buffer (`1 .. Max_N`).
3. **`Process_Slice (Work, 1, n, Depth=0)`** (educational burst):
   * If $|\mathrm{slice}| \le \mathrm{Burst\_Threshold}$, insertion-sort the slice (small-bucket finish).
   * Else if $\mathrm{Depth} \ge \mathrm{Max\_String\_Len}$, return (leave for bubble finish).
   * Else: in-place partition **Ended** ($\mathrm{Length} \le \mathrm{Depth}$) to the front; sort the **Active** region by `Data (Depth+1)`; walk equal-character runs — runs $\le \mathrm{Burst\_Threshold}$ are insertion-sorted, larger runs are **burst** (recurse at $\mathrm{Depth}+1$).
4. Copy `Work` back into $A$.
5. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 107 assertions pass. Running `make prove` reports `Success: all checks proved (449 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / duplicates, prefix families, burst-threshold stress, case-sensitive ASCII, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Make` / `To_String` / ordering.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 32$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Burst / MSD loops use `pragma Loop_Invariant` / `Loop_Variant` / `Subprogram_Variant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (449 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Bounded_String` | Length + `Data (1 .. Max_String_Len)` |
| `String_Array` | `array (Positive range <>) of Bounded_String` |
| `Max_N` | Classroom capacity bound (`32`) |
| `Max_String_Len` | Max characters per string (`16`) |
| `Burst_Threshold` | Bucket size that triggers a burst (`4`) |
| `Alphabet_Size` | Full 8-bit `Character` alphabet (`256`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing under `"<="` |
| `Sort` | Educational burstsort + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
