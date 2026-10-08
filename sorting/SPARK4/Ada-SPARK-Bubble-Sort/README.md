# Bubble Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [bubble sort](https://en.wikipedia.org/wiki/Bubble_sort) (sinking sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it repeatedly compares adjacent pairs and swaps when out of order, shrinking the unsorted suffix by one after each pass and stopping early on a swap-free pass — using only $O(1)$ auxiliary memory (**in-place**), adapting toward $O(n)$ on already-sorted input, and preserving equal-key order when the swap predicate is strict `>` (**stable**).

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-Bubble-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending bubble sort with early exit and a shrinking unsorted suffix.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that the sorted suffix grows by one element per outer step with the partition property vs. the remaining prefix.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `>` when swapping so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* Nested `Bubble_Pass` plus `pragma Loop_Invariant` / `Loop_Variant` so the adjacent-swap pass and outer suffix growth are discharged at Level 4.
* Suffix shrinks by one per pass (last-swap bound of the sibling is omitted); early exit on a clean pass is kept and proved.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition (a simple ghost permutation lemma is not required here).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 283 assertions pass. Running `make prove` reports `Success: all checks proved (184 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia example, turtle cases, signed domain, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Inner adjacent-swap loop uses `pragma Loop_Invariant`; outer loop shrinks the unsorted suffix via `Bubble_Pass` with partition predicates and early exit on a clean pass.
* **GNATprove Level 4:** `Success: all checks proved (184 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
