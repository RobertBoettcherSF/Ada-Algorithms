# Counting Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of classic [counting sort](https://en.wikipedia.org/wiki/Counting_sort) on a bounded-key `Element` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it builds a histogram over keys in $0..\mathrm{Max\_Key}$, then emits each key $\mathrm{Hist}(K)$ times left-to-right (reconstruction / CDF expansion) — using a **fixed** count table of size $k = \mathrm{Max\_Key}+1$, running in $O(n+k)$, and requiring only $O(k)$ auxiliary memory for the table (plus the live array).

$$
O(n + k),\quad k = \mathrm{Max\_Key}+1 = 256,\quad n \le \mathrm{Max\_N} = 64
$$

This is the SPARK Level 4 port of the companion package [Ada-Counting-Sort](https://github.com/RobertBoettcherSF/Ada-Counting-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_Length` / `Max_Range`, exceptions (`Invalid_Argument`), arbitrary `Integer` keys with dynamic min/max span, and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), keys restricted to `0 .. Max_Key` (`Max_Key = 255`), `In_Bounds` / `Is_Sorted` contracts, and machine-checkable absence of run-time errors. README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort).

## Features
* **`Sort (A)`**: Classic ascending counting sort (histogram → emit by ascending key).
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index / overflow errors, ghost occurrence lemmas that $\sum \mathrm{Hist} = n$, and loop invariants that the emitted prefix stays sorted.
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`. Element subtype enforces the key-domain cap.
* **Fixed count table**: `array (0 .. Max_Key) of Natural` — no dynamic allocation of a min..max span.

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $100\,000$) so array / arithmetic VCs stay within automated SMT reach.
* `Max_Key = 255` (sibling `Max_Range = 100\,000` over arbitrary `Integer` min..max) so the count table is a **static** `0 .. 255` array.
* No exceptions: length / shape are `Pre => In_Bounds (A)`; keys are the `Element` subtype `0 .. Max_Key`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* **Reconstruction emit** instead of reverse-scan placement: when `Element` *is* the key, equal keys are identical so content-level stability is vacuous. The non-SPARK sibling uses right-to-left placement for satellite stability; tests here still check multiset / permutation equality and agreement with a stable insertion-sort reference.
* Ghost `Occ` / `Sum_Occ` / `Sum_Hist` lemmas (binary-split induction) plus `pragma Loop_Invariant` so histogram cardinality and emit-cursor bounds are discharged at Level 4.
* **SPARK proves sortedness and permutation** (`Post => Is_Sorted (A) and then Is_Perm (A, A'Old)`): `Occ (A, V, Last)` counts V in `A (A'First .. Last)` and `Is_Perm` compares the counts of every value of either array. The proof counts per value through the histogram and emit loops (ghost Occ_P / Sum_Occ / Sum_Hist with binary-split induction lemmas; no Assume / Annotate). Loop invariants and the Posts of body-local subprograms are proved and not re-evaluated at run time (`Assertion_Policy` Ignore in the body: the count facts range over every value); the Post of `Sort`, including `Is_Perm`, is still checked by the tests. Before 2026-10-09 the Post said only `Is_Sorted`, which an all-zeros body also proves (tools/vv/contract_scan.csv).
* Tests check `Is_Perm` against an independent sorted-copy comparison on every pair of arrays of length 0 .. 4 over -1 .. 1 (14,762 pairs, origins 1 and 7).

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 374 assertions pass. Running `make prove` reports `Success: all checks proved (411 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, Wikipedia-style small example, full `0 .. Max_Key` domain edges, power-of-two and odd lengths.
* **Agreement**: `Sort` vs an independent insertion-sort reference; multiset / permutation equality on every case.
* **Tagged encodings**: Values such as `key×10 + tag` (kept in `0 .. Max_Key`) agree with the stable reference order.
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
* Histogram loop tracks `Hist (K) = Occ (A, I-1, K)`; ghost lemmas prove $\mathrm{Sum\_Hist} = n$; emit loop grows a sorted prefix keyed by the outer key cursor.
* **GNATprove Level 4:** `Success: all checks proved (411 checks).`
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.
