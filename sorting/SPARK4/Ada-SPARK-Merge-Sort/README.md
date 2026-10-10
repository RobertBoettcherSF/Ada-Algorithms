# Merge Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic stable [merge sort](https://en.wikipedia.org/wiki/Merge_sort) (von Neumann, 1945) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it uses **iterative bottom-up** merging with a fixed temporary buffer of size $\mathrm{Max\_N}$: start from unit runs, then stably merge adjacent Width-runs into $2\cdot\mathrm{Width}$-runs (prefer left on ties $L \le R$) until one run remains — preserving equal-key order (**stable**), running in $\Theta(n\log n)$, and using $\Theta(n)$ auxiliary memory for the temp buffer.

$$
\Theta(n \log n),\quad \text{extra space } \Theta(n),\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-Merge-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses top-down recursion, a larger `Max_N`, exceptions (`Invalid_Argument`); this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a static `Temp (1 .. Max_N)`, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort).

## Features
* **`Sort (A)`**: Classic stable ascending bottom-up merge sort via a fixed temp buffer.
* **`Is_Sorted` / `In_Bounds` / `Occ` / `Is_Perm`**: Expression-function guards and value counts; `Is_Sorted (A) and then Is_Perm (A, A'Old)` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, stable merge invariants, and `Sorted_Runs` / ghost lemmas that doubling Width preserves run sortedness until $\mathrm{Width} \ge n$.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Prefer left when $L \le R$ so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Any `A'First` in `1 .. Max_N` (index subtype `Live_Index`, at most `Max_N` elements); indices are First-relative. Tests sort shifted copies at origins 2, 7, `Max_N / 2 + 1` and slices flush to `Max_N`.
* **Iterative bottom-up** instead of top-down recursion (sibling): fixed `Temp (1 .. Max_N)`, `Merge_Pass` / recursive `Merge_From` over Width-aligned pairs (runs aligned at `A'First`; `Temp` covers every possible `A'Range`), and ghost `Sorted_Runs` lemmas so Level 4 discharges sortedness without deep recursive split contracts.
* **SPARK proves sortedness and permutation** (`Post => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old)`; before 2026-10-10 the Post said only `Is_Sorted`, which a constant-fill body also proves: tools/vv/contract_scan.csv). `Merge` carries, for every value, count of `Temp (Lo .. K - 1)` = count of `A (Lo .. I - 1)` + count of `A (Mid + 1 .. J - 1)` through its three loops, and the copy-back keeps the counts of the whole array (`Lemma_Occ_Eq` / `Lemma_Occ_Split`); `Merge_From`, `Merge_Pass` and `Sort` chain that `Same_Occ`. It ranges over every `Integer` value, so the body's contracts, invariants and assertions are proved and not checked at run time (`Assertion_Policy` in the body, `tools/vv/proof_escapes.csv` runtime_only); the spec Post of `Sort` still runs in the tests.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 235 assertions pass. Running `make prove` reports `Success: all checks proved (633 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style example, signed domain, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ (no combinatorial explosion).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Put `gnatprove` on PATH if needed (e.g. via Alire: `alr get gnatprove`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Stable `Merge` uses `pragma Loop_Invariant` / `Loop_Variant`; bottom-up `Merge_From` / `Merge_Pass` plus ghost `Sorted_Runs` / `Lemma_Short_Tail` discharge Width doubling at Level 4.
* **GNATprove Level 4:** `Success: all checks proved (633 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
