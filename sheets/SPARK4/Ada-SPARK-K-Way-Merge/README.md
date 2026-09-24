# K-Way Merge Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of the
[k-way merge algorithm](https://en.wikipedia.org/wiki/K-way_merge_algorithm)
that combines $k$ sorted ascending `Integer` sequences into one sorted
sequence. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it
uses **static storage only** (a flattened `List_Store`, no access types) and a
**linear scan of the $k$ live heads** each step — an educational
$O(N \cdot k)$ simplification of the classic binary min-heap of heads
($O(N \log k)$).

$$
O(N \cdot k),\quad k \le \mathrm{Max\_K} = 8,\quad
N \le \mathrm{Max\_Total} = 64,\quad
\text{per list} \le \mathrm{Max\_Len} = 32
$$

This is the SPARK Level 4 port of the companion package
[Ada-K-Way-Merge](https://github.com/RobertBoettcherSF/Ada-K-Way-Merge) in the
RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses larger
bounds (`Max_K = 64`, `Max_Len = 10_000`, `Max_Total = 100_000`),
`access constant Vector` lists, a binary min-heap of heads, and
`Invalid_Argument` exceptions. This port trades those for classroom bounds,
`In_Bounds` / `Is_Sorted` / `List_Is_Sorted` contracts, and a linear
min-of-heads scan so Level 4 can **prove sortedness of the merge result** when
every input list is sorted (no `Bubble_Finish` fallback). README links only —
do not `with` sibling packages here. Closest SPARK siblings that also merge
sorted runs: [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort)
(2-way stable merge), [Ada-SPARK-Patience-Sorting](https://github.com/RobertBoettcherSF/Ada-SPARK-Patience-Sorting)
(linear min-top $k$-way merge of piles).

## Features
* **`Merge_K`**: Combine up to `Max_K` sorted lists from a static `List_Store`
  into `Output (1 .. Last)` via linear scan of live heads.
* **`Merge`**: Educational 2-way two-pointer merge (special case of $k = 2$).
* **`Is_Sorted` / `In_Bounds` / `List_Is_Sorted` / `Total_Length`**:
  Expression-function guards; sortedness of the merge result is the proved
  postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index
  / overflow errors; loop invariants keep a sorted Output prefix and
  $\mathrm{head} \ge \mathrm{last}$ so `Post => Is_Sorted (Output (1 .. Last))`.
* **Contract Discipline**: Preconditions replace exceptions; oversized /
  unsorted inputs are `Pre` violations rather than `Invalid_Argument`.
* **Static buffers only**: Fixed `List_Store (1 .. Max_K, 1 .. Max_Len)` and
  `Output (1 .. Max_Total)` — no access types, no heap.

## Deliberate simplifications vs non-SPARK sibling
* `Max_K = 8`, `Max_Len = 32`, `Max_Total = 64` (sibling uses $64$ / $10\,000$ /
  $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: shape / length / sortedness are `Pre` contracts.
* No `access` types: inputs live in a flattened `List_Store` plus `Len_Array`
  (sibling uses `access constant Vector`).
* **Linear scan of $k$ heads** ($O(N \cdot k)$) instead of a binary min-heap
  of heads ($O(N \log k)$) — same Wikipedia k-way merge idea, educational
  simplification chosen so Level 4 discharges sortedness without fighting
  heap sift VCs (heap remains the preferred production approach; see sibling).
* **SPARK proves sortedness** of the merge when inputs are sorted
  (`Post => Is_Sorted (Output (1 .. Last))`). Full multiset / permutation
  equality is **checked by tests**, not claimed as a Level-4 postcondition.
* No `Bubble_Finish` — unlike Patience / Strand SPARK ports, the merge
  invariant itself establishes sortedness.

## Algorithm
1. Preconditions: $k \in 1..\mathrm{Max\_K}$, each list length
   $\le \mathrm{Max\_Len}$, each `Store(I, 1..\mathrm{Lens}(I))` sorted
   ascending, and $\sum \mathrm{Lens}(I) \le \mathrm{Max\_Total}$.
2. Keep a cursor $\mathrm{Pos}(I)$ into each list (exhausted when
   $\mathrm{Pos}(I) > \mathrm{Lens}(I)$).
3. While any element remains: scan the $k$ live heads, pick the minimum,
   append it to Output, advance that list's cursor.
4. Loop invariant: Output $(1..\mathrm{OI})$ is sorted and every live head is
   $\ge$ Output$(\mathrm{OI})$ (vacuous when $\mathrm{OI}=0$). Because each
   input list is sorted, advancing preserves head $\ge$ last, so the merge
   result is sorted.

### Example
Lists $[1,4,7]$, $[2,5,8]$, $[3,6,9]$ yield

$$
1,2,3,4,5,6,7,8,9
$$

A separate **2-way** scan (`Merge (A, B, Output, Last)`) covers $k = 2$
without the $k$-head loop.

## Complexity

| Approach | Time | Extra space | Notes |
| -------- | ---- | ----------- | ----- |
| Linear scan of heads (this package) | $O(N \cdot k)$ | $O(k)$ cursors + $O(N)$ output | Educational; proves at L4 |
| Heap of heads (non-SPARK sibling) | $O(N \log k)$ | $O(k)$ heap + $O(N)$ output | Preferred for large $k$ |
| Balanced pairwise 2-way tree | $O(N \log N)$ | $O(N)$ temps | Independent of explicit $k$ |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all assertions pass (164 PASS, 0 FAIL).
Running `make prove` reports `Success: all checks proved (358 checks).`

## Testing
* **Functional correctness**: Empty / singleton lists, classic Wikipedia
  3-way example, uneven lengths with empty slots, duplicates and negatives,
  identical and perfectly interleaved lists, lengths up to `Max_K` /
  `Max_Len` / `Max_Total`.
* **Agreement**: `Merge_K` / `Merge` vs independent insertion-sort of the
  concatenation; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted`, `In_Bounds`, `List_Is_Sorted`,
  `Total_Length`.
* **Contract discipline**: Only valid call paths are exercised (no exception
  handlers). Tests stay within the classroom bounds.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`).
Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` /
  `Global => null`.
* Merge loops use `pragma Loop_Invariant` / `Loop_Variant` tracking
  `Sorted_Slice`, live-head $\ge$ last, and `Live_Count` / `Total_Length`.
* **GNATprove Level 4:** `Success: all checks proved (358 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)`
  suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `List_Store` | `array (1 .. Max_K, 1 .. Max_Len) of Integer` |
| `Len_Array` | Per-list lengths |
| `Max_K` / `Max_Len` / `Max_Total` | Classroom capacity bounds (`8` / `32` / `64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_Total` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `List_Is_Sorted` | Sortedness of one store row |
| `Total_Length` | Sum of `Lens (1 .. K)` |
| `Merge_K` | K-way merge (`Post => Is_Sorted`) |
| `Merge` | Educational 2-way merge (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
