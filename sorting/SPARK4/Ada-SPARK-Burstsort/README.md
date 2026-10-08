# Burstsort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [burstsort](https://en.wikipedia.org/wiki/Burstsort) on a bounded-string array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it is a cache-friendly MSD radix / burst-trie *hybrid* for strings: shared prefixes are refined by character depth; unsorted suffixes live in buckets; buckets larger than $\mathrm{Burst\_Threshold}$ are **burst** (redistributed at the next depth). Small buckets are finished with insertion sort. SPARK proves that this alone sorts the array ($\mathrm{Is\_Sorted}$; no bubble-sort safety net).

$$
O(w n),\quad n \le \mathrm{Max\_N} = 32,\quad w \le \mathrm{Max\_String\_Len} = 16
$$

This is the SPARK Level 4 port of the companion package [Ada-Burstsort](https://github.com/RobertBoettcherSF/Ada-Burstsort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses a heap node pool (`Unchecked_Deallocation`), $\mathrm{Max\_N} = 256$, $\mathrm{Max\_String\_Len} = 64$, $\mathrm{Burst\_Threshold} = 8$, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for hard classroom bounds, `In_Bounds` / `Is_Sorted` contracts, static work buffers only (no heap trie pointers), an educational MSD-bucket approximation of the burst trie, and a proof that the burst phase itself sorts. README links only — do not `with` sibling packages here. Closest SPARK sort sibling (MSD distribution proved the same way): [Ada-SPARK-Postman-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Postman-Sort).

## Features
* **`Sort (A)`**: Lexicographic ascending educational burstsort via static buffers.
* **`Make` / `To_String` / `"<"` / `"<="` / `">"`**: Bounded-string construction and lexicographic order (Ada `String` rules).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and the burst phase proves `Is_Sorted`: every slice shares its first Depth characters (ghost `Common`), ended strings sort first (`Lemma_Ended`), a smaller character at Depth + 1 means a smaller string (`Lemma_Char_Order`), and insertion sorts keep every shared prefix (ghost `Keeps_Prefixes`).
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays / strings are `Pre` violations rather than `Invalid_Argument`.
* **Static buffers only**: No `Unchecked_Deallocation`; all work arrays are `1 .. Max_N`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 32`, `Max_String_Len = 16`, `Burst_Threshold = 4` (sibling uses $256$ / $64$ / $8$) so array / string VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`; `Make` uses `Pre => S'Length <= Max_String_Len`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **No heap trie / `Unchecked_Deallocation`**: educational **MSD-bucket approximation** of the burst trie — in-place Ended partition, sort active region by character at depth, then burst or insertion-finish equal-character runs (same emit order as a burst-trie walk: Ended, then ascending character buckets). Documented as Wikipedia burstsort / burst-trie idea without a 256-wide child-slot node pool that fights Level-4 SMT.
* No bubble finish: the burst phase is proved to sort on its own. The order lemmas (`Lemma_Lt_Asym`, `Lemma_Ended`, `Lemma_Char_Order`) are discharged from the expression-function definition of `"<"`.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.
* Zero `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## Algorithm
1. If $n \le 1$, return.
2. Copy $A$ into a fixed `Work` buffer (`1 .. Max_N`).
3. **`Process_Slice (Work, 1, n, Depth=0)`** (educational burst):
   * If $|\mathrm{slice}| \le \mathrm{Burst\_Threshold}$, insertion-sort the slice (small-bucket finish).
   * Else if $\mathrm{Depth} \ge \mathrm{Max\_String\_Len}$, return (every string in the slice then has all $\mathrm{Max\_String\_Len}$ characters in common, so they are all equal).
   * Else: in-place partition **Ended** ($\mathrm{Length} \le \mathrm{Depth}$) to the front; sort the **Active** region by `Data (Depth+1)`; walk equal-character runs — runs $\le \mathrm{Burst\_Threshold}$ are insertion-sorted, larger runs are **burst** (recurse at $\mathrm{Depth}+1$).
4. Copy `Work` back into $A$ (now sorted: `Is_Sorted` proved).

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 107 assertions pass, followed by the own checks (15,875 sort calls). Running `make prove` reports `Success: all checks proved (531 checks)` (the same at `--mode=silver --level=2`).

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / duplicates, prefix families, burst-threshold stress, case-sensitive ASCII, lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Make` / `To_String` / ordering.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 32$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Burst / MSD loops use `pragma Loop_Invariant` / `Loop_Variant` / `Subprogram_Variant`; the run loop keeps the placed part sorted and its last string below the next run (`Lemma_Join`).
* **GNATprove Level 4:** `Success: all checks proved (531 checks).`
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
| `Sort` | Educational burstsort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
