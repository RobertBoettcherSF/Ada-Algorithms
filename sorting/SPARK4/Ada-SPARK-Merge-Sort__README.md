# Merge Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic stable [merge sort](https://en.wikipedia.org/wiki/Merge_sort) (von Neumann, 1945) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it uses **iterative bottom-up** merging with a fixed temporary buffer of size $\mathrm{Max\_N}$: start from unit runs, then stably merge adjacent Width-runs into $2\cdot\mathrm{Width}$-runs (prefer left on ties $L \le R$) until one run remains — preserving equal-key order (**stable**), running in $\Theta(n\log n)$, and using $\Theta(n)$ auxiliary memory for the temp buffer.

$$
\Theta(n \log n),\quad \text{extra space } \Theta(n),\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Merge-Sort](https://github.com/RobertBoettcherSF/Ada-Merge-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling uses top-down recursion, a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, a static `Temp (1 .. Max_N)`, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort).

## Features
* **`Sort (A)`**: Classic stable ascending bottom-up merge sort via a fixed temp buffer.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors, stable merge invariants, and `Sorted_Runs` / ghost lemmas that doubling Width preserves run sortedness until $\mathrm{Width} \ge n$.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Prefer left when $L \le R$ so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Iterative bottom-up** instead of top-down recursion (sibling): fixed `Temp (1 .. Max_N)`, `Merge_Pass` / recursive `Merge_From` over Width-aligned pairs, and ghost `Sorted_Runs` lemmas so Level 4 discharges sortedness without deep recursive split contracts.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 208 assertions pass. Running `make prove` reports `Success: all checks proved (433 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style example, signed domain, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Stability**: Tagged keys (`key×1000 + arrival_tag`) keep tag order for equal keys.
* **Contract helpers**: `Is_Sorted` true/false; `In_Bounds` at `Max_N` and empty.
* **Contract discipline**: Only valid call paths are exercised (no exception handlers). Tests stay at $n \le 64$ (no combinatorial explosion).

## Building
**Prerequisites:** GNAT with SPARK/GNATprove support, Ada 2022 (`-gnat2022`). Source the SPARK environment if needed (`source /home/box/deps/spark/env.sh`).

**Commands:**
* `make` — Builds the test binary.
* `make test` — Compiles and executes the test suite.
* `make prove` — Runs GNATprove at Level 4.
* `make clean` — Removes `obj/` and `bin/`.

## Proof Status
* Package spec and body use `SPARK_Mode => On` with `Pre` / `Post` / `Global => null`.
* Stable `Merge` uses `pragma Loop_Invariant` / `Loop_Variant`; bottom-up `Merge_From` / `Merge_Pass` plus ghost `Sorted_Runs` / `Lemma_Short_Tail` discharge Width doubling at Level 4.
* **GNATprove Level 4:** `Success: all checks proved (433 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
