# Insertion Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic stable in-place [insertion sort](https://en.wikipedia.org/wiki/Insertion_sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it builds a sorted prefix left-to-right: for each new key, strictly larger predecessors shift one slot right (never $\le$ / $\ge$), then the key is inserted — preserving equal-key order (**stable**), using only $O(1)$ auxiliary memory (**in-place**), and adapting toward $O(n)$ on nearly sorted input (**online** / adaptive).

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Insertion-Sort](https://github.com/RobertBoettcherSF/Ada-Insertion-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK search sibling that shares the same array shape: [Ada-SPARK-Binary-Search](https://github.com/RobertBoettcherSF/Ada-SPARK-Binary-Search).

## Features
* **`Sort (A)`**: Classic stable in-place ascending insertion sort.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, and loop invariants that the sorted prefix grows by one element per outer step.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `<` when shifting so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* Nested `Insert_Step` plus `pragma Loop_Invariant` / `Loop_Variant` so the shift loop and outer prefix growth are discharged at Level 4.
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`): `Occ (A, V, Last)` counts V in `A (A'First .. Last)` and `Is_Perm` compares the counts of every value of either array. The proof carries the ghost `Same_Occ` (equal counts for every Integer) through the loops with swap / point-update lemmas (no Assume / Annotate). Loop invariants and the Posts of body-local subprograms are proved and not re-evaluated at run time (`Assertion_Policy` Ignore in the body: `Same_Occ` ranges over every Integer); the Post of `Sort`, including `Is_Perm`, is still checked by the tests. Before 2026-10-09 the Post said only `Is_Sorted`, which an all-zeros body also proves (tools/vv/contract_scan.csv).
* Tests check `Is_Perm` against an independent sorted-copy comparison on every pair of arrays of length 0 .. 4 over -1 .. 1 (14,762 pairs, origins 1 and 7).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 233 assertions pass. Running `make prove` reports `Success: all checks proved (213 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia example, signed domain, power-of-two and odd lengths.
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
* Inner shift loop uses `pragma Loop_Invariant` and `Loop_Variant`; outer loop grows a sorted prefix via `Insert_Step`.
* **GNATprove Level 4:** `Success: all checks proved (213 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
