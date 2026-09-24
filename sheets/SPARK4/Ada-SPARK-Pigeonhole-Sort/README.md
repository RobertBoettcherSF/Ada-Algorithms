# Pigeonhole Sort in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of [pigeonhole sort](https://en.wikipedia.org/wiki/Pigeonhole_sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it allocates one **pigeonhole** per key in $[\mathrm{min},\mathrm{max}]$, counts items into a static hole table, converts counts to prefix offsets, stably scatters into a work buffer, copies back, then finishes with a proved gap-$1$ bubble pass. It runs in

$$
O(n + N),\quad N = \mathrm{max} - \mathrm{min} + 1,\quad n \le \mathrm{Max\_N} = 64,\quad N \le \mathrm{Max\_Range} = 256
$$

time for the pigeonhole phase (plus $O(n^2)$ worst-case for the bubble finish).

This is the SPARK Level 4 port of the companion package [Ada-Pigeonhole-Sort](https://github.com/RobertBoettcherSF/Ada-Pigeonhole-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses larger caps ($\mathrm{Max\_Length} = \mathrm{Max\_Range} = 100\,000$), exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for classroom bounds (`Max_N = 64`, `Max_Range = 256`), `In_Bounds` / `Keys_In_Range` / `Is_Sorted` contracts, static `Counts (0 .. Max_Range−1)` and `Work (1 .. Max_N)`, and a proved final gap-$1$ bubble finish. README links only — do not `with` sibling packages here. Closest SPARK sort siblings: [Ada-SPARK-Counting-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Counting-Sort) (fixed key domain emit), [Ada-SPARK-Bucket-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bucket-Sort), [Ada-SPARK-Flashsort](https://github.com/RobertBoettcherSF/Ada-SPARK-Flashsort) (same Bubble_Finish proof split).

## Features
* **`Sort (A)`**: Ascending educational pigeonhole sort (count / prefix / stable scatter / copy-back), then a gap-$1$ bubble finish.
* **`Is_Sorted` / `In_Bounds` / `Keys_In_Range`**: Guards for shape, key span, and sortedness; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors; pigeonhole phase proves `In_Bounds` / RTE; `Bubble_Pass` / `Sorted_Slice` / partition invariants prove sortedness.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays or key spans are `Pre` violations rather than `Invalid_Argument`.
* **Static tables only**: `Counts (0 .. Max_Range−1)` and `Work (1 .. Max_N)`; hole index and span use `Long_Long_Integer`.

## Choice: `Keys_In_Range` precondition
Callers must establish `Keys_In_Range (A)`: empty/singleton arrays are always accepted; otherwise $(\mathrm{max}-\mathrm{min}+1) \le \mathrm{Max\_Range}$ must hold, computed with `Long_Long_Integer` so `Integer'First` .. `Integer'Last` cannot wrap. The pigeonhole phase still re-checks the span defensively and returns early if it somehow exceeds `Max_Range` (Bubble_Finish then sorts). An alternative design — `Pre => In_Bounds` only, skipping pigeonhole when the span is too large — would also prove cleanly; this package prefers the explicit `Keys_In_Range` contract so invalid spans are rejected at the API boundary (matching the sibling's `Invalid_Argument` for oversized range).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` and `Max_Range = 256` (sibling uses $100\,000$ / $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape / span are `Pre => In_Bounds (A) and then Keys_In_Range (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Static `Counts` and `Work` (sibling allocates locals sized to the live span / `A'Range`).
* Pigeonhole phase posts only `In_Bounds` / RTE; prefix / scatter use caps and index guards so Level-4 RTE discharges without a full cardinality lemma.
* The final gap-$1$ `Bubble_Finish` reuses the bubble-sort Level-4 argument for `Is_Sorted` (same proof split as Flashsort / Strand / Comb / Odd_Even). Full hole-order / permutation posts that would fight Level 4 are deferred to that finish and to tests.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
Given an array $A$ of length $n$:

1. If $n \le 1$, return.
2. **Min / max.** Scan $A$ for $A_{\min}$ and $A_{\max}$. Require
   $$
   N = A_{\max} - A_{\min} + 1 \le \mathrm{Max\_Range}.
   $$
3. **Count.** For each item, increment $\mathrm{Counts}[\mathrm{key}-A_{\min}]$ (static table over $0 .. \mathrm{Max\_Range}-1$).
4. **Prefix offsets.** Convert counts into starting write cursors for each hole segment in a static work buffer.
5. **Stable scatter.** Place each item left-to-right into its hole segment in `Work` (equal keys keep relative order).
6. **Copy back.** Write `Work(1 .. n)` into $A$.
7. **Gap-$1$ finish:** ordinary bubble sort with a shrinking unsorted suffix (and early exit) $\to$ fully sorted (`Is_Sorted` proved).

Empty and singleton arrays are no-ops. The pigeonhole scatter is **stable**; the bubble finish preserves the already-sorted (or nearly sorted) order.

### Contrast with counting sort and bucket sort

| Algorithm | Auxiliary structure | Item movement | Best when |
| --------- | ------------------- | ------------- | --------- |
| **Pigeonhole** | One hole (segment) per key | Moves items into holes, then concatenates | $N \approx n$ |
| **Counting sort** | Count table of size $N$ | Builds counts, then emits each key $\mathrm{Hist}(K)$ times | Same complexity class; count table only |
| **Bucket sort** | $k \ll N$ buckets | Scatter into buckets, sort each, concatenate | $N \gg n$; keys map into few bins |

Wikipedia highlights the structural difference: pigeonhole sort **moves items twice** — once into the hole array and again to the final destination — whereas counting sort builds an auxiliary count array and uses it to compute each item's final index.

## Complexity

| Case | Time | Extra space |
| ---- | ---- | ----------- |
| Typical ($N = O(n)$) | $O(n + N)$ pigeonhole + $O(n^2)$ finish worst | $O(\mathrm{Max\_N} + \mathrm{Max\_Range})$ |
| Already nearly sorted after scatter | $O(n + N)$ + early-exit bubble | static tables |
| All-equal | $O(n)$ count/scatter + $O(n)$ bubble | static tables |

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 181 assertions pass ($0$ FAIL). Running `make prove` reports `Success: all checks proved (254 checks)`.

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, duplicates / all-equal, signed domain, near `Integer'First` / `Integer'Last` (compact spans), lengths up to `Max_N`.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Pigeonhole-specific**: Exact `Max_Range` span ($0..255$), offset bands, exam-score-ish dense keys, random arrays with span $\le 256$.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty; `Keys_In_Range` true at exact span and false when span $> \mathrm{Max\_Range}$.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ and key span $\le 256$.

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Pigeonhole loops use `pragma Loop_Invariant`; outer bubble finish shrinks the unsorted suffix via `Bubble_Pass` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (254 checks)`.
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `Max_Range` | Max key span $(\mathrm{max}-\mathrm{min}+1)$ (`256`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Keys_In_Range` | Empty/singleton or span $\le \mathrm{Max\_Range}$ |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending pigeonhole + bubble finish (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
