# Odd–Even Sort Algorithm in Ada/SPARK

## Project Overview
This repository contains a formally verified educational implementation of sequential in-place [odd–even sort](https://en.wikipedia.org/wiki/Odd%E2%80%93even_sort) (odd–even transposition sort / brick sort / parity sort) on an `Integer` array. Written in Ada 2022 and verified with SPARK (GNATprove Level 4), it alternates odd- and even-indexed adjacent compare-swaps (Wikipedia 0-based odd-then-even order) until a clean cycle (proved to sort and to terminate, with no finishing pass) — using only $O(1)$ auxiliary memory (**in-place**), and preserving equal-key order when the swap predicate is strict `>` (**stable**). It is **not** Batcher's odd–even mergesort.

$$
\text{best } O(n),\quad \text{average/worst } O(n^2),\quad \text{extra space } O(1)
$$

This is the SPARK Level 4 port of the companion package [Ada-Odd-Even-Sort](https://github.com/RobertBoettcherSF/Ada-Odd-Even-Sort) in the RobertBoettcherSF Ada algorithm series. The non-SPARK sibling exposes a larger `Max_N`, exceptions (`Invalid_Argument`), and arbitrary `A'First`; this port trades those for a hard classroom bound (`Max_N = 64`), `In_Bounds` / `Is_Sorted` contracts, and a proof that the odd–even cycles sort and terminate (no cap, no finishing pass). README links only — do not `with` sibling packages here. Closest SPARK sort sibling that shares the same array shape: [Ada-SPARK-Bubble-Sort](https://github.com/RobertBoettcherSF/Ada-SPARK-Bubble-Sort).

## Features
* **`Sort (A)`**: Classic in-place ascending odd–even (brick) sort: cycles until a cycle makes no swap.
* **`Is_Sorted` / `In_Bounds`**: Expression-function guards; `Is_Sorted` is the proved postcondition.
* **Formal Verification**: Designed for GNATprove Level 4 — absence of index errors; the odd–even cycles themselves are proved to sort (a swap-free cycle has seen every neighbour pair in order) and to terminate (ghost loop variant `Weight (A)` = $\sum_k k \cdot A(k)$, raised by every swap of an out-of-order pair).
* **Contract Discipline**: Preconditions replace exceptions; oversized arrays are `Pre` violations rather than `Invalid_Argument`.
* **Stability**: Strict `>` when swapping so equal keys keep relative order (checked by tagged tests).

## Deliberate simplifications vs non-SPARK sibling
* `Max_N = 64` (sibling uses $10\,000$) so array / arithmetic VCs stay within automated SMT reach.
* No exceptions: length / shape are `Pre => In_Bounds (A)`.
* Indices fixed at `A'First = 1` (sibling allows arbitrary `A'First`).
* Like the sibling, the cycle loop runs until a clean cycle; termination is proved by a loop variant, not by a cap, and there is no finishing pass.
* **SPARK proves sortedness** (`Post => Is_Sorted (A)`). Full multiset / permutation equality is **checked by tests**, not claimed as a Level-4 postcondition.

## Algorithm
1. If $n \le 1$, return.
2. Repeat cycles until a cycle makes no swap:
   * **Odd phase:** compare/swap 1-based pairs $(2,3),\ (4,5),\ \ldots$ (Wikipedia 0-based offsets $1,3,5,\ldots$).
   * **Even phase:** compare/swap 1-based pairs $(1,2),\ (3,4),\ \ldots$ (Wikipedia 0-based offsets $0,2,4,\ldots$).
3. A swap-free cycle has found every neighbour pair in order, so the array is sorted.

Empty and singleton arrays are no-ops.

## Usage
* **Build:** `make`
* **Run tests:** `make test`
* **Verify proofs:** `make prove`

**Expected output:**
When you run `make test`, you will see all 260 assertions pass. Running `make prove` reports `Success: all checks proved (209 checks).`

## Testing
* **Functional correctness**: Empty / singleton, reverse / already-sorted / almost-sorted, README walk-through, brick odd/even length patterns, signed domain, power-of-two and odd lengths up to `Max_N`.
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
* Phase loops use `pragma Loop_Invariant` / `Loop_Variant`: without a swap the array is unchanged and every pair of the phase's parity is in order; with one, the ghost `Weight` grew (`Lemma_Swap_Weight`). The cycle loop's variant is `Increases => Weight (A)`.
* **GNATprove Level 4:** `Success: all checks proved (269 checks).` (gnatprove 16.1)
* **Zero Intentional Gaps:** no `pragma Annotate (GNATprove, Intentional, …)` suppressions.

## API Summary
| Entity | Role |
| ------ | ---- |
| `Element_Array` | `array (Positive range <>) of Integer` |
| `Max_N` | Classroom capacity bound (`64`) |
| `In_Bounds` | `A'First = 1` and `A'Last in 0 .. Max_N` |
| `Is_Sorted` | Adjacent-nondecreasing predicate |
| `Sort` | Ascending in-place odd–even sort (`Post => Is_Sorted`) |

## License
MIT License — Copyright (c) 2026 Sternenfisch.
