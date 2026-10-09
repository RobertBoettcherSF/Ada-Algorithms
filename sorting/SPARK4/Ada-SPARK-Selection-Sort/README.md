# Selection Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic in-place [selection sort](https://en.wikipedia.org/wiki/Selection_sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it grows a sorted prefix left-to-right: each pass finds the minimum of the unsorted suffix and swaps it into the next prefix slot — using only $O(1)$ auxiliary memory (**in-place**), with a data-independent comparison count, and at most $n-1$ swaps. The swap formulation is **not stable**.

$$
\text{comparisons } \Theta(n^2),\quad \text{swaps } \le n-1,\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Selection-Sort](https://github.com/RobertBoettcherSF/Ada-Selection-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length`, exceptions (`Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Insertion-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending selection sort (min of suffix → prefix).
* **`Sort_Descending (A)`**: Same structure selecting the maximum of each suffix (nonincreasing).
* **`Is_Sorted` / `Is_Sorted_Descending` / `In_Bounds`**: Expression-function guards; sortedness is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that the sorted prefix grows by one element per outer step with the partition property vs. the remaining suffix.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* Nested `Select_Min_Step` / `Select_Max_Step` plus `pragma Loop_Invariant` so the scan loop, swap, and outer prefix growth are discharged at Level 4.
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`, and `Is_Sorted_Descending` for `Sort_Descending`): `Occ (A, V, Last)` counts V in `A (A'First .. Last)` and `Is_Perm` compares the counts of every value of either array. The proof carries the ghost `Same_Occ` (equal counts for every Integer) through the selection steps with swap / point-update lemmas (no Assume / Annotate). Loop invariants and the Posts of body-local subprograms are proved and not re-evaluated at run time (`pragma Assertion_Policy (Loop_Invariant => Ignore, Post => Ignore)` in the body: `Same_Occ` ranges over every Integer); the Post, including `Is_Perm`, is still checked by the tests. Before 2026-10-09 the Post said only `Is_Sorted`, which an all-zeros body also proves (tools/vv/contract_scan.csv).
* Tests check `Is_Perm` against an independent sorted-copy comparison on every pair of arrays of length 0 .. 4 over -1 .. 1 (14,762 pairs, origins 1 and 7).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 169 assertions pass. Running `make prove` reports `Success: all checks proved (290 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia example, signed domain, power-of-two and odd lengths.
* **Agreement**: `Sort` / `Sort_Descending` vs independent references; multiset / permutation equality on every case.
* **Contract helpers**: `Is_Sorted` / `Is_Sorted_Descending` true/false; `In_Bounds` at `Max_N` and empty.
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
* Inner scan loops use `pragma Loop_Invariant`; outer loops grow a sorted (or reverse-sorted) prefix via `Select_Min_Step` / `Select_Max_Step` with partition predicates.
* **GNATprove Level 4:** `Success: all checks proved (290 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
