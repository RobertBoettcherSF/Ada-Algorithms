# Quicksort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [quicksort](https://en.wikipedia.org/wiki/Quicksort) (Tony Hoare, 1959/1961) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it chooses a **median-of-three** pivot, **Lomuto-partitions** so the pivot lands in a final slot, and recurses on both sides — **unstable**, **in-place** aside from $O(\log n)$ average recursion stack, and typically $O(n \log n)$.

$$
\text{average } O(n \log n),\quad \text{worst } O(n^2),\quad \text{extra space } O(\log n)\ \text{average stack}
$$

This is the SPARK Level 4 port of the companion package [Ada-Quicksort](https://github.com/RobertBoettcherSF/Ada-Quicksort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), Hoare partition, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, Lomuto (so the pivot has a known final index), and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort siblings that share the same array shape: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort) and [Ada-SPARK-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Merge-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending quicksort (median-of-three + Lomuto).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, a `Subprogram_Variant` on recursive `Sort_Range`, and loop invariants that the Lomuto split and partition bounds reassemble into a sorted slice.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Unstable**: Equal keys may change relative order (permutation is checked by tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic / recursion VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Lomuto partition** (sibling uses Hoare): the pivot is swapped into a final slot $P$, so the recursive sides are $A(\mathrm{Lo} .. P-1)$ and $A(P+1 .. \mathrm{Hi})$ and the glue lemma is adjacent-sortedness plus the two junctions at $P$.
* Median-of-three is kept (first / middle / last, median parked at `Hi`) so sorted and reverse inputs avoid the common $O(n^2)$ first/last-pivot pathology.
* Bounded recursive `Sort_Range` with `Subprogram_Variant => (Decreases => Hi - Lo)` rather than an explicit stack; depth is at most $\mathrm{Max\_N}$.
* Ghost `All_Leq` / `All_Geq` value bounds are threaded through partition and recursion so the partition property survives the recursive permutations (full multiset equality is **not** a Level-4 postcondition).
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition (a simple ghost permutation lemma is not required here).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 297 assertions pass. Running `make prove` reports `Success: all checks proved (327 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia example, signed domain including `Integer'First` / `Integer'Last`, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Pivot stress**: Sorted, reverse, all-equal, sawtooth, organ-pipe, and random arrays up to `Max_N`.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Lomuto scan uses `pragma Loop_Invariant`; recursive `Sort_Range` uses `Subprogram_Variant` and a ghost glue lemma to join the sorted sides at the pivot.
* **GNATprove Level 4:** `Success: all checks proved (327 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
